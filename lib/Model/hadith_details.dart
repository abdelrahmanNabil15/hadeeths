import 'package:equatable/equatable.dart';

import 'json_helpers.dart';

class WordMeaning extends Equatable {
  const WordMeaning({required this.word, required this.meaning});

  factory WordMeaning.fromJson(Map<String, dynamic> json) => WordMeaning(
    word: asString(json['word']),
    meaning: asString(json['meaning']),
  );

  final String word;
  final String meaning;

  @override
  List<Object?> get props => [word, meaning];
}

/// A full hadith. Text fields are kept exactly as received. Non-Arabic responses omit
/// `reference` and `words_meanings`, so every optional field defaults to empty.
class HadithDetails extends Equatable {
  const HadithDetails({
    required this.id,
    required this.title,
    required this.hadeeth,
    this.intro = '',
    this.attribution = '',
    this.grade = '',
    this.explanation = '',
    this.hints = const [],
    this.categories = const [],
    this.translations = const [],
    this.wordsMeanings = const [],
    this.reference = '',
  });

  factory HadithDetails.fromJson(Map<String, dynamic> json) {
    final id = asString(json['id']);
    if (id.isEmpty) throw const FormatException('Hadith without id');
    final words = json['words_meanings'];
    return HadithDetails(
      id: id,
      title: asString(json['title']),
      hadeeth: asString(json['hadeeth']),
      intro: asString(json['hadeeth_intro']),
      attribution: asString(json['attribution']),
      grade: asString(json['grade']),
      explanation: asString(json['explanation']),
      hints: asStringList(json['hints']),
      categories: asStringList(json['categories']),
      translations: asStringList(json['translations']),
      wordsMeanings: words is List
          ? words
                .map((e) => WordMeaning.fromJson(asMap(e, 'word meaning')))
                .toList()
          : const [],
      reference: asString(json['reference']),
    );
  }

  final String id;
  final String title;
  final String hadeeth;
  final String intro;
  final String attribution;
  final String grade;
  final String explanation;
  final List<String> hints;
  final List<String> categories;
  final List<String> translations;
  final List<WordMeaning> wordsMeanings;
  final String reference;

  @override
  List<Object?> get props => [
    id,
    title,
    hadeeth,
    intro,
    attribution,
    grade,
    explanation,
    hints,
    categories,
    translations,
    wordsMeanings,
    reference,
  ];
}
