import 'package:mynewapp/core/json/json_helpers.dart';
import 'package:mynewapp/core/network/endpoints.dart';
import 'package:mynewapp/core/network/hadeeth_client.dart';
import 'package:mynewapp/features/categories/data/category_dto.dart';

abstract interface class CategoriesRemoteDataSource {
  /// Throws a `Failure` on any error.
  Future<List<CategoryDto>> fetchCategories({String language = 'ar'});
}

class HttpCategoriesRemoteDataSource implements CategoriesRemoteDataSource {
  HttpCategoriesRemoteDataSource(this._client);

  final HadeethClient _client;

  @override
  Future<List<CategoryDto>> fetchCategories({String language = 'ar'}) async {
    final data = await _client.get(list, {'language': language});
    return parseResponse(
      () => asList(
        data,
        'categories',
      ).map((e) => CategoryDto.fromJson(asMap(e, 'category'))).toList(),
    );
  }
}
