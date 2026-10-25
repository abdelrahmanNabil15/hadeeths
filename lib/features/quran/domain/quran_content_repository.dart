import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/quran/domain/qiraat.dart';
import 'package:mynewapp/features/quran/domain/quran_editions.dart';
import 'package:mynewapp/features/quran/domain/quran_translation_search.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';

/// Read-only access to the Quran Foundation Content API, through hadeeths' own backend proxy
/// (docs/QURAN_API_REFACTOR_PLAN.md, section 2): translation, tafsir and recitation-audio
/// editions, and one edition's content for one verse. Never the verse text itself -- that stays
/// `QuranSource`'s bundled, offline Tanzil file, unchanged by this interface.
abstract interface class QuranContentRepository {
  /// Every translation edition, with their names shown in [language] where available. Not a
  /// content filter: editions in every language are returned regardless of [language].
  Future<Result<List<TranslationEdition>>> translationEditions({
    String language = 'en',
  });

  Future<Result<List<TafsirEdition>>> tafsirEditions();

  Future<Result<List<Reciter>>> reciters();

  /// The text of [editionId]'s translation of [verse].
  Future<Result<String>> translation({
    required int editionId,
    required VerseRef verse,
  });

  /// The text of [editionId]'s tafsir of [verse].
  Future<Result<String>> tafsir({
    required int editionId,
    required VerseRef verse,
  });

  /// Where to stream [reciterId]'s recitation of [verse] from.
  Future<Result<Uri>> recitationAudioUrl({
    required int reciterId,
    required VerseRef verse,
  });

  /// Verses whose [editionId] translation matches [query] (the Quran Foundation Search API,
  /// additive to `QuranSearch`'s on-device Arabic search). [page] is 1-based.
  Future<Result<TranslationSearchResults>> searchTranslation({
    required int editionId,
    required String query,
    int page = 1,
  });

  /// The approved Qira'at (recitation-variant) comparison for [verse]. Most verses have none;
  /// that is [QiraatMatrix.empty], not a failure.
  Future<Result<QiraatMatrix>> qiraatMatrix(VerseRef verse);
}
