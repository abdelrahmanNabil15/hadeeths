import 'package:mynewapp/features/quran/domain/quran_structure_data.dart';
import 'package:mynewapp/features/quran/domain/quran_text.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';

/// Where each verse sits in the Madinah mushaf: its page (1 to 604), juz (1 to 30) and hizb
/// quarter (1 to 240), and which verses carry a prostration. Only numbers; no Quran text.
class QuranStructure {
  const QuranStructure._(
    this._pageStarts,
    this._juzStarts,
    this._hizbQuarterStarts,
    this._sajdahVerses,
  );

  /// The mushaf layout shipped with the app (see `tool/export_quran_structure.dart`).
  static final madinah = QuranStructure._(
    pageStarts,
    juzStarts,
    hizbQuarterStarts,
    sajdahVerses.toSet(),
  );

  static const pageCount = 604;
  static const juzCount = 30;
  static const hizbQuarterCount = 240;

  final List<int> _pageStarts;
  final List<int> _juzStarts;
  final List<int> _hizbQuarterStarts;
  final Set<int> _sajdahVerses;

  static int _key(VerseRef place) => place.sura * 1000 + place.verse;

  static VerseRef _ref(int key) => VerseRef(key ~/ 1000, key % 1000);

  /// The 1-based position of [key] among [starts]: how many starts are at or before it.
  static int _index(List<int> starts, int key) {
    var low = 0, high = starts.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (starts[mid] <= key) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  /// The page the verse begins on.
  int pageOf(VerseRef place) => _index(_pageStarts, _key(place));

  int juzOf(VerseRef place) => _index(_juzStarts, _key(place));

  int hizbQuarterOf(VerseRef place) => _index(_hizbQuarterStarts, _key(place));

  bool hasSajdah(VerseRef place) => _sajdahVerses.contains(_key(place));

  /// The first verse on [page] (1 to 604).
  VerseRef pageStart(int page) {
    RangeError.checkValueInInterval(page, 1, pageCount, 'page');
    return _ref(_pageStarts[page - 1]);
  }

  /// The first verse of [juz] (1 to 30).
  VerseRef juzStart(int juz) {
    RangeError.checkValueInInterval(juz, 1, juzCount, 'juz');
    return _ref(_juzStarts[juz - 1]);
  }

  /// Whether [place] is the first verse of its page.
  bool startsPage(VerseRef place) =>
      _pageStarts[pageOf(place) - 1] == _key(place);

  /// The verses that begin on [page], in order, taken from [text]. A shorter text (in tests) simply
  /// has fewer; a page none of whose verses exist in it is empty.
  List<Verse> versesOnPage(QuranText text, int page) {
    final first = pageStart(page);
    final end = page == pageCount ? 115001 : _pageStarts[page];
    final verses = <Verse>[];
    var sura = first.sura, number = first.verse;
    while (sura <= text.suraTotal && sura * 1000 + number < end) {
      if (number > text.versesIn(sura)) {
        sura++;
        number = 1;
      } else {
        verses.add(text.verse(sura, number++));
      }
    }
    return verses;
  }
}
