import 'package:mynewapp/features/hadiths/domain/hadith_details.dart';

/// Text shared for a hadith: the unmodified hadith text, then whichever of attribution and
/// grade exist, then the source credit. [credit] is the localized "Source: HadeethEnc.com"
/// line that the HadeethEnc terms require. Empty parts are left out.
String hadithShareText(HadithDetails d, {required String credit}) {
  final meta = [
    d.attribution,
    d.grade,
  ].where((e) => e.isNotEmpty).map((e) => '[$e]').join();
  return [d.hadeeth, if (meta.isNotEmpty) meta, credit].join('\n');
}

/// Text shared for a secondary section (explanation, sources), with the same credit.
String sectionShareText(String text, {required String credit}) =>
    '$text\n$credit';
