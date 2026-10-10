import 'package:mynewapp/core/format/digits.dart';

// The owner approved this wording on 2026-10-10. It is used exactly as given, in Arabic in both
// interface languages until an English wording is approved. Do not edit it without the owner.

/// At the scheduled time.
const salawatNowText = 'حان وقت الصلاة على النبي ﷺ';

/// The optional reminder [minutes] before the scheduled time, from the approved template
/// "الصلاة على النبي ﷺ بعد {عدد الدقائق} دقيقة". The number follows the user's digits, and the noun
/// follows Arabic number agreement as the app's prayer reminders already do (decision D3): دقائق
/// after 3 to 10, دقيقة otherwise.
String salawatSoonText(int minutes, Digits digits) {
  final lastTwo = minutes % 100;
  final noun = lastTwo >= 3 && lastTwo <= 10 ? 'دقائق' : 'دقيقة';
  return 'الصلاة على النبي ﷺ بعد ${digits.format(minutes)} $noun';
}
