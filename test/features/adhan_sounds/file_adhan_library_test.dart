import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/platform/adhan_sound_bridge.dart';
import 'package:mynewapp/features/adhan_sounds/data/file_adhan_library.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_library.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_sound.dart';

/// A phone's shared sound list in memory.
class _FakeBridge implements AdhanSoundBridge {
  bool supported = true;
  bool refuse = false;
  final registered = <String, String>{};
  final removed = <String>[];

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<String?> register(String path, String name) async {
    if (refuse) return null;
    return registered.putIfAbsent(name, () => 'content://media/audio/$name');
  }

  @override
  Future<void> unregister(String name) async {
    registered.remove(name);
    removed.add(name);
  }
}

/// Answers every request with [respond], and counts them.
class _Server implements HttpClientAdapter {
  _Server(this.respond);

  final Future<ResponseBody> Function(RequestOptions options) respond;
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests++;
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

/// The recording used here. Its listed size is what the fake server sends.
final _sound = adhanCatalogue[1];

Uint8List _mp3Bytes([int? length, List<int> head = const [0x49, 0x44, 0x33]]) {
  final bytes = Uint8List(length ?? _sound.bytes);
  bytes.setRange(0, head.length, head);
  return bytes;
}

ResponseBody _audio(Uint8List bytes, {String type = 'audio/mpeg'}) =>
    ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        Headers.contentTypeHeader: [type],
        Headers.contentLengthHeader: ['${bytes.length}'],
      },
    );

void main() {
  late Directory dir;
  late _FakeBridge bridge;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('adhan_test');
    bridge = _FakeBridge();
  });

  tearDown(() => dir.deleteSync(recursive: true));

  FileAdhanLibrary library(_Server server) => FileAdhanLibrary(
    directory: () async => Directory('${dir.path}/adhan'),
    dio: Dio()..httpClientAdapter = server,
    bridge: bridge,
  );

  List<String> leftovers() => Directory('${dir.path}/adhan').existsSync()
      ? [
          for (final f in Directory('${dir.path}/adhan').listSync())
            f.path.split(RegExp(r'[\\/]')).last,
        ]
      : [];

  test(
    'a download is kept, listed for notifications and reported as downloaded',
    () async {
      final lib = library(_Server((_) async => _audio(_mp3Bytes())));
      final progress = <double>[];
      expect(await lib.downloaded(), isEmpty);

      await lib.download(_sound, onProgress: progress.add);

      expect(await lib.downloaded(), {_sound.id});
      expect(leftovers(), ['${_sound.id}.mp3']);
      expect(bridge.registered, {
        _sound.id: 'content://media/audio/${_sound.id}',
      });
      expect(await lib.uriFor(_sound.id), 'content://media/audio/${_sound.id}');
      expect(progress.last, 1);
    },
  );

  test('nothing is requested until a download is asked for', () async {
    final server = _Server((_) async => _audio(_mp3Bytes()));
    final lib = library(server);
    await lib.downloaded();
    await lib.isSupported();
    await lib.uriFor(_sound.id);
    expect(server.requests, 0);
  });

  test(
    'a web page instead of audio is refused and leaves nothing behind',
    () async {
      final lib = library(
        _Server((_) async => _audio(_mp3Bytes(), type: 'text/html')),
      );
      await expectLater(
        lib.download(_sound),
        throwsA(
          isA<AdhanDownloadException>().having(
            (e) => e.failure,
            'failure',
            AdhanDownloadFailure.notAudio,
          ),
        ),
      );
      expect(leftovers(), isEmpty);
      expect(bridge.registered, isEmpty);
    },
  );

  test(
    'a file far from the listed size, or without an MP3 start, is refused',
    () async {
      for (final bytes in [
        _mp3Bytes(_sound.bytes ~/ 4),
        _mp3Bytes(_sound.bytes * 2),
        _mp3Bytes(null, const [0x3C, 0x68, 0x74]),
      ]) {
        final lib = library(_Server((_) async => _audio(bytes)));
        await expectLater(
          lib.download(_sound),
          throwsA(
            isA<AdhanDownloadException>().having(
              (e) => e.failure,
              'failure',
              AdhanDownloadFailure.notAudio,
            ),
          ),
        );
        expect(leftovers(), isEmpty);
      }
    },
  );

  test(
    'an MP3 that starts with a frame header instead of a tag is accepted',
    () async {
      final lib = library(
        _Server((_) async => _audio(_mp3Bytes(null, const [0xFF, 0xFB, 0x90]))),
      );
      await lib.download(_sound);
      expect(await lib.downloaded(), {_sound.id});
    },
  );

  test(
    'a connection error is reported as a network failure with nothing left behind',
    () async {
      final lib = library(
        _Server(
          (options) async => throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        ),
      );
      await expectLater(
        lib.download(_sound),
        throwsA(
          isA<AdhanDownloadException>().having(
            (e) => e.failure,
            'failure',
            AdhanDownloadFailure.network,
          ),
        ),
      );
      expect(leftovers(), isEmpty);
    },
  );

  test('a phone that cannot use it asks for nothing', () async {
    bridge.supported = false;
    final server = _Server((_) async => _audio(_mp3Bytes()));
    await expectLater(
      library(server).download(_sound),
      throwsA(
        isA<AdhanDownloadException>().having(
          (e) => e.failure,
          'failure',
          AdhanDownloadFailure.unsupported,
        ),
      ),
    );
    expect(server.requests, 0);
  });

  test('if the phone refuses to list the file, it is not kept', () async {
    bridge.refuse = true;
    final lib = library(_Server((_) async => _audio(_mp3Bytes())));
    await expectLater(
      lib.download(_sound),
      throwsA(isA<AdhanDownloadException>()),
    );
    expect(leftovers(), isEmpty);
  });

  test('deleting removes the file and its entry in the shared list', () async {
    final lib = library(_Server((_) async => _audio(_mp3Bytes())));
    await lib.download(_sound);
    await lib.delete(_sound.id);
    expect(await lib.downloaded(), isEmpty);
    expect(leftovers(), isEmpty);
    expect(bridge.removed, [_sound.id]);
    expect(await lib.uriFor(_sound.id), isNull);
  });

  test('files that are not in the catalogue are ignored', () async {
    Directory('${dir.path}/adhan').createSync(recursive: true);
    File('${dir.path}/adhan/other.mp3').writeAsBytesSync([1, 2, 3]);
    final lib = library(_Server((_) async => _audio(_mp3Bytes())));
    expect(await lib.downloaded(), isEmpty);
  });

  test(
    'the catalogue has five recordings with unique ids and https addresses',
    () {
      expect(adhanCatalogue, hasLength(5));
      expect({for (final s in adhanCatalogue) s.id}, hasLength(5));
      expect(adhanCatalogue.every((s) => s.url.startsWith('https://')), isTrue);
      expect(adhanById('rifaat')?.nameEn, 'Muhammad Rifaat');
      expect(adhanById('missing'), isNull);
      expect(adhanById(null), isNull);
    },
  );
}
