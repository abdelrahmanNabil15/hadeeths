import 'package:flutter/services.dart';
import 'package:mynewapp/features/quran/data/bundled_quran_source.dart';
import 'package:mynewapp/features/quran/domain/quran_source.dart';

/// The verified Quran file shipped with the app, or null while none has been added.
///
/// To add it: download the Tanzil text exactly as described in `docs/QURAN_SOURCE_OPTIONS.md`,
/// save it unchanged as `assets/quran/quran-uthmani.txt`, list it under `assets` in
/// `pubspec.yaml`, then record its size and `fingerprint()` here (a test reads the file and
/// fails if these do not match).
const QuranFile? bundledQuranFile = null;

QuranSource buildQuranSource() =>
    BundledQuranSource(file: bundledQuranFile, loadAsset: rootBundle.load);
