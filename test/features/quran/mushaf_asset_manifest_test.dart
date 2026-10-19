import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/quran/domain/mushaf_asset_manifest.dart';

/// Every id Quran.ws Quran Assets' catalogue lists as `pending` or `provisional` (not `confirmed`)
/// at the pinned commit this manifest was generated from — see `mushaf_asset_manifest.dart`'s own
/// header and `docs/QURAN_ASSETS_INTEGRATION_PLAN.md` §1. None of these may ever appear in the
/// production manifest; this list is the test's own record of what must stay excluded, not a copy
/// of the generator's input.
const _excludedIds = <String>[
  // Font markers with no licence asserted at all ("pending").
  'font-014-regular',
  'font-015-regular',
  'font-016-regular',
  'font-017-regular',
  'font-018-regular',
  'font-019-regular',
  'font-020-regular',
  // Scan-derived ayah markers, surah headers and page frames (CC-BY-NC-SA-4.0, "provisional").
  'mushaf-douri',
  'mushaf-hafs-adi',
  'mushaf-hafs-madinah-kabir',
  'mushaf-hafs-madinah-mumtaza',
  'mushaf-qalon',
  'mushaf-shubah',
  'mushaf-sousi',
  'mushaf-warsh',
];

void main() {
  group('confirmedAyahMarkers', () {
    test('has exactly the 40 confirmed assets, no duplicates', () {
      expect(confirmedAyahMarkers.length, 40);
      expect(confirmedAyahMarkers.map((a) => a.id).toSet().length, 40);
    });

    test('never contains a pending or provisional id', () {
      final ids = confirmedAyahMarkers.map((a) => a.id).toSet();
      for (final excluded in _excludedIds) {
        expect(
          ids.contains(excluded),
          isFalse,
          reason: '$excluded is not confirmed and must not be in the manifest',
        );
      }
    });

    test('every entry names at least one source family', () {
      for (final asset in confirmedAyahMarkers) {
        expect(asset.families, isNotEmpty, reason: asset.id);
      }
    });

    test('every entry has a sensible aspect ratio and number slot', () {
      for (final asset in confirmedAyahMarkers) {
        expect(asset.aspect, greaterThan(0), reason: asset.id);
        final slot = asset.numberSlot;
        expect(slot.x, inInclusiveRange(0, 1), reason: asset.id);
        expect(slot.y, inInclusiveRange(0, 1), reason: asset.id);
        expect(slot.width, greaterThan(0), reason: asset.id);
        expect(slot.height, greaterThan(0), reason: asset.id);
        expect(
          slot.x + slot.width,
          lessThanOrEqualTo(1.0001),
          reason: asset.id,
        );
        expect(
          slot.y + slot.height,
          lessThanOrEqualTo(1.0001),
          reason: asset.id,
        );
      }
    });

    test(
      'every referenced SVG file exists and is bundled under assets/quran_assets/',
      () {
        for (final asset in confirmedAyahMarkers) {
          for (final path in [asset.colorAsset, asset.monoAsset]) {
            expect(
              path,
              startsWith('assets/quran_assets/ayah_markers/'),
              reason: asset.id,
            );
            expect(File(path).existsSync(), isTrue, reason: '$path is missing');
          }
        }
      },
    );

    test('every referenced mono SVG is single-colour (fill: currentColor)', () {
      for (final asset in confirmedAyahMarkers) {
        final contents = File(asset.monoAsset).readAsStringSync();
        expect(
          contents.contains('currentColor'),
          isTrue,
          reason: '${asset.monoAsset} should tint as one colour',
        );
      }
    });

    test(
      'the default Mushaf glyph is Amiri, already bundled for reading text',
      () {
        expect(defaultMushafGlyph.id, 'font-002-regular');
        expect(defaultMushafGlyph.families, contains('Amiri'));
      },
    );

    test('every source family has a licence file on the Licences page', () {
      final families = confirmedAyahMarkers.expand((a) => a.families).toSet();
      for (final family in families) {
        final fileName = family.replaceAll(RegExp(r'[^A-Za-z]'), '');
        expect(
          File('assets/licenses/OFL-$fileName.txt').existsSync(),
          isTrue,
          reason: family,
        );
      }
    });
  });
}
