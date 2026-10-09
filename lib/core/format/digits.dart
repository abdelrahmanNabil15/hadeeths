import 'package:flutter/widgets.dart';

/// How the app's own numbers are written: Western (0123) or Arabic-Indic (٠١٢٣).
///
/// Only numbers the app itself produces go through this (counts, percentages, list numbering,
/// times, dates). Text that comes from a source (hadith text, category titles, search queries)
/// is never transformed: it is shown exactly as received.
class Digits {
  const Digits({required this.arabicIndic});

  static const western = Digits(arabicIndic: false);
  static const arabicIndicDigits = Digits(arabicIndic: true);

  final bool arabicIndic;

  String format(int number) => localize('$number');

  /// Rewrites every ASCII digit in [text]. Use only on text the app composed itself.
  String localize(String text) {
    if (!arabicIndic) return text;
    return text.replaceAllMapped(
      RegExp('[0-9]'),
      (m) => String.fromCharCode(0x0660 + m[0]!.codeUnitAt(0) - 0x30),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Digits && other.arabicIndic == arabicIndic;

  @override
  int get hashCode => arabicIndic.hashCode;
}

/// Supplies the chosen [Digits] to the widgets below it.
class DigitScope extends InheritedWidget {
  const DigitScope({super.key, required this.digits, required super.child});

  final Digits digits;

  static Digits of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DigitScope>()?.digits ??
      Digits.western;

  @override
  bool updateShouldNotify(DigitScope oldWidget) => digits != oldWidget.digits;
}

extension DigitsContext on BuildContext {
  Digits get digits => DigitScope.of(this);
}
