import 'package:equatable/equatable.dart';

/// The hadith chosen for one day in one language: ids and a page number only, never text from the
/// source.
class DailyPick extends Equatable {
  const DailyPick({
    required this.day,
    required this.language,
    required this.hadithId,
    required this.categoryId,
    required this.page,
    required this.fromOpened,
  });

  /// The local date, `yyyy-MM-dd`.
  final String day;
  final String language;
  final String hadithId;
  final String categoryId;

  /// The list page the hadith was on, so it can be shown again from the saved copy.
  final int page;

  /// Whether it came from a category the user opened (otherwise from the top-level categories).
  final bool fromOpened;

  @override
  List<Object?> get props => [
    day,
    language,
    hadithId,
    categoryId,
    page,
    fromOpened,
  ];
}

/// What the daily hadith remembers on the phone. Nothing here leaves the phone, and "Delete all my
/// data" clears it.
abstract interface class DailyHadithStore {
  /// How many opened categories are kept (the newest).
  static const maxOpened = 50;

  /// How long a shown hadith is avoided.
  static const historyDays = 60;

  /// Whether the categories the user opens are remembered (on by default). Switching it off also
  /// forgets the ones already remembered.
  Future<bool> remembersOpened();
  Future<void> setRemembersOpened(bool on);

  /// Category ids the user opened, newest first. Empty while remembering is off.
  Future<List<String>> openedCategories();

  /// Notes that the user opened a category's hadiths (ignored while remembering is off).
  Future<void> recordOpened(String categoryId);

  Future<DailyPick?> pickFor(String day, String language);

  /// Saves the day's pick and adds its hadith to the history.
  Future<void> savePick(DailyPick pick);

  /// Hadith ids shown on [day] or in the [DailyHadithStore.historyDays] days before it.
  Future<Set<String>> shownBefore(String day);

  Future<void> clear();
}
