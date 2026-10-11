import 'package:mynewapp/features/quran/domain/quran_source.dart';
import 'package:mynewapp/features/quran/domain/quran_text.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';

/// A small made-up text in the Tanzil layout: three "suras" of 7, 12 and 5 lines. These are
/// placeholder words, **not Quran text**; tests never contain typed-in verses.
const placeholderVerseCounts = [7, 12, 5];

String placeholderVerse(int sura, int verse) => switch ((sura, verse)) {
  (1, 1) => 'سطر الافتتاح التجريبي',
  (2, 3) => 'كَلِمَةٌ مُشَكَّلَةٌ لِلبَحْثِ',
  (3, 2) => 'كلمة مشكلة أخرى',
  _ => 'سطر تجريبي $sura $verse',
};

QuranText placeholderQuran() {
  final b = StringBuffer();
  for (var s = 1; s <= placeholderVerseCounts.length; s++) {
    for (var v = 1; v <= placeholderVerseCounts[s - 1]; v++) {
      b.writeln('$s|$v|${placeholderVerse(s, v)}');
    }
  }
  b.writeln('# placeholder notice');
  return QuranText.parseTanzil(
    b.toString(),
    expectedSuras: placeholderVerseCounts.length,
    expectedVerses: placeholderVerseCounts.fold(0, (a, b) => a + b),
  );
}

class FakeQuranSource implements QuranSource {
  FakeQuranSource({this.fail = false});

  final bool fail;
  int loads = 0;

  @override
  Future<QuranText> load() async {
    loads++;
    if (fail) throw const QuranUnavailable('test');
    return placeholderQuran();
  }
}

class InMemoryQuranUserData implements QuranUserData {
  VerseRef? last;
  final Set<VerseRef> marks = {};
  Object? failWrites;

  @override
  Future<VerseRef?> lastRead() async => last;

  @override
  Future<void> setLastRead(VerseRef place) async {
    if (failWrites != null) throw failWrites!;
    last = place;
  }

  @override
  Future<List<VerseRef>> bookmarks() async => marks.toList()..sort();

  @override
  Future<bool> isBookmarked(VerseRef place) async => marks.contains(place);

  @override
  Future<void> setBookmark(VerseRef place, {required bool on}) async {
    if (failWrites != null) throw failWrites!;
    on ? marks.add(place) : marks.remove(place);
  }
}
