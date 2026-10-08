import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Layering rules from ADR-4, checked against the real import graph.
///
/// - domain: pure Dart. No Flutter, Dio, data or presentation code.
/// - data: no presentation code and no Flutter widgets.
/// - presentation: never touches Dio, the data layer or API DTOs.
/// - core: knows nothing about features.
void main() {
  final imports = <String, List<String>>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    imports[path] = [
      for (final line in entity.readAsLinesSync())
        if (line.startsWith('import ') || line.startsWith('export '))
          RegExp(r'''['"]([^'"]+)['"]''').firstMatch(line)!.group(1)!,
    ];
  }

  List<String> violations(
    bool Function(String file) inScope,
    bool Function(String import) forbidden,
  ) => [
    for (final entry in imports.entries)
      if (inScope(entry.key))
        for (final import in entry.value)
          if (forbidden(import)) '${entry.key} imports $import',
  ];

  bool isFeature(String f, String layer) =>
      RegExp('^lib/features/[^/]+/$layer/').hasMatch(f);

  test('the scan finds the source tree', () {
    expect(imports.length, greaterThan(30));
  });

  test('domain is pure Dart', () {
    expect(
      violations(
        (f) => isFeature(f, 'domain'),
        (i) =>
            i.startsWith('package:flutter') ||
            i.startsWith('package:dio') ||
            i.contains('/data/') ||
            i.contains('/presentation/'),
      ),
      isEmpty,
    );
  });

  test('data does not depend on presentation or Flutter widgets', () {
    expect(
      violations(
        (f) => isFeature(f, 'data'),
        (i) => i.contains('/presentation/') || i.startsWith('package:flutter'),
      ),
      isEmpty,
    );
  });

  test('presentation never touches Dio, the data layer or DTOs', () {
    expect(
      violations(
        (f) => isFeature(f, 'presentation'),
        (i) =>
            i.startsWith('package:dio') ||
            i.contains('/data/') ||
            i.contains('dto') ||
            i.contains('hadeeth_client'),
      ),
      isEmpty,
    );
  });

  test('core knows nothing about features', () {
    expect(
      violations(
        (f) => f.startsWith('lib/core/'),
        (i) => i.contains('/features/'),
      ),
      isEmpty,
    );
  });

  test('only the app composition root builds concrete repositories', () {
    expect(
      violations(
        (f) => !f.startsWith('lib/app/') && !isFeature(f, 'data'),
        (i) => i.endsWith('_repository_impl.dart'),
      ),
      isEmpty,
    );
  });
}
