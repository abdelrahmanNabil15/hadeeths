// On-device checks for the rating prompt's platform pieces, with the real app wiring.
//
// Run on an emulator or a phone (not part of `flutter test` or CI):
//
//   flutter test integration_test/app_review_test.dart -d <device> --dart-define=HADEETHS_PREVIEW_SECTIONS=true
//
// What this can show: the installed version reaches Dart through the `hadeeths/app_info` channel,
// and the "Rate" entry is on the More page. What it cannot show: the system's rating sheet itself.
// That appears only for a build installed from Google Play (for example the internal testing
// track), so it stays NOT RUN until it is looked at there.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mynewapp/core/platform/app_version_source.dart';
import 'package:mynewapp/l10n/app_localizations.dart';
import 'package:mynewapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the installed version arrives as name+code', (tester) async {
    final version = await MethodChannelAppVersionSource().version();
    // ignore: avoid_print
    print('installed version: $version');
    expect(version, matches(RegExp(r'^\d+\.\d+\.\d+.*\+\d+$')));
  });

  testWidgets('More offers the Rate entry', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));
    final l10n = AppLocalizations.of(tester.element(find.byType(NavigationBar)));
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(l10n.navMore),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.rateApp), findsOneWidget);
  });
}
