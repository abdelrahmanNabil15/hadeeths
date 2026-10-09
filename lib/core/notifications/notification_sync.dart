import 'dart:convert';

import 'package:mynewapp/core/notifications/notification_gateway.dart';
import 'package:mynewapp/core/notifications/notification_planner.dart';
import 'package:mynewapp/core/notifications/planned_notification.dart';

/// The text attached to every notification the app schedules, so that what the platform holds can
/// be read back, compared with the plan, and told apart from anything else.
abstract final class NotificationPayload {
  static const _version = 1;

  static String encode(PlannedNotification n) => jsonEncode({
    'v': _version,
    'k': n.kind.name,
    'key': n.key,
    'at': n.fireAt.millisecondsSinceEpoch,
    'sig': n.signature,
  });

  /// The notification described by [entry], or null if the entry is not one of ours (or is
  /// unreadable).
  static PlannedNotification? decode(PendingEntry entry) {
    final text = entry.payload;
    if (text == null) return null;
    try {
      final json = jsonDecode(text);
      if (json is! Map<String, dynamic> || json['v'] != _version) return null;
      final kind = NotificationKind.values.where((k) => k.name == json['k']);
      final key = json['key'];
      final at = json['at'];
      final sig = json['sig'];
      if (kind.isEmpty || key is! String || at is! int || sig is! String) {
        return null;
      }
      return PlannedNotification(
        id: entry.id,
        kind: kind.first,
        key: key,
        fireAt: DateTime.fromMillisecondsSinceEpoch(at, isUtc: true),
        signature: sig,
      );
    } on Object {
      return null;
    }
  }
}

/// What a synchronisation did.
class SyncReport {
  const SyncReport({
    this.scheduled = 0,
    this.cancelled = 0,
    this.failed = 0,
    this.kept = 0,
  });

  /// Notifications newly handed to the platform.
  final int scheduled;

  /// Pending notifications of ours that were removed because they are no longer wanted.
  final int cancelled;

  /// Operations the platform refused or that threw. The rest still went through.
  final int failed;

  /// Notifications that were already right and were left alone.
  final int kept;

  /// How many of ours the platform should now be holding.
  int get pendingNow => scheduled + kept;
}

/// Makes the platform's pending notifications match a plan, changing only what differs.
///
/// Safe to run as often as wanted (app start, resume, any setting change): running it twice in a
/// row changes nothing the second time. Only notifications carrying the app's payload are touched.
class NotificationSync {
  const NotificationSync(this._gateway);

  final NotificationGateway _gateway;

  /// [contentFor] builds the text for one planned notification (called only for those that are
  /// actually handed to the platform).
  Future<SyncReport> apply(
    NotificationPlan plan, {
    required NotificationContent Function(PlannedNotification) contentFor,
    bool exact = false,
  }) async {
    final pending = <PlannedNotification>[
      for (final entry in await _gateway.pending())
        ?NotificationPayload.decode(entry),
    ];
    final diff = NotificationPlanner.diff(pending: pending, plan: plan);
    var cancelled = 0;
    var scheduled = 0;
    var failed = 0;
    for (final id in diff.cancel) {
      try {
        await _gateway.cancel(id);
        cancelled++;
      } on Object {
        failed++;
      }
    }
    for (final item in diff.schedule) {
      try {
        await _gateway.schedule(
          id: item.id,
          fireAt: item.fireAt,
          payload: NotificationPayload.encode(item),
          content: contentFor(item),
          exact: exact,
        );
        scheduled++;
      } on Object {
        failed++;
      }
    }
    return SyncReport(
      scheduled: scheduled,
      cancelled: cancelled,
      failed: failed,
      kept: plan.items.length - diff.schedule.length,
    );
  }

  /// Removes every notification of ours (for example when reminders are switched off).
  Future<int> cancelAll() async {
    var removed = 0;
    for (final entry in await _gateway.pending()) {
      if (NotificationPayload.decode(entry) == null) continue;
      try {
        await _gateway.cancel(entry.id);
        removed++;
      } on Object {
        // Keep going: one failure must not leave the others behind.
      }
    }
    return removed;
  }
}
