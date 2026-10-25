import 'package:mynewapp/core/json/json_helpers.dart';
import 'package:mynewapp/features/quran/domain/qiraat.dart';
import 'package:mynewapp/features/quran/domain/quran_editions.dart';
import 'package:mynewapp/features/quran/domain/quran_translation_search.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';

String? _asNullableString(Object? value) =>
    value == null ? null : asString(value);

// --- Edition lists ---

class TranslationEditionDto {
  TranslationEditionDto({
    required this.id,
    required this.name,
    required this.authorName,
    required this.languageName,
  });

  final int id;
  final String name;
  final String? authorName;
  final String languageName;

  factory TranslationEditionDto.fromJson(Map<String, dynamic> json) =>
      TranslationEditionDto(
        id: asInt(json['id'], 0),
        name: asString(json['name']),
        authorName: _asNullableString(json['author_name']),
        languageName: asString(json['language_name']),
      );

  TranslationEdition toEntity() => TranslationEdition(
    id: id,
    name: name,
    authorName: authorName,
    languageName: languageName,
  );
}

/// Parses `{"translations": [...]}` (`/resources/translations`).
List<TranslationEditionDto> translationEditionsFromJson(Object? data) {
  final map = asMap(data, 'translation editions');
  final list = asList(map['translations'], 'translations');
  return [
    for (final entry in list)
      TranslationEditionDto.fromJson(asMap(entry, 'translation edition')),
  ];
}

class TafsirEditionDto {
  TafsirEditionDto({
    required this.id,
    required this.name,
    required this.authorName,
    required this.languageName,
  });

  final int id;
  final String name;
  final String? authorName;
  final String languageName;

  factory TafsirEditionDto.fromJson(Map<String, dynamic> json) =>
      TafsirEditionDto(
        id: asInt(json['id'], 0),
        name: asString(json['name']),
        authorName: _asNullableString(json['author_name']),
        languageName: asString(json['language_name']),
      );

  TafsirEdition toEntity() => TafsirEdition(
    id: id,
    name: name,
    authorName: authorName,
    languageName: languageName,
  );
}

/// Parses `{"tafsirs": [...]}` (`/resources/tafsirs`).
List<TafsirEditionDto> tafsirEditionsFromJson(Object? data) {
  final map = asMap(data, 'tafsir editions');
  final list = asList(map['tafsirs'], 'tafsirs');
  return [
    for (final entry in list)
      TafsirEditionDto.fromJson(asMap(entry, 'tafsir edition')),
  ];
}

class ReciterDto {
  ReciterDto({required this.id, required this.name, required this.style});

  final int id;
  final String name;
  final String? style;

  factory ReciterDto.fromJson(Map<String, dynamic> json) => ReciterDto(
    id: asInt(json['id'], 0),
    name: asString(json['reciter_name']),
    style: _asNullableString(json['style']),
  );

  Reciter toEntity() => Reciter(id: id, name: name, style: style);
}

/// Parses `{"recitations": [...]}` (`/resources/recitations`).
List<ReciterDto> recitersFromJson(Object? data) {
  final map = asMap(data, 'reciters');
  final list = asList(map['recitations'], 'recitations');
  return [
    for (final entry in list) ReciterDto.fromJson(asMap(entry, 'reciter')),
  ];
}

// --- Per-ayah content ---

/// Parses `{"translations": [{"text": ...}], "pagination": {...}}`
/// (`/translations/:id/by_ayah/:verseKey`): one entry for the single ayah asked for.
String translationTextFromJson(Object? data) {
  final map = asMap(data, 'translation');
  final list = asList(map['translations'], 'translations');
  if (list.isEmpty) {
    throw const FormatException('translation response had no translations');
  }
  return asString(asMap(list.first, 'translation entry')['text']);
}

/// Parses `{"tafsir": {"text": ..., ...}}` (`/tafsirs/:id/by_ayah/:verseKey`). `text` is lightly
/// HTML-formatted for at least some editions (confirmed live, 2026-10-22, against Tafsir Ibn
/// Kathir: `<p>` paragraphs and `<span class="blue"|"red"|"reference brown"|"arabic qpc-hafs">`
/// highlights for quoted opinions, emphasis, citations and embedded Quran text) -- returned as
/// given, unparsed: rendering it is `TafsirSheet`'s job (`simple_html_css`), not this layer's.
String tafsirTextFromJson(Object? data) {
  final map = asMap(data, 'tafsir');
  final tafsir = asMap(map['tafsir'], 'tafsir');
  return asString(tafsir['text']);
}

/// The Content API's audio CDN, for `recitationAudioUrlFromJson`'s plain-relative-path case
/// (confirmed live, 2026-10-22: `GET /recitations/:id/ayah/:verseKey` on the deployed proxy
/// returned `"url": "Minshawi/Murattal/mp3/001002.mp3"`, no scheme and no leading `//` -- not the
/// protocol-relative shape originally assumed from the docs alone; resolving it against this CDN
/// returned a real, playable `audio/mpeg` file). Matches the JS SDK's own documented advice for
/// the sibling word-audio case ("resolve it against https://audio.qurancdn.com/").
const _audioCdnBase = 'https://audio.qurancdn.com/';

