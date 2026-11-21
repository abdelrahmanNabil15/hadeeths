import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:mynewapp/core/integrity/fingerprint.dart';
import 'package:mynewapp/features/quran/data/bundled_quran_source.dart';
import 'package:mynewapp/features/quran/domain/mushaf_lines.dart';
import 'package:mynewapp/features/quran/domain/quran_source.dart';

/// Reads the bundled mushaf lines file, checks that it is exactly the expected one (the same way
/// as the Quran text), and parses it on a background isolate. The result is kept for the life of
/// the app.
class BundledMushafLinesSource implements MushafLinesSource {
  BundledMushafLinesSource({required this.file, required this.loadAsset});

  final QuranFile file;

  /// Reads an asset's bytes (the app passes the asset bundle; tests pass a map).
  final Future<ByteData> Function(String path) loadAsset;

  Future<MushafLines>? _loaded;

  @override
  Future<MushafLines> load() => _loaded ??= _load().catchError((Object e) {
    _loaded = null;
    throw e;
  });

  Future<MushafLines> _load() async {
    final ByteData data;
    try {
      data = await loadAsset(file.assetPath);
    } on Object {
      throw QuranUnavailable('missing file ${file.assetPath}');
    }
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    if (bytes.length != file.byteLength ||
        fingerprint(bytes) != file.fingerprint) {
      throw const QuranUnavailable('the bundled lines file is not the verified one');
    }
    try {
      return await Isolate.run(
        () => MushafLines.parse(utf8.decode(Uint8List.fromList(bytes))),
      );
    } on FormatException catch (e) {
      throw QuranUnavailable('the bundled lines file does not read: ${e.message}');
    }
  }
}
