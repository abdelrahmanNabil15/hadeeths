import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/design_system/app_theme.dart';
import 'package:mynewapp/features/quran/presentation/widgets/mushaf_page_frame_decoration.dart';

final _theme = AppTheme.light();

Widget _host(Widget child) => MaterialApp(
  theme: _theme,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('draws round its page without throwing', (tester) async {
    await tester.pumpWidget(
      _host(const MushafPageFrame(child: SizedBox(width: 200, height: 300))),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('adds its margin on every side and leaves the page its size', (
    tester,
  ) async {
    const page = Key('page');
    await tester.pumpWidget(
      _host(
        const MushafPageFrame(
          margin: 20,
          child: SizedBox(key: page, width: 200, height: 300),
        ),
      ),
    );
    expect(tester.getSize(find.byType(MushafPageFrame)), const Size(240, 340));
    expect(tester.getSize(find.byKey(page)), const Size(200, 300));
  });
}
