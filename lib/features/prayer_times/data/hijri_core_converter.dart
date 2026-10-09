import 'package:hijri_core/hijri_core.dart' as hijri;
import 'package:mynewapp/features/prayer_times/domain/hijri_converter.dart';
import 'package:mynewapp/features/prayer_times/domain/hijri_date.dart';
import 'package:mynewapp/features/prayer_times/domain/hijri_settings.dart';

/// Hijri conversion with the `hijri_core` package (MIT): table-driven Umm al-Qura (Hijri years
/// 1318 to 1500) and the calculated FCNA criterion.
class HijriCoreConverter implements HijriConverter {
  const HijriCoreConverter();

  @override
  HijriDate? convert(DateTime gregorian, HijriSettings settings) {
    final shifted = DateTime.utc(
      gregorian.year,
      gregorian.month,
      gregorian.day + settings.adjustmentDays,
    );
    final result = hijri.toHijri(
      shifted,
      options: hijri.ConversionOptions(
        calendar: switch (settings.reference) {
          HijriReference.ummAlQura => 'uaq',
          HijriReference.fcna => 'fcna',
        },
      ),
    );
    if (result == null) return null;
    return HijriDate(year: result.hy, month: result.hm, day: result.hd);
  }
}
