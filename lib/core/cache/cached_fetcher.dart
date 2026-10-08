import 'package:mynewapp/core/cache/response_cache.dart';
import 'package:mynewapp/core/errors/failure.dart';

/// How long a saved response may be used.
class CachePolicy {
  const CachePolicy({
    required this.fresh,
    this.maxStale = const Duration(days: 60),
  });

  /// Within this age the saved copy is used without asking the server.
  final Duration fresh;

  /// Beyond [fresh] a saved copy is used only when the server cannot be reached, and only
  /// up to this age.
  final Duration maxStale;
}

/// Read-through cache for API calls.
///
/// 1. A fresh saved copy is returned without a request (unless [fetch] is told to `refresh`).
/// 2. Otherwise the server is asked. A good answer is parsed first and saved only if it
///    parses, so a malformed response never replaces a good copy.
/// 3. If the server cannot be reached (no connection, timeout, 5xx) an older saved copy is
///    used instead of an error, up to [CachePolicy.maxStale].
/// 4. "Not found" removes the saved copy (the content is gone); other failures keep it.
///
/// A saved copy that no longer parses is discarded and treated as missing.
class CachedFetcher {
  CachedFetcher(this._cache, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ResponseCache _cache;
  final DateTime Function() _now;

  Future<T> fetch<T>({
    required String key,
    required CachePolicy policy,
    required Future<Object?> Function() load,
    required T Function(Object? json) parse,
    bool refresh = false,
  }) async {
    final saved = await _cache.read(key);
    T? fromSaved;
    var age = Duration.zero;
    if (saved != null) {
      age = _now().difference(saved.fetchedAt);
      try {
        fromSaved = parse(saved.json);
      } catch (_) {
        await _cache.delete(key);
      }
    }

    if (fromSaved != null &&
        !refresh &&
        !age.isNegative &&
        age <= policy.fresh) {
      return fromSaved;
    }

    try {
      final json = await load();
      final value = parse(json);
      await _cache.write(key, json, now: _now());
      return value;
    } on Failure catch (failure) {
      if (failure.kind == FailureKind.notFound) {
        await _cache.delete(key);
        rethrow;
      }
      final unreachable =
          failure.kind == FailureKind.noConnection ||
          failure.kind == FailureKind.timeout ||
          (failure.kind == FailureKind.server &&
              (failure.statusCode ?? 500) >= 500);
      if (unreachable && fromSaved != null && age <= policy.maxStale) {
        return fromSaved;
      }
      rethrow;
    }
  }

  /// A stable key for one request.
  static String keyFor(String path, Map<String, dynamic> query) {
    final names = query.keys.toList()..sort();
    return '$path?${[for (final n in names) '$n=${query[n]}'].join('&')}';
  }
}
