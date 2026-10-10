import 'package:equatable/equatable.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/core/time/clock.dart';
import 'package:mynewapp/core/time/zone.dart';
import 'package:mynewapp/features/categories/domain/categories_repository.dart';
import 'package:mynewapp/features/categories/domain/hadith_category.dart';
import 'package:mynewapp/features/daily_hadith/domain/daily_hadith_store.dart';
import 'package:mynewapp/features/daily_hadith/domain/daily_selection.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_page.dart';
import 'package:mynewapp/features/hadiths/domain/hadiths_repository.dart';

/// Today's hadith, ready to show: its title as the source gives it, and where it came from.
class DailyHadith extends Equatable {
  const DailyHadith({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.categoryTitle,
    required this.fromOpened,
  });

  final String id;
  final String title;
  final String categoryId;
  final String categoryTitle;

  /// True when chosen from the categories the user opened, false when from the top-level ones.
  final bool fromOpened;

  @override
  List<Object?> get props => [id, title, categoryId, categoryTitle, fromOpened];
}

/// Chooses and remembers the hadith of the day.
///
/// - The day is the phone's local date; the choice is saved, so the same hadith shows all day even
///   if more categories are opened in the meantime.
/// - Categories: those the user opened (when remembering is on), otherwise the top-level ones, so a
///   new user gets a hadith too. They rotate by day, and yesterday's category is not repeated.
/// - Inside a category the position comes from a stable hash of the day, language and category,
///   skipping hadiths shown in the last [DailyHadithStore.historyDays] days.
/// - At most two list requests (the first page, then the page with the chosen position); both go
///   through the existing saved-copy cache. Nothing runs in the background.
/// - Returns `Success(null)` when there is nothing to choose from (no categories at all).
class DailyHadithService {
  DailyHadithService({
    required this._categories,
    required this._hadiths,
    required this._store,
    this._clock = const SystemClock(),
    this._zone = const DeviceTimeZone(),
  });

  final CategoriesRepository _categories;
  final HadithsRepository _hadiths;
  final DailyHadithStore _store;
  final Clock _clock;
  final TimeZoneRules _zone;

  static const _perPage = HadithsRepository.defaultPageSize;

  Future<Result<DailyHadith?>> today({required String language}) async {
    final date = _zone.localDateAt(_clock.now());
    final day = dayKey(date);
    final categoriesResult = await _categories.getCategories(
      language: language,
    );
    final List<HadithCategory> categories;
    switch (categoriesResult) {
      case Success(:final value):
        categories = value;
      case Err(:final failure):
        return Err(failure);
    }
    final byId = {for (final c in categories) c.id: c};

    final saved = await _store.pickFor(day, language);
    if (saved != null && byId.containsKey(saved.categoryId)) {
      final shown = await _show(saved, byId);
      if (shown != null) return shown;
    }

    final opened = [
      for (final id in await _store.openedCategories())
        if ((byId[id]?.hadithCount ?? 0) > 0) id,
    ];
    final fromOpened = opened.isNotEmpty;
    final pool = fromOpened
        ? opened
        : [
            for (final c in categories)
              if (c.parentId == null && c.hadithCount > 0) c.id,
          ];
    final yesterday = await _store.pickFor(
      dayKey(date.subtract(const Duration(days: 1))),
      language,
    );
    final avoid = await _store.shownBefore(day);

    for (final categoryId in categoryOrder(
      day: dayNumber(date),
      pool: pool,
      yesterday: yesterday?.categoryId,
    )) {
      final first = await _page(categoryId, language, 1);
      switch (first) {
        case Err(:final failure):
          return Err(failure);
        case Success(value: final page):
          if (page.items.isEmpty || page.totalItems <= 0) continue;
          final index = itemIndex(
            day: day,
            language: language,
            categoryId: categoryId,
            count: page.totalItems,
          );
          final pageNumber = index ~/ _perPage + 1;
          var chosenPage = page;
          var offset = index % _perPage;
          if (pageNumber != 1) {
            final other = await _page(categoryId, language, pageNumber);
            if (other is Success<HadithPage> && other.value.items.isNotEmpty) {
              chosenPage = other.value;
            } else {
              offset = 0;
            }
          }
          final ids = [for (final h in chosenPage.items) h.id];
          final at = firstNotShown(ids, offset.clamp(0, ids.length - 1), avoid);
          final hadith = chosenPage.items[at];
          final pick = DailyPick(
            day: day,
            language: language,
            hadithId: hadith.id,
            categoryId: categoryId,
            page: chosenPage.currentPage,
            fromOpened: fromOpened,
          );
          await _store.savePick(pick);
          return Success(
            DailyHadith(
              id: hadith.id,
              title: hadith.title,
              categoryId: categoryId,
              categoryTitle: byId[categoryId]!.title,
              fromOpened: fromOpened,
            ),
          );
      }
    }
    return const Success(null);
  }

  /// The saved pick, from its list page (usually the saved copy); null if it is no longer there.
  Future<Result<DailyHadith?>?> _show(
    DailyPick pick,
    Map<String, HadithCategory> byId,
  ) async {
    final page = await _page(pick.categoryId, pick.language, pick.page);
    switch (page) {
      case Err(:final failure):
        return Err(failure);
      case Success(:final value):
        for (final h in value.items) {
          if (h.id == pick.hadithId) {
            return Success(
              DailyHadith(
                id: h.id,
                title: h.title,
                categoryId: pick.categoryId,
                categoryTitle: byId[pick.categoryId]!.title,
                fromOpened: pick.fromOpened,
              ),
            );
          }
        }
        return null;
    }
  }

  Future<Result<HadithPage>> _page(
    String categoryId,
    String language,
    int page,
  ) => _hadiths.getHadithPage(
    categoryId: categoryId,
    language: language,
    page: page,
    perPage: _perPage,
  );
}
