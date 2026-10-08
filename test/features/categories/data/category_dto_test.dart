import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/categories/data/category_dto.dart';
import 'package:mynewapp/features/categories/domain/hadith_category.dart';

import '../../../support/fixtures.dart';

HadithCategory category(Map<String, dynamic> json) =>
    CategoryDto.fromJson(json).toEntity();

void main() {
  group('CategoryDto', () {
    test('parses string ids/counts and null parent', () {
      final root = category(categoriesJson[0]);
      expect(root.id, '1');
      expect(root.hadithCount, 197);
      expect(root.parentId, isNull);
      expect(root.isRoot, isTrue);
    });

    test('parses a child with a parent id', () {
      final child = category(categoriesJson[2]);
      expect(child.parentId, '1');
      expect(child.isRoot, isFalse);
    });

    test('accepts numeric ids and counts', () {
      final node = category({
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
      expect(() => category({'title': 'x'}), throwsFormatException);
    });
  });
}
