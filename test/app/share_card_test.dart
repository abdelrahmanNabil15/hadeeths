import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/app/feature_flags.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/share/image_sharer.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_details.dart';
import 'package:mynewapp/features/hadiths/presentation/share_card/card_pages.dart';
import 'package:mynewapp/features/hadiths/presentation/share_card/share_card_page.dart';

import '../support/fake_backend.dart';
import '../support/fixtures.dart';
import '../support/test_app.dart';

class _Sharer implements ImageSharer {
  final List<List<Uint8List>> shared = [];
  final List<String> texts = [];

  @override
  Future<void> sharePngs(List<Uint8List> pngs, {required String text}) async {
    shared.add(pngs);
    texts.add(text);
  }
}

const _style = TextStyle(fontFamily: AppFonts.reading, fontSize: 20, height: 2);

String _squash(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

FakeBackend _backend({String? hadeeth}) => FakeBackend(
  pages: {
    '2:1': samplePage(
      ids: List.generate(3, (i) => '${100 + i}'),
      totalItems: 3,
    ),
  },
  details: hadeeth == null
      ? null
      : HadithDetails(
          id: '100',
          title: 'عنوان',
          hadeeth: hadeeth,
          grade: 'صحيح',
          attribution: 'متفق عليه',
        ),
);

Future<_Sharer> _openCards(
  WidgetTester tester, {
  String? hadeeth,
  FeatureFlags features = const FeatureFlags.all(),
}) async {
  tester.view.physicalSize = const Size(700, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final sharer = _Sharer();
  await pumpApp(
    tester,
    _backend(hadeeth: hadeeth),
    locale: 'ar',
    features: features,
    imageSharer: sharer,
  );
  await tapText(tester, 'جذر ثان');
  await tapText(tester, 'حديث 100');
  return sharer;
}

void main() {
  group('splitting into cards', () {
    testWidgets('a short text is one card, unchanged', (tester) async {
      const text = 'نص قصير للتجربة';
      final pages = splitIntoPages(
        text,
        style: _style,
        width: 312,
        maxHeight: 298,
        direction: TextDirection.rtl,
      );
      expect(pages, [text]);
    });

    testWidgets(
      'a long text is split only between words, and nothing is lost',
      (tester) async {
        final text = List.generate(300, (i) => 'كلمة$i').join(' ');
        final pages = splitIntoPages(
          text,
          style: _style,
          width: 312,
          maxHeight: 298,
          direction: TextDirection.rtl,
        );
        expect(pages.length, greaterThan(1));
        expect(pages.join(' '), _squash(text));
        for (final page in pages) {
          expect(
            text,
            contains(page),
            reason: 'each card is a piece of the text',
          );
          final painter = TextPainter(
            text: TextSpan(text: page, style: _style),
            textDirection: TextDirection.rtl,
          )..layout(maxWidth: 312);
          expect(painter.height, lessThanOrEqualTo(298));
          painter.dispose();
        }
      },
    );

    testWidgets('a word longer than a card gets a card of its own, uncut', (
      tester,
    ) async {
      final long = 'ا' * 400;
      final pages = splitIntoPages(
        'قبل $long بعد',
        style: _style,
        width: 312,
        maxHeight: 60,
        direction: TextDirection.rtl,
      );
      expect(pages, contains(long));
    });

    testWidgets('empty text makes no cards', (tester) async {
      expect(
        splitIntoPages(
          '  ',
          style: _style,
          width: 312,
          maxHeight: 298,
          direction: TextDirection.rtl,
        ),
        isEmpty,
      );
    });
  });

  group('sharing a hadith', () {
    testWidgets(
      'the released app (sections off) still shares text straight away',
      (tester) async {
        await _openCards(tester, features: const FeatureFlags());
        // No choice sheet is offered: the share button is the text share it always was.
        expect(find.byTooltip('مشاركة الحديث'), findsOneWidget);
        expect(find.text('مشاركة كصورة'), findsNothing);
      },
    );

    testWidgets('with image sharing on, the user chooses text or image', (
      tester,
    ) async {
      await _openCards(tester);
      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();
      expect(find.text('مشاركة كنص'), findsOneWidget);
      expect(find.text('مشاركة كصورة'), findsOneWidget);
    });

    testWidgets('a short hadith makes one card with the credit and the grade', (
      tester,
    ) async {
      final sharer = await _openCards(tester);
      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();
      await tester.tap(find.text('مشاركة كصورة'));
      await tester.pumpAndSettle();
      expect(find.byType(ShareCard), findsOneWidget);
      expect(find.textContaining('HadeethEnc'), findsOneWidget);
      expect(find.textContaining('صحيح'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('مشاركة الصورة'));
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();
      expect(sharer.shared, hasLength(1));
      final png = sharer.shared.single.single;
      expect(png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      expect(sharer.texts.single, contains('HadeethEnc'));
    });

    testWidgets(
      'a long hadith makes several numbered cards, each with the credit',
      (tester) async {
        final long = List.generate(400, (i) => 'كلمة$i').join(' ');
        final sharer = await _openCards(tester, hadeeth: long);
        await tester.tap(find.byIcon(Icons.share));
        await tester.pumpAndSettle();
        await tester.tap(find.text('مشاركة كصورة'));
        await tester.pumpAndSettle();
        final cards = tester
            .widgetList<ShareCard>(find.byType(ShareCard))
            .toList();
        expect(cards.length, greaterThan(1));
        expect(cards.map((c) => c.text).join(' '), _squash(long));
        expect(find.textContaining('HadeethEnc'), findsNWidgets(cards.length));
        // Tests draw every letter as a square box, so there are more cards than on a phone.
        String arabicDigits(int n) => n
            .toString()
            .split('')
            .map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)])
            .join();
        expect(find.text('١/${arabicDigits(cards.length)}'), findsOneWidget);
        // The grade is on the last card only.
        expect(find.textContaining('صحيح'), findsOneWidget);
        await tester.runAsync(() async {
          await tester.tap(find.byType(FilledButton));
          // Turning many cards into images takes real time; wait until they are handed over.
          for (var i = 0; i < 120 && sharer.shared.isEmpty; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 250));
          }
        });
        await tester.pumpAndSettle();
        expect(sharer.shared.single, hasLength(cards.length));
      },
    );
  });
}
