import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String name) =>
    jsonDecode(File('lib/l10n/$name.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

Set<String> _placeholders(String message) =>
    RegExp(r'\{(\w+)\}').allMatches(message).map((m) => m.group(1)!).toSet();

void main() {
  final ar = _arb('app_ar');
  final en = _arb('app_en');

  test('Arabic and English define exactly the same messages', () {
    final arKeys = _keys(ar)..remove('@@locale');
    final enKeys = _keys(en)..remove('@@locale');
    expect(arKeys.difference(enKeys), isEmpty, reason: 'missing in English');
    expect(enKeys.difference(arKeys), isEmpty, reason: 'missing in Arabic');
  });

  test('both languages use the same placeholders in every message', () {
    for (final key in _keys(ar)) {
      if (key == '@@locale') continue;
      expect(
        _placeholders(ar[key] as String),
        _placeholders(en[key] as String),
        reason: key,
      );
    }
  });

  test('no message is empty', () {
    for (final arb in [ar, en]) {
      for (final key in _keys(arb)) {
        if (key == '@@locale') continue;
        expect((arb[key] as String).trim(), isNotEmpty, reason: key);
      }
    }
  });

  test('the HadeethEnc credit keeps the site name in both languages', () {
    expect(ar['sourceCredit'], contains('HadeethEnc.com'));
    expect(en['sourceCredit'], contains('HadeethEnc.com'));
  });
}
