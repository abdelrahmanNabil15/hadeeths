import 'package:mynewapp/features/quran/domain/quran_user_data.dart';

/// One line of a page of the 15-line Madinah mushaf, exactly as it is set in the printed copy.
sealed class MushafLine {
  const MushafLine();
}

/// The line that carries a sura's name, above its first verse.
class SuraNameLine extends MushafLine {
  const SuraNameLine(this.sura);

  final int sura;
}

/// The basmala line that opens every sura but al-Fatihah (where it is the first verse) and
/// at-Tawbah (which has none).
class BasmalaLine extends MushafLine {
  const BasmalaLine(this.text);

  final String text;
}

/// A line of verse text: one or more pieces of consecutive verses, in reading order.
class VerseLine extends MushafLine {
  const VerseLine(this.pieces);

  final List<VersePiece> pieces;
}

/// The words of one verse that fall on one line. [endsHere] when the verse ends on this line, so
/// its number is drawn after [words]. [words] is empty when the print wraps only the number onto
/// this line.
class VersePiece {
  const VersePiece({
    required this.sura,
    required this.verse,
    required this.words,
    required this.endsHere,
  });

  final int sura;
  final int verse;
  final List<String> words;
  final bool endsHere;

  VerseRef get ref => VerseRef(sura, verse);
}

/// All 604 pages of the Madinah mushaf, line by line (15 lines a page; 8 on the first two pages,
/// which the print sets in a smaller block in the middle of the page).
class MushafLines {
  MushafLines._(this._pages, this._pageOfVerse);

  static const pageCount = 604;

  final List<List<MushafLine>> _pages;
  final Map<int, int> _pageOfVerse;

  /// The lines of [page] (1 to 604), top to bottom.
  List<MushafLine> page(int page) {
    RangeError.checkValueInInterval(page, 1, _pages.length, 'page');
    return _pages[page - 1];
  }

  int get pages => _pages.length;

  /// The page on which [place] begins. Null for a verse the file does not have.
  int? pageOf(VerseRef place) => _pageOfVerse[_key(place.sura, place.verse)];

  /// The first verse that begins on [page] (or continues onto it, for a page with no verse start).
  VerseRef firstVerseOn(int page) {
    for (final line in this.page(page)) {
      if (line is VerseLine) return line.pieces.first.ref;
    }
    throw StateError('page $page has no verse');
  }

  static int _key(int sura, int verse) => sura * 1000 + verse;

  /// Reads `assets/quran/mushaf-madinah-lines.txt` (see `tool/build_mushaf_lines.dart` for its
  /// format). Anything unexpected — a line out of order, a page with the wrong number of lines, a
  /// verse that never ends — is refused with a [FormatException], so a damaged file is never shown.
  ///
  /// [expectedPages] is only for tests with a small sample.
  factory MushafLines.parse(String source, {int expectedPages = pageCount}) {
    final pages = <List<MushafLine>>[];
    final pageOfVerse = <int, int>{};
    final ended = <int>{};
    var lineNumber = 0;
    for (final raw in source.split('\n')) {
      lineNumber++;
      final row = raw.endsWith('\r') ? raw.substring(0, raw.length - 1) : raw;
      if (row.isEmpty || row.startsWith('#')) continue;
      Never fail(String why) =>
          throw FormatException('line $lineNumber: $why', row);
      final parts = row.split('|');
      if (parts.length != 4) fail('expected 4 fields');
      final page = int.tryParse(parts[0]);
      final line = int.tryParse(parts[1]);
      if (page == null || line == null) fail('bad page or line number');
      if (line == 1) {
        if (page != pages.length + 1) fail('page $page out of order');
        pages.add([]);
      } else if (page != pages.length || line != pages.last.length + 1) {
        fail('line $page:$line out of order');
      }
      final payload = parts[3];
      switch (parts[2]) {
        case 's':
          final sura = int.tryParse(payload);
          if (sura == null || sura < 1 || sura > 114) fail('bad sura');
          pages.last.add(SuraNameLine(sura));
        case 'b':
          if (payload.isEmpty) fail('empty basmala');
          pages.last.add(BasmalaLine(payload));
        case 'a':
          final pieces = <VersePiece>[];
          for (final seg in payload.split(';')) {
            final fields = seg.split(':');
            if (fields.length != 4) fail('bad verse piece "$seg"');
            final sura = int.tryParse(fields[0]);
            final verse = int.tryParse(fields[1]);
            // No words: only the verse's number, wrapped onto this line by itself.
            final words = fields[3].isEmpty
                ? const <String>[]
                : fields[3].split(' ');
            if (sura == null ||
                verse == null ||
                (fields[2] != 'e' && fields[2] != '-') ||
                (words.isEmpty && fields[2] != 'e') ||
                words.any((w) => w.isEmpty)) {
              fail('bad verse piece "$seg"');
            }
            final key = _key(sura, verse);
            if (ended.contains(key)) fail('$sura:$verse continues after its end');
            pageOfVerse.putIfAbsent(key, () => page);
            if (fields[2] == 'e') ended.add(key);
            pieces.add(
              VersePiece(
                sura: sura,
                verse: verse,
                words: words,
                endsHere: fields[2] == 'e',
              ),
            );
          }
          pages.last.add(VerseLine(pieces));
        default:
          fail('unknown line kind "${parts[2]}"');
      }
    }
    if (pages.length != expectedPages) {
      throw FormatException('${pages.length} pages, expected $expectedPages');
    }
    for (var i = 0; i < pages.length; i++) {
      final expected = i < 2 ? 8 : 15;
      if (expectedPages == pageCount && pages[i].length != expected) {
        throw FormatException('page ${i + 1} has ${pages[i].length} lines');
      }
    }
    if (pageOfVerse.keys.toSet().difference(ended).isNotEmpty) {
      throw const FormatException('a verse never ends');
    }
    return MushafLines._(pages, pageOfVerse);
  }
}

/// Where the mushaf's lines come from. The app ships one verified file and checks it before use.
abstract interface class MushafLinesSource {
  /// The lines, read and checked once. Throws when the bundled file is missing, damaged or not
  /// the expected one; the reader then sets each page as one running paragraph instead.
  Future<MushafLines> load();
}
