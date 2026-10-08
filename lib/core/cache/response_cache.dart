/// A saved API response: the decoded JSON exactly as it arrived, and when it arrived.
class CacheEntry {
  const CacheEntry({
    required this.key,
    required this.json,
    required this.fetchedAt,
  });

  final String key;
  final Object? json;
  final DateTime fetchedAt;
}

/// Local copies of API responses, so content the user has already opened can be read again
/// without a connection. It is a cache, not a database: anything may be missing, and every
/// failure of the cache itself is swallowed (a broken cache must never break the app).
abstract interface class ResponseCache {
  Future<CacheEntry?> read(String key);

  Future<void> write(String key, Object? json, {required DateTime now});

  Future<void> delete(String key);

  Future<void> clear();

  /// Bytes used on disk (0 for caches that do not use any).
  Future<int> sizeInBytes();
}

/// Keeps entries in memory only (tests, and the fallback when no directory is available).
class InMemoryResponseCache implements ResponseCache {
  final _entries = <String, CacheEntry>{};

  int get length => _entries.length;

  @override
  Future<CacheEntry?> read(String key) async => _entries[key];

  @override
  Future<void> write(String key, Object? json, {required DateTime now}) async {
    _entries[key] = CacheEntry(key: key, json: json, fetchedAt: now);
  }

  @override
  Future<void> delete(String key) async => _entries.remove(key);

  @override
  Future<void> clear() async => _entries.clear();

  @override
  Future<int> sizeInBytes() async => 0;
}

/// Wraps another cache and can be switched off (the user's "save copies" setting). While it
/// is off it reads nothing and writes nothing.
class SwitchableResponseCache implements ResponseCache {
  SwitchableResponseCache(this.inner, {this.enabled = true});

  final ResponseCache inner;
  bool enabled;

  @override
  Future<CacheEntry?> read(String key) async =>
      enabled ? inner.read(key) : null;

  @override
  Future<void> write(String key, Object? json, {required DateTime now}) async {
    if (enabled) await inner.write(key, json, now: now);
  }

  @override
  Future<void> delete(String key) => inner.delete(key);

  @override
  Future<void> clear() => inner.clear();

  @override
  Future<int> sizeInBytes() => inner.sizeInBytes();
}
