import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mynewapp/core/notifications/notification_gateway.dart';
import 'package:mynewapp/core/notifications/notification_planner.dart';
import 'package:mynewapp/core/permissions/permission_gateway.dart';
import 'package:timezone/timezone.dart' as tz;

/// The real notifications, through `flutter_local_notifications` (BSD-3).
///
/// - Times are handed over as absolute instants (UTC), so a change of the phone's time zone never
///   moves a reminder. The plugin's boot receiver puts them back after a restart.
/// - Android: by default notifications are scheduled **inexactly** (`inexactAllowWhileIdle`). That
///   needs no special permission, but the system gives such an alarm a window (observed: one hour),
///   so a reminder can arrive late. With the user's opt-in and the "Alarms & reminders" permission
///   they are scheduled exactly (`exactAllowWhileIdle`) and arrive on the minute.
/// - Nothing here reads, stores or logs where the user is.
class LocalNotificationsGateway implements NotificationGateway {
  LocalNotificationsGateway({
    FlutterLocalNotificationsPlugin? plugin,
    NotificationSoundResolver? soundResolver,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       // ignore: prefer_initializing_formals
       _soundResolver = soundResolver;

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationSoundResolver? _soundResolver;
  Future<bool?>? _initialised;
  ChannelLabels? _labels;

  /// The channels made for a downloaded recording during this run.
  final _recordingChannels = <String>{};

  /// Starts the plugin once. It never asks for a permission by itself.
  Future<bool?> _ensureInitialised() => _initialised ??= _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> prepare(ChannelLabels labels) async {
    _labels = labels;
    await _ensureInitialised();
    final android = _android;
    if (android == null) return;
    // Android keeps a channel's sound and vibration fixed once created, so each combination is its
    // own channel. Re-creating one only refreshes its name and description.
    for (final sound in NotificationSound.values) {
      for (final vibrate in const [true, false]) {
        await android.createNotificationChannel(
          AndroidNotificationChannel(
            _channelId(sound, vibrate),
            _channelName(labels, sound, vibrate),
            description: labels.description,
            importance: Importance.high,
            playSound: sound == NotificationSound.system,
            enableVibration: vibrate,
          ),
        );
      }
    }
  }

  static String _channelId(NotificationSound sound, bool vibrate) =>
      'prayer_${sound.name}_${vibrate ? 'vibrate' : 'still'}';

  static String _channelName(
    ChannelLabels labels,
    NotificationSound sound,
    bool vibrate,
  ) => switch ((sound, vibrate)) {
    (NotificationSound.system, true) => labels.soundAndVibration,
    (NotificationSound.system, false) => labels.soundOnly,
    (NotificationSound.silent, true) => labels.vibrationOnly,
    (NotificationSound.silent, false) => labels.silent,
  };

  /// A downloaded recording is a channel of its own: Android fixes a channel's sound when it is made,
  /// and the recording's location is part of the channel's name, so a recording downloaded again
  /// (which gets a new location) gets a new channel. Returns null when the recording cannot be used
  /// (not Android, not found, no resolver): the caller then uses the system sound.
  Future<NotificationDetails?> _recordingDetails(
    NotificationContent content,
  ) async {
    final custom = content.customSound;
    final resolver = _soundResolver;
    final android = _android;
    if (custom == null ||
        resolver == null ||
        android == null ||
        content.sound != NotificationSound.system) {
      return null;
    }
    final uri = await resolver.uriFor(custom.id);
    if (uri == null) return null;
    final id =
        'prayer_adhan_${custom.id}_${fnv1a31(uri).toRadixString(16)}_'
        '${content.vibrate ? 'vibrate' : 'still'}';
    final labels = _labels;
    final name = labels == null
        ? custom.label
        : '${content.vibrate ? labels.soundAndVibration : labels.soundOnly}'
              ' - ${custom.label}';
    final sound = UriAndroidNotificationSound(uri);
    if (_recordingChannels.add(id)) {
      // Older channels of the same recording point at a location that no longer exists.
      final stale = [
        for (final c
            in await android.getNotificationChannels() ??
                const <AndroidNotificationChannel>[])
          if (c.id.startsWith('prayer_adhan_${custom.id}_') && c.id != id) c.id,
      ];
      for (final old in stale) {
        await android.deleteNotificationChannel(channelId: old);
      }
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          id,
          name,
          description: labels?.description,
          importance: Importance.high,
          playSound: true,
          sound: sound,
          enableVibration: content.vibrate,
        ),
      );
    }
    return NotificationDetails(
      android: AndroidNotificationDetails(
        id,
        name,
        channelDescription: labels?.description,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: sound,
        enableVibration: content.vibrate,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );
  }

  /// A sound that ships with the app plays through a channel of its own, for the same reason. Null
  /// when there is none or this is not Android.
  Future<NotificationDetails?> _bundledDetails(
    NotificationContent content,
  ) async {
    final bundled = content.bundledSound;
    final android = _android;
    if (bundled == null ||
        android == null ||
        content.sound != NotificationSound.system) {
      return null;
    }
    final id =
        'prayer_raw_${bundled.resource}_${content.vibrate ? 'vibrate' : 'still'}';
    final labels = _labels;
    final name = labels == null
        ? bundled.label
        : '${content.vibrate ? labels.soundAndVibration : labels.soundOnly}'
              ' - ${bundled.label}';
    final sound = RawResourceAndroidNotificationSound(bundled.resource);
    final importance = bundled.alarm ? Importance.max : Importance.high;
    final usage = bundled.alarm
        ? AudioAttributesUsage.alarm
        : AudioAttributesUsage.notification;
    if (_recordingChannels.add(id)) {
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          id,
          name,
          description: labels?.description,
          importance: importance,
          playSound: true,
          sound: sound,
          enableVibration: content.vibrate,
          audioAttributesUsage: usage,
        ),
      );
    }
    return NotificationDetails(
      android: AndroidNotificationDetails(
        id,
        name,
        channelDescription: labels?.description,
        importance: importance,
        priority: Priority.high,
        playSound: true,
        sound: sound,
        enableVibration: content.vibrate,
        audioAttributesUsage: usage,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );
  }

