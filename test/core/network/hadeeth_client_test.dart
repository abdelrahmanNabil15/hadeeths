import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/errors/failure.dart';

import '../../support/fake_dio.dart';

Future<Failure> failureOf(Future<Object?> Function() call) async {
  try {
    await call();
  } on Failure catch (f) {
    return f;
  }
  fail('Expected a Failure');
}

void main() {
  test('returns the decoded JSON and sends path and query unchanged', () async {
    final (client, adapter) = fakeClient(
      (o, n) async => jsonResponse({'ok': true}),
    );
    final data = await client.get('some/path', {'language': 'ar', 'page': 2});
    expect(data, {'ok': true});
    expect(adapter.requests.single.path, 'some/path');
    expect(adapter.requests.single.queryParameters, {
      'language': 'ar',
      'page': 2,
    });
  });

  group('error mapping', () {
    test('404 is notFound, not retryable, and not repeated', () async {
      final (client, adapter) = fakeClient((o, n) async => emptyResponse(404));
      final f = await failureOf(() => client.get('x', {}));
      expect(f.kind, FailureKind.notFound);
      expect(f.isRetryable, isFalse);
      expect(adapter.requests, hasLength(1));
    });

    test(
      '500 (unknown category id on the live API) is a server failure, not retried',
      () async {
        final (client, adapter) = fakeClient(
          (o, n) async => jsonResponse({
            'status': false,
            'error': {'message': 'Invalid node primary key 99999'},
          }, 500),
        );
        final f = await failureOf(() => client.get('x', {}));
        expect(f.kind, FailureKind.server);
        expect(f.statusCode, 500);
        expect(adapter.requests, hasLength(1));
      },
    );

    test('503 is retried twice and then reported', () async {
      final (client, adapter) = fakeClient((o, n) async => emptyResponse(503));
      final f = await failureOf(() => client.get('x', {}));
      expect(f.kind, FailureKind.server);
      expect(f.statusCode, 503);
      expect(adapter.requests, hasLength(3));
    });

    test('a transient 503 followed by success succeeds', () async {
      final (client, adapter) = fakeClient(
        (o, n) async => n == 1 ? emptyResponse(503) : jsonResponse([1]),
      );
      expect(await client.get('x', {}), [1]);
      expect(adapter.requests, hasLength(2));
    });

    test(
      'timeouts are retried a bounded number of times, then reported as timeout',
      () async {
        final (client, adapter) = fakeClient(
          (o, n) => throw dioError(o, DioExceptionType.receiveTimeout),
        );
        final f = await failureOf(() => client.get('x', {}));
        expect(f.kind, FailureKind.timeout);
        expect(adapter.requests, hasLength(3));
      },
    );

    test('no connection is reported immediately without retries', () async {
      final (client, adapter) = fakeClient(
        (o, n) => throw dioError(o, DioExceptionType.connectionError),
      );
      final f = await failureOf(() => client.get('x', {}));
      expect(f.kind, FailureKind.noConnection);
      expect(adapter.requests, hasLength(1));
    });

    test('anything else is unexpected, and carries no raw exception', () async {
      final (client, _) = fakeClient(
        (o, n) => throw dioError(o, DioExceptionType.badCertificate),
      );
      final f = await failureOf(() => client.get('x', {}));
      expect(f.kind, FailureKind.unexpected);
      expect(f.toString(), 'Failure(FailureKind.unexpected)');
    });
  });
}
