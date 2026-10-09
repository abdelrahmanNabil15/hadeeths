/// The permissions Phase 3 may need. A permission is requested only when the user turns
/// on the feature that needs it, never at launch.
enum AppPermission {
  /// Precise or approximate location, only while the app is open, for prayer times and Qibla.
  location,

  /// Showing notifications (prayer, salawat and tracker reminders).
  notifications,

  /// Android "Alarms & reminders" access for exact timing. Optional; reminders still work
  /// without it, at a slightly less precise time.
  exactAlarms,
}

/// Where a permission stands, in terms the UI needs rather than a plugin's vocabulary.
enum PermissionState {
  /// The feature may use it.
  granted,

  /// Not granted, and the system will still show its prompt if asked.
  denied,

  /// Not granted, and the system will not show its prompt again. Only the system
  /// settings can change it.
  permanentlyDenied,

  /// This device or OS version cannot grant it (for example no location hardware, or
  /// the platform does not have this permission). Treated as "feature unavailable".
  unavailable,
}

/// A thin wrapper over the platform. One implementation per plugin lives next to the
/// feature that needs it (location with the prayer feature, notifications with
/// reminders); the rest of the app, and every test, uses this interface.
abstract interface class PermissionGateway {
  /// Current state, without prompting the user.
  Future<PermissionState> status(AppPermission permission);

  /// Shows the system prompt (or the system settings page for [AppPermission.exactAlarms])
  /// and returns the resulting state. Callers go through [PermissionFlow.ensure].
  Future<PermissionState> request(AppPermission permission);

  /// Opens this app's page in the system settings. Returns whether it could be opened.
  Future<bool> openAppSettings();
}
