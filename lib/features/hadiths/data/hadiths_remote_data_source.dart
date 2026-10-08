import 'package:mynewapp/core/json/json_helpers.dart';
import 'package:mynewapp/core/network/endpoints.dart';
import 'package:mynewapp/core/network/hadeeth_client.dart';
import 'package:mynewapp/features/hadiths/data/hadith_dtos.dart';

abstract interface class HadithsRemoteDataSource {
  /// All methods throw a `Failure` on any error.
  Future<HadithPageDto> fetchHadithPage({
    required String categoryId,
    required int page,
    required int perPage,
    String language = 'ar',
  });

  Future<HadithDetailsDto> fetchHadithDetails(
    String id, {
    String language = 'ar',
  });
}

class HttpHadithsRemoteDataSource implements HadithsRemoteDataSource {
  HttpHadithsRemoteDataSource(this._client);

  final HadeethClient _client;

  @override
  Future<HadithPageDto> fetchHadithPage({
    required String categoryId,
    required int page,
    required int perPage,
    String language = 'ar',
  }) async {
    final data = await _client.get(headlist, {
      'language': language,
      'category_id': categoryId,
      'page': page,
      'per_page': perPage,
    });
    return parseResponse(
      () => HadithPageDto.fromJson(asMap(data, 'hadith page')),
    );
  }

  @override
  Future<HadithDetailsDto> fetchHadithDetails(
    String id, {
    String language = 'ar',
  }) async {
    final data = await _client.get(oneElment, {'language': language, 'id': id});
    return parseResponse(
      () => HadithDetailsDto.fromJson(asMap(data, 'hadith')),
    );
  }
}
