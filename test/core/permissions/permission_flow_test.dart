import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/permissions/permission_flow.dart';
import 'package:mynewapp/core/permissions/permission_gateway.dart';

import '../../support/fake_permissions.dart';

void main() {
  late FakePermissionGateway gateway;
  late PermissionFlow flow;
  late int explained;

  setUp(() {
    gateway = FakePermissionGateway();
    flow = PermissionFlow(gateway);
    explained = 0;
  });

  Future<bool> Function() explainWith(bool answer) => () async {
    explained++;
    return answer;
  };

  test('already granted: nothing is shown and nothing is requested', () async {
    gateway.states[AppPermission.location] = PermissionState.granted;
    final outcome = await flow.ensure(
      AppPermission.location,
      explain: explainWith(true),
    );
    expect(outcome, PermissionOutcome.granted);
    expect(explained, 0);
    expect(gateway.requested, isEmpty);
  });

  test('the explanation comes first, then the system prompt', () async {
    final outcome = await flow.ensure(
      AppPermission.notifications,
      explain: explainWith(true),
    );
    expect(outcome, PermissionOutcome.granted);
    expect(explained, 1);
    expect(gateway.requested, [AppPermission.notifications]);
  });

  test(
    'if the user declines the explanation the system prompt never appears',
    () async {
      final outcome = await flow.ensure(
        AppPermission.location,
        explain: explainWith(false),
      );
      expect(outcome, PermissionOutcome.declinedExplanation);
      expect(gateway.requested, isEmpty);
    },
  );

  test('a refusal at the system prompt is an outcome, not an error', () async {
    gateway.onRequest[AppPermission.location] = PermissionState.denied;
    final outcome = await flow.ensure(
      AppPermission.location,
      explain: explainWith(true),
    );
    expect(outcome, PermissionOutcome.denied);
  });

  test('"don\'t ask again" at the prompt leads to the settings page', () async {
    gateway.onRequest[AppPermission.location] =
        PermissionState.permanentlyDenied;
    final outcome = await flow.ensure(
      AppPermission.location,
      explain: explainWith(true),
    );
    expect(outcome, PermissionOutcome.needsSettings);
  });

  test('permanently denied earlier: no explanation, no prompt', () async {
    gateway.states[AppPermission.notifications] =
        PermissionState.permanentlyDenied;
    final outcome = await flow.ensure(
      AppPermission.notifications,
      explain: explainWith(true),
    );
    expect(outcome, PermissionOutcome.needsSettings);
    expect(explained, 0);
    expect(gateway.requested, isEmpty);
  });

  test('unavailable on this device: nothing is requested', () async {
    gateway.states[AppPermission.exactAlarms] = PermissionState.unavailable;
    final outcome = await flow.ensure(
      AppPermission.exactAlarms,
      explain: explainWith(true),
    );
    expect(outcome, PermissionOutcome.unavailable);
    expect(gateway.requested, isEmpty);
  });

  test('unavailable after asking is reported as such', () async {
    gateway.onRequest[AppPermission.exactAlarms] = PermissionState.unavailable;
    final outcome = await flow.ensure(
      AppPermission.exactAlarms,
      explain: explainWith(true),
    );
    expect(outcome, PermissionOutcome.unavailable);
  });

  test(
    'a permission revoked in system settings is seen on the next check',
    () async {
      gateway.states[AppPermission.notifications] = PermissionState.granted;
      expect(
        await flow.current(AppPermission.notifications),
        PermissionState.granted,
      );
      gateway.states[AppPermission.notifications] = PermissionState.denied;
      expect(
        await flow.current(AppPermission.notifications),
        PermissionState.denied,
      );
      final outcome = await flow.ensure(
        AppPermission.notifications,
        explain: explainWith(true),
      );
      expect(outcome, PermissionOutcome.granted);
      expect(explained, 1);
    },
  );

  test('permissions are independent of each other', () async {
    gateway.states[AppPermission.location] = PermissionState.granted;
    await flow.ensure(AppPermission.notifications, explain: explainWith(true));
    expect(gateway.requested, [AppPermission.notifications]);
  });

  test('opening the settings is passed through', () async {
    expect(await flow.openSettings(), isTrue);
    gateway.settingsCanOpen = false;
    expect(await flow.openSettings(), isFalse);
    expect(gateway.settingsOpened, 2);
  });
}
