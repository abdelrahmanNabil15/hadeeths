import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/option_group.dart';
import 'package:mynewapp/core/widgets/section_heading.dart';
import 'package:mynewapp/features/prayer_times/domain/hijri_settings.dart';
import 'package:mynewapp/features/prayer_times/presentation/date_labels.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/prayer_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Choose which Hijri calendar to follow and correct it by up to two days.
class HijriPage extends StatelessWidget {
  const HijriPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<PrayerCubit>();
    const days = [-2, -1, 0, 1, 2];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.hijriHeading)),
      body: ContentWidth(
        child: BlocBuilder<PrayerCubit, PrayerState>(
          builder: (context, state) {
            final hijri = state.preferences.hijri;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                OptionGroup<HijriReference>(
                  selected: hijri.reference,
                  onSelected: (value) =>
                      cubit.setHijri(hijri.copyWith(reference: value)),
                  options: [
                    for (final r in HijriReference.values)
                      (r, hijriReferenceName(l10n, r)),
                  ],
                  subtitles: [
                    for (final r in HijriReference.values)
                      hijriReferenceNote(l10n, r),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeading(l10n.hijriAdjustHeading),
                const SizedBox(height: AppSpacing.sm),
                OptionGroup<int>(
                  selected: hijri.adjustmentDays,
                  onSelected: (value) =>
                      cubit.setHijri(hijri.copyWith(adjustmentDays: value)),
                  options: [
                    for (final d in days) (d, hijriAdjustmentLabel(l10n, d)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.hijriAdjustHint,
                  style: TextStyle(
                    fontSize: AppTextSize.meta,
                    height: AppLineHeight.body,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.hijriChangesAtMaghrib,
                  style: TextStyle(
                    fontSize: AppTextSize.meta,
                    height: AppLineHeight.body,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
