import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/categories/domain/hadith_category.dart';

abstract interface class CategoriesRepository {
  /// Every category (roots and descendants) as a flat list; build the tree with `parentId`.
  /// [language] is the API language code (`ar` or `en`); the English tree is smaller because
  /// only translated content is listed.
  Future<Result<List<HadithCategory>>> getCategories({
    required String language,
  });
}
