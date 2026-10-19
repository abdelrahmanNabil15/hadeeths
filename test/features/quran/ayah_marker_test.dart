import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/design_system/app_theme.dart';
import 'package:mynewapp/features/quran/presentation/widgets/ayah_marker.dart';
import 'package:mynewapp/features/quran/presentation/widgets/mushaf_glyph_marker.dart';
import 'package:mynewapp/features/quran/presentation/widgets/verse_marker.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';

final _theme = AppTheme.light();

Widget _host(Widget child, {TextDirection direction = TextDirection.rtl}) =>
    MaterialApp(
      theme: _theme,
      home: Scaffold(
        body: Center(
          child: Directionality(textDirection: direction, child: child),
        ),
      ),
    );

void main() {
  group('AyahMarker', () {
    testWidgets('draws the painted rosette for AyahMarkerStyle.rosette', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const AyahMarker(style: AyahMarkerStyle.rosette, number: 3)),
      );
      expect(find.byType(VerseMarker), findsOneWidget);
      expect(find.byType(MushafGlyphMarker), findsNothing);
    });

    testWidgets('draws the Mushaf glyph for AyahMarkerStyle.mushafGlyph', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const AyahMarker(style: AyahMarkerStyle.mushafGlyph, number: 3)),
      );
      expect(find.byType(MushafGlyphMarker), findsOneWidget);
      expect(find.byType(VerseMarker), findsNothing);
    });

    testWidgets('announces the given semantic label for both styles', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final style in AyahMarkerStyle.values) {
        await tester.pumpWidget(
          _host(AyahMarker(style: style, number: 7, semanticLabel: 'Verse 7')),
        );
        expect(
          tester.getSemantics(find.byType(AyahMarker)),
          matchesSemantics(label: 'Verse 7'),
        );
      }
      handle.dispose();
    });

    testWidgets(
      'the Mushaf glyph survives a large text scale without throwing',
      (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: _host(
              const AyahMarker(style: AyahMarkerStyle.mushafGlyph, number: 112),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('renders left-to-right just as well as right-to-left', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AyahMarker(style: AyahMarkerStyle.mushafGlyph, number: 5),
          direction: TextDirection.ltr,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(MushafGlyphMarker), findsOneWidget);
    });
  });
}
