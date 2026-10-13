import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/platform/review_gateway.dart';

void main() {
  // The plugin calls themselves (the system's sheet and the store page) need a phone with Google
  // Play or the App Store; they are not exercised here.
  group('the store page', () {
    test('is offered on Android', () {
      expect(
        InAppReviewBridge(platform: TargetPlatform.android).canOpenStoreListing,
        isTrue,
      );
    });

    test('is not offered on iOS until the App Store id is known', () {
      expect(
        InAppReviewBridge(platform: TargetPlatform.iOS).canOpenStoreListing,
        isFalse,
      );
      expect(
        InAppReviewBridge(
          platform: TargetPlatform.iOS,
          appStoreId: '123456789',
        ).canOpenStoreListing,
        isTrue,
      );
    });

    test('is not offered elsewhere', () {
      for (final platform in [
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.fuchsia,
      ]) {
        expect(
          InAppReviewBridge(platform: platform).canOpenStoreListing,
          isFalse,
          reason: '$platform',
        );
      }
    });
  });
}
