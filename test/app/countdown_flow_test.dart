import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/prayer_cubit.dart';
import 'package:mynewapp/features/prayer_times/presentation/widgets/prayer_countdown.dart';

import '../support/fake_backend.dart';
import '../support/prayer_fakes.dart';
import '../support/test_app.dart';

PrayerPreferences _cairo() {
  final cairo = realCityCatalog().cities.firstWhere((c) => c.nameEn == 'Cairo');
  return PrayerPreferences().withLocation(cairo.toLocation('en'));
}

Future<PrayerFixture> _open(WidgetTester tester, {double textScale = 1}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final fixture = PrayerFixture(
    now: DateTime.utc(2026, 10, 9, 10),
    saved: _cairo(),
  );
  await pumpApp(
    tester,
    FakeBackend(),
    locale: 'en',
    features: const FeatureFlags(prayer: true),
    prayer: fixture.services,
  );
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Prayer'),
    ),
  );
  await tester.pumpAndSettle();
  return fixture;
}

PrayerCubit _cubit(WidgetTester tester) =>
    tester.element(find.byType(PrayerCountdown)).read<PrayerCubit>();

final _clockFace = RegExp(r'^in \d+:\d\d:\d\d$');

void main() {
  testWidgets('the next prayer shows the time left, ticking', (tester) async {
    final fixture = await _open(tester);
    final nextAt = _cubit(tester).state.moment!.nextAt;
    final left = nextAt.difference(fixture.clock.now());
    String face(Duration d) =>
        'in ${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:'
        '${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    expect(find.text(face(left)), findsOneWidget);

    fixture.clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(face(left - const Duration(seconds: 1))), findsOneWidget);
  });

  testWidgets('at the prayer time it moves on to the following prayer', (
    tester,
  ) async {
    final fixture = await _open(tester);
    final before = _cubit(tester).state.moment!;
    expect(before.next, Prayer.asr);
    fixture.clock.set(before.nextAt.subtract(const Duration(seconds: 1)));
    await tester.pump(const Duration(seconds: 1));
    fixture.clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(_cubit(tester).state.moment!.next, Prayer.maghrib);
    expect(
      find.bySemanticsLabel(RegExp(r'^Next prayer: Maghrib, .*, in ')),
      findsOneWidget,
    );
  });

  testWidgets('screen readers hear the time left in words', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester);
    expect(
      find.bySemanticsLabel(
        RegExp(r'^Next prayer: Asr, .+, in (\d+ hours?)( and \d+ minutes?)?$'),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('fits at 200% text', (tester) async {
    await _open(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.textContaining(_clockFace), findsOneWidget);
  });
}
