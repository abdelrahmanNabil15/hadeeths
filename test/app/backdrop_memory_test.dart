import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/categories/presentation/widgets/category_grid.dart';

/// Decodes [provider] for real and returns its size in bytes (RGBA, 4 bytes per pixel).
Future<int> _decodedBytes(ImageProvider provider) async {
  final completer = Completer<ui.Image>();
  final stream = provider.resolve(ImageConfiguration.empty);
  late ImageStreamListener listener;
  listener = ImageStreamListener((info, _) {
    completer.complete(info.image);
    stream.removeListener(listener);
  }, onError: completer.completeError);
  stream.addListener(listener);
  final image = await completer.future;
  final bytes = image.width * image.height * 4;
  image.dispose();
  return bytes;
}

void main() {
  const asset = AssetImage('assets/backgruond.jpg');

  testWidgets('the backdrop is decoded at display width, not at 2250x4000', (
    tester,
  ) async {
    // Real decoding needs real time, so leave the fake-async zone.
    final full = await tester.runAsync(() => _decodedBytes(asset));
    final resized = await tester.runAsync(
      () => _decodedBytes(ResizeImage(asset, width: 1080)),
    );
    // A 2250x4000 RGBA image is 36 MB; at a 1080 px wide phone it is about 8 MB.
    expect(full, 2250 * 4000 * 4);
    expect(resized, lessThan(full! ~/ 3));
    expect(resized, lessThan(10 * 1024 * 1024));
  });

  testWidgets('CategoryBackdrop asks for the width it is shown at', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: CategoryBackdrop(child: SizedBox())),
    );
    final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    final image = (box.decoration as BoxDecoration).image!.image;
    expect(image, isA<ResizeImage>());
    // 1080 physical px wide = the width of the screen, not the width of the source image.
    expect((image as ResizeImage).width, 1080);
  });
}
