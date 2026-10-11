import 'package:flutter/material.dart';
import 'package:mynewapp/core/widgets/app_tile.dart';
import 'package:mynewapp/features/app_review/presentation/review_scope.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// "Rate Sakina": opens the app's page in the store. Always works when the store page can be
/// opened, whatever the automatic rules say. Nothing is shown when rating is off or there is no
/// store page to open on this platform.
class RateAppTile extends StatelessWidget {
  const RateAppTile({super.key});

  /// Whether the tile would show, so a screen can decide about the space around it.
  static bool isShown(BuildContext context) =>
      ReviewScope.maybeOf(context)?.manualAvailable ?? false;

  @override
  Widget build(BuildContext context) {
    final actions = ReviewScope.maybeOf(context);
    if (actions == null || !actions.manualAvailable) {
      return const SizedBox.shrink();
    }
    return AppTile(
      title: context.l10n.rateApp,
      leadingIcon: Icons.star_outline_rounded,
      pressFeedback: true,
      onTap: () => actions.rateNow(),
    );
  }
}
