import 'package:mynewapp/core/json/json_helpers.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_details.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_page.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_summary.dart';

/// A hadith as listed inside a category (`hadeeths/list`).
class HadithSummaryDto {
  const HadithSummaryDto({required this.id, required this.title});

  factory HadithSummaryDto.fromJson(Map<String, dynamic> json) {
    final id = asString(json['id']);
    if (id.isEmpty) throw const FormatException('Hadith without id');
    return HadithSummaryDto(id: id, title: asString(json['title']));
  }

  final String id;
  final String title;

  HadithSummary toEntity() => HadithSummary(id: id, title: title);
}

/// A `hadeeths/list` response. Meta fields arrive as strings (`current_page`,
/// `per_page`) or numbers (`last_page`, `total_items`), so every reader accepts both.
class HadithPageDto {
  const HadithPageDto({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.totalItems,
  });

  factory HadithPageDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['data'];
    final items = rawItems == null
        ? <HadithSummaryDto>[]
        : asList(
            rawItems,
            'data',
          ).map((e) => HadithSummaryDto.fromJson(asMap(e, 'hadith'))).toList();
    final meta = json['meta'] == null
        ? <String, dynamic>{}
        : asMap(json['meta'], 'meta');
    final currentPage = asInt(meta['current_page'], 1);
    return HadithPageDto(
      items: items,
      currentPage: currentPage,
      lastPage: asInt(meta['last_page'], currentPage),
      totalItems: asInt(meta['total_items'], items.length),
    );
  }

  final List<HadithSummaryDto> items;
  final int currentPage;
  final int lastPage;
  final int totalItems;

  HadithPage toEntity() => HadithPage(
    items: [for (final item in items) item.toEntity()],
    currentPage: currentPage,
    lastPage: lastPage,
    totalItems: totalItems,
  );
}

class WordMeaningDto {
  const WordMeaningDto({required this.word, required this.meaning});

  factory WordMeaningDto.fromJson(Map<String, dynamic> json) => WordMeaningDto(
    word: asString(json['word']),
    meaning: asString(json['meaning']),
  );

  final String word;
  final String meaning;

  WordMeaning toEntity() => WordMeaning(word: word, meaning: meaning);
}

/// A `hadeeths/one` response. Non-Arabic responses have no `reference` and no
/// `words_meanings`, so every optional field defaults to empty.
class HadithDetailsDto {
  const HadithDetailsDto({
    required this.id,
    required this.title,
    required this.hadeeth,
    required this.intro,
    required this.attribution,
    required this.grade,
    required this.explanation,
    required this.hints,
    required this.categories,
    required this.translations,
    required this.wordsMeanings,
    required this.reference,
  });

  factory HadithDetailsDto.fromJson(Map<String, dynamic> json) {
    final id = asString(json['id']);
    if (id.isEmpty) throw const FormatException('Hadith without id');
    final words = json['words_meanings'];
    return HadithDetailsDto(
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
                .map((e) => WordMeaningDto.fromJson(asMap(e, 'word meaning')))
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
  final List<WordMeaningDto> wordsMeanings;
  final String reference;

  HadithDetails toEntity() => HadithDetails(
    id: id,
    title: title,
    hadeeth: hadeeth,
    intro: intro,
    attribution: attribution,
    grade: grade,
    explanation: explanation,
    hints: hints,
    categories: categories,
    translations: translations,
    wordsMeanings: [for (final w in wordsMeanings) w.toEntity()],
    reference: reference,
  );
}
