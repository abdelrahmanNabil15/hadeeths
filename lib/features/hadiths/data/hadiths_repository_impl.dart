import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/hadiths/data/hadiths_remote_data_source.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_details.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_page.dart';
import 'package:mynewapp/features/hadiths/domain/hadiths_repository.dart';

class HadithsRepositoryImpl implements HadithsRepository {
  HadithsRepositoryImpl(this._remote);

  final HadithsRemoteDataSource _remote;

  @override
  Future<Result<HadithPage>> getHadithPage({
    required String categoryId,
    required String language,
    int page = 1,
    int perPage = HadithsRepository.defaultPageSize,
    bool refresh = false,
  }) => Result.guard(() async {
    final dto = await _remote.fetchHadithPage(
      categoryId: categoryId,
      page: page,
      perPage: perPage,
      language: language,
      refresh: refresh,
    );
    return dto.toEntity();
  });

  @override
  Future<Result<HadithDetails>> getHadithDetails(
    String id, {
    required String language,
  }) => Result.guard(() async {
    final dto = await _remote.fetchHadithDetails(id, language: language);
    return dto.toEntity();
  });
}
