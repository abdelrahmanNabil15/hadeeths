import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_library.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_settings.dart';

import '../support/adhan_fakes.dart';
import '../support/fake_backend.dart';
import '../support/prayer_fakes.dart';
import '../support/test_app.dart';

final _cairo = realCityCatalog().cities.firstWhere((c) => c.nameEn == 'Cairo');
final _now = DateTime.utc(2026, 10, 9, 10);

PrayerPreferences _saved({ReminderSettings? reminders}) => PrayerPreferences()
    .withLocation(_cairo.toLocation('ar'))
    .withReminders(reminders ?? ReminderSettings(enabled: true));

Future<void> _openReminders(WidgetTester tester, PrayerFixture f) async {
  tester.view.physicalSize = const Size(700, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await pumpApp(
    tester,
    FakeBackend(),
    features: const FeatureFlags(prayer: true, adhanSounds: true),
    prayer: f.services,
  );
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('الصلاة'),
    ),
  );
  await tester.pumpAndSettle();
  await tapVisible(tester, find.text('التذكيرات'));
}

void main() {
  testWidgets('the Adhan choice is not offered when the feature is off', (
    tester,
  ) async {
    final f = PrayerFixture(saved: _saved(), now: _now);
    await _openReminders(tester, f);
    expect(find.text('صوت إشعارات الهاتف'), findsOneWidget);
    expect(find.text('الأذان'), findsNothing);
  });

  testWidgets('nor on a phone that cannot use a downloaded sound', (
    tester,
  ) async {
    final f = PrayerFixture(
      saved: _saved(),
      now: _now,
      adhan: FakeAdhanLibrary()..supported = false,
    );
    await _openReminders(tester, f);
    expect(find.text('الأذان'), findsNothing);
  });

  testWidgets('download, use, and the reminders at prayer time play it', (
    tester,
  ) async {
    final library = FakeAdhanLibrary();
    final f = PrayerFixture(saved: _saved(), now: _now, adhan: library);
    await _openReminders(tester, f);
    await f.services.reminders.reconcile();
    expect(
      f.notifications.held.values.every((h) => h.content.customSound == null),
      isTrue,
    );

    await tapVisible(tester, find.text('الأذان'));
    expect(find.text('صوت الأذان'), findsOneWidget);
    // All five recordings are listed, none downloaded yet.
    for (final name in [
      'محمود الطوخي',
      'محمد رفعت',
      'عبد الباسط عبد الصمد',
      'أحمد الحداد',
      'علي بن أحمد ملا',
    ]) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    expect(find.textContaining('تنزيل ('), findsNWidgets(5));
    expect(find.text('الأذان المُنزَّل'), findsNothing);

    library.hold = Completer<void>();
    await tester.tap(find.textContaining('تنزيل (').first);
    await tester.pump();
    expect(find.text('جارٍ التنزيل…'), findsOneWidget);
    library.hold!.complete();
    await tester.pumpAndSettle();
    expect(library.downloads, ['tokhi']);
    expect(find.text('استخدم هذا الأذان'), findsOneWidget);

    await tester.tap(find.text('استخدم هذا الأذان'));
    await tester.pumpAndSettle();
    expect(find.text('قيد الاستخدام'), findsOneWidget);
    expect((await f.preferences.load()).reminders.adhanId, 'tokhi');
    await f.services.reminders.reconcile();
    expect(
      f.notifications.held.values.every(
        (h) => h.content.customSound?.id == 'tokhi',
      ),
      isTrue,
    );

    // Going back, the Reminders page names the adhan in use.
    await goBack(tester);
    expect(find.text('اختر أذانًا'), findsOneWidget);
    expect(find.text('محمود الطوخي'), findsOneWidget);
  });

  testWidgets('deleting the one in use goes back to the system sound', (
    tester,
  ) async {
    final library = FakeAdhanLibrary()..have.add('rifaat');
    final f = PrayerFixture(
      saved: _saved(
        reminders: ReminderSettings(enabled: true, adhanId: 'rifaat'),
      ),
      now: _now,
      adhan: library,
    );
    await _openReminders(tester, f);
    await tapVisible(tester, find.text('اختر أذانًا'));
    expect(find.text('قيد الاستخدام'), findsOneWidget);

    await tester.tap(find.byTooltip('حذف الملف'));
    await tester.pumpAndSettle();
    expect(library.deleted, ['rifaat']);
    expect(find.text('قيد الاستخدام'), findsNothing);
    final reminders = (await f.preferences.load()).reminders;
    expect(reminders.adhanId, isNull);
    expect(reminders.sound.name, 'system');
  });

  testWidgets('a failed download says why and can be tried again', (
    tester,
  ) async {
    final library = FakeAdhanLibrary()..fail = AdhanDownloadFailure.network;
    final f = PrayerFixture(saved: _saved(), now: _now, adhan: library);
    await _openReminders(tester, f);
    await tapVisible(tester, find.text('الأذان'));
    await tester.tap(find.textContaining('تنزيل (').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('تعذّر التنزيل'), findsOneWidget);
    expect(find.textContaining('تنزيل ('), findsNWidgets(5));

    library.fail = null;
    await tester.tap(find.textContaining('تنزيل (').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('تعذّر التنزيل'), findsNothing);
    expect(find.text('استخدم هذا الأذان'), findsOneWidget);
  });

  testWidgets('the wake-up alarm before Fajr: switch on, choose the time', (
    tester,
  ) async {
    final f = PrayerFixture(saved: _saved(), now: _now);
    await _openReminders(tester, f);
    expect(find.textContaining('قبل الفجر بـ'), findsNothing);

    await tapVisible(tester, find.text('أيقظني قبل الفجر'));
    expect((await f.preferences.load()).reminders.wakeUp, isTrue);
    // The four choices appear, 30 minutes selected.
    expect(find.textContaining('قبل الفجر بـ'), findsNWidgets(4));

    await tapVisible(tester, find.textContaining('قبل الفجر بـ ٤٥'));
    expect((await f.preferences.load()).reminders.wakeUpMinutes, 45);
    await f.services.reminders.reconcile();
    expect(
      f.notifications.held.values.any(
        (h) => h.content.bundledSound?.resource == 'wake_fajr',
      ),
      isTrue,
    );

    await tapVisible(tester, find.text('أيقظني قبل الفجر'));
    expect((await f.preferences.load()).reminders.wakeUp, isFalse);
    expect(find.textContaining('قبل الفجر بـ'), findsNothing);
  });

  testWidgets('with an early reminder the page says it is spoken', (
    tester,
  ) async {
    final f = PrayerFixture(
      saved: _saved(
        reminders: ReminderSettings(enabled: true, leadMinutes: 10),
      ),
      now: _now,
    );
    await _openReminders(tester, f);
    expect(find.textContaining('اقتربت'), findsOneWidget);
  });

  testWidgets('the adhan page fits at 200% text on a small phone', (
    tester,
  ) async {
    final f = PrayerFixture(
      saved: _saved(),
      now: _now,
      adhan: FakeAdhanLibrary()..have.add('rifaat'),
    );
    useSmallPhone(tester, textScale: 2);
    await pumpApp(
      tester,
      FakeBackend(),
      features: const FeatureFlags(prayer: true, adhanSounds: true),
      prayer: f.services,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('الصلاة'),
      ),
    );
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('التذكيرات'));
    await scrollAndTap(tester, find.text('الأذان'));
    expect(find.text('صوت الأذان'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
