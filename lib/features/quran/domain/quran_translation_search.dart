import 'package:equatable/equatable.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';

/// One verse whose chosen translation matched a search query.
class TranslationSearchMatch extends Equatable {
  const TranslationSearchMatch({required this.verse, required this.snippet});

  final VerseRef verse;

  /// The matched translation text for [verse].
  final String snippet;

  @override
  List<Object?> get props => [verse, snippet];
}

/// One page of results from searching inside a chosen translation edition
/// (the Quran Foundation Search API, distinct from `QuranSearch`'s on-device Arabic search).
class TranslationSearchResults extends Equatable {
  const TranslationSearchResults({
    required this.matches,
    required this.page,
    required this.totalPages,
  });

  final List<TranslationSearchMatch> matches;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [matches, page, totalPages];
}
