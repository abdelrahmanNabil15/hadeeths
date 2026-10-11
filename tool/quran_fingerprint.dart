import 'dart:io';

import 'package:mynewapp/core/integrity/fingerprint.dart';

/// Prints the size and fingerprint of a Quran file, to record in `lib/app/quran_wiring.dart`.
/// Usage: dart run tool/quran_fingerprint.dart assets/quran/quran-uthmani.txt
void main(List<String> args) {
  final bytes = File(args.single).readAsBytesSync();
  stdout.writeln('byteLength: ${bytes.length}');
  stdout.writeln('fingerprint: ${fingerprint(bytes)}');
}
