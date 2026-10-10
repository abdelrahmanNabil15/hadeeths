import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/app/shell/app_shell.dart';
import 'package:mynewapp/app/widget_snapshot.dart';
import 'package:mynewapp/app/widget_updating_reminders.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/platform/home_widget_bridge.dart';
import 'package:mynewapp/features/prayer_times/data/adhan_prayer_times_calculator.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_service.dart';
import 'package:mynewapp/features/prayer_times/presentation/pages/prayer_page.dart';
import 'package:mynewapp/l10n/app_localizations.dart';

import '../support/fake_backend.dart';
import '../support/prayer_fakes.dart';
import '../support/test_app.dart';

final _now = DateTime.utc(2026, 10, 9, 10);

PrayerPreferences _cairo() {
  final cairo = realCityCatalog().cities.firstWhere((c) => c.nameEn == 'Cairo');
  return PrayerPreferences().withLocation(cairo.toLocation('ar'));
}

class _Bridge implements HomeWidgetBridge {
  final updates = <String>[];
  int clears = 0;
  bool? enabled;
  bool fail = false;
  String? launch;
  final _routes = StreamController<String>.broadcast();

  void tap() => _routes.add('prayer');

  @override
  Future<void> update(String snapshot) async {
    if (fail) throw StateError('no widget host');
    updates.add(snapshot);
  }

  @override
  Future<void> clear() async {
    if (fail) throw StateError('no widget host');
    clears++;
  }

  @override
  Future<void> setEnabled(bool on) async => enabled = on;

  @override
  Future<String?> takeLaunchRoute() async {
    final route = launch;
    launch = null;
    return route;
  }

  @override
  Stream<String> get routes => _routes.stream;
}

class _Reminders implements ReminderService {
  int reconciles = 0;
  int cancels = 0;

  @override
  Future<ReminderStatus> reconcile() async {
    reconciles++;
    return const ReminderStatus(scheduled: 3);
  }

  @override
  Future<ReminderStatus> status() async => const ReminderStatus();

  @override
  Future<void> sendTest() async {}

  @override
  Future<void> cancelAll() async => cancels++;
}

String? _snapshot({
  PrayerPreferences? prefs,
  String language = 'ar',
  bool arabicDigits = true,
}) => buildWidgetSnapshot(
  preferences: prefs ?? _cairo(),
  calculator: const AdhanPrayerTimesCalculator(),
  l10n: lookupAppLocalizations(Locale(language)),
  digits: Digits(arabicIndic: arabicDigits),
  use24Hour: false,
  now: _now,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('what the widget is sent', () {
    test('a header, two labels and seven days of times, in order', () {
      final lines = _snapshot()!.split('\n');
      expect(lines[0], widgetSnapshotHeader);
      expect(lines[1], 'الصلاة التالية');
      expect(lines[2], 'ثم');
      final times = lines.skip(3).toList();
      expect(times, hasLength(widgetSnapshotDays * 6));
      final instants = [for (final l in times) int.parse(l.split('\t')[0])];
      expect(instants, [...instants]..sort());
      expect(times.every((l) => l.split('\t').length == 3), isTrue);
    });

    test('names and times follow the language and digits', () {
      final ar = _snapshot()!.split('\n')[3].split('\t');
      expect(ar[1], 'الفجر');
      expect(ar[2], contains('ص'));
      expect(RegExp('[0-9]').hasMatch(ar[2]), isFalse, reason: 'Arabic-Indic');
      final en = _snapshot(
        language: 'en',
        arabicDigits: false,
      )!.split('\n')[3].split('\t');
      expect(en[1], 'Fajr');
      expect(en[2], endsWith('AM'));
    });

    test('no place name and no coordinates', () {
      final text = _snapshot()!;
      expect(text, isNot(contains('القاهرة')));
      expect(text, isNot(contains('Cairo')));
      expect(text, isNot(contains('31.')), reason: 'no longitude');
      expect(text, isNot(contains('30.0')), reason: 'no latitude');
    });

    test('nothing without a place', () {
      expect(_snapshot(prefs: PrayerPreferences()), isNull);
    });
  });

  group('kept in step with the reminders', () {
    test('every reconcile sends a fresh copy', () async {
      final bridge = _Bridge();
      final inner = _Reminders();
      final service = WidgetUpdatingReminderService(
        inner: inner,
        bridge: bridge,
        snapshot: () async => 'snapshot',
      );
      final status = await service.reconcile();
      expect(status.scheduled, 3);
      await service.reconcile();
      expect(inner.reconciles, 2);
      expect(bridge.updates, ['snapshot', 'snapshot']);
    });

    test('no place clears the widget; Delete-all clears it too', () async {
      final bridge = _Bridge();
      final inner = _Reminders();
      final service = WidgetUpdatingReminderService(
        inner: inner,
        bridge: bridge,
        snapshot: () async => null,
      );
      await service.reconcile();
      expect(bridge.clears, 1);
      await service.cancelAll();
      expect(inner.cancels, 1);
      expect(bridge.clears, 2);
    });

    test(
      'a widget that cannot be reached never breaks the reminders',
      () async {
        final bridge = _Bridge()..fail = true;
        final service = WidgetUpdatingReminderService(
          inner: _Reminders(),
          bridge: bridge,
          snapshot: () async => throw StateError('calculation failed'),
        );
        expect((await service.reconcile()).scheduled, 3);
        await service.cancelAll();
      },
    );
  });

  group('the channel', () {
    const channel = MethodChannel('hadeeths/home_widget');

    test('calls the native side and passes taps on', () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return call.method == 'takeLaunchRoute' ? 'prayer' : null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final bridge = MethodChannelHomeWidgetBridge();
      await bridge.update('x');
      await bridge.clear();
      await bridge.setEnabled(true);
      expect(await bridge.takeLaunchRoute(), 'prayer');
      expect(
        [for (final c in calls) c.method],
        ['update', 'clear', 'setEnabled', 'takeLaunchRoute'],
      );
      expect(calls.first.arguments, 'x');

      final routes = <String>[];
      final sub = bridge.routes.listen(routes.add);
      await messenger.handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(const MethodCall('openRoute', 'prayer')),
        (_) {},
      );
      await Future<void>.delayed(Duration.zero);
      expect(routes, ['prayer']);
      await sub.cancel();
    });
  });

  group('a tap on the widget opens the Prayer section', () {
    testWidgets('when the app was opened by the tap', (tester) async {
      final bridge = _Bridge()..launch = 'prayer';
      final fixture = PrayerFixture(now: _now, saved: _cairo());
      await pumpApp(
        tester,
        FakeBackend(),
        locale: 'en',
        features: const FeatureFlags(prayer: true),
        prayer: fixture.services,
        homeWidget: bridge,
      );
      await tester.pumpAndSettle();
      expect(find.byType(PrayerPage), findsOneWidget);
    });

    testWidgets('when the app is already open', (tester) async {
      final bridge = _Bridge();
      final fixture = PrayerFixture(now: _now, saved: _cairo());
      await pumpApp(
        tester,
        FakeBackend(),
        locale: 'en',
        features: const FeatureFlags(prayer: true),
        prayer: fixture.services,
        homeWidget: bridge,
      );
      expect(find.byType(PrayerPage), findsNothing);
      bridge.tap();
      await tester.pumpAndSettle();
      expect(find.byType(PrayerPage), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
      expect(find.byType(AppShell), findsOneWidget);
    });
  });
}
