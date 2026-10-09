import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/core/notifications/notification_gateway.dart';
import 'package:mynewapp/core/notifications/notification_sync.dart';
import 'package:mynewapp/core/permissions/permission_gateway.dart';
import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_settings.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/prayer_cubit.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';

import '../support/fake_backend.dart';
import '../support/prayer_fakes.dart';
import '../support/test_app.dart';

final _cairo = realCityCatalog().cities.firstWhere((c) => c.nameEn == 'Cairo');
final _now = DateTime.utc(2026, 10, 9, 10);

PrayerPreferences _saved({ReminderSettings? reminders, bool place = true}) {
  var p = PrayerPreferences();
  if (place) p = p.withLocation(_cairo.toLocation('ar'));
  return p.withReminders(reminders ?? ReminderSettings());
}

Future<void> _openReminders(
  WidgetTester tester,
  PrayerFixture f, {
  String locale = 'ar',
  AppSettings settings = const AppSettings(),
  bool tall = true,
}) async {
  if (tall) {
    tester.view.physicalSize = const Size(700, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  await pumpApp(
    tester,
    FakeBackend(),
    locale: locale,
    features: const FeatureFlags(prayer: true),
    prayer: f.services,
    settings: settings,
  );
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(locale == 'ar' ? 'الصلاة' : 'Prayer'),
    ),
  );
  await tester.pumpAndSettle();
  final tile = find.text(locale == 'ar' ? 'التذكيرات' : 'Reminders');
  if (!tall) await tester.scrollUntilVisible(tile, 300);
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

Finder _switchFor(String label) => find.widgetWithText(SwitchListTile, label);

void main() {
  group('the page', () {
    testWidgets('starts with reminders off and nothing scheduled', (
      tester,
    ) async {
      final f = PrayerFixture(saved: _saved(), now: _now);
      await _openReminders(tester, f);
      expect(find.text('التذكيرات متوقفة.'), findsOneWidget);
      expect(
        tester
            .widget<SwitchListTile>(_switchFor('ذكّرني عند أوقات الصلاة'))
            .value,
        isFalse,
      );
      expect(f.notifications.held, isEmpty);
      expect(f.gateway.requested, isEmpty);
    });

    testWidgets('lists the five prayers on and sunrise off', (tester) async {
      final f = PrayerFixture(saved: _saved(), now: _now);
      await _openReminders(tester, f);
      for (final name in ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء']) {
        expect(
          tester.widget<SwitchListTile>(_switchFor(name)).value,
          isTrue,
          reason: name,
        );
      }
      expect(
        tester.widget<SwitchListTile>(_switchFor('الشروق')).value,
        isFalse,
      );
    });
  });

  group('switching on', () {
    testWidgets('explains first, asks the system only after, then schedules', (
      tester,
    ) async {
      final f = PrayerFixture(saved: _saved(), now: _now);
      await _openReminders(tester, f);
      await tester.tap(_switchFor('ذكّرني عند أوقات الصلاة'));
      await tester.pumpAndSettle();
      expect(find.text('السماح بالإشعارات؟'), findsOneWidget);
      expect(f.gateway.requested, isEmpty);
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();
      expect(f.gateway.requested, [AppPermission.notifications]);
      expect(f.notifications.held, isNotEmpty);
      expect(f.preferences.stored.reminders.enabled, isTrue);
      expect(find.textContaining('تذكير'), findsWidgets);
      expect(find.textContaining('التذكير التالي: العصر'), findsOneWidget);
    });

    testWidgets('"not now" leaves it off and asks for nothing', (tester) async {
      final f = PrayerFixture(saved: _saved(), now: _now);
      await _openReminders(tester, f);
      await tester.tap(_switchFor('ذكّرني عند أوقات الصلاة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ليس الآن'));
      await tester.pumpAndSettle();
      expect(f.gateway.requested, isEmpty);
      expect(f.preferences.stored.reminders.enabled, isFalse);
      expect(f.notifications.held, isEmpty);
    });

    testWidgets('a refusal explains and offers the system settings', (
      tester,
    ) async {
      final f = PrayerFixture(saved: _saved(), now: _now);
      f.gateway.onRequest[AppPermission.notifications] = PermissionState.denied;
      f.notifications.allowed = false;
      await _openReminders(tester, f);
      await tester.tap(_switchFor('ذكّرني عند أوقات الصلاة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('الإشعارات متوقفة لهذا التطبيق'),
        findsOneWidget,
      );
      expect(f.preferences.stored.reminders.enabled, isFalse);
      await tester.tap(find.text('فتح الإعدادات'));
      await tester.pumpAndSettle();
      expect(f.gateway.settingsOpened, 1);
    });

    testWidgets(
      'turned off for good: no explanation, straight to the settings',
      (tester) async {
        final f = PrayerFixture(saved: _saved(), now: _now);
        f.gateway.states[AppPermission.notifications] =
            PermissionState.permanentlyDenied;
        f.notifications.allowed = false;
        await _openReminders(tester, f);
        await tester.tap(_switchFor('ذكّرني عند أوقات الصلاة'));
        await tester.pumpAndSettle();
        expect(find.text('السماح بالإشعارات؟'), findsNothing);
        expect(find.text('فتح الإعدادات'), findsOneWidget);
        expect(f.preferences.stored.reminders.enabled, isFalse);
      },
    );

    testWidgets(
      'without a place the page is not offered and nothing is asked',
      (tester) async {
        final f = PrayerFixture(saved: _saved(place: false), now: _now);
        await pumpApp(
          tester,
          FakeBackend(),
          features: const FeatureFlags(prayer: true),
          prayer: f.services,
        );
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('الصلاة'),
          ),
        );
        await tester.pumpAndSettle();
        // With no place the Prayer screen offers the set-up, not the reminders.
        expect(find.text('التذكيرات'), findsNothing);
        expect(f.gateway.requested, isEmpty);
      },
    );
  });

  group('changing the choices', () {
    Future<PrayerFixture> enabled(
      WidgetTester tester, {
      AppSettings settings = const AppSettings(),
    }) async {
      final f = PrayerFixture(
        saved: _saved(reminders: ReminderSettings(enabled: true)),
        now: _now,
        appSettings: settings,
      );
      f.gateway.states[AppPermission.notifications] = PermissionState.granted;
      await _openReminders(tester, f, settings: settings);
      return f;
    }

    testWidgets('turning a prayer off removes only that prayer', (
      tester,
    ) async {
      final f = await enabled(tester);
      await tester.tap(_switchFor('العصر'));
      await tester.pumpAndSettle();
      final keys = {
        for (final h in f.notifications.held.values)
          NotificationPayload.decode(
            PendingEntry(id: h.id, payload: h.payload),
          )!.key,
      };
      expect(keys, isNot(contains('asr')));
      expect(keys, contains('isha'));
      expect(
        f.preferences.stored.reminders.prayers,
        isNot(contains(Prayer.asr)),
      );
    });

    testWidgets('a lead time rewrites the reminders', (tester) async {
      final f = await enabled(tester);
      await tester.tap(find.text('قبل ١٠ دقائق'));
      await tester.pumpAndSettle();
      expect(f.preferences.stored.reminders.leadMinutes, 10);
      expect(
        f.notifications.sorted.first.content.title,
        'صلاة العصر بعد ١٠ دقائق',
      );
    });

    testWidgets('silent and no vibration', (tester) async {
      final f = await enabled(tester);
      await tester.tap(find.text('صامت'));
      await tester.pumpAndSettle();
      await tester.tap(_switchFor('الاهتزاز'));
      await tester.pumpAndSettle();
      for (final h in f.notifications.held.values) {
        expect(h.content.sound, NotificationSound.silent);
        expect(h.content.vibrate, isFalse);
      }
    });

    testWidgets('switching off removes every reminder', (tester) async {
      final f = await enabled(tester);
      expect(f.notifications.held, isNotEmpty);
      await tester.tap(_switchFor('ذكّرني عند أوقات الصلاة'));
      await tester.pumpAndSettle();
      expect(f.notifications.held, isEmpty);
      expect(f.preferences.stored.reminders.enabled, isFalse);
    });

    testWidgets('the test reminder shows at once', (tester) async {
      final f = await enabled(tester);
      await tester.tap(find.text('إرسال تذكير تجريبي'));
      await tester.pumpAndSettle();
      expect(f.notifications.shown, hasLength(1));
      expect(f.notifications.shown.single.title, 'تذكير تجريبي');
    });

    testWidgets('the test reminder asks permission first when it is missing', (
      tester,
    ) async {
      final f = PrayerFixture(saved: _saved(), now: _now);
      await _openReminders(tester, f);
      await tester.tap(find.text('إرسال تذكير تجريبي'));
      await tester.pumpAndSettle();
      expect(find.text('السماح بالإشعارات؟'), findsOneWidget);
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();
      expect(f.notifications.shown, hasLength(1));
    });

    testWidgets('English interface', (tester) async {
      final f = PrayerFixture(
        saved: _saved(
          reminders: ReminderSettings(enabled: true, leadMinutes: 5),
        ),
        now: _now,
        appSettings: const AppSettings(language: AppLanguage.english),
      );
      f.gateway.states[AppPermission.notifications] = PermissionState.granted;
      await _openReminders(
        tester,
        f,
        locale: 'en',
        settings: const AppSettings(language: AppLanguage.english),
      );
      expect(find.text('Remind me at prayer times'), findsOneWidget);
      expect(find.text('5 minutes before'), findsOneWidget);
      expect(find.text('At the time'), findsOneWidget);
      expect(
        f.notifications.sorted.first.content.title,
        'Asr prayer in 5 minutes',
      );
    });
  });

  group('exact timing', () {
    Future<PrayerFixture> open(WidgetTester tester) async {
      final f = PrayerFixture(
        saved: _saved(reminders: ReminderSettings(enabled: true)),
        now: _now,
      );
      f.gateway.states[AppPermission.notifications] = PermissionState.granted;
      await _openReminders(tester, f);
      return f;
    }

    testWidgets(
      'the control is there on Android, off by default, with its note',
      (tester) async {
        final f = await open(tester);
        expect(
          tester.widget<SwitchListTile>(_switchFor('التوقيت الدقيق')).value,
          isFalse,
        );
        expect(
          find.textContaining('قد يتأخر النظام في إيصال التذكير'),
          findsOneWidget,
        );
        expect(f.notifications.held.values.every((h) => !h.exact), isTrue);
      },
    );

    testWidgets(
      'explains first, opens the system page after, then reminders are exact',
      (tester) async {
        final f = await open(tester);
        await tester.tap(_switchFor('التوقيت الدقيق'));
        await tester.pumpAndSettle();
        expect(find.text('السماح بالتوقيت الدقيق؟'), findsOneWidget);
        expect(f.gateway.requested, isEmpty);
        await tester.tap(find.text('متابعة'));
        await tester.pumpAndSettle();
        expect(f.gateway.requested, [AppPermission.exactAlarms]);
        expect(f.preferences.stored.reminders.exactTiming, isTrue);
        expect(f.notifications.held.values.every((h) => h.exact), isTrue);
        // The late-delivery note goes away once timing is exact.
        expect(
          find.textContaining('قد يتأخر النظام في إيصال التذكير'),
          findsNothing,
        );
      },
    );

    testWidgets('"not now" leaves it off and asks for nothing', (tester) async {
      final f = await open(tester);
      await tester.tap(_switchFor('التوقيت الدقيق'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ليس الآن'));
      await tester.pumpAndSettle();
      expect(f.gateway.requested, isEmpty);
      expect(f.preferences.stored.reminders.exactTiming, isFalse);
    });

    testWidgets('if the system does not allow it, it stays off and says why', (
      tester,
    ) async {
      final f = await open(tester);
      f.gateway.onRequest[AppPermission.exactAlarms] = PermissionState.denied;
      await tester.tap(_switchFor('التوقيت الدقيق'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();
      expect(f.preferences.stored.reminders.exactTiming, isFalse);
      expect(find.textContaining('التوقيت الدقيق غير مسموح'), findsOneWidget);
      expect(find.text('فتح الإعدادات'), findsOneWidget);
    });

    testWidgets('switching it off goes back to the inexact schedule', (
      tester,
    ) async {
      final f = await open(tester);
      await tester.tap(_switchFor('التوقيت الدقيق'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();
      await tester.tap(_switchFor('التوقيت الدقيق'));
      await tester.pumpAndSettle();
      expect(f.preferences.stored.reminders.exactTiming, isFalse);
      expect(f.notifications.held.values.every((h) => !h.exact), isTrue);
    });

    testWidgets(
      'permission taken away later: reminders still scheduled, the page warns',
      (tester) async {
        final f = PrayerFixture(
          saved: _saved(
            reminders: ReminderSettings(enabled: true, exactTiming: true),
          ),
          now: _now,
        );
        f.gateway.states[AppPermission.notifications] = PermissionState.granted;
        f.notifications.exactAllowed = false;
        await _openReminders(tester, f);
        expect(find.textContaining('التوقيت الدقيق غير مسموح'), findsOneWidget);
        expect(f.notifications.held, isNotEmpty);
      },
    );
  });

  group('when the system permission is taken away later', () {
    testWidgets('the page shows it and offers the settings', (tester) async {
      final f = PrayerFixture(
        saved: _saved(reminders: ReminderSettings(enabled: true)),
        now: _now,
      );
      f.gateway.states[AppPermission.notifications] = PermissionState.denied;
      f.notifications.allowed = false;
      await _openReminders(tester, f);
      expect(
        find.textContaining('الإشعارات متوقفة لهذا التطبيق'),
        findsOneWidget,
      );
      expect(find.text('فتح الإعدادات'), findsOneWidget);
      expect(f.notifications.held, isEmpty);
    });
  });

  group('keeping up with the prayer times', () {
    test('a new place moves the reminders without opening this page', () async {
      final f = PrayerFixture(
        saved: _saved(reminders: ReminderSettings(enabled: true)),
        now: _now,
      );
      await f.services.reminders.reconcile();
      final before = f.notifications.sorted.first.fireAt;
      final cubit = PrayerCubit(f.services);
      await cubit.load();
      final newYork = realCityCatalog().cities.firstWhere(
        (c) => c.nameEn == 'New York',
      );
      await cubit.selectCity(newYork, languageCode: 'ar');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(f.notifications.sorted.first.fireAt, isNot(before));
    });

    test('a new calculation method moves them too', () async {
      final f = PrayerFixture(
        saved: _saved(reminders: ReminderSettings(enabled: true)),
        now: _now,
      );
      await f.services.reminders.reconcile();
      final before = f.notifications.sorted.map((h) => h.fireAt).toList();
      final cubit = PrayerCubit(f.services);
      await cubit.load();
      await cubit.chooseMethod(CalculationMethodId.karachi);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        f.notifications.sorted.map((h) => h.fireAt).toList(),
        isNot(before),
      );
    });
  });

  group('accessibility and layout', () {
    for (final locale in ['ar', 'en']) {
      for (final theme in [ThemePreference.light, ThemePreference.dark]) {
        testWidgets('guidelines hold in $locale / ${theme.name}', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          final f = PrayerFixture(
            saved: _saved(reminders: ReminderSettings(enabled: true)),
            now: _now,
            appSettings: AppSettings(theme: theme),
          );
          f.gateway.states[AppPermission.notifications] =
              PermissionState.granted;
          await _openReminders(
            tester,
            f,
            locale: locale,
            settings: AppSettings(theme: theme),
          );
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });
      }
    }

    for (final scale in [1.3, 2.0]) {
      testWidgets('no overflow at ${(scale * 100).round()}% text', (
        tester,
      ) async {
        useSmallPhone(tester, textScale: scale);
        final f = PrayerFixture(
          saved: _saved(reminders: ReminderSettings(enabled: true)),
          now: _now,
        );
        f.gateway.states[AppPermission.notifications] = PermissionState.granted;
        await _openReminders(tester, f, tall: false);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(find.text('إرسال تذكير تجريبي'), 300);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
