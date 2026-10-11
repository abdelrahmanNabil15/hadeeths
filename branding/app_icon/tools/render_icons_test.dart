// Draws the icon art described by build/spec.json into raw RGBA files (one per job).
// Run from the project root: `flutter test branding/app_icon/tools/render_icons_test.dart`
// then `python branding/app_icon/tools/build.py png`.
//
// The art is plain vector data (polygons and quadratic curves) drawn with dart:ui, so every size is
// rendered from the vectors, never scaled from a bitmap.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

Color _color(String hex) =>
    Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));

Path _parse(String d, {required bool evenOdd}) {
  final path = Path()
    ..fillType = evenOdd ? PathFillType.evenOdd : PathFillType.nonZero;
  final tokens = RegExp(
    r'[MLQZ]|-?\d+(?:\.\d+)?',
  ).allMatches(d).map((m) => m[0]!).toList();
  var i = 0;
  double next() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    switch (tokens[i++]) {
      case 'M':
        path.moveTo(next(), next());
      case 'L':
        path.lineTo(next(), next());
      case 'Q':
        final cx = next(), cy = next(), x = next(), y = next();
        path.quadraticBezierTo(cx, cy, x, y);
      case 'Z':
        path.close();
      default:
        throw FormatException('unexpected token ${tokens[i - 1]}');
    }
  }
  return path;
}

void _drawLayer(Canvas canvas, Map<String, dynamic> layer) {
  final path = _parse(layer['d'] as String, evenOdd: layer['evenodd'] == true);
  final opacity = (layer['opacity'] as num?)?.toDouble() ?? 1.0;
  final fill = layer['fill'] as String?;
  final stroke = layer['stroke'] as String?;
  if (fill != null) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..color = _color(fill).withValues(alpha: opacity),
    );
  }
  if (stroke != null) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true
        ..strokeJoin = StrokeJoin.miter
        ..strokeMiterLimit = 10
        ..strokeCap = layer['cap'] == 'round' ? StrokeCap.round : StrokeCap.butt
        ..strokeWidth = (layer['sw'] as num).toDouble()
        ..color = _color(stroke).withValues(alpha: opacity),
    );
  }
}

Future<List<int>> _render(Map<String, dynamic> job) async {
  final w = job['w'] as int, h = job['h'] as int;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
  );
  final background = job['bg'] as String?;
  if (background != null) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..color = _color(background),
    );
  }
  for (final raw in job['items'] as List) {
    final item = raw as Map<String, dynamic>;
    canvas.save();
    canvas.translate(
      (item['x'] as num).toDouble(),
      (item['y'] as num).toDouble(),
    );
    canvas.scale((item['size'] as num).toDouble() / 1024);
    final clip = item['clip'] as String?;
    if (clip == 'rrect') {
      canvas.clipRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 1024, 1024),
          const Radius.circular(229),
        ),
      );
    } else if (clip == 'circle') {
      canvas.clipPath(Path()..addOval(const Rect.fromLTWH(0, 0, 1024, 1024)));
    }
    final itemBg = item['bg'] as String?;
    if (itemBg != null) {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1024, 1024),
        Paint()..color = _color(itemBg),
      );
    }
    final scale = (item['scale'] as num).toDouble();
    canvas.translate(512, 512);
    canvas.scale(scale);
    canvas.translate(-512, -((item['cy'] as num?)?.toDouble() ?? 512));
    for (final layer in item['layers'] as List) {
      _drawLayer(canvas, layer as Map<String, dynamic>);
    }
    canvas.restore();
  }
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders every icon job to raw RGBA', () async {
    final spec =
        jsonDecode(File('branding/app_icon/build/spec.json').readAsStringSync())
            as Map<String, dynamic>;
    final out = Directory('branding/app_icon/build/raw')
      ..createSync(recursive: true);
    for (final raw in spec['jobs'] as List) {
      final job = raw as Map<String, dynamic>;
      final bytes = await _render(job);
      File('${out.path}/${job['name']}.rgba').writeAsBytesSync(bytes);
    }
  });
}
