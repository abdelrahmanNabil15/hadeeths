import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/core/notifications/notification_gateway.dart';
import 'package:mynewapp/core/notifications/notification_sync.dart';
import 'package:mynewapp/core/notifications/planned_notification.dart';
import 'package:mynewapp/core/permissions/permission_gateway.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/salawat_settings.dart';
import 'package:mynewapp/features/prayer_times/presentation/salawat_wording.dart';
import 'package:mynewapp/l10n/app_localizations.dart';

import '../support/fake_backend.dart';
import '../support/prayer_fakes.dart';
import '../support/test_app.dart';

final _now = DateTime.utc(2026, 10, 9, 10);

PrayerFixture _fixture({ReminderSettings? reminders}) {
  final cairo = realCityCatalog().cities.firstWhere((c) => c.nameEn == 'Cairo');
  final f = PrayerFixture(
    saved: PrayerPreferences()
        .withLocation(cairo.toLocation('ar'))
        .withReminders(reminders ?? ReminderSettings()),
    now: _now,
  );
  f.gateway.states[AppPermission.notifications] = PermissionState.granted;
  return f;
}

/// Opens Prayer, then Reminders, then the given row under "More reminders".
Future<AppLocalizations> _open(
  WidgetTester tester,
  PrayerFixture f, {
  required String Function(AppLocalizations) row,
  String locale = 'en',
  bool tall = true,
}) async {
  if (tall) {
    tester.view.physicalSize = const Size(700, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  final l10n = lookupAppLocalizations(Locale(locale));
  await pumpApp(
    tester,
    FakeBackend(),
    locale: locale,
    features: const FeatureFlags(prayer: true),
    prayer: f.services,
  );
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(l10n.navPrayer),
    ),
  );
  await tester.pumpAndSettle();
  await scrollAndTap(tester, find.text(l10n.remindersHeading));
  await scrollAndTap(tester, find.text(row(l10n)));
  return l10n;
}

List<PlannedNotification> _salawat(PrayerFixture f) => [
  for (final s in f.notifications.sorted)
    if (NotificationPayload.decode(
          PendingEntry(id: s.id, payload: s.payload),
        )!.kind ==
        NotificationKind.salawat)
      NotificationPayload.decode(PendingEntry(id: s.id, payload: s.payload))!,
];

void main() {
  group('salawat page', () {
    testWidgets('shows the approved text and starts off', (tester) async {
      final f = _fixture();
      final l10n = await _open(tester, f, row: (l) => l.salawatTitle);
      expect(find.text(salawatNowText), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
      expect(find.text(l10n.salawatEveryHours(2)), findsOneWidget);
      expect(_salawat(f), isEmpty);
    });

    testWidgets('switching on schedules reminders with the approved text', (
      tester,
    ) async {
      final f = _fixture();
      await _open(tester, f, row: (l) => l.salawatTitle);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(f.preferences.stored.reminders.salawat.enabled, isTrue);
      expect(_salawat(f), isNotEmpty);
      expect(
        f.notifications.sorted
            .where((s) => s.content.title == salawatNowText)
            .length,
        _salawat(f).length,
      );
    });

    testWidgets('changing the interval is saved', (tester) async {
      final f = _fixture(
        reminders: ReminderSettings(salawat: SalawatSettings(enabled: true)),
      );
      final l10n = await _open(tester, f, row: (l) => l.salawatTitle);
      await scrollAndTap(tester, find.text(l10n.salawatEveryHours(4)));
      expect(f.preferences.stored.reminders.salawat.intervalMinutes, 240);
    });

    testWidgets('a window that ends before it starts is refused', (
      tester,
    ) async {
      final f = _fixture();
      final l10n = await _open(tester, f, row: (l) => l.salawatTitle);
      await scrollAndTap(tester, find.text(l10n.timeFrom));
      // Type 10:00 PM, after the end (9:00 PM).
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), '10');
      await tester.enterText(fields.at(1), '00');
      await tester.tap(find.text('PM'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.windowInvalid), findsOneWidget);
      expect(f.preferences.stored.reminders.salawat.windowStartMinute, 540);
    });
  });

  group('quiet hours page', () {
    testWidgets('switching on says what is held back', (tester) async {
      final f = _fixture(
        reminders: ReminderSettings(salawat: SalawatSettings(enabled: true)),
      );
      final l10n = await _open(tester, f, row: (l) => l.quietTitle);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(f.preferences.stored.reminders.quietEnabled, isTrue);
      // Default quiet hours 22:00 to 06:00 do not overlap 09:00 to 21:00.
      expect(find.text(l10n.quietHeldBack(0)), findsOneWidget);
    });

    testWidgets('quiet hours over the salawat times hold them back', (
      tester,
    ) async {
      final f = _fixture(
        reminders: ReminderSettings(
          quietEnabled: true,
          quietStartMinute: 14 * 60,
          quietEndMinute: 20 * 60,
          salawat: SalawatSettings(enabled: true),
        ),
      );
      final l10n = await _open(tester, f, row: (l) => l.quietTitle);
      expect(find.text(l10n.quietHeldBack(6)), findsOneWidget);
    });

    testWidgets('the silent-prayers switch is saved', (tester) async {
      final f = _fixture();
      final l10n = await _open(tester, f, row: (l) => l.quietTitle);
      await scrollAndTap(tester, find.text(l10n.quietPrayersSilent));
      expect(f.preferences.stored.reminders.quietForPrayers, isTrue);
    });
  });

  group('the reminders page lists both', () {
    testWidgets('with their state', (tester) async {
      final f = _fixture(
        reminders: ReminderSettings(salawat: SalawatSettings(enabled: true)),
      );
      final l10n = lookupAppLocalizations(const Locale('en'));
      tester.view.physicalSize = const Size(700, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpApp(
        tester,
        FakeBackend(),
        locale: 'en',
        features: const FeatureFlags(prayer: true),
        prayer: f.services,
      );
      await tester.tap(find.text(l10n.navPrayer).last);
      await tester.pumpAndSettle();
      await scrollAndTap(tester, find.text(l10n.remindersHeading));
      expect(find.text(l10n.remindersMore), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(l10n.salawatTitle)), findsWidgets);
      expect(find.text(l10n.statusOn), findsOneWidget);
      expect(find.text(l10n.statusOff), findsOneWidget);
    });
  });

  group('accessibility and layout', () {
    for (final locale in ['ar', 'en']) {
      for (final (name, row) in [
        ('salawat', (AppLocalizations l) => l.salawatTitle),
        ('quiet hours', (AppLocalizations l) => l.quietTitle),
      ]) {
        testWidgets('$name, $locale: 200% text, tap targets and labels', (
          tester,
        ) async {
          useSmallPhone(tester, textScale: 2);
          final handle = tester.ensureSemantics();
          final f = _fixture(
            reminders: ReminderSettings(
              quietEnabled: true,
              salawat: SalawatSettings(enabled: true),
            ),
          );
          await _open(tester, f, row: row, locale: locale, tall: false);
          expect(tester.takeException(), isNull);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          handle.dispose();
        });
      }
    }
  });
}
