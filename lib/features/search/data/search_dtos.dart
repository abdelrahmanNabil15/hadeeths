import 'package:mynewapp/core/json/json_helpers.dart';
import 'package:mynewapp/features/search/domain/hadith_search_result.dart';

class SearchResultDto {
  const SearchResultDto({
    required this.id,
    required this.title,
    required this.text,
    required this.highlightedText,
  });

  factory SearchResultDto.fromJson(Map<String, dynamic> json) {
    final id = asString(json['id']);
    if (id.isEmpty) throw const FormatException('Search result without id');
    return SearchResultDto(
      id: id,
      title: asString(json['title']),
      text: asString(json['hadith_text']),
      highlightedText: asString(json['hadith_text_highlights']),
    );
  }

  final String id;
  final String title;
  final String text;
  final String highlightedText;

  HadithSearchResult toEntity() => HadithSearchResult(
    id: id,
    title: title,
    text: text,
    highlightedText: highlightedText,
  );
}

/// Parses a `hadeeths/search` response. A search with matches is a JSON array; a search
/// without any is an object (`{"suggestions": {...}}`), which means "no results".
List<SearchResultDto> parseSearchResponse(Object? data) {
  if (data is List) {
    return [for (final e in data) SearchResultDto.fromJson(asMap(e, 'result'))];
  }
  if (data is Map && data.containsKey('suggestions')) return const [];
  throw const FormatException('Unexpected search response');
}
