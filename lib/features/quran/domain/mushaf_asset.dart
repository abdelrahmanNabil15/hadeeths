import 'package:equatable/equatable.dart';

/// Where the ayah number sits inside a [MushafAsset]'s own artwork: a rectangle, as a fraction
/// (0 to 1) of the artwork's width and height, so it still lines up after the artwork is scaled to
/// any size.
class MushafAssetSlot extends Equatable {
  const MushafAssetSlot({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  @override
  List<Object?> get props => [x, y, width, height];
}

/// One ayah-marker glyph from Quran.ws Quran Assets (quran.ws/blocks/quran-assets), traced from the
/// U+06DD glyph of an OFL-1.1 font. Only assets whose licence is `confirmed` are ever represented by
/// this type — see `mushaf_asset_manifest.dart` and `docs/QURAN_ASSETS_INTEGRATION_PLAN.md`. This is
/// decoration only: it carries no Quran text and never changes a verse's text or numbering.
class MushafAsset extends Equatable {
  const MushafAsset({
    required this.id,
    required this.families,
    required this.weight,
    required this.aspect,
    required this.numberSlot,
    required this.colorAsset,
    required this.monoAsset,
  });

  /// The upstream style id, e.g. `font-002-regular`.
  final String id;

  /// The source font family or families this glyph is traced from (for attribution). More than one
  /// when the glyph combines weights of related families, e.g. Amiri and Amiri Quran.
  final List<String> families;

  /// The source font's weight/style label, e.g. `regular`, `bold`, `extralight`.
  final String weight;

  /// Width divided by height of the artwork's own viewBox.
  final double aspect;

  final MushafAssetSlot numberSlot;

  /// The full-colour SVG asset path (the glyph's own fixed palette).
  final String colorAsset;

  /// The single-colour SVG asset path (`fill: currentColor`), for tinting to match the app's theme.
  final String monoAsset;

  @override
  List<Object?> get props => [
    id,
    families,
    weight,
    aspect,
    numberSlot,
    colorAsset,
    monoAsset,
  ];
}
