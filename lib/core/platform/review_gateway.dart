import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

/// The platform's rating sheet and store page. The only place the review plugin is used.
abstract interface class ReviewGateway {
  /// Whether the system can show its rating sheet now. False does not mean an error; the system
  /// decides, and may decline for reasons the app is never told.
  Future<bool> isAvailable();

  /// Asks the system to show its rating sheet. It may show nothing (the system limits how often
  /// it appears), and the app cannot learn whether the user rated. Never throws.
  Future<void> requestReview();

  /// Whether [openStoreListing] can work on this platform.
  bool get canOpenStoreListing;

  /// Opens the app's page in the store. Never throws.
  Future<void> openStoreListing();
}

/// [ReviewGateway] over the `in_app_review` plugin (Google Play In-App Review on Android, the
/// system rating prompt on iOS).
///
/// [appStoreId] is the app's App Store id. It is not known yet (the iOS app is not published),
/// so the store page is offered on Android only until it is given.
class InAppReviewBridge implements ReviewGateway {
  InAppReviewBridge({
    InAppReview? plugin,
    this.appStoreId,
    TargetPlatform? platform,
  }) : _plugin = plugin ?? InAppReview.instance,
       _platform = platform ?? defaultTargetPlatform;

  final InAppReview _plugin;
  final String? appStoreId;
  final TargetPlatform _platform;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _plugin.isAvailable();
    } on Object {
      return false;
    }
  }

  @override
  Future<void> requestReview() async {
    try {
      await _plugin.requestReview();
    } on Object {
      // The sheet is a courtesy; failing to show it is not an error for the user.
    }
  }

  @override
  bool get canOpenStoreListing => switch (_platform) {
    TargetPlatform.android => true,
    TargetPlatform.iOS || TargetPlatform.macOS => appStoreId != null,
    _ => false,
  };

  @override
  Future<void> openStoreListing() async {
    if (!canOpenStoreListing) return;
    try {
      await _plugin.openStoreListing(appStoreId: appStoreId);
    } on Object {
      // Nothing to show; the user can open the store themselves.
    }
  }
}
