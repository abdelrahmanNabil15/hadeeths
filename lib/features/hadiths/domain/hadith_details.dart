import 'package:equatable/equatable.dart';

class WordMeaning extends Equatable {
  const WordMeaning({required this.word, required this.meaning});

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
