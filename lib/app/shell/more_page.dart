import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/core/widgets/app_tile.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/features/settings/presentation/pages/about_page.dart';
import 'package:mynewapp/features/settings/presentation/pages/settings_page.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Secondary destinations. Settings and "Sources and rights" live here once the bottom
/// navigation is on; later phases add the tracker and the salawat counter.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

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
            AppTile(
              title: l10n.settings,
              pressFeedback: true,
              onTap: () => open(const SettingsPage()),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTile(
              title: l10n.aboutTitle,
              pressFeedback: true,
              onTap: () => open(const AboutPage()),
            ),
          ],
        ),
      ),
    );
  }
}
