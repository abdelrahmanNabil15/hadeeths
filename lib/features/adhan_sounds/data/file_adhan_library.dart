import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mynewapp/core/platform/adhan_sound_bridge.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_library.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_sound.dart';

/// Keeps downloaded recordings as files in the app's own folder, and lists each one in the phone's
/// shared notification sounds (through [AdhanSoundBridge]) so that a notification channel can play
/// it.
///
/// Nothing is requested until [download] is called, and nothing about the user is sent: the request
/// is a plain `GET` of the recording's address.
class FileAdhanLibrary implements AdhanLibrary {
  FileAdhanLibrary({
    required this.directory,
    required this.dio,
    required this.bridge,
  });

  final Future<Directory> Function() directory;
  final Dio dio;
  final AdhanSoundBridge bridge;

  /// A real adhan is tens of seconds to a few minutes of audio. Anything much smaller is an error
  /// page; anything much larger is not what was listed.
  static const _smallest = 20 * 1024;
  static const _largest = 12 * 1024 * 1024;

  /// How far a download may differ from the listed size before it is refused.
  static const _sizeSlack = 0.25;

  Future<File> _file(String id) async {
    final dir = await directory();
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}$id.mp3');
  }

  @override
  Future<bool> isSupported() => bridge.isSupported();

  @override
  Future<Set<String>> downloaded() async {
    final dir = await directory();
    if (!dir.existsSync()) return const {};
    final known = {for (final s in adhanCatalogue) s.id};
    return {
      for (final entity in dir.listSync())
        if (entity is File && entity.path.endsWith('.mp3'))
          ?_idOf(entity.path, known),
    };
  }

  static String? _idOf(String path, Set<String> known) {
    final name = path.split(RegExp(r'[\\/]')).last;
    final id = name.substring(0, name.length - '.mp3'.length);
    return known.contains(id) ? id : null;
  }

  @override
  Future<void> download(
    AdhanSound sound, {
    void Function(double fraction)? onProgress,
  }) async {
    if (!await bridge.isSupported()) {
      throw const AdhanDownloadException(AdhanDownloadFailure.unsupported);
    }
    final target = await _file(sound.id);
    final part = File('${target.path}.part');
    try {
      final response = await dio.download(
        sound.url,
        part.path,
        onReceiveProgress: (received, total) {
          final size = total > 0 ? total : sound.bytes;
          onProgress?.call((received / size).clamp(0.0, 1.0));
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 20),
        ),
      );
      final type = response.headers.value(Headers.contentTypeHeader) ?? '';
      if ((response.statusCode ?? 0) != 200 ||
          !type.toLowerCase().startsWith('audio/')) {
        throw const AdhanDownloadException(AdhanDownloadFailure.notAudio);
      }
      await _check(part, sound);
      if (target.existsSync()) target.deleteSync();
      part.renameSync(target.path);
      final uri = await bridge.register(target.path, sound.id);
      if (uri == null) {
        target.deleteSync();
        throw const AdhanDownloadException(AdhanDownloadFailure.unsupported);
      }
      onProgress?.call(1);
    } on DioException {
      throw const AdhanDownloadException(AdhanDownloadFailure.network);
    } on FileSystemException {
      throw const AdhanDownloadException(AdhanDownloadFailure.network);
    } finally {
      if (part.existsSync()) part.deleteSync();
    }
  }

  /// The file is an MP3 of about the size that was listed.
  Future<void> _check(File file, AdhanSound sound) async {
    final length = file.lengthSync();
    final lowest = (sound.bytes * (1 - _sizeSlack)).round();
    final highest = (sound.bytes * (1 + _sizeSlack)).round();
    if (length < _smallest ||
        length > _largest ||
        length < lowest ||
        length > highest) {
      throw const AdhanDownloadException(AdhanDownloadFailure.notAudio);
    }
    final head = await file.openRead(0, 3).expand((b) => b).toList();
    final id3 =
        head.length == 3 &&
        head[0] == 0x49 &&
        head[1] == 0x44 &&
        head[2] == 0x33;
    final frame =
        head.length >= 2 && head[0] == 0xFF && (head[1] & 0xE0) == 0xE0;
    if (!id3 && !frame) {
      throw const AdhanDownloadException(AdhanDownloadFailure.notAudio);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await bridge.unregister(id);
    } on Object {
      // The shared list is cleaned best-effort; the file is removed regardless.
    }
    final file = await _file(id);
    if (file.existsSync()) file.deleteSync();
  }

  @override
  Future<String?> uriFor(String id) async {
    final file = await _file(id);
    if (!file.existsSync()) return null;
    try {
      return await bridge.register(file.path, id);
    } on Object {
      return null;
    }
  }
}
