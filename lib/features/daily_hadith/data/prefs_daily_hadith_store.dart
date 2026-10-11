import 'dart:convert';

import 'package:mynewapp/features/daily_hadith/domain/daily_hadith_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [DailyHadithStore] in shared preferences, as one small JSON entry: the remember switch, up to 50
/// category ids, the picks of the last two days and 60 days of shown ids. Ids and dates only.
///
/// Kept out of the user database on purpose: it is tiny, and a database migration here would
/// collide with the Quran section's migration that is still waiting to be merged.
class PrefsDailyHadithStore implements DailyHadithStore {
  PrefsDailyHadithStore(this._preferences);

  final SharedPreferences _preferences;

  static const storageKey = 'daily_hadith_v1';

  Map<String, dynamic> _read() {
    final text = _preferences.getString(storageKey);
    if (text == null) return {};
    try {
      final json = jsonDecode(text);
      return json is Map<String, dynamic> ? json : {};
    } on FormatException {
      return {};
    }
  }

  Future<void> _write(Map<String, dynamic> json) =>
      _preferences.setString(storageKey, jsonEncode(json));

  static List<String> _strings(Object? value) => [
    if (value is List)
      for (final v in value)
        if (v is String) v,
  ];

  static List<Map<String, dynamic>> _maps(Object? value) => [
    if (value is List)
      for (final v in value)
        if (v is Map<String, dynamic>) v,
  ];

  @override
  Future<bool> remembersOpened() async => _read()['remember'] != false;

  @override
  Future<void> setRemembersOpened(bool on) async {
    final json = _read()..['remember'] = on;
    if (!on) json['opened'] = <String>[];
    await _write(json);
  }

  @override
  Future<List<String>> openedCategories() async {
    final json = _read();
    if (json['remember'] == false) return const [];
    return _strings(json['opened']);
  }

  @override
  Future<void> recordOpened(String categoryId) async {
    final json = _read();
    if (json['remember'] == false) return;
    final opened = [
      categoryId,
      for (final id in _strings(json['opened']))
        if (id != categoryId) id,
    ].take(DailyHadithStore.maxOpened).toList();
    await _write(json..['opened'] = opened);
  }

  @override
  Future<DailyPick?> pickFor(String day, String language) async {
    for (final p in _maps(_read()['picks'])) {
      if (p['day'] == day && p['language'] == language) {
        final id = p['id'];
        final category = p['category'];
        final page = p['page'];
        if (id is String && category is String && page is int) {
          return DailyPick(
            day: day,
            language: language,
            hadithId: id,
            categoryId: category,
            page: page,
            fromOpened: p['fromOpened'] == true,
          );
        }
      }
    }
    return null;
  }

  @override
  Future<void> savePick(DailyPick pick) async {
    final json = _read();
    // Keep the picks of this day and the one before (yesterday's category is not repeated).
    final days = {pick.day, _previousDay(pick.day)};
    final picks = [
      for (final p in _maps(json['picks']))
        if (days.contains(p['day']) &&
            !(p['day'] == pick.day && p['language'] == pick.language))
          p,
      {
        'day': pick.day,
        'language': pick.language,
        'id': pick.hadithId,
        'category': pick.categoryId,
        'page': pick.page,
        'fromOpened': pick.fromOpened,
      },
    ];
    final cutoff = _dayBefore(pick.day, DailyHadithStore.historyDays);
    final history = [
      for (final h in _maps(json['history']))
        if (h['day'] is String && (h['day'] as String).compareTo(cutoff) >= 0)
          h,
      {'day': pick.day, 'id': pick.hadithId},
    ];
    await _write(
      json
        ..['picks'] = picks
        ..['history'] = history,
    );
  }

  @override
  Future<Set<String>> shownBefore(String day) async {
    final cutoff = _dayBefore(day, DailyHadithStore.historyDays);
    return {
      for (final h in _maps(_read()['history']))
        if (h['day'] is String &&
            (h['day'] as String).compareTo(cutoff) >= 0 &&
            (h['day'] as String).compareTo(day) < 0 &&
            h['id'] is String)
          h['id'] as String,
    };
  }

  @override
  Future<void> clear() => _preferences.remove(storageKey);

  static String _previousDay(String day) => _dayBefore(day, 1);

  static String _dayBefore(String day, int days) {
    final date = DateTime.parse(
      '${day}T00:00:00Z',
    ).subtract(Duration(days: days));
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
