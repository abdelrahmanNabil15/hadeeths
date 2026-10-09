import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/features/prayer_times/domain/city.dart';
import 'package:mynewapp/features/prayer_times/domain/location_setup.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';
import 'package:mynewapp/features/prayer_times/presentation/pages/city_picker_page.dart';
import 'package:mynewapp/features/prayer_times/presentation/prayer_labels.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/prayer_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Two ways to set the place: "Use my location" (explained first, read once) or a city picked
/// by hand (no permission). Shown when nothing is set and when the user wants to change it.
class PrayerSetupView extends StatelessWidget {
  const PrayerSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<PrayerCubit>();
    return ContentWidth(
      child: BlocBuilder<PrayerCubit, PrayerState>(
        builder: (context, state) {
          final problem = state.setupProblem == null
              ? null
              : locationProblemMessage(l10n, state.setupProblem!);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 48,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                header: true,
                child: Text(
                  l10n.prayerSetupTitle,
                  style: TextStyle(
                    fontSize: AppTextSize.title,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.prayerSetupBody,
                style: TextStyle(
                  fontSize: AppTextSize.body,
                  height: AppLineHeight.body,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (problem != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  liveRegion: true,
                  container: true,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: scheme.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          problem,
                          style: TextStyle(
                            fontSize: AppTextSize.body,
                            height: AppLineHeight.body,
                            color: scheme.onSurface,
                          ),
                        ),
                        if (state.setupProblem ==
                            LocationSetupStatus.needsSettings)
                          TextButton(
                            onPressed: cubit.openAppSettings,
                            child: Text(l10n.openSettings),
                          ),
                        if (state.setupProblem ==
                            LocationSetupStatus.serviceDisabled)
                          TextButton(
                            onPressed: cubit.openLocationSettings,
                            child: Text(l10n.openSettings),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (state.locating)
                Semantics(
                  liveRegion: true,
                  label: l10n.locating,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(l10n.locating)),
                    ],
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: () =>
                      cubit.useMyLocation(explain: () => _explain(context)),
                  icon: const Icon(Icons.my_location),
                  label: Text(l10n.useMyLocation),
                ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: state.locating ? null : () => _pickCity(context),
                icon: const Icon(Icons.location_city),
                label: Text(l10n.chooseCity),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<bool> _explain(BuildContext context) async {
    final l10n = context.l10n;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.locationExplainTitle),
        content: Text(l10n.locationExplainBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.continueAction),
          ),
        ],
      ),
    );
    return agreed ?? false;
  }

  static Future<void> _pickCity(BuildContext context) async {
    final cubit = context.read<PrayerCubit>();
    final services = context.read<PrayerServices>();
    final language = context.apiLanguage;
    final city = await Navigator.of(context).push<City>(
      MaterialPageRoute<City>(
        builder: (_) => CityPickerPage(loadCities: services.loadCities),
      ),
    );
    if (city != null) {
      await cubit.selectCity(city, languageCode: language);
    }
  }
}
