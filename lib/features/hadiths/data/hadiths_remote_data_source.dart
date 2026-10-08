import 'package:mynewapp/core/cache/cached_fetcher.dart';
import 'package:mynewapp/core/json/json_helpers.dart';
import 'package:mynewapp/core/network/endpoints.dart';
import 'package:mynewapp/core/network/hadeeth_client.dart';
import 'package:mynewapp/features/hadiths/data/hadith_dtos.dart';

abstract interface class HadithsRemoteDataSource {
  /// All methods throw a `Failure` on any error. [refresh] asks the server even if a recent
  /// saved copy exists (pull-to-refresh).
  Future<HadithPageDto> fetchHadithPage({
    required String categoryId,
    required int page,
    required int perPage,
    String language = 'ar',
    bool refresh = false,
  });

  Future<HadithDetailsDto> fetchHadithDetails(
    String id, {
    String language = 'ar',
  });
}

class HttpHadithsRemoteDataSource implements HadithsRemoteDataSource {
  HttpHadithsRemoteDataSource(this._client, this._fetcher);

  final HadeethClient _client;
  final CachedFetcher _fetcher;

  /// Lists can gain items; keep them a day.
  static const listPolicy = CachePolicy(fresh: Duration(days: 1));

  /// A hadith's text rarely changes; keep it a week before checking again.
  static const detailsPolicy = CachePolicy(fresh: Duration(days: 7));

  @override
  Future<HadithPageDto> fetchHadithPage({
    required String categoryId,
    required int page,
    required int perPage,
    String language = 'ar',
    bool refresh = false,
  }) {
    final query = {
      'language': language,
      'category_id': categoryId,
      'page': page,
      'per_page': perPage,
    };
    return _fetcher.fetch(
      key: CachedFetcher.keyFor(headlist, query),
      policy: listPolicy,
      refresh: refresh,
      load: () => _client.get(headlist, query),
      parse: (data) => parseResponse(
        () => HadithPageDto.fromJson(asMap(data, 'hadith page')),
      ),
    );
  }

  @override
  Future<HadithDetailsDto> fetchHadithDetails(
    String id, {
    String language = 'ar',
  }) {
    final query = {'language': language, 'id': id};
    return _fetcher.fetch(
      key: CachedFetcher.keyFor(oneElment, query),
      policy: detailsPolicy,
      load: () => _client.get(oneElment, query),
      parse: (data) =>
          parseResponse(() => HadithDetailsDto.fromJson(asMap(data, 'hadith'))),
    );
  }
}
