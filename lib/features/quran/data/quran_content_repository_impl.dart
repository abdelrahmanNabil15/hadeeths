import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/quran/data/quran_content_remote_data_source.dart';
import 'package:mynewapp/features/quran/domain/qiraat.dart';
import 'package:mynewapp/features/quran/domain/quran_content_repository.dart';
import 'package:mynewapp/features/quran/domain/quran_editions.dart';
import 'package:mynewapp/features/quran/domain/quran_translation_search.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';

String _verseKey(VerseRef verse) => '${verse.sura}:${verse.verse}';

class QuranContentRepositoryImpl implements QuranContentRepository {
  QuranContentRepositoryImpl(this._remote);

  final QuranContentRemoteDataSource _remote;

  @override
  Future<Result<List<TranslationEdition>>> translationEditions({
    String language = 'en',
  }) => Result.guard(() async {
    final dtos = await _remote.fetchTranslationEditions(language: language);
    return [for (final dto in dtos) dto.toEntity()];
  });

  @override
  Future<Result<List<TafsirEdition>>> tafsirEditions() =>
      Result.guard(() async {
        final dtos = await _remote.fetchTafsirEditions();
        return [for (final dto in dtos) dto.toEntity()];
      });

  @override
  Future<Result<List<Reciter>>> reciters() => Result.guard(() async {
    final dtos = await _remote.fetchReciters();
    return [for (final dto in dtos) dto.toEntity()];
  });

  @override
  Future<Result<String>> translation({
    required int editionId,
    required VerseRef verse,
  }) => Result.guard(
    () => _remote.fetchTranslation(
      editionId: editionId,
      verseKey: _verseKey(verse),
    ),
  );

  @override
  Future<Result<String>> tafsir({
    required int editionId,
    required VerseRef verse,
  }) => Result.guard(
    () => _remote.fetchTafsir(editionId: editionId, verseKey: _verseKey(verse)),
  );

  @override
  Future<Result<Uri>> recitationAudioUrl({
    required int reciterId,
    required VerseRef verse,
  }) => Result.guard(
    () => _remote.fetchRecitationAudioUrl(
      reciterId: reciterId,
      verseKey: _verseKey(verse),
    ),
  );

  @override
  Future<Result<TranslationSearchResults>> searchTranslation({
    required int editionId,
    required String query,
    int page = 1,
  }) => Result.guard(
    () => _remote.searchTranslation(
      editionId: editionId,
      query: query,
      page: page,
    ),
  );

  @override
  Future<Result<QiraatMatrix>> qiraatMatrix(VerseRef verse) =>
      Result.guard(() => _remote.fetchQiraatMatrix(verseKey: _verseKey(verse)));
}
