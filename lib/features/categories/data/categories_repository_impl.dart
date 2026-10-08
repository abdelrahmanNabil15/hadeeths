import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/categories/data/categories_remote_data_source.dart';
import 'package:mynewapp/features/categories/domain/categories_repository.dart';
import 'package:mynewapp/features/categories/domain/hadith_category.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  CategoriesRepositoryImpl(this._remote);

  final CategoriesRemoteDataSource _remote;

  @override
  Future<Result<List<HadithCategory>>> getCategories({
    required String language,
    bool refresh = false,
  }) => Result.guard(
    () async => [
      for (final dto in await _remote.fetchCategories(
        language: language,
        refresh: refresh,
      ))
        dto.toEntity(),
    ],
  );
}
