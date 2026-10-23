import 'package:equatable/equatable.dart';

/// One translation edition the reader can choose, from the Quran Foundation API's edition list.
class TranslationEdition extends Equatable {
  const TranslationEdition({
    required this.id,
    required this.name,
    required this.authorName,
    required this.languageName,
  });

  final int id;
  final String name;
  final String? authorName;

  /// The edition's own language (e.g. "english", "urdu") -- not the language its name is shown
  /// in, which the caller picks separately.
  final String languageName;

  @override
  List<Object?> get props => [id, name, authorName, languageName];
}

/// One tafsir edition the reader can choose.
class TafsirEdition extends Equatable {
  const TafsirEdition({
    required this.id,
    required this.name,
    required this.authorName,
    required this.languageName,
  });

  final int id;
  final String name;
  final String? authorName;
  final String languageName;

  @override
  List<Object?> get props => [id, name, authorName, languageName];
}

/// One reciter the reader can choose for audio.
class Reciter extends Equatable {
  const Reciter({required this.id, required this.name, this.style});

  final int id;
  final String name;

  /// How this reciter recites (e.g. "Murattal", "Mujawwad"); not always given.
  final String? style;

  @override
  List<Object?> get props => [id, name, style];
}
