import 'dart:async';

import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/quran/domain/quran_audio_player.dart';
import 'package:mynewapp/features/quran/domain/quran_content_repository.dart';
import 'package:mynewapp/features/quran/domain/quran_editions.dart';
import 'package:mynewapp/features/quran/domain/quran_source.dart';
import 'package:mynewapp/features/quran/domain/quran_text.dart';
import 'package:mynewapp/features/quran/domain/quran_translation_search.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';

/// A small made-up text in the Tanzil layout: three "suras" of 7, 12 and 5 lines. These are
/// placeholder words, **not Quran text**; tests never contain typed-in verses.
const placeholderVerseCounts = [7, 12, 5];

String placeholderVerse(int sura, int verse) => switch ((sura, verse)) {
  (1, 1) => 'سطر الافتتاح التجريبي',
  (2, 3) => 'كَلِمَةٌ مُشَكَّلَةٌ لِلبَحْثِ',
  (3, 2) => 'كلمة مشكلة أخرى',
  _ => 'سطر تجريبي $sura $verse',
};

QuranText placeholderQuran() {
  final b = StringBuffer();
  for (var s = 1; s <= placeholderVerseCounts.length; s++) {
    for (var v = 1; v <= placeholderVerseCounts[s - 1]; v++) {
      b.writeln('$s|$v|${placeholderVerse(s, v)}');
    }
  }
  b.writeln('# placeholder notice');
  return QuranText.parseTanzil(
    b.toString(),
    expectedSuras: placeholderVerseCounts.length,
    expectedVerses: placeholderVerseCounts.fold(0, (a, b) => a + b),
  );
}

class FakeQuranSource implements QuranSource {
  FakeQuranSource({this.fail = false});

  final bool fail;
  int loads = 0;

  @override
  Future<QuranText> load() async {
    loads++;
    if (fail) throw const QuranUnavailable('test');
    return placeholderQuran();
  }
}

class InMemoryQuranUserData implements QuranUserData {
  VerseRef? last;
  final Set<VerseRef> marks = {};
  Object? failWrites;

  @override
  Future<VerseRef?> lastRead() async => last;

  @override
  Future<void> setLastRead(VerseRef place) async {
    if (failWrites != null) throw failWrites!;
    last = place;
  }

  @override
  Future<List<VerseRef>> bookmarks() async => marks.toList()..sort();

  @override
  Future<bool> isBookmarked(VerseRef place) async => marks.contains(place);

  @override
  Future<void> setBookmark(VerseRef place, {required bool on}) async {
    if (failWrites != null) throw failWrites!;
    on ? marks.add(place) : marks.remove(place);
  }
}

/// Placeholder translation editions, **not real Quran Foundation editions** -- same rule as
/// [placeholderVerse]: tests never contain typed-in source content.
final placeholderTranslationEditions = [
  const TranslationEdition(
    id: 1,
    name: 'Placeholder Edition One',
    authorName: 'Author One',
    languageName: 'english',
  ),
  const TranslationEdition(
    id: 2,
    name: 'Placeholder Edition Two',
    authorName: null,
    languageName: 'english',
  ),
];

String placeholderTranslation(int editionId, VerseRef verse) =>
    'placeholder translation $editionId ${verse.sura}:${verse.verse}';

/// Placeholder tafsir editions, **not real Quran Foundation editions** -- same rule as
/// [placeholderVerse].
final placeholderTafsirEditions = [
  const TafsirEdition(
    id: 10,
    name: 'Placeholder Tafsir One',
    authorName: 'Scholar One',
    languageName: 'english',
  ),
  const TafsirEdition(
    id: 20,
    name: 'Placeholder Tafsir Two',
    authorName: null,
    languageName: 'english',
  ),
];

String placeholderTafsir(int editionId, VerseRef verse) =>
    'placeholder tafsir $editionId ${verse.sura}:${verse.verse}';

/// Placeholder translation-search matches, **not real Quran Foundation content** -- same rule as
/// [placeholderVerse]. Three matches so a 2-per-page fake search has something to paginate.
final placeholderSearchMatches = [
  const TranslationSearchMatch(
    verse: VerseRef(1, 1),
    snippet: 'placeholder snippet alpha',
  ),
  const TranslationSearchMatch(
    verse: VerseRef(1, 2),
    snippet: 'placeholder snippet beta',
  ),
  const TranslationSearchMatch(
    verse: VerseRef(2, 1),
    snippet: 'placeholder snippet gamma',
  ),
];

/// Placeholder reciters, **not real Quran Foundation reciters** -- same rule as
/// [placeholderVerse].
final placeholderReciters = [
  const Reciter(id: 1, name: 'Placeholder Reciter One', style: 'Murattal'),
  const Reciter(id: 2, name: 'Placeholder Reciter Two', style: null),
];

Uri placeholderRecitationUrl(int reciterId, VerseRef verse) => Uri.parse(
  'https://example.test/audio/$reciterId/${verse.sura}_${verse.verse}.mp3',
);

