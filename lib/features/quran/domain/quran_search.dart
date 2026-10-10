import 'package:mynewapp/core/text/arabic_search.dart';
import 'package:mynewapp/features/quran/domain/quran_text.dart';

/// Finds verses by words. Marks, tatweel and alef forms are ignored **for matching only**; results
/// are the verses themselves, unchanged. Uthmani spellings that differ from everyday spelling (for
/// example with a small alef in place of a written one) may need the Uthmani form to match.
class QuranSearch {
  QuranSearch(this.text)
    : _index = [
        for (var s = 1; s <= text.suraTotal; s++)
          for (final v in text.sura(s)) (v, normalizeForSearch(v.text)),
      ];

  final QuranText text;
  final List<(Verse, String)> _index;

  /// Shorter queries are not searched (they would match almost everything).
  static const minLength = 2;

  /// Verses containing every word of [query], in Mushaf order, at most [limit].
  List<Verse> search(String query, {int limit = 200}) {
    final words = normalizeForSearch(
      query,
    ).split(' ').where((w) => w.isNotEmpty).toList();
    if (words.join().length < minLength) return const [];
    final found = <Verse>[];
    for (final (verse, normalized) in _index) {
      if (words.every(normalized.contains)) {
        found.add(verse);
        if (found.length == limit) break;
      }
    }
    return found;
  }
}
