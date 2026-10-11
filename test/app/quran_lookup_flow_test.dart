import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';
import 'package:mynewapp/features/quran/domain/sura_names.dart';
import 'package:mynewapp/l10n/app_localizations.dart';

import '../support/fake_backend.dart';
import '../support/quran_fakes.dart';
import '../support/test_app.dart';

Future<(InMemoryQuranUserData, AppLocalizations)> _open(
  WidgetTester tester, {
  String locale = 'ar',
}) async {
  tester.view.physicalSize = const Size(700, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final data = InMemoryQuranUserData();
  await pumpApp(
    tester,
    FakeBackend(),
    locale: locale,
    features: const FeatureFlags(quran: true),
    quran: FakeQuranSource(),
    quranUserData: data,
  );
  final l10n = lookupAppLocalizations(Locale(locale));
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(l10n.navQuran),
    ),
  );
  await tester.pumpAndSettle();
  return (data, l10n);
}

Finder get _filter => find.widgetWithText(TextField, '').first;

void main() {
  testWidgets('the sura filter narrows the list and can be cleared', (
    tester,
  ) async {
    final (_, l10n) = await _open(tester);
    // The test text has three suras.
    expect(find.textContaining(SuraNames.arabic(3)), findsOneWidget);
    await tester.enterText(_filter, 'البقرة');
    await tester.pump();
    expect(find.text('٢. ${SuraNames.arabic(2)}'), findsOneWidget);
    expect(find.textContaining(SuraNames.arabic(3)), findsNothing);
    await tester.tap(find.byTooltip(l10n.searchClear));
    await tester.pump();
    expect(find.textContaining(SuraNames.arabic(3)), findsOneWidget);
  });

  testWidgets('a number finds the sura, in Arabic-Indic digits too', (
    tester,
  ) async {
    await _open(tester);
    await tester.enterText(_filter, '٣');
    await tester.pump();
    expect(find.textContaining(SuraNames.arabic(3)), findsOneWidget);
    expect(find.textContaining(SuraNames.arabic(2)), findsNothing);
  });

  testWidgets('no match says so', (tester) async {
    final (_, l10n) = await _open(tester, locale: 'en');
    await tester.enterText(_filter, 'zzzz');
    await tester.pump();
    expect(find.text(l10n.quranFilterNone), findsOneWidget);
  });

  testWidgets('go to a verse accepts Arabic-Indic digits', (tester) async {
    final (data, l10n) = await _open(tester);
    await tester.tap(find.text(l10n.quranJump));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), '٢');
    await tester.pump();
    await tester.enterText(fields.at(1), '٩');
    await tester.pump();
    await tester.tap(find.text(l10n.quranGo));
    await tester.pumpAndSettle();
    expect(data.last, const VerseRef(2, 9));
  });

  testWidgets('the filter fits at 200% text on a small phone', (tester) async {
    useSmallPhone(tester, textScale: 2);
    await pumpApp(
      tester,
      FakeBackend(),
      features: const FeatureFlags(quran: true),
      quran: FakeQuranSource(),
      quranUserData: InMemoryQuranUserData(),
    );
    await tester.tap(find.text('المصحف'));
    await tester.pumpAndSettle();
    final field = find.byType(TextField);
    await tester.scrollUntilVisible(
      field,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(field, 'ب');
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
