import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/core/widgets/app_tile.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/features/favorites/domain/favorites_repository.dart';
import 'package:mynewapp/features/favorites/presentation/favorites_page.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';
import 'package:mynewapp/features/settings/presentation/pages/about_page.dart';
import 'package:mynewapp/features/settings/presentation/pages/settings_page.dart';
import 'package:mynewapp/features/tasbeeh/domain/tasbeeh_repository.dart';
import 'package:mynewapp/features/tasbeeh/presentation/pages/tasbeeh_page.dart';
import 'package:mynewapp/features/tracker/domain/prayer_log_repository.dart';
import 'package:mynewapp/features/tracker/presentation/pages/tracker_page.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Secondary destinations. Settings and "Sources and rights" live here once the bottom
/// navigation is on; later phases add the tracker and the salawat counter.
class MorePage extends StatelessWidget {
  const MorePage({
    super.key,
    this.tracker,
    this.tasbeeh,
    this.favorites,
    this.onDeleteAll,
  });

  /// Deletes everything the app keeps about the user (offered in Settings).
  final Future<bool> Function()? onDeleteAll;

  /// Favourite hadiths; null when they are not available.
  final FavoritesRepository? favorites;

  /// The counter's storage; null when it is not available.
  final TasbeehRepository? tasbeeh;

  /// What the prayer tracker needs; null when it is not available.
  final ({PrayerLogRepository log, PrayerServices services})? tracker;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void open(Widget page) =>
        Navigator.of(context).push(appRoute<void>(builder: (_) => page));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMore)),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (favorites != null) ...[
              AppTile(
                title: l10n.favoritesTitle,
                pressFeedback: true,
                onTap: () => open(FavoritesPage(repository: favorites!)),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (tracker != null) ...[
              AppTile(
                title: l10n.trackerTitle,
                pressFeedback: true,
                onTap: () => open(
                  TrackerPage(log: tracker!.log, services: tracker!.services),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (tasbeeh != null) ...[
              AppTile(
                title: l10n.tasbeehTitle,
                pressFeedback: true,
                onTap: () => open(TasbeehPage(repository: tasbeeh!)),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTile(
              title: l10n.settings,
              pressFeedback: true,
              onTap: () => open(SettingsPage(onDeleteAll: onDeleteAll)),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTile(
              title: l10n.aboutTitle,
              pressFeedback: true,
              onTap: () => open(const AboutPage(extended: true)),
            ),
          ],
        ),
      ),
    );
  }
}
