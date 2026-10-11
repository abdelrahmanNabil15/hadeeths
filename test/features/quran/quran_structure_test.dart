import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/quran/domain/quran_structure.dart';
import 'package:mynewapp/features/quran/domain/quran_structure_data.dart';
import 'package:mynewapp/features/quran/domain/quran_text.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';

void main() {
  final structure = QuranStructure.madinah;
  // The bundled file itself, read from disk: the table must only name verses that exist in it.
  final text = QuranText.parseTanzil(
    File('assets/quran/quran-uthmani.txt').readAsStringSync(),
  );

  bool exists(int key) {
    final sura = key ~/ 1000, verse = key % 1000;
    return sura >= 1 &&
        sura <= 114 &&
        verse >= 1 &&
        verse <= text.sura(sura).length;
  }

  group('the data table', () {
    test('has 604 pages, 30 juz, 240 hizb quarters and 15 sajdah verses', () {
      expect(pageStarts, hasLength(QuranStructure.pageCount));
      expect(juzStarts, hasLength(QuranStructure.juzCount));
      expect(hizbQuarterStarts, hasLength(QuranStructure.hizbQuarterCount));
      expect(sajdahVerses, hasLength(15));
    });

    test('starts at the first verse and only moves forward', () {
      for (final starts in [pageStarts, juzStarts, hizbQuarterStarts]) {
        expect(starts.first, 1001);
        for (var i = 1; i < starts.length; i++) {
          expect(starts[i], greaterThan(starts[i - 1]), reason: 'entry $i');
        }
      }
    });

    test('names only verses that exist in the bundled text', () {
      for (final key in [
        ...pageStarts,
        ...juzStarts,
        ...hizbQuarterStarts,
        ...sajdahVerses,
      ]) {
        expect(exists(key), isTrue, reason: '${key ~/ 1000}:${key % 1000}');
      }
    });
  });

  group('lookups', () {
    test(
      'page 1 is al-Fatihah and the last page begins at an-Nas-adjacent suras',
      () {
        expect(structure.pageOf(const VerseRef(1, 1)), 1);
        expect(structure.pageOf(const VerseRef(1, 7)), 1);
        expect(structure.pageOf(const VerseRef(2, 1)), 2);
        expect(structure.pageStart(604), const VerseRef(112, 1));
        expect(structure.pageOf(const VerseRef(114, 6)), 604);
        expect(structure.juzOf(const VerseRef(114, 6)), 30);
        expect(structure.hizbQuarterOf(const VerseRef(114, 6)), 240);
      },
    );

    // Compared with quran.com's page and juz data on 2026-10-10: page 50 holds 3:1-9, page 187
    // holds 9:1-6, page 511 holds 48:1-9, and juz 26 begins at 46:1 (page 502).
    test('agree with quran.com on fixed points', () {
      expect(structure.pageStart(50), const VerseRef(3, 1));
      expect(structure.pageStart(187), const VerseRef(9, 1));
      expect(structure.pageStart(511), const VerseRef(48, 1));
      expect(structure.pageOf(const VerseRef(48, 9)), 511);
      expect(structure.pageOf(const VerseRef(48, 10)), 512);
      expect(structure.juzStart(26), const VerseRef(46, 1));
      expect(structure.pageOf(const VerseRef(46, 1)), 502);
      expect(structure.juzOf(const VerseRef(48, 1)), 26);
    });

    // Ayat al-Kursi: page 42, juz 3, hizb quarter 17 (quran.com).
    test('a verse in the middle of a page belongs to the page it began on', () {
      const place = VerseRef(2, 255);
      expect(structure.pageOf(place), 42);
      expect(structure.juzOf(place), 3);
      expect(structure.hizbQuarterOf(place), 17);
      expect(structure.startsPage(place), isFalse);
      expect(structure.startsPage(const VerseRef(48, 1)), isTrue);
    });

    test(
      'the sajdah verses include as-Sajdah at 32:15 and al-Araf at 7:206',
      () {
        expect(structure.hasSajdah(const VerseRef(7, 206)), isTrue);
        expect(structure.hasSajdah(const VerseRef(32, 15)), isTrue);
        expect(structure.hasSajdah(const VerseRef(2, 255)), isFalse);
      },
    );

    test('pages and juz outside the range are refused', () {
      expect(() => structure.pageStart(0), throwsRangeError);
      expect(() => structure.pageStart(605), throwsRangeError);
      expect(() => structure.juzStart(31), throwsRangeError);
    });
  });
}
