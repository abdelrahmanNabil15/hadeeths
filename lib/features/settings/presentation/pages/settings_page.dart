import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/cache/response_cache.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/widgets/app_tile.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/option_group.dart';
import 'package:mynewapp/core/widgets/section_heading.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';
import 'package:mynewapp/features/settings/presentation/pages/about_page.dart';
import 'package:mynewapp/features/settings/presentation/state/settings_cubit.dart';
import 'package:mynewapp/features/settings/presentation/widgets/reading_size_control.dart';
import 'package:mynewapp/l10n/l10n.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ContentWidth(
        child: BlocBuilder<SettingsCubit, AppSettings>(
          builder: (context, settings) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              SectionHeading(l10n.language),
              const SizedBox(height: AppSpacing.sm),
              OptionGroup<AppLanguage>(
                selected: settings.language,
                onSelected: cubit.setLanguage,
                options: [
                  (AppLanguage.system, l10n.languageSystem),
                  (AppLanguage.arabic, l10n.languageArabic),
                  (AppLanguage.english, l10n.languageEnglish),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeading(l10n.theme),
              const SizedBox(height: AppSpacing.sm),
              OptionGroup<ThemePreference>(
                selected: settings.theme,
                onSelected: cubit.setTheme,
                options: [
                  (ThemePreference.system, l10n.themeSystem),
                  (ThemePreference.light, l10n.themeLight),
                  (ThemePreference.dark, l10n.themeDark),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeading(l10n.digitsHeading),
              const SizedBox(height: AppSpacing.sm),
              OptionGroup<DigitStyle>(
                selected: settings.digits,
                onSelected: cubit.setDigits,
                options: [
                  (DigitStyle.automatic, l10n.digitsAutomatic),
                  (DigitStyle.arabicIndic, l10n.digitsArabicIndic),
                  (DigitStyle.western, l10n.digitsWestern),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeading(l10n.textSize),
              const SizedBox(height: AppSpacing.sm),
              const ReadingSizeControl(),
              const SizedBox(height: AppSpacing.xl),
              SectionHeading(l10n.offlineCopies),
              const SizedBox(height: AppSpacing.sm),
              _OfflineCopies(
                enabled: settings.offlineCopies,
                onChanged: (v) => cubit.setOfflineCopies(enabled: v),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTile(
                title: l10n.aboutTitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AboutPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The switch for saved copies, with a button that removes them.
class _OfflineCopies extends StatelessWidget {
  const _OfflineCopies({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            value: enabled,
            onChanged: onChanged,
            title: Text(
              l10n.offlineCopies,
              style: const TextStyle(
                fontSize: AppTextSize.body + 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              l10n.offlineCopiesHint,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          const Divider(),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final message = l10n.savedCopiesCleared;
                await context.read<ResponseCache>().clear();
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(message)));
              },
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.clearSavedCopies),
            ),
          ),
        ],
      ),
    );
  }
}
