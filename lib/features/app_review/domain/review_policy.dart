import 'package:mynewapp/features/app_review/domain/review_state.dart';

/// Why a request may not be made now (or [eligible]).
enum ReviewDecision {
  eligible,
  noPendingAction,
  tooFewDays,
  tooNew,
  tooFewActions,
  cooldown,
  lifetimeLimit,
  sameVersion,
  unknownVersion,
}

/// When the app may ask the system to show its rating sheet, and how its memory changes. Pure
/// Dart: every function takes the time it should use, so tests control it.
///
/// An automatic request needs all of: a completed action since the last request, enough days of
/// use, enough time since install, enough completed actions, a long wait since the last request,
/// fewer than the lifetime limit, and an app version that has not asked yet. A clock that moved
/// backwards can only make the app wait longer, never ask sooner.
class ReviewPolicy {
  const ReviewPolicy({
    this.minUsageDays = 3,
    this.minInstallDays = 5,
    this.minActions = 15,
    this.cooldownDays = 90,
    this.maxRequests = 3,
  });

  final int minUsageDays;
  final int minInstallDays;
  final int minActions;
  final int cooldownDays;
  final int maxRequests;

  static const _maxDays = 400;
  static const _maxKeys = 500;
  static const _maxRequests = 20;
  static const _maxActions = 1000000;

  /// `yyyy-mm-dd` of [moment] in UTC.
  static String dayKey(DateTime moment) {
    final utc = moment.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-${two(utc.day)}';
  }

  /// The app was opened at [now]: remembers the first time, today as a day of use, and repairs
  /// anything the clock made impossible (a first time or a day in the future).
  ReviewState recordUse(ReviewState state, DateTime now) {
    final instant = now.toUtc();
    final today = dayKey(instant);
    var first = state.firstSeen;
    if (first == null || first.isAfter(instant)) first = instant;
    final days = {
      for (final d in state.usageDays)
        if (d.compareTo(today) <= 0) d,
      today,
    }.toList()..sort();
    final requests = [...state.requests];
    if (state.lostHistory) {
      requests.add(
        ReviewRequest(at: instant, version: 'unknown', counted: false),
      );
    }
    return state.copyWith(
      firstSeen: first,
      usageDays: days.length > _maxDays
          ? days.sublist(days.length - _maxDays)
          : days,
      requests: requests.length > _maxRequests
          ? requests.sublist(requests.length - _maxRequests)
          : requests,
      lostHistory: false,
    );
  }

  /// A qualifying action, identified by [key], was completed. Counted once per key per day.
  ReviewState recordAction(ReviewState state, String key, DateTime now) {
    final today = dayKey(now);
    final keys = state.actionDay == today ? state.actionKeys : const <String>[];
    if (keys.contains(key) || keys.length >= _maxKeys) {
      return state.actionDay == today
          ? state
          : state.copyWith(actionDay: today, actionKeys: const []);
    }
    return state.copyWith(
      actionDay: today,
      actionKeys: [...keys, key],
      actions: state.actions >= _maxActions ? _maxActions : state.actions + 1,
      pendingAction: true,
    );
  }

  /// Whether to ask now. [version] is the app's version, or null when it cannot be read (then
  /// the answer is never yes: the version rule could not be kept).
  ReviewDecision evaluate(ReviewState state, DateTime now, String? version) {
    final instant = now.toUtc();
    if (version == null || version.isEmpty) {
      return ReviewDecision.unknownVersion;
    }
    if (!state.pendingAction) return ReviewDecision.noPendingAction;
    final today = dayKey(instant);
    final days = state.usageDays.where((d) => d.compareTo(today) <= 0).length;
    if (days < minUsageDays) return ReviewDecision.tooFewDays;
    final first = state.firstSeen;
    if (first == null ||
        instant.difference(first) < Duration(days: minInstallDays)) {
      return ReviewDecision.tooNew;
    }
    if (state.actions < minActions) return ReviewDecision.tooFewActions;
    if (state.requests.where((r) => r.counted).length >= maxRequests) {
      return ReviewDecision.lifetimeLimit;
    }
    if (state.requests.any((r) => r.version == version)) {
      return ReviewDecision.sameVersion;
    }
    if (state.requests.isNotEmpty) {
      final last = state.requests
          .map((r) => r.at)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      // A negative difference (the clock went back) is shorter than the wait too.
      if (instant.difference(last) < Duration(days: cooldownDays)) {
        return ReviewDecision.cooldown;
      }
    }
    return ReviewDecision.eligible;
  }

  /// A request was made at [now] by [version]. [counted] is false when the system could not show
  /// the sheet at all: it still holds back the next request, but is not one of the few allowed.
  /// Never means "the user rated": the app cannot know that.
  ReviewState recordRequest(
    ReviewState state,
    DateTime now,
    String version, {
    bool counted = true,
  }) {
    final requests = [
      ...state.requests,
      ReviewRequest(at: now.toUtc(), version: version, counted: counted),
    ];
    return state.copyWith(
      pendingAction: false,
      requests: requests.length > _maxRequests
          ? requests.sublist(requests.length - _maxRequests)
          : requests,
    );
  }
}
