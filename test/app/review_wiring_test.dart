import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/review_wiring.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/core/time/zone.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_library.dart';
import 'package:mynewapp/features/categories/presentation/state/categories_cubit.dart';
import 'package:mynewapp/features/prayer_times/data/adhan_prayer_times_calculator.dart';
import 'package:mynewapp/features/prayer_times/domain/place_zone.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_day.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';

import '../support/adhan_fakes.dart';
import '../support/fake_backend.dart';
import '../support/prayer_fakes.dart';

final _cairo = realCityCatalog().cities.firstWhere((c) => c.nameEn == 'Cairo');
final _noon = DateTime.utc(2026, 10, 9, 10);

PrayerFixture _fixture({AdhanLibrary? adhan, bool withPlace = true}) =>
    PrayerFixture(
      saved: withPlace
          ? PrayerPreferences().withLocation(_cairo.toLocation('ar'))
          : null,
      now: _noon,
      adhan: adhan,
    );

/// Today's calculated times at the saved place.
Future<PrayerDay> _day(PrayerFixture f) async {
  final prefs = await f.preferences.load();
  final place = prefs.location!;
  final result = const AdhanPrayerTimesCalculator().calculate(
    location: place.point,
    date: zoneForPlace(place).localDateAt(f.clock.now()),
    settings: prefs.settings,
  );
  return (result as Success<PrayerDay>).value;
}

void main() {
  group('a prayer is due', () {
    test('just after it began', () async {
      final f = _fixture();
      final day = await _day(f);
      f.clock.set(day[Prayer.dhuhr].add(const Duration(minutes: 5)));
      expect(await prayerIsDue(f.services), isTrue);
    });

    test('until 20 minutes after it began, not beyond', () async {
      final f = _fixture();
      final day = await _day(f);
      f.clock.set(day[Prayer.dhuhr].add(const Duration(minutes: 19)));
      expect(await prayerIsDue(f.services), isTrue);
      f.clock.set(day[Prayer.dhuhr].add(const Duration(minutes: 21)));
      expect(await prayerIsDue(f.services), isFalse);
    });

    test('in the 10 minutes before it, not earlier', () async {
      final f = _fixture();
      final day = await _day(f);
      f.clock.set(day[Prayer.asr].subtract(const Duration(minutes: 9)));
      expect(await prayerIsDue(f.services), isTrue);
      f.clock.set(day[Prayer.asr].subtract(const Duration(minutes: 11)));
      expect(await prayerIsDue(f.services), isFalse);
    });

    test('sunrise is not a prayer', () async {
      final f = _fixture();
      final day = await _day(f);
      f.clock.set(day[Prayer.sunrise].add(const Duration(minutes: 3)));
      expect(await prayerIsDue(f.services), isFalse);
      f.clock.set(day[Prayer.sunrise].subtract(const Duration(minutes: 3)));
      expect(await prayerIsDue(f.services), isFalse);
    });

    test('with no place saved it is never due', () async {
      expect(await prayerIsDue(_fixture(withPlace: false).services), isFalse);
    });
  });

  group('what the user is not interrupted for', () {
    test('without prayer times nothing blocks', () async {
      expect(await reviewCanInterrupt()(), isTrue);
    });

    test('a quiet moment is fine', () async {
      final f = _fixture();
      final day = await _day(f);
      f.clock.set(day[Prayer.dhuhr].add(const Duration(hours: 1)));
      expect(await reviewCanInterrupt(prayer: f.services)(), isTrue);
    });

    test('a due prayer blocks', () async {
      final f = _fixture();
      final day = await _day(f);
      f.clock.set(day[Prayer.maghrib].add(const Duration(minutes: 2)));
      expect(await reviewCanInterrupt(prayer: f.services)(), isFalse);
    });

    test('a download under way blocks', () async {
      final library = FakeAdhanLibrary()..downloading = true;
      final f = _fixture(adhan: library);
      final day = await _day(f);
      f.clock.set(day[Prayer.dhuhr].add(const Duration(hours: 1)));
      expect(await reviewCanInterrupt(prayer: f.services)(), isFalse);
      library.downloading = false;
      expect(await reviewCanInterrupt(prayer: f.services)(), isTrue);
    });
  });

  group('the hadith home screen is calm', () {
    Future<BuildContext> pump(
      WidgetTester tester,
      FakeBackend api, {
      bool provide = true,
    }) async {
      late BuildContext inside;
      final cubit = CategoriesCubit(api, language: 'ar');
      await tester.pumpWidget(
        MaterialApp(
          home: provide
              ? BlocProvider.value(
                  value: cubit,
                  child: Builder(
                    builder: (context) {
                      inside = context;
                      return const SizedBox();
                    },
                  ),
                )
              : Builder(
                  builder: (context) {
                    inside = context;
                    return const SizedBox();
                  },
                ),
        ),
      );
      if (provide) await cubit.load();
      await tester.pump();
      addTearDown(cubit.close);
      return inside;
    }

    testWidgets('after the categories loaded', (tester) async {
      final context = await pump(tester, FakeBackend());
      expect(homeIsCalm(context), isTrue);
    });

    testWidgets('not when loading failed', (tester) async {
      final context = await pump(
        tester,
        FakeBackend()..categoriesFailure = noConnection,
      );
      expect(homeIsCalm(context), isFalse);
    });

    testWidgets('not without a home screen to look at', (tester) async {
      final context = await pump(tester, FakeBackend(), provide: false);
      expect(homeIsCalm(context), isFalse);
      expect(homeIsCalm(null), isFalse);
    });
  });

  group('the observer', () {
    testWidgets('tells only when the first page shows again', (tester) async {
      var told = 0;
      final observer = HomeReturnObserver(() => told++);
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          navigatorObservers: [observer],
          home: const Text('home'),
        ),
      );
      final navigator = key.currentState!;
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const Text('one')),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const Text('two')),
        ),
      );
      await tester.pumpAndSettle();
      expect(told, 0);
      navigator.pop(); // two closes, one shows
      await tester.pumpAndSettle();
      expect(told, 0);
      navigator.pop(); // one closes, home shows
      await tester.pumpAndSettle();
      expect(told, 1);
    });
  });
}