/// Parses `{"audio_files": [{"url": ...}], "pagination": {...}}`
/// (`/recitations/:id/by_ayah/:verseKey`): one entry for the single ayah asked for. The API's
/// `url` has been observed both protocol-relative (`//...`) and as a plain relative path with no
/// leading slash at all; either is resolved to an `https` url on [_audioCdnBase]. An already
/// absolute url (`http(s)://...`) is returned unchanged.
Uri recitationAudioUrlFromJson(Object? data) {
  final map = asMap(data, 'recitation');
  final list = asList(map['audio_files'], 'audio_files');
  if (list.isEmpty) {
    throw const FormatException('recitation response had no audio files');
  }
  final url = asString(asMap(list.first, 'audio file')['url']);
  final normalized = switch (url) {
    _ when url.startsWith('//') => 'https:$url',
    _ when url.startsWith('http://') || url.startsWith('https://') => url,
    _ => '$_audioCdnBase$url',
  };
  final parsed = Uri.tryParse(normalized);
  if (parsed == null || !parsed.hasScheme) {
    throw FormatException('could not parse audio url: $url');
  }
  return parsed;
}

// --- Translation search ---

/// Parses `{"pagination": {...}, "result": {"verses": [{"key": "1:1", "name": "..."}, ...]}}`
/// (`/search`, advanced mode filtered to one translation edition): `key` is the verse's
/// `sura:verse` address, `name` its matched translation text.
TranslationSearchResults translationSearchResultsFromJson(Object? data) {
  final map = asMap(data, 'search results');
  final pagination = asMap(map['pagination'], 'pagination');
  final result = asMap(map['result'], 'search result');
  final verses = asList(result['verses'], 'verses');
  return TranslationSearchResults(
    matches: [
      for (final entry in verses)
        _translationSearchMatchFromJson(asMap(entry, 'search match')),
    ],
    page: asInt(pagination['current_page'], 1),
    totalPages: asInt(pagination['total_pages'], 1),
  );
}

TranslationSearchMatch _translationSearchMatchFromJson(
  Map<String, dynamic> json,
) {
  final key = asString(json['key']);
  final parts = key.split(':');
  final sura = parts.length == 2 ? int.tryParse(parts[0]) : null;
  final verse = parts.length == 2 ? int.tryParse(parts[1]) : null;
  if (sura == null || verse == null) {
    throw FormatException('could not parse verse key: $key');
  }
  return TranslationSearchMatch(
    verse: VerseRef(sura, verse),
    snippet: asString(json['name']),
  );
}

// --- Qira'at ---

/// Parses `{"readers": [...], "transmitters": [...], "junctures": [...]}` (`/qiraat/matrix/
/// by_verse/:verseKey`). Readers and transmitters are only looked up here to turn each reading's
/// `matrix.cells` ids into display names (e.g. "Hafs", "Warsh (Nafi')"); nothing else about them
/// is kept.
QiraatMatrix qiraatMatrixFromJson(Object? data) {
  final map = asMap(data, 'qiraat matrix');
  final readerNames = <int, String>{
    for (final entry in asList(map['readers'], 'readers'))
      asInt(asMap(entry, 'reader')['id'], -1): asString(
        asMap(entry, 'reader')['name'],
      ),
  };
  final transmitterNames = <int, String>{
    for (final entry in asList(map['transmitters'], 'transmitters'))
      asInt(asMap(entry, 'transmitter')['id'], -1): asString(
        asMap(entry, 'transmitter')['name'],
      ),
  };
  return QiraatMatrix(
    junctures: [
      for (final entry in asList(map['junctures'], 'junctures'))
        _qiraatJunctureFromJson(
          asMap(entry, 'juncture'),
          readerNames,
          transmitterNames,
        ),
    ],
  );
}

QiraatJuncture _qiraatJunctureFromJson(
  Map<String, dynamic> json,
  Map<int, String> readerNames,
  Map<int, String> transmitterNames,
) => QiraatJuncture(
  text: asString(json['text']),
  category: qiraatCategoryFromCode(asString(json['category'])),
  commentary: _asNullableString(json['commentary']),
  readings: [
    for (final entry in asList(json['readings'], 'readings'))
      _qiraatReadingFromJson(
        asMap(entry, 'reading'),
        readerNames,
        transmitterNames,
      ),
  ],
);

QiraatReading _qiraatReadingFromJson(
  Map<String, dynamic> json,
  Map<int, String> readerNames,
  Map<int, String> transmitterNames,
) {
  final cells = asList(
    asMap(json['matrix'], 'reading matrix')['cells'],
    'cells',
  );
  final attributions = [
    for (final entry in cells)
      _qiraatAttributionFromJson(
        asMap(entry, 'cell'),
        readerNames,
        transmitterNames,
      ),
  ];
  return QiraatReading(
    text: asString(json['text']),
    attributions: attributions,
    translation: _asNullableString(json['translation']),
  );
}

String _qiraatAttributionFromJson(
  Map<String, dynamic> cell,
  Map<int, String> readerNames,
  Map<int, String> transmitterNames,
) {
  final readerId = asInt(cell['reader_id'], -1);
  final readerName = readerNames[readerId] ?? 'Reader #$readerId';
  final transmitterId = cell['transmitter_id'];
  if (transmitterId == null) return readerName;
  final id = asInt(transmitterId, -1);
  final transmitterName = transmitterNames[id] ?? 'Transmitter #$id';
  return '$readerName ($transmitterName)';
}
