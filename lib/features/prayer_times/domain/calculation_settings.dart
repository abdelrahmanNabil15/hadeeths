import 'package:equatable/equatable.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';

/// The calculation methods the app offers. Each one is a published set of twilight angles
/// (or a fixed interval for Isha); see [methodInfo] for the exact numbers the app uses.
/// Calculated times can differ from a local mosque or religious authority.
enum CalculationMethodId {
  egyptian,
  ummAlQura,
  muslimWorldLeague,
  karachi,
  northAmerica,
}

/// Which shadow length defines the start of Asr.
enum Madhab {
  /// Shadow equals the object's height (earlier Asr): the Shafii, Maliki and Hanbali schools.
  shafii,

  /// Shadow equals twice the object's height (later Asr): the Hanafi school.
  hanafi,
}

/// How Fajr and Isha are limited when the twilight angle is never reached (far north or south).
enum HighLatitudeRule { middleOfTheNight, seventhOfTheNight, twilightAngle }

/// What a method does, in numbers the user can see. Kept next to the enum so the screen that
/// describes a method and the code that calculates with it cannot drift apart (a test
/// compares this table with the calculation library).
class MethodInfo extends Equatable {
  const MethodInfo({
    required this.fajrAngle,
    this.ishaAngle,
    this.ishaIntervalMinutes,
    this.dhuhrOffsetMinutes = 0,
  });

  /// Sun angle below the horizon for Fajr.
  final double fajrAngle;

  /// Sun angle below the horizon for Isha; null when Isha is a fixed interval after Maghrib.
  final double? ishaAngle;

  /// Minutes after Maghrib for Isha; null when Isha uses an angle.
  final int? ishaIntervalMinutes;

  /// Minutes the method adds to the astronomical noon for Dhuhr (a small safety margin).
  final int dhuhrOffsetMinutes;

  @override
  List<Object?> get props => [
    fajrAngle,
    ishaAngle,
    ishaIntervalMinutes,
    dhuhrOffsetMinutes,
  ];
}

const Map<CalculationMethodId, MethodInfo> methodInfo = {
  CalculationMethodId.egyptian: MethodInfo(
    fajrAngle: 19.5,
    ishaAngle: 17.5,
    dhuhrOffsetMinutes: 1,
  ),
  CalculationMethodId.ummAlQura: MethodInfo(
    fajrAngle: 18.5,
    ishaIntervalMinutes: 90,
  ),
  CalculationMethodId.muslimWorldLeague: MethodInfo(
    fajrAngle: 18,
    ishaAngle: 17,
    dhuhrOffsetMinutes: 1,
  ),
  CalculationMethodId.karachi: MethodInfo(
    fajrAngle: 18,
    ishaAngle: 18,
    dhuhrOffsetMinutes: 1,
  ),
  CalculationMethodId.northAmerica: MethodInfo(
    fajrAngle: 15,
    ishaAngle: 15,
    dhuhrOffsetMinutes: 1,
  ),
};

/// Everything the user can choose about how times are calculated. Never changed behind the
/// user's back: a new value only ever comes from an explicit choice.
class CalculationSettings extends Equatable {
  CalculationSettings({
    this.method = defaultMethod,
    this.madhab = Madhab.shafii,
    this.highLatitudeRule = HighLatitudeRule.middleOfTheNight,
    Map<Prayer, int> adjustments = const {},
  }) : adjustments = Map.unmodifiable({
         for (final entry in adjustments.entries)
           if (entry.value != 0) entry.key: _checked(entry.key, entry.value),
       });

  /// First-run method. A product decision still to be confirmed by the owner; the user can
  /// change it at any time.
  static const defaultMethod = CalculationMethodId.egyptian;

  /// The largest manual correction per prayer, in minutes either way.
  static const maxAdjustmentMinutes = 30;

  final CalculationMethodId method;
  final Madhab madhab;
  final HighLatitudeRule highLatitudeRule;

  /// Manual corrections in whole minutes (for matching a local mosque's timetable). Only
  /// non-zero entries are kept.
  final Map<Prayer, int> adjustments;

  int adjustmentFor(Prayer prayer) => adjustments[prayer] ?? 0;

  CalculationSettings copyWith({
    CalculationMethodId? method,
    Madhab? madhab,
    HighLatitudeRule? highLatitudeRule,
    Map<Prayer, int>? adjustments,
  }) => CalculationSettings(
    method: method ?? this.method,
    madhab: madhab ?? this.madhab,
    highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
    adjustments: adjustments ?? this.adjustments,
  );

  static int _checked(Prayer prayer, int minutes) {
    if (minutes.abs() > maxAdjustmentMinutes) {
      throw RangeError.range(
        minutes,
        -maxAdjustmentMinutes,
        maxAdjustmentMinutes,
        prayer.name,
        'adjustment in minutes',
      );
    }
    return minutes;
  }

  @override
  List<Object?> get props => [
    method,
    madhab,
    highLatitudeRule,
    [for (final p in Prayer.values) adjustmentFor(p)],
  ];
}
