import 'package:flutter/services.dart';

/// Makes a downloaded recording readable by the system's notification service (Android 10 and
/// later). A recording kept in the app's private folder cannot be played by a notification, so it is
/// also listed, under the same name, in the phone's shared "Notifications" sounds.
abstract interface class AdhanSoundBridge {
  /// Whether this phone can do it (Android 10 or later). False elsewhere.
  Future<bool> isSupported();

  /// Lists the file at [path] as the notification sound [name] and returns the address the
  /// notification channel plays. Calling it again for the same [name] returns the same address.
  Future<String?> register(String path, String name);

  /// Removes the sound called [name] from the shared list.
  Future<void> unregister(String name);
}

/// [AdhanSoundBridge] over the `hadeeths/adhan_sound` channel (`MainActivity`, Android only).
class MethodChannelAdhanSoundBridge implements AdhanSoundBridge {
  MethodChannelAdhanSoundBridge([
    this._channel = const MethodChannel('hadeeths/adhan_sound'),
  ]);

  final MethodChannel _channel;

  @override
  Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<String?> register(String path, String name) =>
      _channel.invokeMethod<String>('register', {'path': path, 'name': name});

  @override
  Future<void> unregister(String name) =>
      _channel.invokeMethod<void>('unregister', {'name': name});
}
