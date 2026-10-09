import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/core/time/zone.dart';
import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/city.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/hijri_converter.dart';
import 'package:mynewapp/features/prayer_times/domain/hijri_date.dart';
import 'package:mynewapp/features/prayer_times/domain/hijri_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/location_setup.dart';
import 'package:mynewapp/features/prayer_times/domain/place_zone.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_day.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_location.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_moment.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_preferences.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_service.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_settings.dart';

enum PrayerStatus { loading, needsSetup, ready }

class PrayerState extends Equatable {
  PrayerState({
    this.status = PrayerStatus.loading,
    PrayerPreferences? preferences,
    this.today,
    this.moment,
    this.hijriDate,
    this.zone,
    this.calculationFailed = false,
    this.locating = false,
    this.setupProblem,
  }) : preferences = preferences ?? PrayerPreferences();

  final PrayerStatus status;
  final PrayerPreferences preferences;

  /// Today's times at the chosen place, when they could be calculated.
  final PrayerDay? today;

  /// Which prayer period it is now and what comes next (null when there are no times).
  final PrayerMoment? moment;

  /// The Hijri date now (it changes at Maghrib); null when the chosen reference does not cover it.
  final HijriDate? hijriDate;

  /// The zone of the chosen place, for showing times in its local clock.
  final TimeZoneRules? zone;

  /// The place is set but no sensible times exist for it (for example inside the polar circle).
  final bool calculationFailed;

  /// "Use my location" is running.
  final bool locating;

  /// Why the last "use my location" did not produce a place; null when it did or was not tried.
  final LocationSetupStatus? setupProblem;

  PrayerState copyWith({bool? locating, LocationSetupStatus? setupProblem}) =>
      PrayerState(
        status: status,
        preferences: preferences,
        today: today,
        moment: moment,
        hijriDate: hijriDate,
        zone: zone,
        calculationFailed: calculationFailed,
        locating: locating ?? this.locating,
        setupProblem: setupProblem ?? this.setupProblem,
      );

  @override
  List<Object?> get props => [
    status,
    preferences,
    today,
    moment,
    hijriDate,
    zone?.id,
    calculationFailed,
    locating,
    setupProblem,
  ];
}

/// Loads the saved place and settings, sets the place (from the device or from a city), and keeps
/// today's times up to date. Changes are saved; failing to save never blocks the screen.
class PrayerCubit extends Cubit<PrayerState> {
  PrayerCubit(this._services) : super(PrayerState());

  final PrayerServices _services;

  Future<void> load() async {
    final saved = await _services.preferences.load();
    _apply(saved);
  }

  /// Recalculates for the current moment (for example when the screen is opened again after the
  /// date changed).
  void refresh() => _apply(state.preferences);

  Future<void> selectCity(City city, {required String languageCode}) =>
      _setLocation(city.toLocation(languageCode));

  /// "Use my location": [explain] shows the reason and returns whether the user agrees. Ends
  /// with either a saved place or [PrayerState.setupProblem].
  Future<void> useMyLocation({required Future<bool> Function() explain}) async {
    emit(
      PrayerState(
        status: state.status,
        preferences: state.preferences,
        today: state.today,
        moment: state.moment,
        hijriDate: state.hijriDate,
        zone: state.zone,
        calculationFailed: state.calculationFailed,
        locating: true,
      ),
    );
    // The spinner belongs to the work after the user has agreed, not to the explanation.
    final result = await _services.locationSetup.run(
      explain: () async {
        emit(state.copyWith(locating: false));
        final agreed = await explain();
        if (agreed) emit(state.copyWith(locating: true));
        return agreed;
      },
    );
    final GeoPoint? point = result.point;
    if (result.status != LocationSetupStatus.found || point == null) {
      emit(state.copyWith(locating: false, setupProblem: result.status));
      return;
    }
    String? country;
    try {
      country = (await _services.loadCountries()).countryAt(point);
    } on Object {
      country = null;
    }
    await _setLocation(
      PrayerLocation(
        point: point,
        source: LocationSource.gps,
        zoneId: PrayerLocation.deviceZoneId,
        countryCode: country,
      ),
    );
  }

  Future<void> chooseMethod(CalculationMethodId method) async {
    final next = state.preferences.withMethod(method);
    _apply(next);
    await _save(next);
  }

  /// The user changed the Hijri reference or the day correction.
  Future<void> setHijri(HijriSettings settings) async {
    final next = state.preferences.withHijri(settings);
    _apply(next);
    await _save(next);
  }

  /// The user changed the reminder choices. Saves them, then makes the system's reminders match, and
  /// returns what is scheduled afterwards.
  Future<ReminderStatus> setReminders(ReminderSettings settings) async {
    final next = state.preferences.withReminders(settings);
    _apply(next);
    await _save(next, reconcile: false);
    return _services.reminders.reconcile();
  }

  Future<void> openAppSettings() => _services.locationSetup.openAppSettings();

  Future<void> openLocationSettings() =>
      _services.locationSetup.openLocationSettings();

  Future<void> _setLocation(PrayerLocation place) async {
    final next = state.preferences.withLocation(place);
    _apply(next);
    await _save(next);
  }

  Future<void> _save(
    PrayerPreferences preferences, {
    bool reconcile = true,
  }) async {
    try {
      await _services.preferences.save(preferences);
    } on Object {
      // Still applies for this session.
    }
    // A new place, method or day correction moves the prayer times, so the reminders move too.
    if (reconcile) unawaited(_services.reminders.reconcile());
  }

  void _apply(PrayerPreferences preferences) {
    final place = preferences.location;
    if (place == null) {
      emit(
        PrayerState(
          status: PrayerStatus.needsSetup,
          preferences: preferences,
          setupProblem: state.setupProblem,
        ),
      );
      return;
    }
    final zone = zoneFor(place);
    final date = zone.localDateAt(_services.clock.now());
    final result = _services.calculator.calculate(
      location: place.point,
      date: date,
      settings: preferences.settings,
    );
    final day = result is Success<PrayerDay> ? result.value : null;
    PrayerMoment? moment;
    HijriDate? hijriDate;
    if (day != null) {
      hijriDate = hijriDateAt(
        converter: _services.hijri,
        settings: preferences.hijri,
        day: day,
        now: _services.clock.now(),
      );
      try {
        moment = PrayerMoment.at(day, _services.clock.now());
      } on ArgumentError {
        moment = null;
      }
    }
    emit(
      PrayerState(
        status: PrayerStatus.ready,
        preferences: preferences,
        today: day,
        moment: moment,
        hijriDate: hijriDate,
        zone: zone,
        calculationFailed: result is! Success<PrayerDay>,
      ),
    );
  }

  /// See [zoneForPlace].
  static TimeZoneRules zoneFor(PrayerLocation place) => zoneForPlace(place);
}
