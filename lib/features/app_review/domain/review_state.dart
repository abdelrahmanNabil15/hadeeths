import 'package:equatable/equatable.dart';

/// One time the app asked the system to show its rating sheet.
class ReviewRequest extends Equatable {
  const ReviewRequest({
    required this.at,
    required this.version,
    this.counted = true,
  });

  /// When it was asked (UTC).
  final DateTime at;

  /// The app version that asked, such as `1.1.0+2`.
  final String version;

  /// Whether it counts towards the lifetime limit. A request the system could not show at all
  /// (or one made after the stored history was lost) still holds back the next one, but does not
  /// use up one of the few automatic requests.
  final bool counted;

  @override
  List<Object?> get props => [at, version, counted];
}

/// Everything the rating prompt remembers, all on the phone: when the app was first seen, the
/// days it was used, how many completed actions the user made, and the requests already made.
/// No content, no identifiers, nothing about what was read.
class ReviewState extends Equatable {
  const ReviewState({
    this.firstSeen,
    this.usageDays = const [],
    this.actions = 0,
    this.pendingAction = false,
    this.actionDay = '',
    this.actionKeys = const [],
    this.requests = const [],
    this.lostHistory = false,
  });

  /// Nothing known yet.
  static const fresh = ReviewState();

  /// The first time the app was used (UTC); null before the first launch is recorded.
  final DateTime? firstSeen;

  /// Distinct days of use, as `yyyy-mm-dd` in UTC, oldest first.
  final List<String> usageDays;

  /// Qualifying completed actions so far.
  final int actions;

  /// A qualifying action has happened since the last request, so a request is worth considering
  /// when the user is next back on the hadith home screen.
  final bool pendingAction;

  /// The day [actionKeys] belongs to. An action is counted once per key per day, so a repeated
  /// tap or a reopened page does not count twice.
  final String actionDay;
  final List<String> actionKeys;

  final List<ReviewRequest> requests;

  /// The saved memory could not be read. Nothing is guessed: the policy replaces this with a
  /// request made "now", which holds back automatic requests for the usual waiting time.
  final bool lostHistory;

  ReviewState copyWith({
    DateTime? firstSeen,
    List<String>? usageDays,
    int? actions,
    bool? pendingAction,
    String? actionDay,
    List<String>? actionKeys,
    List<ReviewRequest>? requests,
    bool? lostHistory,
  }) => ReviewState(
    firstSeen: firstSeen ?? this.firstSeen,
    usageDays: usageDays ?? this.usageDays,
    actions: actions ?? this.actions,
    pendingAction: pendingAction ?? this.pendingAction,
    actionDay: actionDay ?? this.actionDay,
    actionKeys: actionKeys ?? this.actionKeys,
    requests: requests ?? this.requests,
    lostHistory: lostHistory ?? this.lostHistory,
  );

  @override
  List<Object?> get props => [
    firstSeen,
    usageDays,
    actions,
    pendingAction,
    actionDay,
    actionKeys,
    requests,
    lostHistory,
  ];
}
