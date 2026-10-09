import 'dart:convert';

import 'package:mynewapp/core/notifications/planned_notification.dart';
import 'package:mynewapp/core/notifications/quiet_hours.dart';
import 'package:mynewapp/core/time/zone.dart';

/// Turns what features would like to notify about into what the platform should hold.
///
/// Pure and deterministic: the same candidates and the same `now` always give the same
/// plan, whatever the order of the candidates. It never talks to the operating system
/// and never reads the clock; the caller passes `now` (from a `Clock`).
///
/// Rules, in order:
/// 1. not after `now` -> [DropReason.notInFuture];
/// 2. later than `now + horizon` -> [DropReason.beyondHorizon] (planned on a later run);
/// 3. inside quiet hours (only for candidates that respect them, judged on the local
///    time of the fire instant) -> [DropReason.quietHours];
/// 4. same identity as one already kept -> [DropReason.duplicate];
/// 5. more than `maxPending` left -> keep the highest priority, then the earliest;
///    the rest are [DropReason.overLimit].
///
/// iOS holds only 64 pending local notifications, so `maxPending` defaults to 60 to
/// leave headroom. Android has no such small limit, but the same window keeps both
/// platforms behaving alike.
class NotificationPlanner {
  const NotificationPlanner({
    required this.zone,
    this.quietHours,
    this.maxPending = 60,
    this.horizon = const Duration(days: 7),
    this.hash = fnv1a31,
  }) : assert(maxPending > 0);

  final TimeZoneRules zone;
  final QuietHours? quietHours;
  final int maxPending;
  final Duration horizon;

  /// Maps an identity to a positive 31-bit id. Replaceable so tests can force collisions.
  final int Function(String identity) hash;

  NotificationPlan plan(
    Iterable<NotificationCandidate> candidates, {
    required DateTime now,
  }) {
    final utcNow = now.toUtc();
    final limit = utcNow.add(horizon);
    final ordered = candidates.toList()..sort(_processingOrder);

    final dropped = <DroppedCandidate>[];
    final seen = <String>{};
    final eligible = <NotificationCandidate>[];
    for (final c in ordered) {
      if (!c.fireAt.isAfter(utcNow)) {
        dropped.add(DroppedCandidate(c, DropReason.notInFuture));
      } else if (c.fireAt.isAfter(limit)) {
        dropped.add(DroppedCandidate(c, DropReason.beyondHorizon));
      } else if (c.respectsQuietHours &&
          (quietHours?.contains(zone.minuteOfDayAt(c.fireAt)) ?? false)) {
        dropped.add(DroppedCandidate(c, DropReason.quietHours));
      } else if (!seen.add(c.identity)) {
        dropped.add(DroppedCandidate(c, DropReason.duplicate));
      } else {
        eligible.add(c);
      }
    }

    var kept = eligible;
    if (eligible.length > maxPending) {
      final byImportance = [...eligible]
        ..sort((a, b) {
          final p = b.priority.compareTo(a.priority);
          if (p != 0) return p;
          final t = a.fireAt.compareTo(b.fireAt);
          return t != 0 ? t : a.identity.compareTo(b.identity);
        });
      kept = byImportance.take(maxPending).toList();
      final keptSet = kept.toSet();
      for (final c in eligible) {
        if (!keptSet.contains(c)) {
          dropped.add(DroppedCandidate(c, DropReason.overLimit));
        }
      }
    }

    final ids = _assignIds(kept);
    final items =
        [
          for (final c in kept)
            PlannedNotification(
              id: ids[c.identity]!,
              kind: c.kind,
              key: c.key,
              fireAt: c.fireAt,
              signature: c.signature,
            ),
        ]..sort((a, b) {
          final t = a.fireAt.compareTo(b.fireAt);
          return t != 0 ? t : a.id.compareTo(b.id);
        });
    return NotificationPlan(items: items, dropped: dropped);
  }

  /// What to cancel and what to (re)schedule so that [pending] becomes [plan].
  /// Applying it twice, or diffing a plan against itself, gives an empty result.
  static PlanDiff diff({
    required Iterable<PlannedNotification> pending,
    required NotificationPlan plan,
  }) {
    final pendingById = {for (final p in pending) p.id: p};
    final wantedIds = {for (final p in plan.items) p.id};
    final cancel = [
      for (final id in pendingById.keys)
        if (!wantedIds.contains(id)) id,
    ]..sort();
    final schedule = [
      for (final item in plan.items)
        if (pendingById[item.id] != item) item,
    ];
    return PlanDiff(cancel: cancel, schedule: schedule);
  }

  int _processingOrder(NotificationCandidate a, NotificationCandidate b) {
    var c = a.fireAt.compareTo(b.fireAt);
    if (c != 0) return c;
    c = a.kind.index.compareTo(b.kind.index);
    if (c != 0) return c;
    c = a.key.compareTo(b.key);
    if (c != 0) return c;
    c = b.priority.compareTo(a.priority);
    if (c != 0) return c;
    return a.signature.compareTo(b.signature);
  }

  /// Identity -> id. Collisions (about one in a million for 60 items) are resolved by
  /// probing upwards in identity order, so the result does not depend on input order.
  Map<String, int> _assignIds(List<NotificationCandidate> kept) {
    final identities = [for (final c in kept) c.identity]..sort();
    final used = <int>{};
    final ids = <String, int>{};
    for (final identity in identities) {
      var id = _clamp(hash(identity));
      while (!used.add(id)) {
        id = id == _maxId ? 1 : id + 1;
      }
      ids[identity] = id;
    }
    return ids;
  }

  static const _maxId = 0x7fffffff;

  static int _clamp(int value) {
    final id = value & _maxId;
    return id == 0 ? 1 : id;
  }
}

/// FNV-1a, 32 bits, reduced to 31 bits. Stable across runs, platforms and releases (unlike
/// `String.hashCode`), so a notification keeps the same id every time it is planned.
/// Requires 64-bit integers (Android and iOS).
int fnv1a31(String text) {
  var h = 0x811c9dc5;
  for (final byte in utf8.encode(text)) {
    h ^= byte;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h & 0x7fffffff;
}