/// A `QuranContentRepository` test double: configurable editions and translation/tafsir text,
/// with `fail*` flags to simulate a server failure instead.
class FakeQuranContentRepository implements QuranContentRepository {
  FakeQuranContentRepository({
    List<TranslationEdition>? translationEditions,
    List<TafsirEdition>? tafsirEditions,
    List<Reciter>? reciters,
    this.failEditions = false,
    this.failTranslation = false,
    this.failTafsirEditions = false,
    this.failTafsir = false,
    this.failSearch = false,
    this.failReciters = false,
    this.failRecitation = false,
  }) : _translationEditions =
           translationEditions ?? placeholderTranslationEditions,
       _tafsirEditions = tafsirEditions ?? placeholderTafsirEditions,
       _reciters = reciters ?? placeholderReciters;

  final List<TranslationEdition> _translationEditions;
  final List<TafsirEdition> _tafsirEditions;
  final List<Reciter> _reciters;
  bool failEditions;
  bool failTranslation;
  bool failTafsirEditions;
  bool failTafsir;
  bool failSearch;
  bool failReciters;
  bool failRecitation;
  int translationCalls = 0;
  int tafsirCalls = 0;
  int searchCalls = 0;
  int recitationCalls = 0;

  /// Matches [placeholderSearchMatches] two per page, like the real Search API's pagination.
  static const _searchPageSize = 2;

  @override
  Future<Result<List<TranslationEdition>>> translationEditions({
    String language = 'en',
  }) async => failEditions
      ? const Err(Failure(FailureKind.server))
      : Success(_translationEditions);

  @override
  Future<Result<List<TafsirEdition>>> tafsirEditions() async =>
      failTafsirEditions
      ? const Err(Failure(FailureKind.server))
      : Success(_tafsirEditions);

  @override
  Future<Result<List<Reciter>>> reciters() async => failReciters
      ? const Err(Failure(FailureKind.server))
      : Success(_reciters);

  @override
  Future<Result<String>> translation({
    required int editionId,
    required VerseRef verse,
  }) async {
    translationCalls++;
    return failTranslation
        ? const Err(Failure(FailureKind.server))
        : Success(placeholderTranslation(editionId, verse));
  }

  @override
  Future<Result<String>> tafsir({
    required int editionId,
    required VerseRef verse,
  }) async {
    tafsirCalls++;
    return failTafsir
        ? const Err(Failure(FailureKind.server))
        : Success(placeholderTafsir(editionId, verse));
  }

  @override
  Future<Result<Uri>> recitationAudioUrl({
    required int reciterId,
    required VerseRef verse,
  }) async {
    recitationCalls++;
    return failRecitation
        ? const Err(Failure(FailureKind.server))
        : Success(placeholderRecitationUrl(reciterId, verse));
  }

  @override
  Future<Result<TranslationSearchResults>> searchTranslation({
    required int editionId,
    required String query,
    int page = 1,
  }) async {
    searchCalls++;
    if (failSearch) return const Err(Failure(FailureKind.server));
    final matches = placeholderSearchMatches
        .where((m) => m.snippet.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final totalPages = matches.isEmpty
        ? 1
        : (matches.length / _searchPageSize).ceil();
    final start = (page - 1) * _searchPageSize;
    final end = (start + _searchPageSize).clamp(0, matches.length);
    final pageMatches = start >= matches.length
        ? const <TranslationSearchMatch>[]
        : matches.sublist(start, end);
    return Success(
      TranslationSearchResults(
        matches: pageMatches,
        page: page,
        totalPages: totalPages,
      ),
    );
  }
}

/// A `QuranAudioPlayer` test double: no real audio engine, so tests drive its playback state
/// directly (`complete()`, `emitPosition()`) instead of waiting on a real player.
class FakeQuranAudioPlayer implements QuranAudioPlayer {
  final playedUrls = <Uri>[];
  int pauseCalls = 0;
  int resumeCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;
  bool failPlay = false;

  final _stateController = StreamController<QuranAudioEngineState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();

  @override
  Future<void> play(Uri url) async {
    playedUrls.add(url);
    if (failPlay) throw Exception('fake play failure');
    _stateController.add(QuranAudioEngineState.playing);
    _durationController.add(const Duration(seconds: 10));
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    _stateController.add(QuranAudioEngineState.paused);
  }

  @override
  Future<void> resume() async {
    resumeCalls++;
    _stateController.add(QuranAudioEngineState.playing);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    _stateController.add(QuranAudioEngineState.idle);
  }

  @override
  Stream<QuranAudioEngineState> get stateStream => _stateController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  /// Test helper: simulates the current verse finishing on its own (as opposed to [stop]).
  void complete() => _stateController.add(QuranAudioEngineState.completed);

  void emitPosition(Duration d) => _positionController.add(d);

  @override
  Future<void> dispose() async {
    disposeCalls++;
    await _stateController.close();
    await _positionController.close();
    await _durationController.close();
  }
}
