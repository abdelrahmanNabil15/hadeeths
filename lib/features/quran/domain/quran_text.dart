import 'package:equatable/equatable.dart';

/// One verse, with its text exactly as in the source file. Nothing in the app may change [text]:
/// not digits, not spacing, not marks. Display code only lays it out.
class Verse extends Equatable {
  const Verse({required this.sura, required this.number, required this.text});

  final int sura;
  final int number;
  final String text;

  @override
  List<Object?> get props => [sura, number, text];
}

/// The whole text, verse by verse, in order.
class QuranText {
  QuranText._(this._suras);

  /// The number of suras and verses in the Hafs reading, which every source file must match.
  static const suraCount = 114;
  static const verseCount = 6236;

  final List<List<Verse>> _suras;

  /// Verses of sura [sura] (1 to 114).
  List<Verse> sura(int sura) {
    RangeError.checkValueInInterval(sura, 1, _suras.length, 'sura');
    return _suras[sura - 1];
  }

  int versesIn(int sura) => this.sura(sura).length;

  Verse verse(int sura, int number) {
    final verses = this.sura(sura);
    RangeError.checkValueInInterval(number, 1, verses.length, 'number');
    return verses[number - 1];
  }

  int get totalVerses => _suras.fold(0, (sum, s) => sum + s.length);

  /// How many suras this text has (114 for the real file; fewer only in tests).
  int get suraTotal => _suras.length;

  /// Reads a Tanzil "text with aya numbers" file: one `sura|verse|text` line per verse, with the
  /// licence notice in lines starting with `#`. The text after the second `|` is kept byte for
  /// byte. Anything unexpected (a missing or repeated verse, a sura out of order, a wrong total)
  /// is refused with a [FormatException], so a damaged file is never shown.
  ///
  /// [expectedVerses] and [expectedSuras] are only for tests with a small sample.
  factory QuranText.parseTanzil(
    String source, {
    int expectedSuras = suraCount,
    int expectedVerses = verseCount,
  }) {
    final suras = <List<Verse>>[];
    var lineNumber = 0;
    for (final rawLine in source.split('\n')) {
      lineNumber++;
      final line = rawLine.endsWith('\r')
          ? rawLine.substring(0, rawLine.length - 1)
          : rawLine;
      if (line.isEmpty || line.startsWith('#')) continue;
      final first = line.indexOf('|');
      final second = first < 0 ? -1 : line.indexOf('|', first + 1);
      if (first < 0 || second < 0) {
        throw FormatException('line $lineNumber is not sura|verse|text', line);
      }
      final sura = int.tryParse(line.substring(0, first));
      final number = int.tryParse(line.substring(first + 1, second));
      final text = line.substring(second + 1);
      if (sura == null || number == null || text.isEmpty) {
        throw FormatException('line $lineNumber is not sura|verse|text', line);
      }
      if (sura == suras.length + 1 && number == 1) {
        suras.add([]);
      }
      if (sura != suras.length || number != suras.last.length + 1) {
        throw FormatException(
          'line $lineNumber: expected ${_next(suras)}, found $sura:$number',
        );
      }
      suras.last.add(Verse(sura: sura, number: number, text: text));
    }
    final total = suras.fold(0, (sum, s) => sum + s.length);
    if (suras.length != expectedSuras || total != expectedVerses) {
      throw FormatException(
        'expected $expectedSuras suras and $expectedVerses verses, '
        'found ${suras.length} and $total',
      );
    }
    return QuranText._(
      List.unmodifiable([for (final s in suras) List<Verse>.unmodifiable(s)]),
    );
  }

  static String _next(List<List<Verse>> suras) => suras.isEmpty
      ? '1:1'
      : '${suras.length}:${suras.last.length + 1} or ${suras.length + 1}:1';
}
