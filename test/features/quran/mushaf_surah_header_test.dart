import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/design_system/app_theme.dart';
import 'package:mynewapp/features/quran/presentation/widgets/mushaf_surah_header.dart';
import 'package:mynewapp/l10n/l10n.dart';

final _theme = AppTheme.light();

Widget _host(Widget child, {double width = 360}) => MaterialApp(
  theme: _theme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Center(child: SizedBox(width: width, child: child)),
  ),
);

void main() {
  testWidgets('draws the band with the sura name in Arabic, no crash', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const MushafSuraHeader(sura: 1)));
    expect(tester.takeException(), isNull);
    expect(find.text('سورة الفاتحة'), findsOneWidget);
  });

  testWidgets('is exactly as wide as the text column it heads', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const MushafSuraHeader(sura: 2, height: 40), width: 300),
    );
    expect(tester.getSize(find.byType(MushafSuraHeader)), const Size(300, 40));
  });

  testWidgets('defaults to a ninth of its width tall', (tester) async {
    await tester.pumpWidget(_host(const MushafSuraHeader(sura: 2)));
    expect(tester.getSize(find.byType(MushafSuraHeader)).height, 40);
  });

  testWidgets('announces itself as a header to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(const MushafSuraHeader(sura: 2)));
    final node = tester.getSemantics(find.bySemanticsLabel(RegExp('Al-Baqarah')));
    expect(node.getSemanticsData().flagsCollection.isHeader, isTrue);
    handle.dispose();
  });
}
