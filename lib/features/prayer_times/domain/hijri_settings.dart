import 'package:equatable/equatable.dart';

/// Which rules decide when a Hijri month starts. Two published references, because countries
/// follow different ones (Saudi Arabia: Umm al-Qura; many communities in North America: a
/// calculated criterion) and some, like Egypt, announce each month after moon sighting, which no
/// offline calculation can reproduce. That is why a manual correction exists too.
enum HijriReference {
  /// The official Saudi calendar (tables from KACST, Hijri years 1318 to 1500).
  ummAlQura,

  /// Astronomical calculation used by the Fiqh Council of North America: a month starts the day
  /// after a new moon that occurs before noon UTC, otherwise the day after that.
  fcna,
}

/// The user's choices about the Hijri date.
class HijriSettings extends Equatable {
  HijriSettings({
    this.reference = HijriReference.ummAlQura,
    int adjustmentDays = 0,
  }) : adjustmentDays = _checked(adjustmentDays);

  /// The largest manual correction, in days either way.
  static const maxAdjustmentDays = 2;

  final HijriReference reference;

  /// Added to the calendar date before converting, to follow a local announcement. Positive means
  /// later.
  final int adjustmentDays;

  HijriSettings copyWith({HijriReference? reference, int? adjustmentDays}) =>
      HijriSettings(
        reference: reference ?? this.reference,
        adjustmentDays: adjustmentDays ?? this.adjustmentDays,
      );

  static int _checked(int days) {
    if (days.abs() > maxAdjustmentDays) {
      throw RangeError.range(
        days,
        -maxAdjustmentDays,
        maxAdjustmentDays,
        'adjustmentDays',
      );
    }
    return days;
  }

  @override
  List<Object?> get props => [reference, adjustmentDays];
}
