import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/search/data/search_remote_data_source.dart';
import 'package:mynewapp/features/search/domain/hadith_search_result.dart';
import 'package:mynewapp/features/search/domain/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._remote);

  final SearchRemoteDataSource _remote;

  @override
  Future<Result<List<HadithSearchResult>>> search(
    String phrase, {
    required String language,
  }) => Result.guard(() async {
    final dtos = await _remote.search(phrase, language: language);
    return [for (final dto in dtos) dto.toEntity()];
  });
}
