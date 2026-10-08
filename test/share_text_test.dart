import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/Model/hadith_details.dart';
import 'package:mynewapp/Shared/share_text.dart';

import 'support/fixtures.dart';

void main() {
  test(
    'shares the unmodified hadith, attribution, grade and the source credit',
    () {
      final text = hadithShareText(sampleDetails());
      expect(text, contains(arabicDetailsJson['hadeeth']! as String));
      expect(text, contains('[متفق عليه][صحيح]'));
      expect(text.trim().endsWith(hadeethEncCredit), isTrue);
    },
  );

  test(
    'missing grade or attribution never turns the share into placeholder text',
    () {
      const d = HadithDetails(id: '1', title: 't', hadeeth: 'نص الحديث');
      final text = hadithShareText(d);
      expect(text, 'نص الحديث\n$hadeethEncCredit');
      expect(text, isNot(contains('not data')));
    },
  );

  test('section text is shared with the credit', () {
    expect(sectionShareText('شرح'), 'شرح\n$hadeethEncCredit');
  });
}
