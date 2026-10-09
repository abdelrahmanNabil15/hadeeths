import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/composite_permission_gateway.dart';
import 'package:mynewapp/app/prayer_wiring.dart';
import 'package:mynewapp/core/notifications/local_notifications_gateway.dart';
import 'package:mynewapp/core/permissions/permission_gateway.dart';

import '../support/fake_permissions.dart';

void main() {
  test(
    'every permission the app can ask for has a route in the real wiring',
    () {
      final gateway = buildPermissionGateway(
        notifications: LocalNotificationsGateway(),
      );
      expect(gateway.byPermission.keys.toSet(), AppPermission.values.toSet());
    },
  );

  group('the composite gateway', () {
    test('sends each question to the gateway for that permission', () async {
      final location = FakePermissionGateway({
        AppPermission.location: PermissionState.granted,
      });
      final notifications = FakePermissionGateway({
        AppPermission.notifications: PermissionState.denied,
      });
      final composite = CompositePermissionGateway(
        byPermission: {
          AppPermission.location: location,
          AppPermission.notifications: notifications,
        },
        settingsOpener: location,
      );
      expect(
        await composite.status(AppPermission.location),
        PermissionState.granted,
      );
      expect(
        await composite.status(AppPermission.notifications),
        PermissionState.denied,
      );
      await composite.request(AppPermission.notifications);
      expect(notifications.requested, [AppPermission.notifications]);
      expect(location.requested, isEmpty);
    });

    test(
      'a permission with no route is reported as unavailable, not granted',
      () async {
        final composite = CompositePermissionGateway(
          byPermission: const {},
          settingsOpener: FakePermissionGateway(),
        );
        expect(
          await composite.status(AppPermission.exactAlarms),
          PermissionState.unavailable,
        );
        expect(
          await composite.request(AppPermission.exactAlarms),
          PermissionState.unavailable,
        );
      },
    );

    test('the settings page is opened through the chosen gateway', () async {
      final opener = FakePermissionGateway();
      final composite = CompositePermissionGateway(
        byPermission: const {},
        settingsOpener: opener,
      );
      expect(await composite.openAppSettings(), isTrue);
      expect(opener.settingsOpened, 1);
    });
  });
}
