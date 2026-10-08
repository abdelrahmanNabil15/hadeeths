import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_details.dart';
import 'package:mynewapp/features/hadiths/presentation/share_text.dart';

import '../../../support/fixtures.dart';

const credit = 'Source: HadeethEnc.com';

void main() {
  test(
    'shares the unmodified hadith, attribution, grade and the source credit',
    () {
      final text = hadithShareText(sampleDetails(), credit: credit);
      expect(text, contains(arabicDetailsJson['hadeeth']! as String));
      expect(text, contains('[متفق عليه][صحيح]'));
      expect(text.trim().endsWith(credit), isTrue);
    },
  );

  test(
    'missing grade or attribution never turns the share into placeholder text',
    () {
      const d = HadithDetails(id: '1', title: 't', hadeeth: 'نص الحديث');
      final text = hadithShareText(d, credit: credit);
      expect(text, 'نص الحديث\n$credit');
      expect(text, isNot(contains('not data')));
    },
  );

  test('section text is shared with the credit', () {
    expect(sectionShareText('شرح', credit: credit), 'شرح\n$credit');
  });
}
