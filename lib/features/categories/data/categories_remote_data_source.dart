import 'package:mynewapp/core/cache/cached_fetcher.dart';
import 'package:mynewapp/core/json/json_helpers.dart';
import 'package:mynewapp/core/network/endpoints.dart';
import 'package:mynewapp/core/network/hadeeth_client.dart';
import 'package:mynewapp/features/categories/data/category_dto.dart';

abstract interface class CategoriesRemoteDataSource {
  /// Throws a `Failure` on any error. [refresh] asks the server even if a recent saved
  /// copy exists (pull-to-refresh).
  Future<List<CategoryDto>> fetchCategories({
    String language = 'ar',
    bool refresh = false,
  });
}

class HttpCategoriesRemoteDataSource implements CategoriesRemoteDataSource {
  HttpCategoriesRemoteDataSource(this._client, this._fetcher);

  final HadeethClient _client;
  final CachedFetcher _fetcher;

  /// The category tree changes rarely; a day-old copy is fine.
  static const policy = CachePolicy(fresh: Duration(days: 1));

  @override
  Future<List<CategoryDto>> fetchCategories({
    String language = 'ar',
    bool refresh = false,
  }) {
    final query = {'language': language};
    return _fetcher.fetch(
      key: CachedFetcher.keyFor(list, query),
      policy: policy,
      refresh: refresh,
      load: () => _client.get(list, query),
      parse: (data) => parseResponse(
        () => asList(
          data,
          'categories',
        ).map((e) => CategoryDto.fromJson(asMap(e, 'category'))).toList(),
      ),
    );
  }
}
