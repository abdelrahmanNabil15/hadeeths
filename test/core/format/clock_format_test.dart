import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/format/clock_format.dart';
import 'package:mynewapp/core/format/digits.dart';

String _f(
  int h,
  int m, {
  bool arabic = false,
  bool h24 = false,
  Digits digits = Digits.western,
}) => formatClock(
  DateTime.utc(2026, 1, 1, h, m),
  arabic: arabic,
  use24Hour: h24,
  digits: digits,
);

void main() {
  test('English 12-hour', () {
    expect(_f(0, 5), '12:05 AM');
    expect(_f(9, 30), '9:30 AM');
    expect(_f(12, 0), '12:00 PM');
    expect(_f(15, 7), '3:07 PM');
    expect(_f(23, 59), '11:59 PM');
  });

  test('Arabic 12-hour uses ص and م', () {
    expect(_f(5, 18, arabic: true), '5:18 ص');
    expect(_f(12, 8, arabic: true), '12:08 م');
    expect(_f(0, 0, arabic: true), '12:00 ص');
  });

  test('24-hour', () {
    expect(_f(5, 8, h24: true), '05:08');
    expect(_f(17, 49, h24: true), '17:49');
    expect(_f(0, 0, h24: true), '00:00');
  });

  test('digits follow the numeral setting', () {
    expect(_f(15, 7, arabic: true, digits: Digits.arabicIndicDigits), '٣:٠٧ م');
    expect(_f(17, 49, h24: true, digits: Digits.arabicIndicDigits), '١٧:٤٩');
  });
}
