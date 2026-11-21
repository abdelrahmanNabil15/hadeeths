import 'package:flutter/widgets.dart';

/// [n] in Arabic-Indic digits (٢٢٣), as every mushaf numbers its verses, whatever digits the
/// interface uses.
String arabicIndicDigits(int n) => n
    .toString()
    .split('')
    .map((d) => String.fromCharCode(0x0660 + int.parse(d)))
    .join();

/// The verse number inside a marker: Arabic-Indic digits in a bold Naskh (Amiri), the shape of
/// the numbers printed in the mushaf. Every marker style uses it, so only its frame differs.
TextStyle markerDigitStyle({required double fontSize, required Color color}) =>
    TextStyle(
      fontFamily: 'Amiri',
      fontWeight: FontWeight.w700,
      fontSize: fontSize,
      height: 1.1,
      color: color,
    );
