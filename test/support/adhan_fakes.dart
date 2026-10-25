import 'dart:async';

import 'package:mynewapp/features/adhan_sounds/domain/adhan_library.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_player.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_sound.dart';

/// A phone's adhan recordings in memory. [hold] pauses downloads until it is completed.
class FakeAdhanLibrary implements AdhanLibrary {
  bool supported = true;
  final have = <String>{};

  /// Ids with a short iOS notification-sound clip "prepared" (see [iosSoundFileFor]). A test adds
  /// to this to simulate a successful conversion; left empty, the fallback-to-system-sound path
  /// is exercised instead.
  final haveIosSound = <String>{};
  AdhanDownloadFailure? fail;
  Completer<void>? hold;
  final deleted = <String>[];
  final downloads = <String>[];

  /// Set by a test to say a download is under way.
  @override
  bool downloading = false;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<Set<String>> downloaded() async => {...have};

  @override
  Future<void> download(
    AdhanSound sound, {
    void Function(double fraction)? onProgress,
  }) async {
    downloads.add(sound.id);
    onProgress?.call(0.5);
    await hold?.future;
    if (fail != null) throw AdhanDownloadException(fail!);
    have.add(sound.id);
    onProgress?.call(1);
  }

  @override
  Future<void> delete(String id) async {
    deleted.add(id);
    have.remove(id);
  }

  @override
  Future<String?> uriFor(String id) async =>
      have.contains(id) ? 'content://test/$id' : null;

  @override
  Future<String?> localPathFor(String id) async =>
      have.contains(id) ? '/fake/adhan/$id.mp3' : null;

  @override
  Future<String?> iosSoundFileFor(String id) async =>
      haveIosSound.contains(id) ? '$id.caf' : null;
}

/// An in-app player in memory: records what was played (and at what volume), and lets a test
/// signal completion.
class FakeAdhanPlayer implements AdhanPlayer {
  String? playing;
  final played = <String>[];
  final volumes = <double>[];
  final stopped = <void>[];
  bool disposed = false;
  final _completeController = StreamController<void>.broadcast();

  @override
  Future<void> play(String path, {double volume = 1}) async {
    playing = path;
    played.add(path);
    volumes.add(volume);
  }

  @override
  Future<void> stop() async {
    playing = null;
    stopped.add(null);
  }

  @override
  Stream<void> get onComplete => _completeController.stream;

  /// A test calls this to say the current recording finished playing on its own.
  void completeNow() {
    playing = null;
    _completeController.add(null);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _completeController.close();
  }
}
