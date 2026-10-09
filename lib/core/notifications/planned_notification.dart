import 'package:equatable/equatable.dart';

/// Which feature asked for a notification. Part of its identity, so two features can
/// never collide on the same slot.
enum NotificationKind { prayer, salawat, tracker }

/// A notification a feature would like to show, before the planner applies the
/// operating-system limits and the user's quiet hours.
///
/// Carries no text: titles and bodies are produced when the plan is handed to the
/// platform, so nothing sensitive is stored in the plan.
class NotificationCandidate extends Equatable {
  NotificationCandidate({
    required this.kind,
    required this.key,
    required this.fireAt,
    this.priority = 0,
    this.respectsQuietHours = true,
    this.signature = '',
  }) {
    if (!fireAt.isUtc) {
      throw ArgumentError.value(fireAt, 'fireAt', 'must be a UTC DateTime');
    }
  }

  final NotificationKind kind;

  /// Distinguishes notifications of one kind, for example `fajr` or `interval`.
  final String key;

  /// The instant to fire, in UTC.
  final DateTime fireAt;

  /// Higher values are kept first when the platform limit forces some to be dropped.
  final int priority;

  /// Whether the user's quiet hours suppress this notification.
  final bool respectsQuietHours;

  /// Describes everything about the notification except when it fires (sound, wording
  /// variant, actions). When it changes the notification is re-scheduled under the same id.
  final String signature;

  /// Same kind, key and minute means the same notification.
  String get identity =>
      '${kind.name}|$key|${fireAt.millisecondsSinceEpoch ~/ Duration.millisecondsPerMinute}';

  @override
  List<Object?> get props => [
    kind,
    key,
    fireAt,
    priority,
    respectsQuietHours,
    signature,
  ];
}

/// A notification that survived planning and has a stable platform id.
class PlannedNotification extends Equatable {
  const PlannedNotification({
    required this.id,
    required this.kind,
    required this.key,
    required this.fireAt,
    required this.signature,
  });

  /// Positive 31-bit id, valid on both Android and iOS.
  final int id;
  final NotificationKind kind;
  final String key;
  final DateTime fireAt;
  final String signature;

  @override
  List<Object?> get props => [id, kind, key, fireAt, signature];
}

/// Why a candidate was not planned.
enum DropReason {
  /// Its time is not after "now".
  notInFuture,

  /// It is further away than the planning horizon (it will be planned on a later run).
  beyondHorizon,

  /// It falls inside the user's quiet hours.
  quietHours,

  /// Another candidate with the same identity was already planned.
  duplicate,

  /// The platform limit on pending notifications was reached.
  overLimit,
}

class DroppedCandidate extends Equatable {
  const DroppedCandidate(this.candidate, this.reason);

  final NotificationCandidate candidate;
  final DropReason reason;

  @override
  List<Object?> get props => [candidate, reason];
}

/// The result of planning: what to have pending, and what was left out and why.
class NotificationPlan extends Equatable {
  const NotificationPlan({required this.items, required this.dropped});

  /// Sorted by fire time, then by id.
  final List<PlannedNotification> items;
  final List<DroppedCandidate> dropped;

  @override
  List<Object?> get props => [items, dropped];
}

/// What must change on the platform to reach a plan from what is currently pending.
class PlanDiff extends Equatable {
  const PlanDiff({required this.cancel, required this.schedule});

  /// Ids that are pending but no longer wanted.
  final List<int> cancel;

  /// Notifications that are new or changed. Scheduling one under an id that is already
  /// pending replaces it.
  final List<PlannedNotification> schedule;

  bool get isEmpty => cancel.isEmpty && schedule.isEmpty;

  @override
  List<Object?> get props => [cancel, schedule];
}
