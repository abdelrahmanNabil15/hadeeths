import 'dart:async';

import 'package:mynewapp/core/platform/app_version_source.dart';
import 'package:mynewapp/core/platform/review_gateway.dart';
import 'package:mynewapp/core/time/clock.dart';
import 'package:mynewapp/features/app_review/domain/review_actions.dart';
import 'package:mynewapp/features/app_review/domain/review_policy.dart';
import 'package:mynewapp/features/app_review/domain/review_state.dart';
import 'package:mynewapp/features/app_review/domain/review_store.dart';

/// Keeps the rating prompt's memory and decides, at the moment the user is back on the hadith
/// home screen, whether to ask the system to show its rating sheet.
///
/// Every change to the memory goes through one queue, so two quick events can never overwrite
/// each other. A request is recorded before it is made, so a crash cannot make it repeat. Nothing
/// is shown by the app itself: only the system's own sheet, and only when [maybeRequest] finds the
/// rules satisfied at that moment.
class ReviewCoordinator implements ReviewActions {
  ReviewCoordinator({
    required this.store,
    required this.gateway,
    required this.versions,
    this.clock = const SystemClock(),
    this.policy = const ReviewPolicy(),
    this.automatic = true,
    this.canInterrupt,
  });

  final ReviewStore store;
  final ReviewGateway gateway;
  final AppVersionSource versions;
  final Clock clock;
  final ReviewPolicy policy;

  /// Whether the app may ask by itself. Off, only the manual entry works.
  final bool automatic;

  /// Whether nothing the user is doing right now should be left alone (a due prayer, a download).
  /// Asked just before the rules are, at the moment of asking.
  final Future<bool> Function()? canInterrupt;

  ReviewState? _state;
  String? _version;
  Future<void> _queue = Future.value();
  bool _requesting = false;

  /// The memory as it is now (loaded on first use). For tests and diagnostics.
  Future<ReviewState> get state => _run(_load);

  Future<ReviewState> _load() async => _state ??= await store.load();

  Future<T> _run<T>(Future<T> Function() job) {
    final done = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        done.complete(await job());
      } on Object catch (error, stack) {
        done.completeError(error, stack);
      }
    });
    return done.future;
  }

  Future<void> _change(ReviewState Function(ReviewState) change) => _run(
    () async {
      final next = change(await _load());
      _state = next;
      try {
        await store.save(next);
      } on Object {
        // Kept in memory for this run; losing a counter only delays a request.
      }
    },
  );

  /// The app was opened: records the first time and today as a day of use.
  Future<void> start() => _change((s) => policy.recordUse(s, clock.now()));

  @override
  void recordAction(String key) {
    unawaited(
      _change(
        (s) => policy.recordAction(s, key, clock.now()),
      ).catchError((Object _) {}),
    );
  }

  /// "Delete all my data": forgets everything, then starts counting again from now.
  Future<void> forget() => _run(() async {
    _state = null;
    await store.clear();
    _state = policy.recordUse(ReviewState.fresh, clock.now());
    try {
      await store.save(_state!);
    } on Object {
      // Kept in memory.
    }
  });

  /// Called when the user is back on the hadith home screen. Asks the system for its rating
  /// sheet only if every rule holds right now; returns why not otherwise (null when automatic
  /// requests are off or one is already being considered). The system may still show nothing:
  /// the app is never told whether the user rated, and does not retry.
  Future<ReviewDecision?> maybeRequest() async {
    if (!automatic || _requesting) return null;
    _requesting = true;
    try {
      final guard = canInterrupt;
      if (guard != null && !await guard()) return null;
      final version = _version ??= await versions.version();
      return await _run(() async {
        final state = await _load();
        // The rules are read at this instant, after everything above has been waited for.
        final now = clock.now();
        final decision = policy.evaluate(state, now, version);
        if (decision != ReviewDecision.eligible) return decision;
        final available = await gateway.isAvailable();
        // Recorded first: a request that shows nothing still holds back the next one.
        final next = policy.recordRequest(
          state,
          now,
          version!,
          counted: available,
        );
        _state = next;
        try {
          await store.save(next);
        } on Object {
          // Kept in memory for this run.
        }
        if (available) await gateway.requestReview();
        return decision;
      });
    } finally {
      _requesting = false;
    }
  }

  @override
  bool get manualAvailable => gateway.canOpenStoreListing;

  @override
  Future<void> rateNow() => gateway.openStoreListing();
}