  Future<NotificationDetails> _detailsFor(NotificationContent content) async =>
      await _recordingDetails(content) ??
      await _bundledDetails(content) ??
      _details(content);

  NotificationDetails _details(NotificationContent content) {
    final labels = _labels;
    final id = _channelId(content.sound, content.vibrate);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        id,
        labels == null
            ? id
            : _channelName(labels, content.sound, content.vibrate),
        channelDescription: labels?.description,
        importance: Importance.high,
        priority: Priority.high,
        playSound: content.sound == NotificationSound.system,
        enableVibration: content.vibrate,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: content.sound == NotificationSound.system,
      ),
    );
  }

  @override
  Future<List<PendingEntry>> pending() async {
    await _ensureInitialised();
    final requests = await _plugin.pendingNotificationRequests();
    return [
      for (final r in requests) PendingEntry(id: r.id, payload: r.payload),
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
    await _ensureInitialised();
    // Exact only when the system allows it; otherwise fall back to the inexact mode.
    final useExact = exact && await exactAlarmsAllowed();
    await _plugin.zonedSchedule(
      id: id,
      title: content.title,
      body: content.body,
      scheduledDate: tz.TZDateTime.fromMillisecondsSinceEpoch(
        tz.UTC,
        fireAt.millisecondsSinceEpoch,
      ),
      notificationDetails: await _detailsFor(content),
      androidScheduleMode: useExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _ensureInitialised();
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> showNow({
    required int id,
    required NotificationContent content,
  }) async {
    await _ensureInitialised();
    await _plugin.show(
      id: id,
      title: content.title,
      body: content.body,
      notificationDetails: await _detailsFor(content),
    );
  }

  @override
  Future<bool> notificationsAllowed() async {
    await _ensureInitialised();
    final android = _android;
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = _ios;
    if (ios != null) return (await ios.checkPermissions())?.isEnabled ?? false;
    return false;
  }

  @override
  Future<bool> exactAlarmsAllowed() async {
    await _ensureInitialised();
    final android = _android;
    if (android == null) return true;
    return await android.canScheduleExactNotifications() ?? false;
  }

  /// Opens the Android page where the user can allow "Alarms & reminders" for the app. Returns
  /// whether exact alarms are allowed afterwards.
  Future<bool> requestExactAlarms() async {
    await _ensureInitialised();
    final android = _android;
    if (android == null) return true;
    return await android.requestExactAlarmsPermission() ?? false;
  }

  /// Asks the system for permission to show notifications (Android 13 and later show a prompt;
  /// iOS always does the first time). Returns whether it was granted.
  Future<bool> requestPermission() async {
    await _ensureInitialised();
    final android = _android;
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _ios;
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }
}

/// Notification and exact-alarm permission through the same plugin. Location is not handled here
/// (it reports "unavailable").
///
/// Neither platform says whether a refusal was final, so a refusal is reported as `denied`; the
/// screen offers the system settings in that case.
class NotificationPermissionGateway implements PermissionGateway {
  NotificationPermissionGateway(this._notifications);

  final LocalNotificationsGateway _notifications;

  @override
  Future<PermissionState> status(AppPermission permission) async {
    try {
      return switch (permission) {
        AppPermission.notifications =>
          await _notifications.notificationsAllowed()
              ? PermissionState.granted
              : PermissionState.denied,
        AppPermission.exactAlarms =>
          await _notifications.exactAlarmsAllowed()
              ? PermissionState.granted
              : PermissionState.denied,
        AppPermission.location => PermissionState.unavailable,
      };
    } on Object {
      return PermissionState.unavailable;
    }
  }

  @override
  Future<PermissionState> request(AppPermission permission) async {
    try {
      return switch (permission) {
        AppPermission.notifications =>
          await _notifications.requestPermission()
              ? PermissionState.granted
              : PermissionState.denied,
        // Opens the system page "Alarms & reminders" and reports whether it was allowed.
        AppPermission.exactAlarms =>
          await _notifications.requestExactAlarms()
              ? PermissionState.granted
              : PermissionState.denied,
        AppPermission.location => PermissionState.unavailable,
      };
    } on Object {
      return PermissionState.denied;
    }
  }

  /// The system settings page is opened by the composite gateway (through geolocator's
  /// `openAppSettings`), so nothing is done here.
  @override
  Future<bool> openAppSettings() async => false;
}
