// Fails when line coverage of the logic layers is below a threshold.
//
//   flutter test --coverage
//   dart run tool/check_coverage.dart [minPercent]
//
// "Logic layers" = domain, data and state (cubit) code plus core/ without widgets and logging.
// Widgets are covered by widget tests but are deliberately not gated on a percentage.
import 'dart:io';

bool _isLogic(String path) {
  final p = path.replaceAll(r'\', '/');
  if (p.startsWith('lib/l10n/')) return false;
  if (p.startsWith('lib/core/')) {
    return !p.startsWith('lib/core/widgets/') &&
        !p.startsWith('lib/core/logging/') &&
        !p.startsWith('lib/core/design_system/');
  }
  return RegExp(r'^lib/features/[^/]+/(domain|data)/').hasMatch(p) ||
      RegExp(r'^lib/features/[^/]+/presentation/state/').hasMatch(p);
}

void main(List<String> args) {
  final threshold = args.isEmpty ? 80.0 : double.parse(args.first);
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    stderr.writeln(
      'coverage/lcov.info not found; run `flutter test --coverage` first.',
    );
    exit(2);
  }
  var found = 0;
  var hit = 0;
  String? current;
  final perFile = <String, (int, int)>{};
  var fileFound = 0;
  var fileHit = 0;
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      current = line.substring(3);
      fileFound = 0;
      fileHit = 0;
    } else if (line.startsWith('LF:')) {
      fileFound = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      fileHit = int.parse(line.substring(3));
    } else if (line == 'end_of_record' && current != null) {
      if (_isLogic(current)) {
        found += fileFound;
        hit += fileHit;
        perFile[current] = (fileHit, fileFound);
      }
      current = null;
    }
  }
  final percent = found == 0 ? 0.0 : hit * 100 / found;
  final worst = perFile.entries.where((e) => e.value.$2 > 0).toList()
    ..sort(
      (a, b) => (a.value.$1 / a.value.$2).compareTo(b.value.$1 / b.value.$2),
    );
  for (final e in worst.take(5)) {
    stdout.writeln(
      '  ${(e.value.$1 * 100 / e.value.$2).toStringAsFixed(0).padLeft(3)}%  ${e.key}',
    );
  }
  stdout.writeln(
    'Logic-layer line coverage: ${percent.toStringAsFixed(1)}% ($hit/$found lines, ${perFile.length} files)',
  );
  if (percent < threshold) {
    stderr.writeln('Below the required ${threshold.toStringAsFixed(0)}%.');
    exit(1);
  }
}
