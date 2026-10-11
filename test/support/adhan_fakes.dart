import 'dart:async';

import 'package:mynewapp/features/adhan_sounds/domain/adhan_library.dart';
import 'package:mynewapp/features/adhan_sounds/domain/adhan_sound.dart';

/// A phone's adhan recordings in memory. [hold] pauses downloads until it is completed.
class FakeAdhanLibrary implements AdhanLibrary {
  bool supported = true;
  final have = <String>{};
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
}
