import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/tracker/domain/day_key.dart';
import 'package:mynewapp/features/tracker/presentation/state/tracker_cubit.dart';

import '../../support/prayer_fakes.dart';
import '../../support/tracker_fakes.dart';

PrayerPreferences _savedCairo() {
  final cairo = realCityCatalog().cities.firstWhere((c) => c.nameEn == 'Cairo');
  return PrayerPreferences().withLocation(cairo.toLocation('ar'));
}

void main() {
  late InMemoryPrayerLog log;
  late PrayerFixture fixture;
  late TrackerCubit cubit;

  // Cairo is UTC+3 in October 2026. 20:30 UTC is 23:30 on the 9th there; 21:30 UTC is 00:30 on the 10th.
  Future<void> open({DateTime? now, bool withPlace = true}) async {
    log = InMemoryPrayerLog();
    fixture = PrayerFixture(
      now: now ?? DateTime.utc(2026, 10, 9, 10),
      saved: withPlace ? _savedCairo() : null,
    );
    cubit = TrackerCubit(log: log, services: fixture.services);
    addTearDown(cubit.close);
    await cubit.load();
  }

  group('loading', () {
    test('shows today and the six days before it, today first', () async {
      await open();
      final s = cubit.state;
      expect(s.status, TrackerStatus.ready);
      expect(s.days, [
        for (var i = 0; i < 7; i++) DayKey(2026, 10, 9).addDays(-i),
      ]);
      expect(s.selected, DayKey(2026, 10, 9));
      expect(s.today, DayKey(2026, 10, 9));
    });

    test(
      'a new day starts at midnight in the saved place, not in UTC',
      () async {
        await open(now: DateTime.utc(2026, 10, 9, 20, 30));
        expect(cubit.state.today, DayKey(2026, 10, 9));
        await open(now: DateTime.utc(2026, 10, 9, 21, 30));
        expect(cubit.state.today, DayKey(2026, 10, 10));
      },
    );

    test('uses the phone zone when no place is saved', () async {
      await open(withPlace: false);
      expect(cubit.state.status, TrackerStatus.ready);
      expect(cubit.state.days, hasLength(7));
    });

    test('shows what was saved, and nothing older than the week', () async {
      log = InMemoryPrayerLog()
        ..data[DayKey(2026, 10, 9)] = {Prayer.fajr}
        ..data[DayKey(2026, 10, 4)] = {Prayer.isha, Prayer.asr}
        ..data[DayKey(2026, 10, 2)] = {Prayer.dhuhr};
      fixture = PrayerFixture(
        now: DateTime.utc(2026, 10, 9, 10),
        saved: _savedCairo(),
      );
      cubit = TrackerCubit(log: log, services: fixture.services);
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.doneOn(DayKey(2026, 10, 9)), {Prayer.fajr});
      expect(cubit.state.doneOn(DayKey(2026, 10, 4)), {
        Prayer.isha,
        Prayer.asr,
      });
      expect(cubit.state.doneOn(DayKey(2026, 10, 2)), isEmpty);
    });

    test('reports storage as unavailable instead of crashing', () async {
      log = InMemoryPrayerLog()..failReads = StateError('disk');
      fixture = PrayerFixture(saved: _savedCairo());
      cubit = TrackerCubit(log: log, services: fixture.services);
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.status, TrackerStatus.unavailable);
    });
  });

  group('marking', () {
    test('a mark shows at once and is saved', () async {
      await open();
      final saved = cubit.toggle(Prayer.fajr, on: true);
      expect(cubit.state.doneOn(DayKey(2026, 10, 9)), {Prayer.fajr});
      await saved;
      expect(log.data[DayKey(2026, 10, 9)], {Prayer.fajr});
    });

    test('unmarking removes it, and undoing is just marking again', () async {
      await open();
      await cubit.toggle(Prayer.asr, on: true);
      await cubit.toggle(Prayer.asr, on: false);
      expect(cubit.state.doneOn(DayKey(2026, 10, 9)), isEmpty);
      expect(log.data, isEmpty);
      await cubit.toggle(Prayer.asr, on: true);
      expect(log.data[DayKey(2026, 10, 9)], {Prayer.asr});
    });

    test('marks go to the chosen day', () async {
      await open();
      cubit.select(DayKey(2026, 10, 7));
      await cubit.toggle(Prayer.maghrib, on: true);
      expect(log.data.keys, [DayKey(2026, 10, 7)]);
      expect(cubit.state.doneOn(DayKey(2026, 10, 9)), isEmpty);
    });

    test('only the days shown can be chosen', () async {
      await open();
      cubit.select(DayKey(2026, 10, 10));
      expect(cubit.state.selected, DayKey(2026, 10, 9));
      cubit.select(DayKey(2026, 9, 1));
      expect(cubit.state.selected, DayKey(2026, 10, 9));
    });

    test(
      'quick taps are all kept and saved in the order they were made',
      () async {
        await open();
        log.gate = Completer<void>();
        final taps = [
          cubit.toggle(Prayer.fajr, on: true),
          cubit.toggle(Prayer.dhuhr, on: true),
          cubit.toggle(Prayer.fajr, on: false),
          cubit.toggle(Prayer.isha, on: true),
        ];
        // Everything shows before any save has finished.
        expect(cubit.state.doneOn(DayKey(2026, 10, 9)), {
          Prayer.dhuhr,
          Prayer.isha,
        });
        log.gate!.complete();
        await Future.wait(taps);
        expect(log.writes.map((w) => (w.$2, w.$3)), [
          (Prayer.fajr, true),
          (Prayer.dhuhr, true),
          (Prayer.fajr, false),
          (Prayer.isha, true),
        ]);
        expect(log.data[DayKey(2026, 10, 9)], {Prayer.dhuhr, Prayer.isha});
      },
    );

    test('a failed save is taken back and said so', () async {
      await open();
      log.failWrites = StateError('disk full');
      await cubit.toggle(Prayer.fajr, on: true);
      expect(cubit.state.doneOn(DayKey(2026, 10, 9)), isEmpty);
      expect(cubit.state.saveFailed, isTrue);
      log.failWrites = null;
      await cubit.toggle(Prayer.fajr, on: true);
      expect(cubit.state.saveFailed, isFalse);
      expect(log.data[DayKey(2026, 10, 9)], {Prayer.fajr});
    });

    test('sunrise cannot be marked', () async {
      await open();
      await cubit.toggle(Prayer.sunrise, on: true);
      expect(log.writes, isEmpty);
      expect(cubit.state.doneOn(DayKey(2026, 10, 9)), isEmpty);
    });
  });

  group('the day changes', () {
    test(
      'reloading after midnight moves today forward and keeps the chosen day',
      () async {
        await open(now: DateTime.utc(2026, 10, 9, 20, 30));
        cubit.select(DayKey(2026, 10, 8));
        await cubit.toggle(Prayer.isha, on: true);
        fixture.clock.advance(const Duration(hours: 2));
        await cubit.load();
        expect(cubit.state.today, DayKey(2026, 10, 10));
        expect(cubit.state.selected, DayKey(2026, 10, 8));
        expect(cubit.state.doneOn(DayKey(2026, 10, 8)), {Prayer.isha});
      },
    );

    test('a chosen day that has left the week falls back to today', () async {
      await open(now: DateTime.utc(2026, 10, 9, 10));
      cubit.select(DayKey(2026, 10, 3));
      fixture.clock.advance(const Duration(days: 1));
      await cubit.load();
      expect(cubit.state.selected, cubit.state.today);
    });
  });

  group('delete all', () {
    test('removes every mark everywhere', () async {
      await open();
      await cubit.toggle(Prayer.fajr, on: true);
      cubit.select(DayKey(2026, 10, 6));
      await cubit.toggle(Prayer.asr, on: true);
      await cubit.deleteAll();
      expect(log.deletes, 1);
      expect(log.data, isEmpty);
      expect(cubit.state.done, isEmpty);
    });

    test('waits for saves already under way', () async {
      await open();
      log.gate = Completer<void>();
      final tap = cubit.toggle(Prayer.fajr, on: true);
      final delete = cubit.deleteAll();
      expect(log.deletes, 0);
      log.gate!.complete();
      await Future.wait([tap, delete]);
      expect(log.data, isEmpty);
    });
  });
}
