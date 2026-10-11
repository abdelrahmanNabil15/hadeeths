import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/notifications/notification_gateway.dart';
import 'package:mynewapp/core/notifications/planned_notification.dart';
import 'package:mynewapp/core/permissions/permission_flow.dart';
import 'package:mynewapp/core/permissions/permission_gateway.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_service.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_settings.dart';
import 'package:mynewapp/features/prayer_times/domain/salawat_settings.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/prayer_cubit.dart';

/// Why reminders could not be switched on, for the screen to explain.
enum ReminderProblem {
  /// There is no place yet, so there are no prayer times to remind about.
  needsPlace,

  /// The user closed the explanation, so the system prompt never appeared.
  declined,

  /// The system prompt was refused.
  denied,

  /// Refused for good: only the system settings can change it.
  needsSettings,

  /// This device cannot show notifications.
  unavailable,

  /// Exact timing was asked for but the system did not allow it.
  exactNotAllowed,
}

class RemindersState extends Equatable {
  const RemindersState({
    this.status = const ReminderStatus(),
    this.permission,
    this.problem,
    this.busy = false,
    this.testSent = false,
  });

  /// What is scheduled.
  final ReminderStatus status;

  /// Whether the system lets the app show notifications (null until checked).
  final PermissionState? permission;

  final ReminderProblem? problem;

  /// An operation is running.
  final bool busy;

  /// The test reminder was just shown.
  final bool testSent;

  int get scheduled => status.scheduled;

  PlannedNotification? get next => status.next;

  RemindersState copyWith({
    ReminderStatus? status,
    PermissionState? permission,
    ReminderProblem? problem,
    bool clearProblem = false,
    bool? busy,
    bool? testSent,
  }) => RemindersState(
    status: status ?? this.status,
    permission: permission ?? this.permission,
    problem: clearProblem ? null : problem ?? this.problem,
    busy: busy ?? this.busy,
    testSent: testSent ?? this.testSent,
  );

  @override
  List<Object?> get props => [
    status.scheduled,
    status.next?.id,
    status.failed,
    status.notificationsAllowed,
    status.needsPlace,
    status.exactDenied,
    status.heldBackByQuietHours,
    status.scheduledPrayers,
    status.nextPrayer?.id,
    permission,
    problem,
    busy,
    testSent,
  ];
}

/// The reminders screen's logic. The choices themselves live in the prayer cubit (one saved
/// copy); this adds the permission step and the "what is scheduled" summary.
class RemindersCubit extends Cubit<RemindersState> {
  RemindersCubit({required this.prayer, required this.services})
    : super(const RemindersState());

  final PrayerCubit prayer;
  final PrayerServices services;

  ReminderSettings get _settings => prayer.state.preferences.reminders;

  /// Looks at the system and at what is scheduled; changes nothing.
  Future<void> load() async {
    final permission = await services.permissions.current(
      AppPermission.notifications,
    );
    final status = await services.reminders.status();
    if (isClosed) return;
    emit(
      state.copyWith(
        status: status,
        permission: permission,
        clearProblem: true,
        testSent: false,
      ),
    );
  }

  /// Switches reminders on or off. Switching on first explains, then asks the system; if there is
  /// no place yet or the permission is refused, reminders stay off and the reason is shown.
  Future<void> setEnabled(
    bool enabled, {
    required Future<bool> Function() explain,
  }) async {
    if (!enabled) {
      await _apply(_settings.copyWith(enabled: false));
      return;
    }
    if (prayer.state.preferences.location == null) {
      emit(state.copyWith(problem: ReminderProblem.needsPlace));
      return;
    }
    emit(state.copyWith(busy: true, clearProblem: true));
    final outcome = await services.permissions.ensure(
      AppPermission.notifications,
      explain: explain,
    );
    if (outcome != PermissionOutcome.granted) {
      emit(
        state.copyWith(
          busy: false,
          permission: await services.permissions.current(
            AppPermission.notifications,
          ),
          problem: switch (outcome) {
            PermissionOutcome.declinedExplanation => ReminderProblem.declined,
            PermissionOutcome.denied => ReminderProblem.denied,
            PermissionOutcome.needsSettings => ReminderProblem.needsSettings,
            _ => ReminderProblem.unavailable,
          },
        ),
      );
      return;
    }
    await _apply(_settings.copyWith(enabled: true));
  }

