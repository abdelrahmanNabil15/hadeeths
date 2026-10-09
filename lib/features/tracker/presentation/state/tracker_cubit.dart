import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/time/zone.dart';
import 'package:mynewapp/features/prayer_times/domain/place_zone.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';
import 'package:mynewapp/features/tracker/domain/day_key.dart';
import 'package:mynewapp/features/tracker/domain/prayer_log_repository.dart';

enum TrackerStatus { loading, ready, unavailable }

class TrackerState extends Equatable {
  const TrackerState({
    this.status = TrackerStatus.loading,
    this.days = const [],
    this.selected,
    this.done = const {},
    this.saveFailed = false,
  });

  final TrackerStatus status;

  /// The days that can be marked: today first, then the six before it.
  final List<DayKey> days;

  final DayKey? selected;

  /// What is marked, per day.
  final Map<DayKey, Set<Prayer>> done;

  /// The last change could not be saved and was taken back.
  final bool saveFailed;

  DayKey? get today => days.isEmpty ? null : days.first;

  Set<Prayer> doneOn(DayKey day) => done[day] ?? const {};

  /// The five prayers, in daily order.
  static final List<Prayer> prayers = [
    for (final p in Prayer.values)
      if (p.isPrayer) p,
  ];

  TrackerState copyWith({
    TrackerStatus? status,
    List<DayKey>? days,
    DayKey? selected,
    Map<DayKey, Set<Prayer>>? done,
    bool? saveFailed,
  }) => TrackerState(
    status: status ?? this.status,
    days: days ?? this.days,
    selected: selected ?? this.selected,
    done: done ?? this.done,
    saveFailed: saveFailed ?? this.saveFailed,
  );

  @override
  List<Object?> get props => [
    status,
    days,
    selected,
    [
      for (final e in done.entries)
        (e.key.id, (e.value.map((p) => p.index).toList()..sort())),
    ],
    saveFailed,
  ];
}

/// Marking prayers as prayed, for today and the six days before it.
///
/// A mark shows at once and is saved after; if saving fails it is taken back and the screen says
/// so. Saves run one after another in the order of the taps, so quick taps never lose or reorder a
/// change. Which day is "today" is read from the clock in the zone of the saved place (the
/// phone's zone if there is none), so it changes at that place's midnight.
class TrackerCubit extends Cubit<TrackerState> {
  TrackerCubit({required this.log, required this.services})
    : super(const TrackerState());

  final PrayerLogRepository log;
  final PrayerServices services;

  /// Saves wait for the one before them.
  Future<void> _saves = Future.value();

  static const dayCount = 7;

  Future<TimeZoneRules> _zone() async {
    final place = (await services.preferences.load()).location;
    return place == null ? const DeviceTimeZone() : zoneForPlace(place);
  }

  /// Reads today's date and what is saved. Also called when the app comes back to the front, so
  /// a new day appears without leaving the screen. The chosen day is kept if it is still shown.
  Future<void> load() async {
    try {
      final zone = await _zone();
      final today = DayKey.fromWallClock(
        zone.wallClockAt(services.clock.now()),
      );
      final days = [for (var i = 0; i < dayCount; i++) today.addDays(-i)];
      final done = await log.between(days.last, days.first);
      if (isClosed) return;
      final keep = state.selected;
      emit(
        TrackerState(
          status: TrackerStatus.ready,
          days: days,
          selected: keep != null && days.contains(keep) ? keep : today,
          done: done,
        ),
      );
    } on Object {
      if (isClosed) return;
      emit(const TrackerState(status: TrackerStatus.unavailable));
    }
  }

  void select(DayKey day) {
    if (state.days.contains(day)) {
      emit(state.copyWith(selected: day, saveFailed: false));
    }
  }

  /// Marks or unmarks [prayer] on the chosen day.
  Future<void> toggle(Prayer prayer, {required bool on}) {
    final day = state.selected;
    if (day == null ||
        !prayer.isPrayer ||
        state.status != TrackerStatus.ready) {
      return Future.value();
    }
    _setLocally(day, prayer, on: on);
    emit(state.copyWith(saveFailed: false));
    final save = _saves.then((_) async {
      try {
        await log.setDone(day, prayer, done: on);
      } on Object {
        if (isClosed) return;
        _setLocally(day, prayer, on: !on);
        emit(state.copyWith(saveFailed: true));
      }
    });
    _saves = save;
    return save;
  }

  void _setLocally(DayKey day, Prayer prayer, {required bool on}) {
    final done = {
      for (final e in state.done.entries) e.key: {...e.value},
    };
    final set = done[day] ??= {};
    on ? set.add(prayer) : set.remove(prayer);
    if (set.isEmpty) done.remove(day);
    emit(state.copyWith(done: done));
  }

  /// Removes everything recorded, on every day.
  Future<void> deleteAll() async {
    await _saves;
    try {
      await log.deleteAll();
      if (isClosed) return;
      emit(state.copyWith(done: const {}, saveFailed: false));
    } on Object {
      if (isClosed) return;
      emit(state.copyWith(saveFailed: true));
    }
  }
}
