import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:mynewapp/core/integrity/fingerprint.dart';
import 'package:mynewapp/features/quran/domain/quran_source.dart';
import 'package:mynewapp/features/quran/domain/quran_text.dart';

/// The exact file the app expects: its asset path, its size and its fingerprint. Recorded when
/// the file is added from its source, unchanged; any other file is refused.
class QuranFile {
  const QuranFile({
    required this.assetPath,
    required this.byteLength,
    required this.fingerprint,
  });

  final String assetPath;
  final int byteLength;
  final String fingerprint;
}

/// Reads the bundled Tanzil file, checks that it is exactly the expected one, and parses it on a
/// background isolate (it is about 6,000 lines). The result is kept for the life of the app.
class BundledQuranSource implements QuranSource {
  BundledQuranSource({required this.file, required this.loadAsset});

  /// Null until a verified file has been added to the app: the section then reports that the
  /// text is not available rather than showing anything else.
  final QuranFile? file;

  /// Reads an asset's bytes (the app passes the asset bundle; tests pass a map).
  final Future<ByteData> Function(String path) loadAsset;

  Future<QuranText>? _loaded;

  @override
  Future<QuranText> load() => _loaded ??= _load().catchError((Object e) {
    _loaded = null; // a later attempt may succeed (for example after an update)
    throw e;
  });

  Future<QuranText> _load() async {
    final expected = file;
    if (expected == null) {
      throw const QuranUnavailable('no verified Quran file in this build');
    }
    final ByteData data;
    try {
      data = await loadAsset(expected.assetPath);
    } on Object {
      throw QuranUnavailable('missing file ${expected.assetPath}');
    }
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    if (bytes.length != expected.byteLength ||
        fingerprint(bytes) != expected.fingerprint) {
      throw const QuranUnavailable('the bundled file is not the verified one');
    }
    try {
      return await Isolate.run(() => _parse(Uint8List.fromList(bytes)));
    } on FormatException catch (e) {
      throw QuranUnavailable('the bundled file does not read: ${e.message}');
    }
  }

  static QuranText _parse(Uint8List bytes) =>
      QuranText.parseTanzil(utf8.decode(bytes));
}
