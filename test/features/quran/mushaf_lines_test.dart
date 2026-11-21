import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/quran_wiring.dart';
import 'package:mynewapp/core/integrity/fingerprint.dart';
import 'package:mynewapp/features/quran/data/bundled_mushaf_lines_source.dart';
import 'package:mynewapp/features/quran/data/bundled_quran_source.dart';
import 'package:mynewapp/features/quran/domain/mushaf_lines.dart';
import 'package:mynewapp/features/quran/domain/quran_source.dart';
import 'package:mynewapp/features/quran/domain/quran_structure.dart';
import 'package:mynewapp/features/quran/domain/quran_text.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';

void main() {
  const file = bundledMushafLinesFile;
  final bytes = File(file.assetPath).readAsBytesSync();
  final lines = MushafLines.parse(utf8.decode(bytes));
  final tanzil = QuranText.parseTanzil(
    File('assets/quran/quran-uthmani.txt').readAsStringSync(),
  );

  test('the bundled lines file is exactly the one recorded', () {
    expect(bytes.length, file.byteLength);
    expect(fingerprint(bytes), file.fingerprint);
  });

  test('604 pages: 8 lines on the first two, 15 on every other', () {
    expect(lines.pages, 604);
    expect(lines.page(1), hasLength(8));
    expect(lines.page(2), hasLength(8));
    for (var page = 3; page <= 604; page++) {
      expect(lines.page(page), hasLength(15), reason: 'page $page');
    }
  });

  test('every sura has its name line, and a basmala but for 1 and 9', () {
    final names = <int>[];
    var basmalas = 0;
    for (var page = 1; page <= 604; page++) {
      for (final line in lines.page(page)) {
        if (line is SuraNameLine) names.add(line.sura);
        if (line is BasmalaLine) basmalas++;
      }
    }
    expect(names, [for (var s = 1; s <= 114; s++) s]);
    expect(basmalas, 112);
  });

  test('every verse is there, once, in order, ending exactly once', () {
    final seen = <VerseRef>[];
    var ends = 0;
    for (var page = 1; page <= 604; page++) {
      for (final line in lines.page(page)) {
        if (line is! VerseLine) continue;
        for (final piece in line.pieces) {
          if (seen.isEmpty || seen.last != piece.ref) seen.add(piece.ref);
          if (piece.endsHere) ends++;
        }
      }
    }
    expect(seen, [
      for (var s = 1; s <= 114; s++)
        for (var v = 1; v <= tanzil.versesIn(s); v++) VerseRef(s, v),
    ]);
    expect(ends, QuranText.verseCount);
  });

  test('a verse is on the page the Madinah mushaf puts it on', () {
    expect(lines.pageOf(const VerseRef(1, 1)), 1);
    expect(lines.pageOf(const VerseRef(2, 1)), 2);
    expect(lines.pageOf(const VerseRef(2, 6)), 3);
    expect(lines.pageOf(const VerseRef(3, 1)), 50);
    expect(lines.pageOf(const VerseRef(114, 1)), 604);
    // Verse starts agree with the page table the rest of the app uses.
    final structure = QuranStructure.madinah;
    var agree = 0;
    for (var s = 1; s <= 114; s++) {
      for (var v = 1; v <= tanzil.versesIn(s); v++) {
        final place = VerseRef(s, v);
        if (lines.pageOf(place) == structure.pageOf(place)) agree++;
      }
    }
    expect(agree / QuranText.verseCount, greaterThan(0.99));
  });

  test('page 1 is al-Fatihah line for line', () {
    final page = lines.page(1);
    expect((page[0] as SuraNameLine).sura, 1);
    final first = (page[1] as VerseLine).pieces.single;
    expect(first.ref, const VerseRef(1, 1));
    expect(first.endsHere, isTrue);
    expect(first.words, hasLength(4));
    final last = (page[7] as VerseLine).pieces.single;
    expect(last.ref, const VerseRef(1, 7));
    expect(last.endsHere, isTrue);
  });

  group('MushafLines.parse refuses a damaged file', () {
    test('a line out of order', () {
      expect(
        () => MushafLines.parse('1|2|s|1\n', expectedPages: 1),
        throwsFormatException,
      );
    });

    test('a verse that never ends', () {
      expect(
        () => MushafLines.parse('1|1|a|1:1:-:بِسۡمِ\n', expectedPages: 1),
        throwsFormatException,
      );
    });

    test('an unknown line kind', () {
      expect(
        () => MushafLines.parse('1|1|x|1\n', expectedPages: 1),
        throwsFormatException,
      );
    });
  });

  group('BundledMushafLinesSource', () {
    Future<ByteData> fromDisk(String path) async =>
        ByteData.sublistView(Uint8List.fromList(File(path).readAsBytesSync()));

    test('loads the verified file', () async {
      final source = BundledMushafLinesSource(
        file: file,
        loadAsset: fromDisk,
      );
      expect((await source.load()).pages, 604);
    });

    test('refuses a file that is not the verified one', () async {
      final source = BundledMushafLinesSource(
        file: const QuranFile(
          assetPath: 'assets/quran/mushaf-madinah-lines.txt',
          byteLength: 1,
          fingerprint: '0',
        ),
        loadAsset: fromDisk,
      );
      await expectLater(source.load(), throwsA(isA<QuranUnavailable>()));
    });
  });
}
