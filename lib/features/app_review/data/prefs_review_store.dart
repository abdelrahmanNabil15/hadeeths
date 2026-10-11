import 'dart:convert';

import 'package:mynewapp/features/app_review/domain/review_state.dart';
import 'package:mynewapp/features/app_review/domain/review_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [ReviewStore] in shared preferences, as one small JSON entry: dates, counters and the app
/// versions that asked. Nothing about content or the user.
///
/// A missing entry is an empty memory. An entry that cannot be read as a whole is reported as
/// lost history, so the policy waits rather than guessing; one bad field falls back to its own
/// default and the rest is kept.
class PrefsReviewStore implements ReviewStore {
  PrefsReviewStore(this._preferences);

  final SharedPreferences _preferences;

  static const storageKey = 'app_review_v1';

  @override
  Future<ReviewState> load() async {
    try {
      final text = _preferences.getString(storageKey);
      if (text == null) return ReviewState.fresh;
      final json = jsonDecode(text);
      if (json is! Map<String, dynamic>) {
        return ReviewState.fresh.copyWith(lostHistory: true);
      }
      final requests = _requests(json['requests']);
      if (requests == null) {
        // The part that keeps the waiting rules is unreadable: do not ask again soon.
        return _decode(json, const []).copyWith(lostHistory: true);
      }
      return _decode(json, requests);
    } on Object {
      return ReviewState.fresh.copyWith(lostHistory: true);
    }
  }

  static ReviewState _decode(
    Map<String, dynamic> json,
    List<ReviewRequest> requests,
  ) {
    final actions = json['actions'];
    final actionDay = json['actionDay'];
    return ReviewState(
      firstSeen: _date(json['firstSeen']),
      usageDays: _strings(json['days']).where(_isDay).toList()..sort(),
      actions: actions is int && actions >= 0 ? actions : 0,
      pendingAction: json['pending'] == true,
      actionDay: actionDay is String && _isDay(actionDay) ? actionDay : '',
      actionKeys: _strings(json['actionKeys']),
      requests: requests,
    );
  }

  static final _dayPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static bool _isDay(String value) => _dayPattern.hasMatch(value);

  static DateTime? _date(Object? value) {
    if (value is! String) return null;
    final parsed = DateTime.tryParse(value);
    return parsed?.toUtc();
  }

  static List<String> _strings(Object? value) => [
    if (value is List)
      for (final v in value)
        if (v is String) v,
  ];

  /// The requests, or null when the list is present but not readable.
  static List<ReviewRequest>? _requests(Object? value) {
    if (value == null) return const [];
    if (value is! List) return null;
    final out = <ReviewRequest>[];
    for (final item in value) {
      if (item is! Map<String, dynamic>) return null;
      final at = _date(item['at']);
      final version = item['version'];
      if (at == null || version is! String || version.isEmpty) return null;
      out.add(
        ReviewRequest(
          at: at,
          version: version,
          counted: item['counted'] != false,
        ),
      );
    }
    return out;
  }

  @override
  Future<void> save(ReviewState state) => _preferences.setString(
    storageKey,
    jsonEncode({
      'firstSeen': state.firstSeen?.toIso8601String(),
      'days': state.usageDays,
      'actions': state.actions,
      'pending': state.pendingAction,
      'actionDay': state.actionDay,
      'actionKeys': state.actionKeys,
      'requests': [
        for (final r in state.requests)
          {
            'at': r.at.toIso8601String(),
            'version': r.version,
            'counted': r.counted,
          },
      ],
    }),
  );

  @override
  Future<void> clear() async {
    await _preferences.remove(storageKey);
  }
}
