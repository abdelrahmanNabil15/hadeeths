import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/categories/domain/hadith_category.dart';

abstract interface class CategoriesRepository {
  /// Every category (roots and descendants) as a flat list; build the tree with `parentId`.
  Future<Result<List<HadithCategory>>> getCategories();
}
