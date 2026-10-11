import 'package:mynewapp/core/platform/home_widget_bridge.dart';
import 'package:mynewapp/features/prayer_times/domain/reminder_service.dart';

/// Keeps the home-screen widget in step with the reminders: every time the reminders are rebuilt
/// (app start and return, a change of place, method, language or numerals) the widget gets a fresh
/// copy of the times, and "Delete all my data" (which cancels reminders) clears it.
///
/// The widget is a convenience: a failure to update it never fails the reminders.
class WidgetUpdatingReminderService implements ReminderService {
  WidgetUpdatingReminderService({
    required this._inner,
    required this._bridge,
    required this._snapshot,
  });

  final ReminderService _inner;
  final HomeWidgetBridge _bridge;

  /// The text the widget should show now, or null when there is nothing to show (no place).
  final Future<String?> Function() _snapshot;

  @override
  Future<ReminderStatus> reconcile() async {
    final status = await _inner.reconcile();
    await refreshWidget();
    return status;
  }

  /// Writes a fresh copy of the times to the widget.
  Future<void> refreshWidget() async {
    try {
      final text = await _snapshot();
      if (text == null) {
        await _bridge.clear();
      } else {
        await _bridge.update(text);
      }
    } on Object {
      // The widget keeps what it had; the next reconcile tries again.
    }
  }

  @override
  Future<ReminderStatus> status() => _inner.status();

  @override
  Future<void> sendTest() => _inner.sendTest();

  @override
  Future<void> cancelAll() async {
    await _inner.cancelAll();
    try {
      await _bridge.clear();
    } on Object {
      // Nothing more to do: the widget will be cleared on the next start.
    }
  }
}
