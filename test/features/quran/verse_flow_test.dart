import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/quran/domain/quran_text.dart';
import 'package:mynewapp/features/quran/presentation/widgets/verse_flow.dart';

/// Placeholder words in the Tanzil layout, **not Quran text**: sura 1 opens with a line that the
/// second sura repeats at the start of its first verse, as the real file does.
QuranText _sample() => QuranText.parseTanzil(
  '1|1|سطر افتتاح تجريبي\n'
  '1|2|سطر ثان\n'
  '2|1|سطر افتتاح تجريبي بقية الأول\n'
  '2|2|سطر آخر\n'
  '3|1|سطر مختلف تماما\n'
  '# placeholder notice\n',
  expectedSuras: 3,
  expectedVerses: 5,
);

void main() {
  group('the opening line above a sura', () {
    test('is the first verse of al-Fatihah, taken from the file itself', () {
      expect(leadingBasmala(_sample(), 2), 'سطر افتتاح تجريبي');
    });

    test('is never taken from al-Fatihah itself', () {
      expect(leadingBasmala(_sample(), 1), isNull);
    });

    test('is absent when a sura does not begin with it', () {
      expect(leadingBasmala(_sample(), 3), isNull);
    });

    test('is split off only at a word boundary', () {
      final text = QuranText.parseTanzil(
        '1|1|سطر\n2|1|سطرا بقية\n',
        expectedSuras: 2,
        expectedVerses: 2,
      );
      expect(leadingBasmala(text, 2), isNull);
    });
  });
}
