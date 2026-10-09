import 'dart:convert';
import 'dart:io';

import 'package:mynewapp/core/cache/response_cache.dart';

/// Stores each response as one small JSON file in [directory].
///
/// - Writes go to a temporary file first and are renamed, so a crash never leaves half a file.
/// - Each file records its own key, so two keys that hash alike can never return each other's data.
/// - Reading a file marks it as recently used; when the total passes [maxBytes] the
///   least recently used files are deleted first.
/// - Any problem (missing directory, corrupt file, full disk) behaves like "not cached".
class FileResponseCache implements ResponseCache {
  FileResponseCache(this.directory, {this.maxBytes = defaultMaxBytes});

  static const defaultMaxBytes = 20 * 1024 * 1024;
  static const _formatVersion = 1;

  final Directory directory;
  final int maxBytes;

  @override
  Future<CacheEntry?> read(String key) async {
    final file = _fileFor(key);
    try {
      if (!await file.exists()) return null;
      final envelope = jsonDecode(await file.readAsString());
      if (envelope is! Map ||
          envelope['v'] != _formatVersion ||
          envelope['key'] != key ||
          envelope['at'] is! String) {
        await _deleteQuietly(file);
        return null;
      }
      await file.setLastModified(
        DateTime.now(),
      ); // "recently used" for eviction
      return CacheEntry(
        key: key,
        json: envelope['json'],
        fetchedAt: DateTime.parse(envelope['at'] as String),
      );
    } catch (_) {
      await _deleteQuietly(file);
      return null;
    }
  }

  @override
  Future<void> write(String key, Object? json, {required DateTime now}) async {
    try {
      await directory.create(recursive: true);
      final file = _fileFor(key);
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(
        jsonEncode({
          'v': _formatVersion,
          'key': key,
          'at': now.toUtc().toIso8601String(),
          'json': json,
        }),
        flush: true,
      );
      await temp.rename(file.path);
      await _evictIfNeeded();
    } catch (_) {
      // A cache that cannot write is just a cache that stays empty.
    }
  }

  @override
  Future<void> delete(String key) => _deleteQuietly(_fileFor(key));

  @override
  Future<void> clear() async {
    try {
      if (await directory.exists()) await directory.delete(recursive: true);
    } catch (_) {}
  }

  @override
  Future<int> sizeInBytes() async {
    var total = 0;
    for (final f in await _files()) {
      try {
        total += await f.length();
      } catch (_) {}
    }
    return total;
  }

  File _fileFor(String key) =>
      File('${directory.path}${Platform.pathSeparator}${_hash(key)}.json');

  Future<List<File>> _files() async {
    try {
      if (!await directory.exists()) return const [];
      return [
        await for (final e in directory.list())
          if (e is File && e.path.endsWith('.json')) e,
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _evictIfNeeded() async {
    final files = await _files();
    final stats = <(File, int, DateTime)>[];
    var total = 0;
    for (final f in files) {
      try {
        final s = await f.stat();
        stats.add((f, s.size, s.modified));
        total += s.size;
      } catch (_) {}
    }
    if (total <= maxBytes) return;
    stats.sort((a, b) => a.$3.compareTo(b.$3)); // oldest use first
    final target = (maxBytes * 0.9)
        .floor(); // leave some room so we do not evict on every write
    for (final (file, size, _) in stats) {
      if (total <= target) break;
      await _deleteQuietly(file);
      total -= size;
    }
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// 64-bit FNV-1a as 16 hex digits (the two 32-bit halves, so the result is never negative):
  /// short, stable file names without another dependency.
  static String _hash(String key) {
    var hash = 0xcbf29ce484222325;
    for (final unit in utf8.encode(key)) {
      hash ^= unit;
      hash *= 0x100000001b3; // wraps around at 64 bits
    }
    String half(int value) => value.toRadixString(16).padLeft(8, '0');
    return half((hash >>> 32) & 0xFFFFFFFF) + half(hash & 0xFFFFFFFF);
  }
}
