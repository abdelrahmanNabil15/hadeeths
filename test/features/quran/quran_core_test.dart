import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/integrity/fingerprint.dart';
import 'package:mynewapp/features/quran/data/bundled_quran_source.dart';
import 'package:mynewapp/features/quran/domain/quran_source.dart';
import 'package:mynewapp/features/quran/domain/quran_text.dart';

/// A made-up file in the Tanzil layout. The "verses" are placeholders, not Quran text: tests must
/// never contain typed-in Quran text, which could be wrong.
String _sample({List<int> verses = const [3, 2, 4], bool notice = true}) {
  final b = StringBuffer();
  for (var s = 1; s <= verses.length; s++) {
    for (var v = 1; v <= verses[s - 1]; v++) {
      b.writeln('$s|$v|placeholder $s:$v, with | a bar and  two spaces');
    }
  }
  if (notice) {
    b
      ..writeln()
      ..writeln('#  Placeholder notice line')
      ..writeln('#  Another notice line');
  }
  return b.toString();
}

QuranText _parse(String text, {List<int> verses = const [3, 2, 4]}) =>
    QuranText.parseTanzil(
      text,
      expectedSuras: verses.length,
      expectedVerses: verses.fold(0, (a, b) => a + b),
    );

void main() {
  group('reading the Tanzil layout', () {
    test('reads every verse in order, with the text exactly as given', () {
      final q = _parse(_sample());
      expect(q.totalVerses, 9);
      expect(q.versesIn(1), 3);
      expect(q.versesIn(3), 4);
      expect(
        q.verse(2, 2).text,
        'placeholder 2:2, with | a bar and  two spaces',
      );
      expect(
        q.verse(3, 4),
        const Verse(
          sura: 3,
          number: 4,
          text: 'placeholder 3:4, with | a bar and  two spaces',
        ),
      );
    });

    test('Windows line endings do not change the text', () {
      final q = _parse(_sample().replaceAll('\n', '\r\n'));
      expect(q.verse(1, 1).text, endsWith('two spaces'));
    });

    test('the notice lines are not verses', () {
      expect(
        _parse(_sample()).totalVerses,
        _parse(_sample(notice: false)).totalVerses,
      );
    });

    test('a missing verse is refused', () {
      final broken = _sample().replaceFirst(
        RegExp(r'^1\|2\|.*\n', multiLine: true),
        '',
      );
      expect(() => _parse(broken), throwsFormatException);
    });

    test('a repeated verse is refused', () {
      final broken = _sample().replaceFirst('2|1|', '2|1|x\n2|1|');
      expect(() => _parse(broken), throwsFormatException);
    });

    test('verses out of order are refused', () {
      final lines = _sample().split('\n');
      final swapped = [lines[1], lines[0], ...lines.skip(2)].join('\n');
      expect(() => _parse(swapped), throwsFormatException);
    });

    test('a wrong total is refused', () {
      expect(
        () => QuranText.parseTanzil(
          _sample(),
          expectedSuras: 3,
          expectedVerses: 10,
        ),
        throwsFormatException,
      );
      expect(
        () => QuranText.parseTanzil(_sample()),
        throwsFormatException,
        reason: 'the real file must have 114 suras and 6236 verses',
      );
    });

    test('a line that is not sura|verse|text is refused', () {
      for (final bad in ['1|1', 'a|1|x', '1|b|x', '1|1|']) {
        expect(
          () => _parse('$bad\n${_sample()}'),
          throwsFormatException,
          reason: bad,
        );
      }
    });

    test('the text cannot be changed from outside', () {
      final q = _parse(_sample());
      expect(
        () => q.sura(1).add(const Verse(sura: 1, number: 4, text: 'x')),
        throwsUnsupportedError,
      );
      expect(() => q.sura(0), throwsRangeError);
      expect(() => q.verse(1, 4), throwsRangeError);
    });
  });

  group('the bundled source', () {
    final bytes = utf8.encode(_sample());

    BundledQuranSource source({
      QuranFile? file,
      Map<String, List<int>>? assets,
    }) => BundledQuranSource(
      file: file,
      loadAsset: (path) async {
        final data = (assets ?? {'q.txt': bytes})[path];
        if (data == null) throw StateError('no asset $path');
        return ByteData.sublistView(Uint8List.fromList(data));
      },
    );

    test(
      'without a verified file in the build, the text is unavailable',
      () async {
        await expectLater(source().load(), throwsA(isA<QuranUnavailable>()));
      },
    );

    test('a missing asset is reported as unavailable', () async {
      final file = QuranFile(
        assetPath: 'missing.txt',
        byteLength: bytes.length,
        fingerprint: fingerprint(bytes),
      );
      await expectLater(
        source(file: file).load(),
        throwsA(isA<QuranUnavailable>()),
      );
    });

    test('a file that is not exactly the verified one is refused', () async {
      final changed = [...bytes]..[10] ^= 1;
      final file = QuranFile(
        assetPath: 'q.txt',
        byteLength: bytes.length,
        fingerprint: fingerprint(bytes),
      );
      await expectLater(
        source(file: file, assets: {'q.txt': changed}).load(),
        throwsA(isA<QuranUnavailable>()),
      );
    });

    test(
      'the verified file is checked and then parsed (the real totals apply)',
      () async {
        // The sample has 3 suras, so the real 114/6236 check refuses it: proof that the check runs
        // on the bundled file and is not relaxed outside tests.
        final file = QuranFile(
          assetPath: 'q.txt',
          byteLength: bytes.length,
          fingerprint: fingerprint(bytes),
        );
        await expectLater(
          source(file: file).load(),
          throwsA(isA<QuranUnavailable>()),
        );
      },
    );
  });

  group('fingerprint', () {
    test('is stable and sensitive to every byte', () {
      expect(fingerprint(const []), 'cbf29ce484222325');
      expect(fingerprint(utf8.encode('a')), 'af63dc4c8601ec8c');
      expect(fingerprint([1, 2, 3]), isNot(fingerprint([1, 2, 4])));
      expect(fingerprint([1, 2, 3]), hasLength(16));
    });
  });
}
