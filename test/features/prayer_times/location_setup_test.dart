import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mynewapp/core/permissions/permission_flow.dart';
import 'package:mynewapp/core/permissions/permission_gateway.dart';
import 'package:mynewapp/features/prayer_times/data/geolocator_location_service.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/location_service.dart';
import 'package:mynewapp/features/prayer_times/domain/location_setup.dart';

import '../../support/fake_permissions.dart';
import '../../support/prayer_fakes.dart';

void main() {
  late FakePermissionGateway gateway;
  late FakeLocationService location;
  late LocationSetup setup;
  late int explained;

  setUp(() {
    gateway = FakePermissionGateway();
    location = FakeLocationService();
    setup = LocationSetup(PermissionFlow(gateway), location);
    explained = 0;
  });

  Future<bool> Function() agree([bool answer = true]) => () async {
    explained++;
    return answer;
  };

  test('explained, allowed, read once: a position', () async {
    final result = await setup.run(explain: agree());
    expect(result.status, LocationSetupStatus.found);
    expect(result.point, GeoPoint(30.0444, 31.2357));
    expect(explained, 1);
    expect(gateway.requested, [AppPermission.location]);
    expect(location.reads, 1);
  });

  test('already allowed: no explanation, no prompt, still one read', () async {
    gateway.states[AppPermission.location] = PermissionState.granted;
    final result = await setup.run(explain: agree());
    expect(result.status, LocationSetupStatus.found);
    expect(explained, 0);
    expect(gateway.requested, isEmpty);
    expect(location.reads, 1);
  });

  test('closing the explanation shows no prompt and reads nothing', () async {
    final result = await setup.run(explain: agree(false));
    expect(result.status, LocationSetupStatus.declinedExplanation);
    expect(gateway.requested, isEmpty);
    expect(location.reads, 0);
  });

  test('refusing the system prompt reads nothing', () async {
    gateway.onRequest[AppPermission.location] = PermissionState.denied;
    final result = await setup.run(explain: agree());
    expect(result.status, LocationSetupStatus.denied);
    expect(location.reads, 0);
  });

  test('"don\'t ask again" points to the settings', () async {
    gateway.onRequest[AppPermission.location] =
        PermissionState.permanentlyDenied;
    expect(
      (await setup.run(explain: agree())).status,
      LocationSetupStatus.needsSettings,
    );
    gateway.states[AppPermission.location] = PermissionState.permanentlyDenied;
    explained = 0;
    expect(
      (await setup.run(explain: agree())).status,
      LocationSetupStatus.needsSettings,
    );
    expect(explained, 0);
    expect(location.reads, 0);
  });

  test('permission that cannot exist on this device', () async {
    gateway.states[AppPermission.location] = PermissionState.unavailable;
    expect(
      (await setup.run(explain: agree())).status,
      LocationSetupStatus.permissionUnavailable,
    );
  });

  test(
    'location switched off, no signal in time, or no position at all',
    () async {
      for (final (problem, status) in [
        (LocationProblem.serviceDisabled, LocationSetupStatus.serviceDisabled),
        (LocationProblem.timeout, LocationSetupStatus.timeout),
        (LocationProblem.unavailable, LocationSetupStatus.unavailable),
      ]) {
        location.result = LocationFailed(problem);
        final result = await setup.run(explain: agree());
        expect(result.status, status);
        expect(result.point, isNull);
      }
    },
  );

  test('the settings pages open through the right objects', () async {
    expect(await setup.openAppSettings(), isTrue);
    expect(gateway.settingsOpened, 1);
    expect(await setup.openLocationSettings(), isTrue);
    expect(location.locationSettingsOpened, 1);
  });

  group('geolocator permission mapping', () {
    test('while in use and always both allow a read', () {
      expect(
        GeolocatorPermissionGateway.mapLocationPermission(
          LocationPermission.whileInUse,
        ),
        PermissionState.granted,
      );
      expect(
        GeolocatorPermissionGateway.mapLocationPermission(
          LocationPermission.always,
        ),
        PermissionState.granted,
      );
    });

    test('denied can be asked again, denied forever cannot', () {
      expect(
        GeolocatorPermissionGateway.mapLocationPermission(
          LocationPermission.denied,
        ),
        PermissionState.denied,
      );
      expect(
        GeolocatorPermissionGateway.mapLocationPermission(
          LocationPermission.deniedForever,
        ),
        PermissionState.permanentlyDenied,
      );
      expect(
        GeolocatorPermissionGateway.mapLocationPermission(
          LocationPermission.unableToDetermine,
        ),
        PermissionState.denied,
      );
    });

    test('the other permissions are not served by this gateway', () async {
      const gateway = GeolocatorPermissionGateway();
      expect(
        await gateway.status(AppPermission.notifications),
        PermissionState.unavailable,
      );
      expect(
        await gateway.request(AppPermission.exactAlarms),
        PermissionState.unavailable,
      );
    });
  });
}
