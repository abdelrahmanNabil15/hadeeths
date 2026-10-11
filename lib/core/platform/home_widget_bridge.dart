import 'dart:async';

import 'package:flutter/services.dart';

/// Talks to the Android home-screen widget. The widget never runs Dart: it shows what was last
/// written here, so the app writes a fresh copy whenever prayer times or their wording change.
abstract interface class HomeWidgetBridge {
  /// Replaces what the widget shows (see `lib/app/widget_snapshot.dart` for the format).
  Future<void> update(String snapshot);

  /// Forgets everything; the widget then asks the user to open the app.
  Future<void> clear();

  /// Offers the widget in the launcher's widget list, or withdraws it.
  Future<void> setEnabled(bool enabled);

  /// The page the app was opened for from the widget (`prayer`), once; null otherwise.
  Future<String?> takeLaunchRoute();

  /// Pages asked for by taps on the widget while the app is already running.
  Stream<String> get routes;
}

/// [HomeWidgetBridge] over the `hadeeths/home_widget` channel (Android only; `MainActivity`).
class MethodChannelHomeWidgetBridge implements HomeWidgetBridge {
  MethodChannelHomeWidgetBridge([
    this._channel = const MethodChannel('hadeeths/home_widget'),
  ]) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openRoute' && call.arguments is String) {
        _routes.add(call.arguments as String);
      }
    });
  }

  final MethodChannel _channel;
  final _routes = StreamController<String>.broadcast();

  @override
  Future<void> update(String snapshot) =>
      _channel.invokeMethod<void>('update', snapshot);

  @override
  Future<void> clear() => _channel.invokeMethod<void>('clear');

  @override
  Future<void> setEnabled(bool enabled) =>
      _channel.invokeMethod<void>('setEnabled', enabled);

  @override
  Future<String?> takeLaunchRoute() =>
      _channel.invokeMethod<String>('takeLaunchRoute');

  @override
  Stream<String> get routes => _routes.stream;
}
