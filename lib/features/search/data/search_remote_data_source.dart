import 'package:mynewapp/core/network/endpoints.dart';
import 'package:mynewapp/core/network/hadeeth_client.dart';
import 'package:mynewapp/features/search/data/search_dtos.dart';

abstract interface class SearchRemoteDataSource {
  /// Throws a `Failure` on any error.
  Future<List<SearchResultDto>> search(String phrase, {String language = 'ar'});
}

class HttpSearchRemoteDataSource implements SearchRemoteDataSource {
  HttpSearchRemoteDataSource(this._client);

  final HadeethClient _client;

  @override
  Future<List<SearchResultDto>> search(
    String phrase, {
    String language = 'ar',
  }) async {
    final data = await _client.get(searchPath, {
      'phrase': phrase,
      'language': language,
    });
    return parseResponse(() => parseSearchResponse(data));
  }
}
