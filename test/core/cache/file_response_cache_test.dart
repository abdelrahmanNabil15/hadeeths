import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/cache/file_response_cache.dart';

final _t0 = DateTime.utc(2026, 10, 9, 12);

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('hadeeth_cache_test'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  FileResponseCache cache({int maxBytes = FileResponseCache.defaultMaxBytes}) =>
      FileResponseCache(Directory('${dir.path}/c'), maxBytes: maxBytes);

  test(
    'a saved response reads back exactly, with Arabic text untouched',
    () async {
      final c = cache();
      const json = {
        'id': '1',
        'hadeeth': 'عَنْ أَبِي هُرَيْرَةَ رضي الله عنه',
        'hints': ['أ', 'ب'],
        'n': 3,
        'nothing': null,
      };
      await c.write('hadeeths/one?id=1', json, now: _t0);
      final entry = await c.read('hadeeths/one?id=1');
      expect(entry!.json, json);
      expect(entry.fetchedAt.toUtc(), _t0);
    },
  );

  test('an unknown key reads as nothing', () async {
    expect(await cache().read('missing'), isNull);
  });

  test('a cache directory that does not exist yet is fine', () async {
    final c = FileResponseCache(Directory('${dir.path}/nested/not/yet'));
    expect(await c.read('k'), isNull);
    expect(await c.sizeInBytes(), 0);
    await c.write('k', {'a': 1}, now: _t0);
    expect(await c.read('k'), isNotNull);
  });

  test('overwriting replaces the entry', () async {
    final c = cache();
    await c.write('k', {'v': 1}, now: _t0);
    await c.write('k', {'v': 2}, now: _t0);
    expect((await c.read('k'))!.json, {'v': 2});
  });

  test('delete removes one entry, clear removes everything', () async {
    final c = cache();
    await c.write('a', {'v': 1}, now: _t0);
    await c.write('b', {'v': 2}, now: _t0);
    await c.delete('a');
    expect(await c.read('a'), isNull);
    expect(await c.read('b'), isNotNull);
    await c.clear();
    expect(await c.read('b'), isNull);
    expect(await c.sizeInBytes(), 0);
  });

  test('a corrupt file counts as a miss and is removed', () async {
    final c = cache();
    await c.write('k', {'v': 1}, now: _t0);
    final file = Directory('${dir.path}/c').listSync().whereType<File>().single;
    file.writeAsStringSync('{not json');
    expect(await c.read('k'), isNull);
    expect(file.existsSync(), isFalse);
  });

  test('a file from another format version is ignored', () async {
    final c = cache();
    await c.write('k', {'v': 1}, now: _t0);
    final file = Directory('${dir.path}/c').listSync().whereType<File>().single;
    final envelope =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    envelope['v'] = 99;
    file.writeAsStringSync(jsonEncode(envelope));
    expect(await c.read('k'), isNull);
  });

  test(
    'a file that belongs to a different key is never returned for this one',
    () async {
      final c = cache();
      await c.write('real-key', {'v': 'private'}, now: _t0);
      final file = Directory(
        '${dir.path}/c',
      ).listSync().whereType<File>().single;
      // Pretend another key hashed to the same file name.
      final envelope =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      envelope['key'] = 'some-other-key';
      file.writeAsStringSync(jsonEncode(envelope));
      expect(await c.read('real-key'), isNull);
    },
  );

  test('no half-written temporary files are left behind', () async {
    final c = cache();
    for (var i = 0; i < 5; i++) {
      await c.write('k$i', {'i': i}, now: _t0);
    }
    final names = Directory(
      '${dir.path}/c',
    ).listSync().map((e) => e.path).toList();
    expect(names.where((n) => n.endsWith('.tmp')), isEmpty);
    expect(names, hasLength(5));
  });

  group('size limit', () {
    final payload = {'text': 'x' * 400};

    /// File systems keep modification times to the second, so the test sets them itself.
    Future<void> setLastUsed(String key, DateTime when) async {
      for (final f in Directory('${dir.path}/c').listSync().whereType<File>()) {
        if (f.path.endsWith('.json') &&
            (jsonDecode(f.readAsStringSync()) as Map)['key'] == key) {
          await f.setLastModified(when);
        }
      }
    }

    test('the least recently used entries are evicted first', () async {
      final c = cache(maxBytes: 2500);
      final base = DateTime.now().subtract(const Duration(hours: 1));
      for (var i = 0; i < 4; i++) {
        await c.write('k$i', payload, now: _t0);
        await setLastUsed('k$i', base.add(Duration(minutes: i)));
      }
      // k0 is the oldest, but reading it makes it the most recently used.
      expect(await c.read('k0'), isNotNull);
      await c.write('k4', payload, now: _t0);
      await setLastUsed('k4', base.add(const Duration(minutes: 30)));
      await c.write('k5', payload, now: _t0); // pushes the total over the limit

      expect(await c.read('k0'), isNotNull, reason: 'recently read, so kept');
      expect(await c.read('k1'), isNull, reason: 'oldest unused, so evicted');
      expect(await c.read('k5'), isNotNull, reason: 'just written, so kept');
      expect(await c.sizeInBytes(), lessThanOrEqualTo(2500));
    });

    test('the cache never grows past the limit', () async {
      final c = cache(maxBytes: 3000);
      for (var i = 0; i < 30; i++) {
        await c.write('k$i', payload, now: _t0);
      }
      expect(await c.sizeInBytes(), lessThanOrEqualTo(3000));
    });
  });

  test('size is the sum of the saved files', () async {
    final c = cache();
    expect(await c.sizeInBytes(), 0);
    await c.write('k', {'text': 'hello'}, now: _t0);
    expect(await c.sizeInBytes(), greaterThan(10));
  });

  test('file names are 16 hex digits and never start with a dash', () async {
    final c = cache();
    for (var i = 0; i < 50; i++) {
      await c.write('hadeeths/one?id=$i&language=ar', {'i': i}, now: _t0);
    }
    final names = Directory(
      '${dir.path}/c',
    ).listSync().map((e) => e.path.split(Platform.pathSeparator).last).toList();
    expect(names, hasLength(50));
    expect(
      names.every((n) => RegExp(r'^[0-9a-f]{16}\.json$').hasMatch(n)),
      isTrue,
    );
  });
}
