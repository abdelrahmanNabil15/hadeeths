import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/state/load_status.dart';
import 'package:mynewapp/core/widgets/animated_state_switcher.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/expandable_section.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/favorites/presentation/favorite_button.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_details.dart';
import 'package:mynewapp/features/hadiths/domain/hadiths_repository.dart';
import 'package:mynewapp/features/hadiths/presentation/share_text.dart';
import 'package:mynewapp/features/hadiths/presentation/state/hadith_detail_cubit.dart';
import 'package:mynewapp/features/hadiths/presentation/widgets/reading_surface.dart';
import 'package:mynewapp/features/settings/presentation/state/settings_cubit.dart';
import 'package:mynewapp/features/settings/presentation/widgets/reading_size_control.dart';
import 'package:mynewapp/features/settings/presentation/widgets/reading_text.dart';
import 'package:mynewapp/l10n/l10n.dart';
import 'package:share_plus/share_plus.dart';

/// One hadith, loaded by id with its own cubit (independent of any list).
class HadithDetailsPage extends StatelessWidget {
  const HadithDetailsPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final language = context.apiLanguage;
    final l10n = context.l10n;
    return BlocProvider(
      create: (context) => HadithDetailCubit(
        context.read<HadithsRepository>(),
        id,
        language: language,
      )..load(),
      child: Scaffold(
        appBar: AppBar(
          actions: [
            FavoriteButton(hadithId: id),
            const ReadingSizeButton(),
            BlocBuilder<HadithDetailCubit, HadithDetailState>(
              builder: (context, state) {
                final details = state.details;
                if (details == null) return const SizedBox.shrink();
                return IconButton(
                  tooltip: l10n.shareHadith,
                  icon: const Icon(Icons.share),
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      text: hadithShareText(details, credit: l10n.sourceCredit),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<HadithDetailCubit, HadithDetailState>(
          builder: (context, state) {
            // The hadith itself is never faded: it appears exactly as before. Only the loading
            // and error states fade into each other (for example after a retry).
            if (state.status == LoadStatus.success) {
              return HadithDetailsBody(details: state.details!);
            }
            return AnimatedStateSwitcher(
              child: state.status == LoadStatus.failure
                  ? ErrorView(
                      key: const ValueKey('failure'),
                      failure: state.failure!,
                      onRetry: context.read<HadithDetailCubit>().load,
                    )
                  : const LoadingView(key: ValueKey('loading')),
            );
          },
        ),
      ),
    );
  }
}

class HadithDetailsBody extends StatelessWidget {
  const HadithDetailsBody({super.key, required this.details});

  final HadithDetails details;

  @override
  Widget build(BuildContext context) {
    final d = details;
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final scale = context.select((SettingsCubit c) => c.state.readingScale);
    final secondary = readingTextStyle(context, scale: scale, factor: 0.8);
    final credit = l10n.sourceCredit;
    return SafeArea(
      child: ContentWidth(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (d.title.isNotEmpty) ...[
                Semantics(
                  header: true,
                  child: SelectionArea(
                    child: Text(
                      d.title,
                      style: TextStyle(
                        fontSize: AppTextSize.title - 2,
                        fontWeight: FontWeight.w700,
                        height: AppLineHeight.body,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              ReadingSurface(text: d.hadeeth, scale: scale),
              if (d.grade.isNotEmpty || d.attribution.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                SourceBlock(attribution: d.attribution, grade: d.grade),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (d.explanation.isNotEmpty) ...[
                ExpandableSection(
                  title: l10n.explanation,
                  shareTooltip: l10n.share,
                  onShare: () => SharePlus.instance.share(
                    ShareParams(
                      text: sectionShareText(d.explanation, credit: credit),
                    ),
                  ),
                  child: SelectionArea(
                    child: Text(d.explanation, style: secondary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (d.hints.isNotEmpty) ...[
                ExpandableSection(
                  title: l10n.benefits,
                  child: SelectionArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < d.hints.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: Text(
                              '${context.digits.format(i + 1)}. ${d.hints[i]}',
                              style: secondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (d.wordsMeanings.isNotEmpty) ...[
                ExpandableSection(
                  title: l10n.wordMeanings,
                  child: SelectionArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final w in d.wordsMeanings)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: w.word.isEmpty ? '' : '${w.word}: ',
                                    style: secondary.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  TextSpan(text: w.meaning, style: secondary),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (d.reference.isNotEmpty) ...[
                ExpandableSection(
                  title: l10n.sources,
                  shareTooltip: l10n.share,
                  onShare: () => SharePlus.instance.share(
                    ShareParams(
                      text: sectionShareText(d.reference, credit: credit),
                    ),
                  ),
                  child: SelectionArea(
                    child: Text(
                      d.reference,
                      style: TextStyle(
                        fontSize: AppTextSize.body,
                        height: AppLineHeight.body,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              const SizedBox(height: AppSpacing.lg),
              SelectionArea(
                child: Text(
                  credit,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTextSize.meta,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
