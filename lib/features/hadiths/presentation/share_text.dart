import 'package:mynewapp/features/hadiths/domain/hadith_details.dart';

/// Credit line required by the HadeethEnc terms: name the publisher and source.
const hadeethEncCredit = 'المصدر: HadeethEnc.com';

/// Text shared for a hadith: the unmodified hadith text, then whichever of attribution and
/// grade exist, then the source credit. Empty parts are left out.
String hadithShareText(HadithDetails d) {
  final meta = [
    d.attribution,
    d.grade,
  ].where((e) => e.isNotEmpty).map((e) => '[$e]').join();
  return [d.hadeeth, if (meta.isNotEmpty) meta, hadeethEncCredit].join('\n');
}

/// Text shared for a secondary section (explanation, sources), with the same credit.
String sectionShareText(String text) => '$text\n$hadeethEncCredit';
