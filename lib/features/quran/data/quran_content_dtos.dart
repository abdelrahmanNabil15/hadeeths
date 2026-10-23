import 'package:mynewapp/core/json/json_helpers.dart';
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

/// Parses `{"tafsir": {"text": ..., ...}}` (`/tafsirs/:id/by_ayah/:verseKey`).
String tafsirTextFromJson(Object? data) {
  final map = asMap(data, 'tafsir');
  final tafsir = asMap(map['tafsir'], 'tafsir');
  return asString(tafsir['text']);
}

/// Parses `{"audio_files": [{"url": ...}], "pagination": {...}}`
/// (`/recitations/:id/by_ayah/:verseKey`): one entry for the single ayah asked for. The API's
/// urls are protocol-relative (`//...`); this always returns an `https` one.
Uri recitationAudioUrlFromJson(Object? data) {
  final map = asMap(data, 'recitation');
  final list = asList(map['audio_files'], 'audio_files');
  if (list.isEmpty) {
    throw const FormatException('recitation response had no audio files');
  }
  final url = asString(asMap(list.first, 'audio file')['url']);
  final normalized = url.startsWith('//') ? 'https:$url' : url;
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
