import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/Model/category_node.dart';
import 'package:mynewapp/Model/hadith_details.dart';
import 'package:mynewapp/Model/hadith_page.dart';

import '../support/fixtures.dart';

void main() {
  group('CategoryNode', () {
    test('parses string ids/counts and null parent', () {
      final root = CategoryNode.fromJson(categoriesJson[0]);
      expect(root.id, '1');
      expect(root.hadithCount, 197);
      expect(root.parentId, isNull);
      expect(root.isRoot, isTrue);
    });

    test('parses a child with a parent id', () {
      final child = CategoryNode.fromJson(categoriesJson[2]);
      expect(child.parentId, '1');
      expect(child.isRoot, isFalse);
    });

    test('accepts numeric ids and counts', () {
      final node = CategoryNode.fromJson({
        'id': 5,
        'title': 't',
        'hadeeths_count': 7,
        'parent_id': 2,
      });
      expect(node.id, '5');
      expect(node.hadithCount, 7);
      expect(node.parentId, '2');
    });

    test('rejects a category without an id', () {
      expect(
        () => CategoryNode.fromJson({'title': 'x'}),
        throwsFormatException,
      );
    });
  });

  group('HadithPage', () {
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
      final page = HadithPage.fromJson({
        'data': [
          {'id': '1', 'title': 'a'},
        ],
      });
      expect(page.currentPage, 1);
      expect(page.lastPage, 1);
      expect(page.totalItems, 1);
    });

    test('missing data is an empty page', () {
      final page = HadithPage.fromJson({
        'meta': {'current_page': '1', 'last_page': 1},
      });
      expect(page.items, isEmpty);
    });

    test('a malformed item is reported, not swallowed', () {
      expect(
        () => HadithPage.fromJson({
          'data': ['not an object'],
        }),
        throwsFormatException,
      );
    });
  });

  group('HadithDetails', () {
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
      final d = HadithDetails.fromJson({
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
        () => HadithDetails.fromJson({'title': 't'}),
        throwsFormatException,
      );
    });
  });
}
