import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/section_heading.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Credits and licences: who the content comes from, which fonts are bundled, and privacy.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final body = TextStyle(
      fontSize: AppTextSize.body,
      height: AppLineHeight.body,
      color: scheme.onSurface,
    );
    Widget section(String heading, String text) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(heading),
        const SizedBox(height: AppSpacing.sm),
        SelectionArea(child: Text(text, style: body)),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            section(l10n.aboutContentHeading, l10n.aboutContentBody),
            SelectionArea(
              child: Text(
                l10n.sourceCredit,
                style: body.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            section(l10n.aboutFontsHeading, l10n.aboutFontsBody),
            section(l10n.aboutPrivacyHeading, l10n.aboutPrivacyBody),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: l10n.appTitle,
                ),
                icon: const Icon(Icons.description_outlined),
                label: Text(l10n.openSourceLicences),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
