import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/features/prayer_times/domain/hijri_date.dart';
import 'package:mynewapp/features/prayer_times/domain/hijri_settings.dart';
import 'package:mynewapp/l10n/l10n.dart';

String hijriMonthName(AppLocalizations l10n, int month) => switch (month) {
  1 => l10n.hijriMonth1,
  2 => l10n.hijriMonth2,
  3 => l10n.hijriMonth3,
  4 => l10n.hijriMonth4,
  5 => l10n.hijriMonth5,
  6 => l10n.hijriMonth6,
  7 => l10n.hijriMonth7,
  8 => l10n.hijriMonth8,
  9 => l10n.hijriMonth9,
  10 => l10n.hijriMonth10,
  11 => l10n.hijriMonth11,
  _ => l10n.hijriMonth12,
};

String gregorianMonthName(AppLocalizations l10n, int month) => switch (month) {
  1 => l10n.gregMonth1,
  2 => l10n.gregMonth2,
  3 => l10n.gregMonth3,
  4 => l10n.gregMonth4,
  5 => l10n.gregMonth5,
  6 => l10n.gregMonth6,
  7 => l10n.gregMonth7,
  8 => l10n.gregMonth8,
  9 => l10n.gregMonth9,
  10 => l10n.gregMonth10,
  11 => l10n.gregMonth11,
  _ => l10n.gregMonth12,
};

/// Monday is 1 and Sunday is 7, as in `DateTime.weekday`.
String weekdayName(AppLocalizations l10n, int weekday) => switch (weekday) {
  1 => l10n.weekday1,
  2 => l10n.weekday2,
  3 => l10n.weekday3,
  4 => l10n.weekday4,
  5 => l10n.weekday5,
  6 => l10n.weekday6,
  _ => l10n.weekday7,
};

/// "٢٧ ربيع الآخر ١٤٤٨ هـ" or "27 Rabi al-Thani 1448 AH".
String hijriDateText(AppLocalizations l10n, Digits digits, HijriDate date) =>
    '${digits.format(date.day)} ${hijriMonthName(l10n, date.month)} '
    '${digits.format(date.year)} ${l10n.hijriYearSuffix}';

/// "الجمعة ٩ أكتوبر ٢٠٢٦" (the calendar day at the place; [date] is a UTC-flagged date).
String gregorianDateText(AppLocalizations l10n, Digits digits, DateTime date) =>
    '${weekdayName(l10n, date.weekday)} ${digits.format(date.day)} '
    '${gregorianMonthName(l10n, date.month)} ${digits.format(date.year)}';

String hijriAdjustmentLabel(AppLocalizations l10n, int days) => switch (days) {
  -2 => l10n.hijriAdjustMinus2,
  -1 => l10n.hijriAdjustMinus1,
  1 => l10n.hijriAdjustPlus1,
  2 => l10n.hijriAdjustPlus2,
  _ => l10n.hijriAdjustNone,
};

String hijriReferenceName(AppLocalizations l10n, HijriReference reference) =>
    switch (reference) {
      HijriReference.ummAlQura => l10n.hijriReferenceUmmAlQura,
      HijriReference.fcna => l10n.hijriReferenceFcna,
    };

String hijriReferenceNote(AppLocalizations l10n, HijriReference reference) =>
    switch (reference) {
      HijriReference.ummAlQura => l10n.hijriReferenceUmmAlQuraNote,
      HijriReference.fcna => l10n.hijriReferenceFcnaNote,
    };
