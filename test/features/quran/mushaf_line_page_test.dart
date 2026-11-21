import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/design_system/app_theme.dart';
import 'package:mynewapp/features/quran/domain/mushaf_lines.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';
import 'package:mynewapp/features/quran/presentation/widgets/mushaf_line_page.dart';
import 'package:mynewapp/features/quran/presentation/widgets/mushaf_surah_header.dart';
import 'package:mynewapp/l10n/l10n.dart';

final _lines = MushafLines.parse(
  utf8.decode(File('assets/quran/mushaf-madinah-lines.txt').readAsBytesSync()),
);

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Center(child: FittedBox(child: child)),
  ),
);

MushafLinePage _page(int page, {void Function(VerseRef)? onVerse}) =>
    MushafLinePage(
      lines: _lines.page(page),
      page: page,
      width: 360,
      bookmarks: const [VerseRef(2, 255)],
      onVerseActions: onVerse ?? (_) {},
    );

void main() {
  for (final page in [1, 2, 3, 42, 106, 187, 293, 600, 604]) {
    testWidgets('page $page is set at its full size without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_page(page)));
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MushafLinePage)),
        const Size(360, 360 * MushafLinePage.lineHeightFactor * 15),
      );
    });
  }

  testWidgets('a sura that begins on the page gets its header, a line high', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_page(604)));
    // al-Ikhlas, al-Falaq and an-Nas all begin on the last page.
    expect(find.byType(MushafSuraHeader), findsNWidgets(3));
    final size = tester.getSize(find.byType(MushafSuraHeader).first);
    expect(size.width, 360);
    expect(size.height, closeTo(360 * MushafLinePage.lineHeightFactor, 0.01));
  });

  testWidgets('long-pressing a word acts on its verse', (tester) async {
    VerseRef? pressed;
    await tester.pumpWidget(_host(_page(604, onVerse: (v) => pressed = v)));
    final firstLine = _lines.page(604).whereType<VerseLine>().first;
    final word = firstLine.pieces.first.words.first;
    await tester.longPress(find.text(word).first);
    expect(pressed, firstLine.pieces.first.ref);
  });
}
