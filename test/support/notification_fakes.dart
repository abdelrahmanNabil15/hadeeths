import 'package:mynewapp/core/notifications/notification_gateway.dart';

/// One notification the fake platform is holding.
class FakeScheduled {
  FakeScheduled({
    required this.id,
    required this.fireAt,
    required this.payload,
    required this.content,
    this.exact = false,
  });

  /// Scheduled for delivery on the minute (the system allowed it and it was asked for).
  final bool exact;

  final int id;
  final DateTime fireAt;
  final String payload;
  final NotificationContent content;
}

/// A platform whose notifications live in a map. Counts every call so tests can prove that
/// repeating a synchronisation does nothing.
class FakeNotificationGateway implements NotificationGateway {
  final Map<int, FakeScheduled> held = {};

  /// Notifications that did not come from the app (they must never be touched).
  final List<PendingEntry> foreign = [];

  /// What the user sees right now (the test button).
  final List<NotificationContent> shown = [];

  bool allowed = true;
  bool exactAllowed = true;
  int schedules = 0;
  int cancels = 0;
  int prepares = 0;
  ChannelLabels? labels;

  /// Ids whose scheduling or cancelling should fail.
  final Set<int> failScheduleFor = {};
  final Set<int> failCancelFor = {};

  /// When set, listing pending notifications fails.
  bool failPending = false;

  @override
  Future<void> prepare(ChannelLabels labels) async {
    prepares++;
    this.labels = labels;
  }

  @override
  Future<List<PendingEntry>> pending() async {
    if (failPending) throw StateError('platform unavailable');
    return [
      for (final h in held.values) PendingEntry(id: h.id, payload: h.payload),
      ...foreign,
    ];
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime fireAt,
    required String payload,
    required NotificationContent content,
    bool exact = false,
  }) async {
    if (failScheduleFor.contains(id)) throw StateError('refused');
    schedules++;
    held[id] = FakeScheduled(
      id: id,
      fireAt: fireAt,
      payload: payload,
      content: content,
      exact: exact && exactAllowed,
    );
  }

  @override
  Future<void> cancel(int id) async {
    if (failCancelFor.contains(id)) throw StateError('refused');
    cancels++;
    held.remove(id);
  }

  @override
  Future<void> showNow({
    required int id,
    required NotificationContent content,
  }) async {
    shown.add(content);
  }

  @override
  Future<bool> notificationsAllowed() async => allowed;

  @override
  Future<bool> exactAlarmsAllowed() async => exactAllowed;

  /// The held notifications, soonest first.
  List<FakeScheduled> get sorted =>
      held.values.toList()..sort((a, b) => a.fireAt.compareTo(b.fireAt));
}
