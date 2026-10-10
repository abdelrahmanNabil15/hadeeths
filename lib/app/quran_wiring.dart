import 'package:flutter/services.dart';
import 'package:mynewapp/features/quran/data/bundled_quran_source.dart';
import 'package:mynewapp/features/quran/domain/quran_source.dart';

/// The verified Quran file shipped with the app. The app reads only this exact file.
///
/// To replace it (for a Tanzil update): download the Tanzil text exactly as described in `docs/QURAN_SOURCE_OPTIONS.md`,
/// save it unchanged as `assets/quran/quran-uthmani.txt`, list it under `assets` in
/// `pubspec.yaml`, then record its size and fingerprint here (`dart run tool/quran_fingerprint.dart
/// assets/quran/quran-uthmani.txt`; a test reads the file and fails if they do not match).
///
/// Recorded 2026-10-09 from the owner's download: Tanzil Quran Text (Uthmani, Version 1.1),
/// with pause marks, sajdah and rub-el-hizb signs, text with aya numbers; 114 suras, 6236 verses.
const bundledQuranFile = QuranFile(
  assetPath: 'assets/quran/quran-uthmani.txt',
  byteLength: 1396684,
  fingerprint: '4530c298616797b3',
);

QuranSource buildQuranSource() =>
    BundledQuranSource(file: bundledQuranFile, loadAsset: rootBundle.load);
