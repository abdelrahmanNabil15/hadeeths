import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/categories/data/categories_remote_data_source.dart';
import 'package:mynewapp/features/categories/data/categories_repository_impl.dart';
import 'package:mynewapp/features/categories/data/category_dto.dart';

import '../../../support/fake_dio.dart';
import '../../../support/fixtures.dart';

class _ThrowingSource implements CategoriesRemoteDataSource {
  _ThrowingSource(this.error);

  final Object error;

  @override
  Future<List<CategoryDto>> fetchCategories({String language = 'ar'}) async =>
      throw error;
}

void main() {
  group('HttpCategoriesRemoteDataSource', () {
    test('requests categories/list for the language', () async {
      final (client, adapter) = fakeClient(
        (o, n) async => jsonResponse(categoriesJson),
      );
      final dtos = await HttpCategoriesRemoteDataSource(
        client,
      ).fetchCategories();
      expect(dtos, hasLength(5));
      expect(adapter.requests.single.path, 'categories/list');
      expect(adapter.requests.single.queryParameters, {'language': 'ar'});
    });

    test('a response of the wrong shape is a parse failure', () async {
      final (client, _) = fakeClient(
        (o, n) async => jsonResponse({'unexpected': true}),
      );
      expect(
        HttpCategoriesRemoteDataSource(client).fetchCategories(),
        throwsA(
          isA<Failure>().having((f) => f.kind, 'kind', FailureKind.parse),
        ),
      );
    });

    test('an item without an id is a parse failure', () async {
      final (client, _) = fakeClient(
        (o, n) async => jsonResponse([
          {'title': 'no id'},
        ]),
      );
      expect(
        HttpCategoriesRemoteDataSource(client).fetchCategories(),
        throwsA(
          isA<Failure>().having((f) => f.kind, 'kind', FailureKind.parse),
        ),
      );
    });
  });

  group('CategoriesRepositoryImpl', () {
    test('maps DTOs to domain entities', () async {
      final (client, _) = fakeClient(
        (o, n) async => jsonResponse(categoriesJson),
      );
      final repo = CategoriesRepositoryImpl(
        HttpCategoriesRemoteDataSource(client),
      );
      final result = await repo.getCategories();
      expect(result, isA<Success>());
      final categories = (result as Success).value as List;
      expect(categories, hasLength(5));
      expect(categories.first.title, 'جذر أول');
    });

    test('a Failure from the data source becomes an Err', () async {
      final repo = CategoriesRepositoryImpl(
        _ThrowingSource(const Failure(FailureKind.noConnection)),
      );
      final result = await repo.getCategories();
      expect((result as Err).failure, const Failure(FailureKind.noConnection));
    });

    test(
      'any other exception is reported as unexpected, not rethrown',
      () async {
        final repo = CategoriesRepositoryImpl(
          _ThrowingSource(StateError('bug')),
        );
        final result = await repo.getCategories();
        expect((result as Err).failure.kind, FailureKind.unexpected);
      },
    );
  });
}
