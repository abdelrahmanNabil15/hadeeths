// On-device flows for the Quran section, with the real bundled text and the real app wiring.
//
// Run on an emulator or a phone (not part of `flutter test` or CI):
//
//   flutter test integration_test/quran_test.dart -d <device> --dart-define=HADEETHS_PREVIEW_SECTIONS=true
//
// The app language follows the device; the steps below work in either language.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mynewapp/features/quran/domain/sura_names.dart';
import 'package:mynewapp/l10n/app_localizations.dart';
import 'package:mynewapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('filter, open a sura, go to a verse with Arabic-Indic digits', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final context = tester.element(find.byType(NavigationBar));
    final l10n = AppLocalizations.of(context);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(l10n.navQuran),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // The filter narrows the 114 suras to al-Baqarah.
    final filter = find.byType(TextField).first;
    await tester.scrollUntilVisible(
      filter,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(filter, SuraNames.arabic(2));
    await tester.pumpAndSettle();
    final row = find.textContaining(RegExp(r'^[٢2]\. '));
    expect(row, findsOneWidget);
    await tester.tap(row);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text(SuraNames.arabic(2)), findsWidgets);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Go to 2:255 typed in Arabic-Indic digits.
    await tester.scrollUntilVisible(
      find.text(l10n.quranJump),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(l10n.quranJump));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), '٢');
    await tester.pump();
    await tester.enterText(fields.at(1), '٢٥٥');
    await tester.pump();
    await tester.tap(find.text(l10n.quranGo));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(Dialog), findsNothing, reason: 'the reader opened');
  });
}
