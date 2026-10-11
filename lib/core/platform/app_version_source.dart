import 'package:flutter/services.dart';

/// The installed app's version, as `name+build` (for example `1.1.0+2`).
abstract interface class AppVersionSource {
  /// The version, or null when the platform cannot say. Never throws.
  Future<String?> version();
}

/// [AppVersionSource] over the `hadeeths/app_info` channel (`MainActivity` on Android,
/// `AppDelegate` on iOS). A small channel instead of a package, because this is the only
/// place the version is needed.
class MethodChannelAppVersionSource implements AppVersionSource {
  MethodChannelAppVersionSource([
    this._channel = const MethodChannel('hadeeths/app_info'),
  ]);

  final MethodChannel _channel;

  @override
  Future<String?> version() async {
    try {
      final value = await _channel.invokeMethod<String>('version');
      return value == null || value.isEmpty ? null : value;
    } on Object {
      return null;
    }
  }
}
