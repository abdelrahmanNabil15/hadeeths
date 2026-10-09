import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/text/arabic_search.dart';

void main() {
  group('normalizeForSearch', () {
    test('alef with hamza or madda counts as plain alef', () {
      expect(
        normalizeForSearch('الإسكندرية'),
        normalizeForSearch('الاسكندريه'),
      );
      expect(normalizeForSearch('أبوظبي'), normalizeForSearch('ابوظبي'));
      expect(normalizeForSearch('آبار'), normalizeForSearch('ابار'));
      expect(normalizeForSearch('ٱلله'), normalizeForSearch('الله'));
    });

    test('ta marbuta counts as ha and alef maqsura as ya', () {
      expect(normalizeForSearch('مكة'), normalizeForSearch('مكه'));
      expect(normalizeForSearch('مرسى'), normalizeForSearch('مرسي'));
    });

    test('diacritics and tatweel are ignored', () {
      expect(normalizeForSearch('مَكَّةُ'), normalizeForSearch('مكة'));
      expect(normalizeForSearch('القــاهرة'), normalizeForSearch('القاهرة'));
    });

    test('Latin text is lower-cased, spaces collapse and trim', () {
      expect(normalizeForSearch('  New   YORK '), 'new york');
    });

    test('different letters are not merged (no over-normalisation)', () {
      expect(normalizeForSearch('سعد') == normalizeForSearch('صعد'), isFalse);
      expect(normalizeForSearch('بئر') == normalizeForSearch('بير'), isFalse);
      expect(normalizeForSearch('مؤمن') == normalizeForSearch('مومن'), isFalse);
    });

    test('digits and punctuation are left alone', () {
      expect(normalizeForSearch('6 أكتوبر'), '6 اكتوبر');
    });

    test('empty stays empty', () {
      expect(normalizeForSearch(''), '');
      expect(normalizeForSearch('   '), '');
    });
  });
}
