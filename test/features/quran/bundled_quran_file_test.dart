import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/quran_wiring.dart';
import 'package:mynewapp/core/integrity/fingerprint.dart';
import 'package:mynewapp/features/quran/data/bundled_quran_source.dart';
import 'package:mynewapp/features/quran/domain/quran_search.dart';
import 'package:mynewapp/features/quran/domain/quran_text.dart';

/// Checks on the real bundled file. Nothing here types Quran text: every comparison is between
/// the file and what the app reads from it.
void main() {
  const file = bundledQuranFile;
  final bytes = File(file.assetPath).readAsBytesSync();

  test('the bundled file is exactly the one recorded', () {
    expect(bytes.length, file.byteLength);
    expect(fingerprint(bytes), file.fingerprint);
  });

  test('it keeps Tanzil\'s copyright notice', () {
    final text = utf8.decode(bytes);
    expect(text, contains('Tanzil Quran Text'));
    expect(text, contains('CHANGING IT IS NOT ALLOWED'));
    expect(text, contains('Creative Commons Attribution 3.0'));
  });

  group('read by the app', () {
    late QuranText quran;

    setUpAll(() async {
      quran = await BundledQuranSource(
        file: file,
        loadAsset: (path) async => ByteData.sublistView(
          Uint8List.fromList(File(path).readAsBytesSync()),
        ),
      ).load();
    });

    test('114 suras and 6236 verses', () {
      expect(quran.suraTotal, 114);
      expect(quran.totalVerses, 6236);
      expect(quran.versesIn(2), 286);
      expect(quran.versesIn(108), 3);
    });

    test(
      'every verse is byte for byte the text after sura|verse| in the file',
      () {
        final lines = const LineSplitter()
            .convert(utf8.decode(bytes))
            .where((l) => l.isNotEmpty && !l.startsWith('#'))
            .toList();
        expect(lines, hasLength(6236));
        var i = 0;
        for (var s = 1; s <= 114; s++) {
          for (final verse in quran.sura(s)) {
            expect(lines[i], '${verse.sura}|${verse.number}|${verse.text}');
            i++;
          }
        }
      },
    );

    test('search over the whole text finds a verse by its own words', () {
      // Take words from a verse in the file and look for them; the verse must be among the results.
      final verse = quran.verse(112, 1);
      final words = verse.text.split(' ').take(2).join(' ');
      final found = QuranSearch(quran).search(words);
      expect(found, contains(verse));
    });
  });
}
