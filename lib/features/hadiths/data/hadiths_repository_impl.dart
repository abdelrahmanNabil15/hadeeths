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
    int page = 1,
    int perPage = HadithsRepository.defaultPageSize,
  }) => Result.guard(() async {
    final dto = await _remote.fetchHadithPage(
      categoryId: categoryId,
      page: page,
      perPage: perPage,
    );
    return dto.toEntity();
  });

  @override
  Future<Result<HadithDetails>> getHadithDetails(String id) =>
      Result.guard(() async {
        final dto = await _remote.fetchHadithDetails(id);
        return dto.toEntity();
      });
}
