import 'package:equatable/equatable.dart';

import 'json_helpers.dart';

/// A hadith as listed inside a category: only an id and a title are provided.
class HadithSummary extends Equatable {
  const HadithSummary({required this.id, required this.title});

  factory HadithSummary.fromJson(Map<String, dynamic> json) {
    final id = asString(json['id']);
    if (id.isEmpty) throw const FormatException('Hadith without id');
    return HadithSummary(id: id, title: asString(json['title']));
  }

  final String id;
  final String title;

  @override
  List<Object?> get props => [id, title];
}

/// One page of a category's hadith list together with the server's paging metadata.
///
/// [totalItems] is informational only. Rendering must always use `items.length`.
class HadithPage extends Equatable {
  const HadithPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.totalItems,
  });

  factory HadithPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['data'];
    final items = rawItems == null
        ? <HadithSummary>[]
        : asList(
            rawItems,
            'data',
          ).map((e) => HadithSummary.fromJson(asMap(e, 'hadith'))).toList();
    final meta = json['meta'] == null
        ? <String, dynamic>{}
        : asMap(json['meta'], 'meta');
    final currentPage = asInt(meta['current_page'], 1);
    return HadithPage(
      items: items,
      currentPage: currentPage,
      lastPage: asInt(meta['last_page'], currentPage),
      totalItems: asInt(meta['total_items'], items.length),
    );
  }

  final List<HadithSummary> items;
  final int currentPage;
  final int lastPage;
  final int totalItems;

  @override
  List<Object?> get props => [items, currentPage, lastPage, totalItems];
}
