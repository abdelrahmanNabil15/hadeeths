import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_details.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_page.dart';

abstract interface class HadithsRepository {
  /// Hadiths per page requested from the server (the API's own default).
  static const defaultPageSize = 20;

  /// One page of the hadiths filed under [categoryId]; pages start at 1.
  Future<Result<HadithPage>> getHadithPage({
    required String categoryId,
    int page = 1,
    int perPage = defaultPageSize,
  });

  Future<Result<HadithDetails>> getHadithDetails(String id);
}
