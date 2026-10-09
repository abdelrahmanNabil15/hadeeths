import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/design_system/app_theme.dart';
import 'package:mynewapp/core/haptics/haptics.dart';
import 'package:mynewapp/core/widgets/switch_row.dart';

class _CountingHaptics implements Haptics {
  int selections = 0;
  int alignments = 0;

  @override
  void selection() => selections++;

  @override
  void alignment() => alignments++;
}

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );

  testWidgets('flipping the switch gives a light tick and reports the change', (
    tester,
  ) async {
    final haptics = _CountingHaptics();
    final changes = <bool>[];
    await tester.pumpWidget(
      host(
        SwitchRow(
          title: 'Reminders',
          value: false,
          onChanged: changes.add,
          haptics: haptics,
        ),
      ),
    );
    await tester.tap(find.text('Reminders'));
    await tester.pump();
    expect(changes, [true]);
    expect(haptics.selections, 1);
    expect(haptics.alignments, 0);
  });

  testWidgets('a disabled row does nothing and gives no tick', (tester) async {
    final haptics = _CountingHaptics();
    await tester.pumpWidget(
      host(
        SwitchRow(
          title: 'Reminders',
          value: false,
          onChanged: null,
          haptics: haptics,
        ),
      ),
    );
    await tester.tap(find.text('Reminders'));
    await tester.pump();
    expect(haptics.selections, 0);
  });
}
