import 'package:equatable/equatable.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_summary.dart';

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

  final List<HadithSummary> items;
  final int currentPage;
  final int lastPage;
  final int totalItems;

  @override
  List<Object?> get props => [items, currentPage, lastPage, totalItems];
}
