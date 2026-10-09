import 'package:mynewapp/core/permissions/permission_gateway.dart';

/// A permission gateway whose answers the test decides.
class FakePermissionGateway implements PermissionGateway {
  FakePermissionGateway([Map<AppPermission, PermissionState>? initial])
    : states = {
        for (final p in AppPermission.values) p: PermissionState.denied,
        ...?initial,
      };

  final Map<AppPermission, PermissionState> states;

  /// What a request turns the state into (default: granted).
  final Map<AppPermission, PermissionState> onRequest = {};

  final List<AppPermission> requested = [];
  int settingsOpened = 0;
  bool settingsCanOpen = true;

  @override
  Future<PermissionState> status(AppPermission permission) async =>
      states[permission]!;

  @override
  Future<PermissionState> request(AppPermission permission) async {
    requested.add(permission);
    final result = onRequest[permission] ?? PermissionState.granted;
    states[permission] = result;
    return result;
  }

  @override
  Future<bool> openAppSettings() async {
    settingsOpened++;
    return settingsCanOpen;
  }
}
