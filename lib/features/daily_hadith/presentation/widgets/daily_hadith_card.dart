import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/core/widgets/animated_state_switcher.dart';
import 'package:mynewapp/core/widgets/app_card.dart';
import 'package:mynewapp/core/widgets/app_icons.dart';
import 'package:mynewapp/core/widgets/ornament_divider.dart';
import 'package:mynewapp/core/widgets/section_heading.dart';
import 'package:mynewapp/features/daily_hadith/domain/daily_hadith_service.dart';
import 'package:mynewapp/features/daily_hadith/presentation/state/daily_hadith_cubit.dart';
import 'package:mynewapp/features/hadiths/presentation/pages/hadith_details_page.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// The "hadith of the day" section on the home screen: the hadith's title as the source gives it,
/// the category it came from and the source credit. Tapping opens the hadith, with its text and
/// reference. Hidden when there is nothing to choose from; a short message with a retry when it
/// could not be loaded. It never shows invented content.
class DailyHadithSection extends StatelessWidget {
  const DailyHadithSection({super.key, required this.service});

  final DailyHadithService service;

  @override
  Widget build(BuildContext context) {
    final language = context.apiLanguage;
    return BlocProvider(
      key: ValueKey(language),
      create: (_) => DailyHadithCubit(service, language: language)..load(),
      child: BlocBuilder<DailyHadithCubit, DailyHadithState>(
        builder: (context, state) {
          if (state.status == DailyHadithStatus.none) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeading(context.l10n.dailyHadithHeading),
                const SizedBox(height: AppSpacing.md),
                AnimatedStateSwitcher(
                  child: switch (state.status) {
                    DailyHadithStatus.ready => _HadithCard(
                      key: const ValueKey('ready'),
                      hadith: state.hadith!,
                    ),
                    DailyHadithStatus.failure => _Unavailable(
                      key: const ValueKey('failure'),
                      onRetry: context.read<DailyHadithCubit>().load,
                    ),
                    _ => const _Placeholder(key: ValueKey('loading')),
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  const _HadithCard({super.key, required this.hadith});

  final DailyHadith hadith;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = AppTypography.of(context);
    final scheme = Theme.of(context).colorScheme;
    final from = l10n.dailyHadithFrom(hadith.categoryTitle);
    void open() => Navigator.of(
      context,
    ).push(appRoute<void>(builder: (_) => HadithDetailsPage(id: hadith.id)));
    return Semantics(
      button: true,
      label: '${l10n.dailyHadithHeading}: ${hadith.title}. $from',
      excludeSemantics: true,
      onTap: open,
      child: AppCard(
        raised: true,
        color: AppColors.of(context).readingSurface,
        onTap: open,
        padding: const EdgeInsets.all(AppSpacing.lg + AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hadith.title,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: type.editorial.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: AppTextSize.heading + 2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const OrnamentDivider(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    from,
                    style: type.meta.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(
                  AppIcons.chevron,
                  size: AppSizes.iconSmall,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
            Text(l10n.sourceCredit, style: type.meta),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.loading,
    excludeSemantics: true,
    child: const AppCard(child: SizedBox(height: 140, width: double.infinity)),
  );
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.dailyHadithUnavailable,
              style: AppTypography.of(context).body,
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}
