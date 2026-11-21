import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the licence texts of the bundled fonts to Flutter's licence page.
void registerFontLicences() {
  LicenseRegistry.addLicense(() async* {
    for (final font in const ['Cairo', 'Amiri']) {
      final text = await rootBundle.loadString('assets/licenses/OFL-$font.txt');
      yield LicenseEntryWithLineBreaks([
        if (font == 'Amiri') ...[
          'Amiri font',
          'Amiri Quran font',
        ] else
          '$font font',
      ], text);
    }
  });
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'KFGQPC HAFS Uthmanic Script font',
    ], await rootBundle.loadString('assets/licenses/KFGQPC-Hafs.txt'));
    yield LicenseEntryWithLineBreaks([
      'Mushaf line layout (Quran.com)',
    ], await rootBundle.loadString('assets/licenses/QuranCom-MushafLines.txt'));
  });
  registerMushafAssetLicences();
}

/// Families whose OFL-licensed glyph the ayah-marker artwork (`assets/quran_assets/ayah_markers/`)
/// is traced from — every one of Quran.ws Quran Assets' 40 `confirmed` markers, and nothing else
/// from that collection. See `lib/features/quran/domain/mushaf_asset_manifest.dart` and
/// `docs/QURAN_ASSETS_INTEGRATION_PLAN.md` §2.1. The filename is the family name with spaces and
/// punctuation removed; the licence file itself carries the family's own copyright line verbatim.
const _mushafAssetFontFamilies = <String>[
  'Alkalami',
  'Amiri Quran',
  'Estedad',
  'IBM Plex Sans Arabic',
  'Jomhuria',
  'Katibeh',
  'Kufam',
  'Mada',
  'Mirza',
  'Noto Naskh Arabic',
  'Noto Nastaliq Urdu',
  'Noto Sans Arabic',
  'Scheherazade New',
];

/// Adds the licence texts for the font families the ayah-marker glyphs are traced from. `Amiri`
/// itself is already covered by [registerFontLicences]'s own entry (the app bundles that font for
/// reading text); this only adds the families that exist solely because of the marker artwork.
void registerMushafAssetLicences() {
  LicenseRegistry.addLicense(() async* {
    for (final family in _mushafAssetFontFamilies) {
      final fileName = family.replaceAll(RegExp(r'[^A-Za-z]'), '');
      final text = await rootBundle.loadString(
        'assets/licenses/OFL-$fileName.txt',
      );
      yield LicenseEntryWithLineBreaks([
        '$family font (ayah-marker glyph)',
      ], text);
    }
  });
}
