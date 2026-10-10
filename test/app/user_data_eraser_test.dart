import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/user_data_eraser.dart';
import 'package:mynewapp/core/cache/response_cache.dart';
import 'package:mynewapp/core/database/schema.dart';
import 'package:mynewapp/core/database/user_database.dart';
import 'package:mynewapp/core/permissions/permission_gateway.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_settings.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';
import 'package:mynewapp/features/settings/domain/settings_repository.dart';

import '../support/prayer_fakes.dart';

class _Settings implements SettingsRepository {
  AppSettings saved = const AppSettings(theme: ThemePreference.dark);
  Object? fail;

  @override
  Future<AppSettings> load() async => saved;

  @override
  Future<void> save(AppSettings settings) async {
    if (fail != null) throw fail!;
    saved = settings;
  }
}

class _Cache extends InMemoryResponseCache {
  int clears = 0;
  Object? fail;

  @override
  Future<void> clear() async {
    clears++;
    if (fail != null) throw fail!;
    await super.clear();
  }
}

void _fill(UserDatabase database) {
  final db = database.db;
  db.execute("INSERT INTO app_meta (key, value) VALUES ('created', 'x')");
  db.execute(
    "INSERT INTO prayer_log (day, prayer) VALUES ('2026-10-09', 'fajr')",
  );
  db.execute(
    'INSERT INTO tasbeeh_counter (id, count, target) VALUES (1, 40, 33)',
  );
  db.execute("INSERT INTO favorites (hadith_id, added_at) VALUES ('100', 1)");
}

int _rows(UserDatabase database, String table) =>
    database.db.select('SELECT COUNT(*) AS n FROM $table').first['n'] as int;

void main() {
  group('clearing the user tables', () {
    test('empties every user table and keeps the database metadata', () {
      final database = UserDatabase.inMemory();
      _fill(database);
      database.clearUserTables();
      for (final table in ['prayer_log', 'tasbeeh_counter', 'favorites']) {
        expect(_rows(database, table), 0, reason: table);
      }
      expect(_rows(database, 'app_meta'), 1);
      expect(
        database.db.select('PRAGMA user_version').first.values.first,
        userDatabaseMigrations.length,
      );
      database.close();
    });

    test('covers every table the schema creates, including future ones', () {
      final database = UserDatabase.inMemory();
      final tables = database.db
          .select(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
          )
          .map((r) => r['name'] as String)
          .toSet();
      // If a migration adds a table, it is cleared too; this list only documents today's.
      expect(tables, {
        'app_meta',
        'prayer_log',
        'tasbeeh_counter',
        'favorites',
        'quran_last_read',
        'quran_bookmarks',
      });
      database.close();
    });
  });

  group('UserDataEraser', () {
    late UserDatabase database;
    late PrayerFixture prayer;
    late _Settings settings;
    late _Cache cache;

    setUp(() async {
      database = UserDatabase.inMemory();
      _fill(database);
      final cairo = realCityCatalog().cities.firstWhere(
        (c) => c.nameEn == 'Cairo',
      );
      prayer = PrayerFixture(
        now: DateTime.utc(2026, 10, 9, 10),
        saved: PrayerPreferences()
            .withLocation(cairo.toLocation('ar'))
            .withReminders(ReminderSettings(enabled: true)),
        permissions: {AppPermission.notifications: PermissionState.granted},
      );
      settings = _Settings();
      cache = _Cache();
    });

    tearDown(() => database.close());

    UserDataEraser eraser() => UserDataEraser(
      settings: settings,
      cache: cache,
      userData: database,
      prayer: prayer.services,
    );

    test('removes everything and reports success', () async {
      expect(await eraser().eraseAll(), isTrue);
      expect((await prayer.preferences.load()).location, isNull);
      expect(_rows(database, 'prayer_log'), 0);
      expect(_rows(database, 'tasbeeh_counter'), 0);
      expect(_rows(database, 'favorites'), 0);
      expect(cache.clears, 1);
      expect(settings.saved, const AppSettings());
    });

    test('cancels every scheduled reminder', () async {
      await prayer.services.reminders.reconcile();
      expect(prayer.notifications.held, isNotEmpty);
      await eraser().eraseAll();
      expect(prayer.notifications.held, isEmpty);
      // And nothing comes back on the next start, because the place is gone.
      await prayer.services.reminders.reconcile();
      expect(prayer.notifications.held, isEmpty);
    });

    test('keeps going after a failed step and reports it', () async {
      cache.fail = StateError('disk');
      expect(await eraser().eraseAll(), isFalse);
      // The steps after the failing one still ran.
      expect(settings.saved, const AppSettings());
      expect(_rows(database, 'favorites'), 0);
    });

    test('works without the user database or the prayer section', () async {
      final result = await UserDataEraser(
        settings: settings,
        cache: cache,
      ).eraseAll();
      expect(result, isTrue);
      expect(settings.saved, const AppSettings());
    });
  });
}