  /// Switches exact timing on or off. Switching on explains first, then opens Android's own page
  /// for "Alarms & reminders"; if it is not allowed the setting stays off and the reason is shown.
  Future<void> setExact(
    bool on, {
    required Future<bool> Function() explain,
  }) async {
    if (!on) {
      await _apply(_settings.copyWith(exactTiming: false));
      return;
    }
    emit(state.copyWith(busy: true, clearProblem: true));
    final outcome = await services.permissions.ensure(
      AppPermission.exactAlarms,
      explain: explain,
    );
    if (outcome != PermissionOutcome.granted) {
      emit(
        state.copyWith(busy: false, problem: ReminderProblem.exactNotAllowed),
      );
      return;
    }
    await _apply(_settings.copyWith(exactTiming: true));
  }

  Future<void> setPrayer(Prayer p, {required bool on}) {
    final chosen = {..._settings.prayers};
    on ? chosen.add(p) : chosen.remove(p);
    return _apply(_settings.copyWith(prayers: chosen));
  }

  Future<void> setLead(int minutes) =>
      _apply(_settings.copyWith(leadMinutes: minutes));

  Future<void> setSound(NotificationSound sound) =>
      _apply(_settings.copyWith(sound: sound));

  Future<void> setVibrate({required bool on}) =>
      _apply(_settings.copyWith(vibrate: on));

  /// Switches salawat reminders on or off. Switching on asks for the notification permission the
  /// same way as prayer reminders; no place is needed, they follow the phone's clock.
  Future<void> setSalawatEnabled(
    bool on, {
    required Future<bool> Function() explain,
  }) async {
    if (on && !await _notificationsAllowed(explain)) return;
    await _apply(
      _settings.copyWith(salawat: _settings.salawat.copyWith(enabled: on)),
    );
  }

  /// Saves a change to the salawat times (interval, window or earlier reminder).
  Future<void> setSalawat(SalawatSettings next) =>
      _apply(_settings.copyWith(salawat: next));

  /// Saves a change to quiet hours.
  Future<void> setQuiet({
    bool? enabled,
    int? startMinute,
    int? endMinute,
    bool? forPrayers,
  }) => _apply(
    _settings.copyWith(
      quietEnabled: enabled,
      quietStartMinute: startMinute,
      quietEndMinute: endMinute,
      quietForPrayers: forPrayers,
    ),
  );

  /// Plans again (changes nothing when nothing changed) so the screen can say what quiet hours hold
  /// back.
  Future<void> refreshPlan() async {
    final status = await services.reminders.reconcile();
    if (!isClosed) emit(state.copyWith(status: status));
  }

  /// Asks for the notification permission when needed; on refusal shows the reason and returns
  /// false.
  Future<bool> _notificationsAllowed(Future<bool> Function() explain) async {
    emit(state.copyWith(busy: true, clearProblem: true));
    final outcome = await services.permissions.ensure(
      AppPermission.notifications,
      explain: explain,
    );
    if (outcome == PermissionOutcome.granted) return true;
    emit(
      state.copyWith(
        busy: false,
        permission: await services.permissions.current(
          AppPermission.notifications,
        ),
        problem: switch (outcome) {
          PermissionOutcome.declinedExplanation => ReminderProblem.declined,
          PermissionOutcome.denied => ReminderProblem.denied,
          PermissionOutcome.needsSettings => ReminderProblem.needsSettings,
          _ => ReminderProblem.unavailable,
        },
      ),
    );
    return false;
  }

  /// Shows a test notification now (asking for permission first if needed).
  Future<void> sendTest({required Future<bool> Function() explain}) async {
    emit(state.copyWith(busy: true, clearProblem: true, testSent: false));
    final outcome = await services.permissions.ensure(
      AppPermission.notifications,
      explain: explain,
    );
    if (outcome != PermissionOutcome.granted) {
      emit(
        state.copyWith(
          busy: false,
          problem: outcome == PermissionOutcome.needsSettings
              ? ReminderProblem.needsSettings
              : ReminderProblem.denied,
        ),
      );
      return;
    }
    await services.reminders.sendTest();
    if (!isClosed) emit(state.copyWith(busy: false, testSent: true));
  }

  Future<void> openSettings() => services.permissions.openSettings();

  Future<void> _apply(ReminderSettings next) async {
    emit(state.copyWith(busy: true, clearProblem: true, testSent: false));
    final status = await prayer.setReminders(next);
    final permission = await services.permissions.current(
      AppPermission.notifications,
    );
    if (isClosed) return;
    emit(state.copyWith(status: status, permission: permission, busy: false));
  }
}
