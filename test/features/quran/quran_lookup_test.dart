import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/quran_wiring.dart';
import 'package:mynewapp/core/text/arabic_search.dart';
import 'package:mynewapp/features/quran/data/bundled_quran_source.dart';
import 'package:mynewapp/features/quran/domain/quran_search.dart';
import 'package:mynewapp/features/quran/domain/quran_text.dart';
import 'package:mynewapp/features/quran/domain/sura_lookup.dart';
import 'package:mynewapp/features/quran/domain/sura_names.dart';

/// Nothing here types Quran text: verses are taken from the bundled file and compared with
/// themselves or with their own normalised form.
void main() {
  late QuranText quran;

  setUpAll(() async {
    quran = await BundledQuranSource(
      file: bundledQuranFile,
      loadAsset: (path) async => ByteData.sublistView(
        Uint8List.fromList(File(path).readAsBytesSync()),
      ),
    ).load();
  });

  group('normalisation for matching (one rule each)', () {
    test('harakat and other marks are dropped', () {
      expect(normalizeForSearch('بَِّ'), 'ب');
    });
    test('the dagger alef is dropped', () {
      expect(normalizeForSearch('هٰذ'), 'هذ');
    });
    test('Quranic annotation marks are dropped', () {
      expect(normalizeForSearch('بۭۖۡ'), 'ب');
    });
    test('tatweel is dropped', () {
      expect(normalizeForSearch('بـب'), 'بب');
    });
    test('alef with hamza or madda, and alef wasla, count as alef', () {
      for (final alef in ['آ', 'أ', 'إ', 'ٱ']) {
        expect(normalizeForSearch(alef), 'ا');
      }
    });
    test('alef maqsura counts as ya, ta marbuta as ha', () {
      expect(normalizeForSearch('ى'), 'ي');
      expect(normalizeForSearch('ة'), 'ه');
    });
    test('hamza on waw or ya and the lone hamza are kept', () {
      expect(normalizeForSearch('ؤئء'), 'ؤئء');
    });
    test('Latin is lower-cased; spaces collapse and are trimmed', () {
      expect(normalizeForSearch('  Al   Fatiha '), 'al fatiha');
    });
    test('a query of marks only becomes empty', () {
      expect(normalizeForSearch('َِٰ'), '');
    });
  });

  group('search over the real text', () {
    test('a phrase from the first and from the last verse finds them', () {
      final search = QuranSearch(quran);
      final first = quran.verse(1, 1);
      final last = quran.verse(114, 6);
      expect(search.search(first.text), contains(first));
      expect(search.search(last.text), contains(last));
    });

    test(
      'the plain form of a verse finds the same verses as the verse itself',
      () {
        final search = QuranSearch(quran);
        final verse = quran.verse(112, 1);
        expect(
          search.search(normalizeForSearch(verse.text)),
          search.search(verse.text),
        );
      },
    );

    test('results come back unchanged, in Mushaf order, up to the limit', () {
      final search = QuranSearch(quran);
      final word = normalizeForSearch(quran.verse(1, 2).text).split(' ').first;
      final found = search.search(word, limit: 5);
      expect(found.length, lessThanOrEqualTo(5));
      for (var i = 1; i < found.length; i++) {
        final a = found[i - 1];
        final b = found[i];
        expect(
          a.sura < b.sura || (a.sura == b.sura && a.number < b.number),
          isTrue,
        );
      }
      for (final v in found) {
        expect(v.text, quran.verse(v.sura, v.number).text);
      }
    });

    test('one-letter and mark-only queries return nothing', () {
      final search = QuranSearch(quran);
      expect(search.search('ب'), isEmpty);
      expect(search.search('ََ'), isEmpty);
      expect(search.search(''), isEmpty);
    });

    test('a search over all 6,236 verses stays quick', () {
      final search = QuranSearch(quran);
      final watch = Stopwatch()..start();
      search.search('الله');
      watch.stop();
      // A generous bound for slow CI machines; the point is to catch a large regression.
      expect(watch.elapsedMilliseconds, lessThan(2000));
    });
  });

  group('numbers as people type them', () {
    test('Western, Arabic-Indic and Persian digits', () {
      expect(parseTypedNumber('255'), 255);
      expect(parseTypedNumber('٢٥٥'), 255);
      expect(parseTypedNumber('۲۵۵'), 255);
      expect(parseTypedNumber(' 7 '), 7);
    });

    test('anything else is refused', () {
      for (final bad in ['', '  ', '-3', '+3', '2a', '1.5', '12345', '٢ ٣']) {
        expect(parseTypedNumber(bad), isNull, reason: '"$bad"');
      }
    });
  });

  group('go to a verse, checked against every sura', () {
    test('first and last verse open; zero and one past the last do not', () {
      for (var s = 1; s <= quran.suraTotal; s++) {
        final count = quran.versesIn(s);
        ({int? sura, int? verseCount, int verse, bool valid}) check(String v) =>
            checkGoTo(
              suraText: '$s',
              verseText: v,
              suraTotal: quran.suraTotal,
              versesIn: quran.versesIn,
            );
        expect(check('1').valid, isTrue, reason: '$s:1');
        expect(check('$count').valid, isTrue, reason: '$s:$count');
        expect(check('${count + 1}').valid, isFalse, reason: '$s:${count + 1}');
        expect(check('0').valid, isFalse, reason: '$s:0');
        expect(check('').verse, 1, reason: 'empty verse means the first');
        expect(check('').verseCount, count);
      }
    });

    test('suras outside 1 to 114 are refused', () {
      for (final s in ['0', '115', '999', 'x', '']) {
        final r = checkGoTo(
          suraText: s,
          verseText: '1',
          suraTotal: quran.suraTotal,
          versesIn: quran.versesIn,
        );
        expect(r.valid, isFalse, reason: s);
        expect(r.sura, isNull);
      }
    });

    test('Arabic-Indic digits work for both fields', () {
      final r = checkGoTo(
        suraText: '٢',
        verseText: '٢٥٥',
        suraTotal: quran.suraTotal,
        versesIn: quran.versesIn,
      );
      expect(r.valid, isTrue);
      expect((r.sura, r.verse), (2, 255));
    });
  });

  group('finding a sura', () {
    test('an empty query lists all 114', () {
      expect(filterSuras(''), hasLength(114));
      expect(filterSuras('   '), hasLength(114));
    });

    test('by number in either digit style', () {
      expect(filterSuras('2'), [2]);
      expect(filterSuras('٢'), [2]);
      expect(filterSuras('114'), [114]);
    });

    test(
      'by Arabic name, with or without the article, marks or ta marbuta',
      () {
        final name = SuraNames.arabic(2);
        expect(filterSuras(name), contains(2));
        expect(
          filterSuras(name.substring(2)),
          contains(2),
          reason: 'without ال',
        );
        expect(
          filterSuras(normalizeForSearch(name)),
          contains(2),
          reason: 'plain spelling',
        );
      },
    );

    test(
      'by English name, ignoring case, article, apostrophes and hyphens',
      () {
        expect(filterSuras('Al-Baqarah'), contains(2));
        expect(filterSuras('baqara'), contains(2));
        expect(filterSuras('BAQARAH'), contains(2));
        expect(filterSuras('imran'), contains(3));
        expect(filterSuras("nisa'"), contains(4));
      },
    );

    test('every sura is found by its own names', () {
      for (var s = 1; s <= 114; s++) {
        expect(filterSuras(SuraNames.arabic(s)), contains(s), reason: 'ar $s');
        expect(filterSuras(SuraNames.latin(s)), contains(s), reason: 'en $s');
      }
    });

    test('nothing matches nonsense', () {
      expect(filterSuras('zzzz'), isEmpty);
      expect(filterSuras('ظظظظ'), isEmpty);
    });
  });
}
