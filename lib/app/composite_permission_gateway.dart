import 'package:mynewapp/core/permissions/permission_gateway.dart';

/// Routes each permission to the gateway that knows how to ask for it, and opens the app's system
/// settings page through one of them.
class CompositePermissionGateway implements PermissionGateway {
  const CompositePermissionGateway({
    required this.byPermission,
    required this.settingsOpener,
  });

  final Map<AppPermission, PermissionGateway> byPermission;

  /// The gateway whose `openAppSettings` opens this app's page in the system settings.
  final PermissionGateway settingsOpener;

  @override
  Future<PermissionState> status(AppPermission permission) async =>
      byPermission[permission]?.status(permission) ??
      PermissionState.unavailable;

  @override
  Future<PermissionState> request(AppPermission permission) async =>
      byPermission[permission]?.request(permission) ??
      PermissionState.unavailable;

  @override
  Future<bool> openAppSettings() => settingsOpener.openAppSettings();
}
