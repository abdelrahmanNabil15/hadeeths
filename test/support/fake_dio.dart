import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mynewapp/core/cache/cached_fetcher.dart';
import 'package:mynewapp/core/cache/response_cache.dart';
import 'package:mynewapp/core/network/hadeeth_client.dart';

typedef FakeHandler =
    Future<ResponseBody> Function(RequestOptions options, int callNumber);

/// A Dio adapter that answers from [handler] and records every request.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final FakeHandler handler;
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

ResponseBody jsonResponse(Object body, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
      },
    );

ResponseBody emptyResponse(int status) => ResponseBody.fromString('', status);

DioException dioError(RequestOptions o, DioExceptionType type) =>
    DioException(requestOptions: o, type: type);

/// A [HadeethClient] wired to a fake adapter, with no retry delay.
(HadeethClient, FakeAdapter) fakeClient(FakeHandler handler) {
  final adapter = FakeAdapter(handler);
  final dio = HadeethClient.createDio()..httpClientAdapter = adapter;
  return (HadeethClient(dio: dio, retryDelay: Duration.zero), adapter);
}

/// A fetcher whose cache is switched off, so a data source behaves as if nothing is saved.
CachedFetcher uncachedFetcher() => CachedFetcher(
  SwitchableResponseCache(InMemoryResponseCache(), enabled: false),
);
