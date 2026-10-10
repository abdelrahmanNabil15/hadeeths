import 'package:mynewapp/core/text/arabic_search.dart';
import 'package:mynewapp/features/quran/domain/sura_names.dart';

/// A whole number as a person types it: Western (0-9), Arabic-Indic (٠-٩) or Persian (۰-۹) digits,
/// with spaces around it ignored. Null for anything else, or for more than four digits.
int? parseTypedNumber(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty || trimmed.length > 4) return null;
  var value = 0;
  for (final rune in trimmed.runes) {
    final digit = _digitValue(rune);
    if (digit == null) return null;
    value = value * 10 + digit;
  }
  return value;
}

int? _digitValue(int rune) {
  if (rune >= 0x30 && rune <= 0x39) return rune - 0x30;
  if (rune >= 0x0660 && rune <= 0x0669) return rune - 0x0660;
  if (rune >= 0x06F0 && rune <= 0x06F9) return rune - 0x06F0;
  return null;
}

/// What the "go to a verse" fields say: the sura when it is a real sura number, the number of
/// verses it has, the verse (1 when left empty), and whether the request can be opened.
({int? sura, int? verseCount, int verse, bool valid}) checkGoTo({
  required String suraText,
  required String verseText,
  required int suraTotal,
  required int Function(int sura) versesIn,
}) {
  final sura = parseTypedNumber(suraText);
  final validSura = sura != null && sura >= 1 && sura <= suraTotal;
  final count = validSura ? versesIn(sura) : null;
  final emptyVerse = verseText.trim().isEmpty;
  final verse = emptyVerse ? 1 : parseTypedNumber(verseText);
  final validVerse =
      verse != null && count != null && verse >= 1 && verse <= count;
  return (
    sura: validSura ? sura : null,
    verseCount: count,
    verse: verse ?? 1,
    valid: validSura && validVerse,
  );
}

/// The suras matching [query], in order:
/// - a number (in any of the digit styles above) matches that sura;
/// - Arabic text matches a name ignoring marks, alef forms and the article ال;
/// - Latin text matches a transliteration ignoring case, apostrophes, hyphens, spaces and the article
///   (Al-, An-, Ash- ...).
///
/// An empty query matches them all. [suraTotal] is the number of suras in the loaded text (114).
List<int> filterSuras(String query, {int suraTotal = 114}) {
  final all = [for (var s = 1; s <= suraTotal; s++) s];
  if (query.trim().isEmpty) return all;
  final number = parseTypedNumber(query);
  final arabic = _arabicKey(query);
  final latin = _latinKey(query);
  return [
    for (final s in all)
      if (s == number ||
          (arabic.isNotEmpty &&
              _arabicKey(SuraNames.arabic(s)).contains(arabic)) ||
          (latin.isNotEmpty && _latinKey(SuraNames.latin(s)).contains(latin)))
        s,
  ];
}

String _arabicKey(String text) {
  final words = normalizeForSearch(text)
      .split(' ')
      .map((w) => w.startsWith('ال') && w.length > 2 ? w.substring(2) : w);
  return words.join().replaceAll(RegExp(r'[^ء-ي]'), '');
}

String _latinKey(String text) => text
    .toLowerCase()
    .trim()
    .replaceFirst(RegExp(r'^a[a-z]{1,2}[- ]'), '')
    .replaceAll(RegExp('[^a-z]'), '');
