import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/cache/response_cache.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/core/widgets/app_card.dart';
import 'package:mynewapp/core/widgets/app_tile.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/option_group.dart';
import 'package:mynewapp/core/widgets/section_heading.dart';
import 'package:mynewapp/core/widgets/switch_row.dart';
import 'package:mynewapp/features/daily_hadith/domain/daily_hadith_store.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';
import 'package:mynewapp/features/settings/presentation/pages/about_page.dart';
import 'package:mynewapp/features/settings/presentation/state/settings_cubit.dart';
import 'package:mynewapp/features/settings/presentation/widgets/reading_size_control.dart';
import 'package:mynewapp/l10n/l10n.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, this.onDeleteAll});

  /// Deletes everything the app keeps about the user; true when all of it went. Only given when
  /// the newer sections are on (the released app keeps no other data), so the section is hidden
  /// otherwise. On success the app starts afresh, so this page does not stay open.
  final Future<bool> Function()? onDeleteAll;

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
              if (context.read<DailyHadithStore?>() case final daily?) ...[
                const SizedBox(height: AppSpacing.xl),
                SectionHeading(l10n.dailyHadithHeading),
                const SizedBox(height: AppSpacing.sm),
                _RememberOpened(store: daily),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppTile(
                title: l10n.aboutTitle,
                onTap: () => Navigator.of(context).push(
                  appRoute<void>(
                    builder: (_) => AboutPage(extended: onDeleteAll != null),
                  ),
                ),
              ),
              if (onDeleteAll != null) ...[
                const SizedBox(height: AppSpacing.xl),
                SectionHeading(l10n.deleteAllHeading),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.deleteAllBody,
                  style: TextStyle(
                    fontSize: AppTextSize.meta,
                    height: AppLineHeight.body,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _DeleteAllButton(onDeleteAll: onDeleteAll!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks first, then deletes everything. A partial failure is reported here; on success the app
/// restarts from its first page and says so there.
class _DeleteAllButton extends StatelessWidget {
  const _DeleteAllButton({required this.onDeleteAll});

  final Future<bool> Function() onDeleteAll;

  Future<void> _confirm(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAllTitle),
        content: Text(l10n.deleteAllConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.notNow),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteAllConfirm),
          ),
        ],
      ),
    );
    if (!(agreed ?? false)) return;
    final partial = l10n.deleteAllPartial;
    final ok = await onDeleteAll();
    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(partial)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.error,
        side: BorderSide(color: scheme.error),
      ),
      onPressed: () => _confirm(context),
      icon: const Icon(Icons.delete_forever_outlined),
      label: Text(context.l10n.deleteAllButton),
    );
  }
}

/// Whether the hadith of the day is chosen from the categories the user opens. Switching it off also
/// forgets the ones already remembered.
class _RememberOpened extends StatefulWidget {
  const _RememberOpened({required this.store});

  final DailyHadithStore store;

  @override
  State<_RememberOpened> createState() => _RememberOpenedState();
}

class _RememberOpenedState extends State<_RememberOpened> {
  bool? _on;

  @override
  void initState() {
    super.initState();
    widget.store.remembersOpened().then((on) {
      if (mounted) setState(() => _on = on);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final on = _on;
    return SwitchRow(
      title: l10n.dailyHadithRemember,
      subtitle: l10n.dailyHadithRememberHint,
      value: on ?? true,
      onChanged: on == null
          ? null
          : (value) async {
              setState(() => _on = value);
              await widget.store.setRemembersOpened(value);
            },
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
    return AppCard(
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
