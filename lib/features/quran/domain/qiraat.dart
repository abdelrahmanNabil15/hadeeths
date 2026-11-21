import 'package:equatable/equatable.dart';

/// What kind of difference a juncture records, per the Quran Foundation API's own A/B/C
/// classification.
enum QiraatCategory {
  /// A: the readings differ in meaning.
  meaning,

  /// B: an orthographic difference with the same meaning.
  wording,

  /// C: a phonetic difference only.
  pronunciation,

  /// An unrecognised or missing category code.
  unknown,
}

QiraatCategory qiraatCategoryFromCode(String code) => switch (code) {
  'A' => QiraatCategory.meaning,
  'B' => QiraatCategory.wording,
  'C' => QiraatCategory.pronunciation,
  _ => QiraatCategory.unknown,
};

/// One reader's (or one reader-transmitter pair's) wording at a juncture.
class QiraatReading extends Equatable {
  const QiraatReading({
    required this.text,
    required this.attributions,
    this.translation,
  });

  final String text;

  /// Who holds this reading, already resolved to display names (e.g. "Hafs", "Warsh (Nafi')"),
  /// in the matrix's own reader/transmitter order.
  final List<String> attributions;

  final String? translation;

  @override
  List<Object?> get props => [text, attributions, translation];
}

/// One approved point of variation within a verse: the base wording, every attested reading at
/// that point, and (when the API supplies one) a scholarly note on the difference.
class QiraatJuncture extends Equatable {
  const QiraatJuncture({
    required this.text,
    required this.category,
    required this.readings,
    this.commentary,
  });

  final String text;
  final QiraatCategory category;
  final List<QiraatReading> readings;
  final String? commentary;

  @override
  List<Object?> get props => [text, category, readings, commentary];
}

/// The full comparison for one verse: every approved juncture touching it. Most verses have
/// none at all -- `junctures` being empty is the normal case, not a failure.
class QiraatMatrix extends Equatable {
  const QiraatMatrix({required this.junctures});

  static const empty = QiraatMatrix(junctures: []);

  final List<QiraatJuncture> junctures;

  bool get hasVariations => junctures.isNotEmpty;

  @override
  List<Object?> get props => [junctures];
}
