import 'dart:async';

import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/tracker/domain/day_key.dart';
import 'package:mynewapp/features/tracker/domain/prayer_log_repository.dart';

/// A prayer log in memory that the test can make slow or failing.
class InMemoryPrayerLog implements PrayerLogRepository {
  final Map<DayKey, Set<Prayer>> data = {};

  /// Every call to [setDone], in order, with what it asked for.
  final List<(DayKey, Prayer, bool)> writes = [];

  /// When set, writes fail with this.
  Object? failWrites;

  /// When set, reads fail with this.
  Object? failReads;

  /// When set, a write waits for this before it takes effect.
  Completer<void>? gate;

  int deletes = 0;

  @override
  Future<Map<DayKey, Set<Prayer>>> between(DayKey from, DayKey to) async {
    if (failReads != null) throw failReads!;
    return {
      for (final e in data.entries)
        if (!e.key.isBefore(from) && !e.key.isAfter(to) && e.value.isNotEmpty)
          e.key: {...e.value},
    };
  }

  @override
  Future<void> setDone(DayKey day, Prayer prayer, {required bool done}) async {
    writes.add((day, prayer, done));
    if (gate != null) await gate!.future;
    if (failWrites != null) throw failWrites!;
    final set = data[day] ??= {};
    done ? set.add(prayer) : set.remove(prayer);
    if (set.isEmpty) data.remove(day);
  }

  @override
  Future<void> deleteAll() async {
    deletes++;
    data.clear();
  }
}
