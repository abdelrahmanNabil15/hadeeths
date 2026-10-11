import 'package:flutter/material.dart';

/// The icons the shared components use, chosen once so every screen uses the same glyph for the
/// same meaning. Directional ones mirror in right-to-left text.
abstract final class AppIcons {
  /// Opens something further: rows and tiles. Mirrors in Arabic.
  static const chevron = Icons.chevron_right_rounded;
  static const search = Icons.search;
  static const settings = Icons.tune;
  static const info = Icons.info_outline;
  static const retry = Icons.refresh;
  static const offline = Icons.wifi_off;
  static const error = Icons.error_outline;
  static const selected = Icons.check_circle;
  static const share = Icons.share;
  static const shareText = Icons.notes;
  static const shareImage = Icons.image_outlined;
  static const clear = Icons.close_rounded;
}
