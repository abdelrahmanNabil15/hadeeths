import 'package:mynewapp/features/quran/domain/quran_text.dart';

/// Where the Quran text comes from. The app ships one verbatim file and checks it before use.
abstract interface class QuranSource {
  /// The text, read and checked once. Throws [QuranUnavailable] when the bundled file is missing,
  /// damaged or not the expected one; the Quran section then says so instead of showing anything.
  Future<QuranText> load();
}

class QuranUnavailable implements Exception {
  const QuranUnavailable(this.reason);

  final String reason;

  @override
  String toString() => 'QuranUnavailable: $reason';
}
