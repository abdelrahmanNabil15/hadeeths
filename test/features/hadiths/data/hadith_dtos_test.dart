import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/hadiths/data/hadith_dtos.dart';

import '../../../support/fixtures.dart';

void main() {
  group('HadithPageDto', () {
    test('parses live meta types (string page numbers, numeric totals)', () {
      final page = samplePage(
        ids: ['1', '2', '3'],
        page: 2,
        lastPage: 66,
        totalItems: 197,
      );
      expect(page.items.map((e) => e.id), ['1', '2', '3']);
      expect(page.currentPage, 2);
      expect(page.lastPage, 66);
      expect(page.totalItems, 197);
    });

    test(
      'totalItems can exceed the number of items without breaking parsing',
      () {
        final page = samplePage(ids: ['1'], totalItems: 450);
        expect(page.items, hasLength(1));
        expect(page.totalItems, 450);
      },
    );

    test('missing meta falls back to the items it has', () {
      final page = HadithPageDto.fromJson({
        'data': [
          {'id': '1', 'title': 'a'},
        ],
      });
      expect(page.currentPage, 1);
      expect(page.lastPage, 1);
      expect(page.totalItems, 1);
    });

    test('missing data is an empty page', () {
      final page = HadithPageDto.fromJson({
        'meta': {'current_page': '1', 'last_page': 1},
      });
      expect(page.items, isEmpty);
    });

    test('a malformed item is reported, not swallowed', () {
      expect(
        () => HadithPageDto.fromJson({
          'data': ['not an object'],
        }),
        throwsFormatException,
      );
    });
  });

  group('HadithDetailsDto', () {
    test('parses an Arabic response', () {
      final d = sampleDetails();
      expect(d.hadeeth, 'عَنْ عَبْدِ اللهِ بنِ مَسْعُودٍ رضي الله عنه');
      expect(d.grade, 'صحيح');
      expect(d.hints, hasLength(2));
      expect(d.wordsMeanings.single.word, 'كلمة');
      expect(d.reference, 'صحيح البخاري');
    });

    test('keeps the source text exactly, including diacritics', () {
      final raw = arabicDetailsJson['hadeeth']! as String;
      expect(sampleDetails().hadeeth, raw);
    });

    test(
      'parses an English response that has no reference or word meanings',
      () {
        final d = sampleDetails(englishDetailsJson);
        expect(d.reference, '');
        expect(d.wordsMeanings, isEmpty);
        expect(d.grade, 'Sahih');
      },
    );

    test('null lists default to empty', () {
      final d = HadithDetailsDto.fromJson({
        'id': '1',
        'title': 't',
        'hadeeth': 'h',
        'hints': null,
        'words_meanings': null,
        'categories': null,
      });
      expect(d.hints, isEmpty);
      expect(d.wordsMeanings, isEmpty);
      expect(d.categories, isEmpty);
    });

    test('rejects a hadith without an id', () {
      expect(
        () => HadithDetailsDto.fromJson({'title': 't'}),
        throwsFormatException,
      );
    });
  });
}
