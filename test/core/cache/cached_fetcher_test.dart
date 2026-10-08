import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/cache/cached_fetcher.dart';
import 'package:mynewapp/core/cache/response_cache.dart';
import 'package:mynewapp/core/errors/failure.dart';

const _policy = CachePolicy(
  fresh: Duration(hours: 1),
  maxStale: Duration(days: 10),
);
final _t0 = DateTime.utc(2026, 10, 9, 12);

class _Harness {
  _Harness() {
    fetcher = CachedFetcher(cache, now: () => now);
  }

  final cache = InMemoryResponseCache();
  DateTime now = _t0;
  late final CachedFetcher fetcher;
  int loads = 0;

  /// Parses a JSON object with a "value" field, throwing a parse failure otherwise.
  static String parse(Object? json) {
    if (json is Map && json['value'] is String) return json['value'] as String;
    throw const Failure(FailureKind.parse);
  }

  Future<String> fetch({
    Object? answer = const {'value': 'fresh'},
    Failure? failure,
    bool refresh = false,
    String key = 'k',
  }) => fetcher.fetch<String>(
    key: key,
    policy: _policy,
    refresh: refresh,
    parse: parse,
    load: () async {
      loads++;
      if (failure != null) throw failure;
      return answer;
    },
  );

  Future<void> save(Object? json, {Duration age = Duration.zero}) =>
      cache.write('k', json, now: now.subtract(age));
}

void main() {
  late _Harness h;
  setUp(() => h = _Harness());

  group('reading', () {
    test('a miss asks the server and saves the answer', () async {
      expect(await h.fetch(), 'fresh');
      expect(h.loads, 1);
      expect((await h.cache.read('k'))!.json, {'value': 'fresh'});
    });

    test('a fresh saved copy is used without asking the server', () async {
      await h.save({'value': 'saved'}, age: const Duration(minutes: 30));
      expect(await h.fetch(), 'saved');
      expect(h.loads, 0);
    });

    test('an expired saved copy is replaced by a new answer', () async {
      await h.save({'value': 'saved'}, age: const Duration(hours: 2));
      expect(await h.fetch(), 'fresh');
      expect(h.loads, 1);
      expect((await h.cache.read('k'))!.json, {'value': 'fresh'});
      expect((await h.cache.read('k'))!.fetchedAt, h.now);
    });

    test('refresh skips a fresh saved copy', () async {
      await h.save({'value': 'saved'}, age: const Duration(minutes: 1));
      expect(await h.fetch(refresh: true), 'fresh');
      expect(h.loads, 1);
    });
  });

  group('when the server cannot be reached', () {
    for (final kind in [FailureKind.noConnection, FailureKind.timeout]) {
      test('an old saved copy is used instead of an error ($kind)', () async {
        await h.save({'value': 'saved'}, age: const Duration(days: 3));
        expect(await h.fetch(failure: Failure(kind)), 'saved');
      });
    }

    test('a 5xx answer also falls back to the saved copy', () async {
      await h.save({'value': 'saved'}, age: const Duration(days: 3));
      expect(
        await h.fetch(
          failure: const Failure(FailureKind.server, statusCode: 503),
        ),
        'saved',
      );
    });

    test('refresh does not prevent the fallback', () async {
      await h.save({'value': 'saved'}, age: const Duration(days: 1));
      expect(
        await h.fetch(
          refresh: true,
          failure: const Failure(FailureKind.noConnection),
        ),
        'saved',
      );
    });

    test('a copy older than the limit is not used', () async {
      await h.save({'value': 'saved'}, age: const Duration(days: 11));
      await expectLater(
        h.fetch(failure: const Failure(FailureKind.noConnection)),
        throwsA(
          isA<Failure>().having(
            (f) => f.kind,
            'kind',
            FailureKind.noConnection,
          ),
        ),
      );
    });

    test('with nothing saved the failure is reported', () async {
      await expectLater(
        h.fetch(failure: const Failure(FailureKind.timeout)),
        throwsA(isA<Failure>()),
      );
    });
  });

  group('other failures', () {
    test('not found removes the saved copy and is reported', () async {
      await h.save({'value': 'saved'}, age: const Duration(hours: 5));
      await expectLater(
        h.fetch(failure: const Failure(FailureKind.notFound, statusCode: 404)),
        throwsA(
          isA<Failure>().having((f) => f.kind, 'kind', FailureKind.notFound),
        ),
      );
      expect(await h.cache.read('k'), isNull);
    });

    test(
      'a client error (4xx other than 404) is reported and keeps the copy',
      () async {
        await h.save({'value': 'saved'}, age: const Duration(hours: 5));
        await expectLater(
          h.fetch(failure: const Failure(FailureKind.server, statusCode: 400)),
          throwsA(isA<Failure>()),
        );
        expect(await h.cache.read('k'), isNotNull);
      },
    );
  });

  group('bad data', () {
    test(
      'a malformed answer is reported and does not replace the good copy',
      () async {
        await h.save({'value': 'saved'}, age: const Duration(hours: 5));
        await expectLater(
          h.fetch(answer: {'unexpected': true}),
          throwsA(
            isA<Failure>().having((f) => f.kind, 'kind', FailureKind.parse),
          ),
        );
        expect((await h.cache.read('k'))!.json, {'value': 'saved'});
      },
    );

    test(
      'a saved copy that no longer parses is discarded and the server asked',
      () async {
        await h.save({'old-shape': 1}, age: const Duration(minutes: 5));
        expect(await h.fetch(), 'fresh');
        expect(h.loads, 1);
        expect((await h.cache.read('k'))!.json, {'value': 'fresh'});
      },
    );

    test(
      'an unparseable saved copy is not used as a fallback either',
      () async {
        await h.save({'old-shape': 1}, age: const Duration(days: 2));
        await expectLater(
          h.fetch(failure: const Failure(FailureKind.noConnection)),
          throwsA(isA<Failure>()),
        );
      },
    );
  });

  test('different keys never share a copy', () async {
    await h.fetch(answer: {'value': 'one'}, key: 'a');
    await h.fetch(answer: {'value': 'two'}, key: 'b');
    expect(await h.fetch(key: 'a'), 'one');
    expect(await h.fetch(key: 'b'), 'two');
    expect(h.loads, 2);
  });

  test('keyFor does not depend on the order of the query parameters', () {
    expect(
      CachedFetcher.keyFor('hadeeths/list', {'page': 1, 'language': 'ar'}),
      CachedFetcher.keyFor('hadeeths/list', {'language': 'ar', 'page': 1}),
    );
    expect(
      CachedFetcher.keyFor('hadeeths/list', {'page': 1}),
      isNot(CachedFetcher.keyFor('hadeeths/list', {'page': 2})),
    );
  });

  group('SwitchableResponseCache', () {
    test('while off it reads and writes nothing', () async {
      final inner = InMemoryResponseCache();
      final cache = SwitchableResponseCache(inner, enabled: false);
      await cache.write('k', {'a': 1}, now: _t0);
      expect(inner.length, 0);
      await inner.write('k', {'a': 1}, now: _t0);
      expect(await cache.read('k'), isNull);
      cache.enabled = true;
      expect(await cache.read('k'), isNotNull);
    });
  });
}
