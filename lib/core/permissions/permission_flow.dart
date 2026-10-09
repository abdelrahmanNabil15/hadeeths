import 'package:mynewapp/core/permissions/permission_gateway.dart';

/// What happened when a feature asked for a permission.
enum PermissionOutcome {
  /// Granted (already, or just now). Go ahead.
  granted,

  /// The user declined our explanation, so the system prompt was never shown. The
  /// feature stays off; asking again later is fine.
  declinedExplanation,

  /// The system prompt was shown and refused. The feature stays off.
  denied,

  /// Refused earlier and the system will not ask again. Offer the settings page.
  needsSettings,

  /// Not possible on this device.
  unavailable,
}

/// The one way features obtain a permission, so every flow behaves the same:
///
/// 1. already granted -> nothing is shown;
/// 2. unavailable, or permanently denied -> nothing is requested (the UI explains and may
///    offer the settings page);
/// 3. otherwise the feature's own explanation is shown first (`explain`), and the system
///    prompt appears only if the user agrees.
///
/// Nothing here throws on denial: a refused permission is an ordinary outcome, never a crash.
class PermissionFlow {
  const PermissionFlow(this._gateway);

  final PermissionGateway _gateway;

  Future<PermissionOutcome> ensure(
    AppPermission permission, {
    required Future<bool> Function() explain,
  }) async {
    final current = await _gateway.status(permission);
    switch (current) {
      case PermissionState.granted:
        return PermissionOutcome.granted;
      case PermissionState.unavailable:
        return PermissionOutcome.unavailable;
      case PermissionState.permanentlyDenied:
        return PermissionOutcome.needsSettings;
      case PermissionState.denied:
        break;
    }
    if (!await explain()) return PermissionOutcome.declinedExplanation;
    final result = await _gateway.request(permission);
    switch (result) {
      case PermissionState.granted:
        return PermissionOutcome.granted;
      case PermissionState.denied:
        return PermissionOutcome.denied;
      case PermissionState.permanentlyDenied:
        return PermissionOutcome.needsSettings;
      case PermissionState.unavailable:
        return PermissionOutcome.unavailable;
    }
  }

  /// Current state without prompting, for settings screens that reflect reality (a user can
  /// revoke a permission in the system settings at any time).
  Future<PermissionState> current(AppPermission permission) =>
      _gateway.status(permission);

  Future<bool> openSettings() => _gateway.openAppSettings();
}
