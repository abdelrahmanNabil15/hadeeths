import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/Shared/Network/hadeeth_api.dart';
import 'package:mynewapp/Shared/errors/failure.dart';

import '../support/fixtures.dart';

typedef _Handler =
    Future<ResponseBody> Function(RequestOptions options, int callNumber);

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final _Handler handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options, requests.length);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json; charset=utf-8'],
  },
);

ResponseBody _empty(int status) => ResponseBody.fromString('', status);

(HttpHadeethApi, _FakeAdapter) _api(_Handler handler) {
  final adapter = _FakeAdapter(handler);
  final dio = HttpHadeethApi.createDio()..httpClientAdapter = adapter;
  return (HttpHadeethApi(dio: dio, retryDelay: Duration.zero), adapter);
}

DioException _dioError(RequestOptions o, DioExceptionType type) =>
    DioException(requestOptions: o, type: type);

Future<Failure> _failureOf(Future<Object?> Function() call) async {
  try {
    await call();
  } on Failure catch (f) {
    return f;
  }
  fail('Expected a Failure');
}

void main() {
  group('requests', () {
    test('categories: path and language', () async {
      final (api, adapter) = _api((o, n) async => _json(categoriesJson));
      final categories = await api.getCategories();
      expect(categories, hasLength(5));
      expect(adapter.requests.single.path, 'categories/list');
      expect(adapter.requests.single.queryParameters, {'language': 'ar'});
    });

    test('hadith page: category, page and page size are sent', () async {
      final (api, adapter) = _api(
        (o, n) async => _json(hadithPageJson(ids: ['1'])),
      );
      await api.getHadithPage(categoryId: '8', page: 3);
      expect(adapter.requests.single.path, 'hadeeths/list');
      expect(adapter.requests.single.queryParameters, {
        'language': 'ar',
        'category_id': '8',
        'page': 3,
        'per_page': 20,
      });
    });

    test('details: id and language are sent', () async {
      final (api, adapter) = _api((o, n) async => _json(englishDetailsJson));
      final d = await api.getHadithDetails('2962', language: 'en');
      expect(d.grade, 'Sahih');
      expect(adapter.requests.single.queryParameters, {
        'language': 'en',
        'id': '2962',
      });
    });
  });

  group('error mapping', () {
    test('404 is notFound and is not retried', () async {
      final (api, adapter) = _api((o, n) async => _empty(404));
      final f = await _failureOf(() => api.getHadithDetails('1'));
      expect(f.kind, FailureKind.notFound);
      expect(f.isRetryable, isFalse);
      expect(adapter.requests, hasLength(1));
    });

    test(
      '500 (unknown category id on the live API) is a server failure, not retried',
      () async {
        final (api, adapter) = _api(
          (o, n) async => _json({
            'status': false,
            'error': {'message': 'Invalid node primary key 99999'},
          }, 500),
        );
        final f = await _failureOf(
          () => api.getHadithPage(categoryId: '99999'),
        );
        expect(f.kind, FailureKind.server);
        expect(f.statusCode, 500);
        expect(adapter.requests, hasLength(1));
      },
    );

    test('503 is retried twice and then reported', () async {
      final (api, adapter) = _api((o, n) async => _empty(503));
      final f = await _failureOf(() => api.getCategories());
      expect(f.kind, FailureKind.server);
      expect(f.statusCode, 503);
      expect(adapter.requests, hasLength(3));
    });

    test('a transient 503 followed by success succeeds', () async {
      final (api, adapter) = _api(
        (o, n) async => n == 1 ? _empty(503) : _json(categoriesJson),
      );
      expect(await api.getCategories(), hasLength(5));
      expect(adapter.requests, hasLength(2));
    });

    test(
      'timeouts are retried a bounded number of times, then reported as timeout',
      () async {
        final (api, adapter) = _api(
          (o, n) => throw _dioError(o, DioExceptionType.receiveTimeout),
        );
        final f = await _failureOf(() => api.getCategories());
        expect(f.kind, FailureKind.timeout);
        expect(adapter.requests, hasLength(3));
      },
    );

    test('no connection is reported immediately without retries', () async {
      final (api, adapter) = _api(
        (o, n) => throw _dioError(o, DioExceptionType.connectionError),
      );
      final f = await _failureOf(() => api.getCategories());
      expect(f.kind, FailureKind.noConnection);
      expect(adapter.requests, hasLength(1));
    });

    test('a response of the wrong shape is a parse failure', () async {
      final (api, _) = _api((o, n) async => _json({'unexpected': true}));
      final f = await _failureOf(() => api.getCategories());
      expect(f.kind, FailureKind.parse);
    });

    test('an empty 200 body is a parse failure', () async {
      final (api, _) = _api((o, n) async => _empty(200));
      final f = await _failureOf(() => api.getHadithDetails('1'));
      expect(f.kind, FailureKind.parse);
    });

    test('failures never expose raw exceptions through toString', () async {
      final (api, _) = _api((o, n) async => _empty(404));
      final f = await _failureOf(() => api.getHadithDetails('1'));
      expect(f.toString(), 'Failure(FailureKind.notFound, 404)');
    });
  });
}
