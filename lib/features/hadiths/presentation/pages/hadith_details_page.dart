import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/state/load_status.dart';
import 'package:mynewapp/core/widgets/custom_text.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_details.dart';
import 'package:mynewapp/features/hadiths/domain/hadiths_repository.dart';
import 'package:mynewapp/features/hadiths/presentation/share_text.dart';
import 'package:mynewapp/features/hadiths/presentation/state/hadith_detail_cubit.dart';
import 'package:mynewapp/features/hadiths/presentation/widgets/text_sheet.dart';
import 'package:mynewapp/l10n/l10n.dart';
import 'package:share_plus/share_plus.dart';

/// One hadith, loaded by id with its own cubit (independent of any list).
class HadithDetailsPage extends StatelessWidget {
  const HadithDetailsPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final language = context.apiLanguage;
    return BlocProvider(
      create: (context) => HadithDetailCubit(
        context.read<HadithsRepository>(),
        id,
        language: language,
      )..load(),
      child: Scaffold(
        appBar: AppBar(backgroundColor: AppColors.appBar),
        body: BlocBuilder<HadithDetailCubit, HadithDetailState>(
          builder: (context, state) {
            switch (state.status) {
              case LoadStatus.initial:
              case LoadStatus.loading:
                return const LoadingView();
              case LoadStatus.failure:
                return ErrorView(
                  failure: state.failure!,
                  onRetry: context.read<HadithDetailCubit>().load,
                );
              case LoadStatus.success:
                return HadithDetailsBody(details: state.details!);
            }
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
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CustomText(
                        fontWeight: FontWeight.bold,
                        alignment: AlignmentDirectional.centerStart,
                        color: AppColors.heading,
                        text: l10n.hadithLabel,
                        fontSize: AppTextSize.heading,
                        isHeader: true,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.shareHadith,
                      icon: const Icon(Icons.share),
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(
                          text: hadithShareText(d, credit: l10n.sourceCredit),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: SelectionArea(
                    child: CustomText(
                      fontWeight: FontWeight.normal,
                      alignment: AlignmentDirectional.centerStart,
                      text: d.hadeeth,
                      fontSize: AppTextSize.hadith,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (d.grade.isNotEmpty || d.attribution.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (d.attribution.isNotEmpty)
                        Expanded(
                          child: CustomText(
                            fontWeight: FontWeight.normal,
                            alignment: AlignmentDirectional.centerStart,
                            color: AppColors.accent,
                            text: '[${d.attribution}]',
                            fontSize: AppTextSize.body,
                          ),
                        ),
                      if (d.grade.isNotEmpty)
                        Expanded(
                          child: CustomText(
                            fontWeight: FontWeight.normal,
                            alignment: AlignmentDirectional.centerEnd,
                            color: AppColors.accent,
                            text: '[${d.grade}]',
                            fontSize: AppTextSize.body,
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.sm),
                if (d.explanation.isNotEmpty)
                  _SectionRow(
                    title: l10n.explanation,
                    onTap: () => _showTextSheet(
                      context,
                      l10n.explanationTitle,
                      d.explanation,
                    ),
                  ),
                if (d.hints.isNotEmpty)
                  _SectionRow(
                    title: l10n.benefits,
                    onTap: () => _showHintsSheet(context, d.hints),
                  ),
                if (d.wordsMeanings.isNotEmpty) ...[
                  CustomText(
                    fontWeight: FontWeight.bold,
                    alignment: AlignmentDirectional.centerStart,
                    color: AppColors.heading,
                    text: l10n.wordMeanings,
                    fontSize: AppTextSize.heading,
                    isHeader: true,
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: d.wordsMeanings.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: AppColors.accent),
                    itemBuilder: (context, index) {
                      final w = d.wordsMeanings[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomText(
                              fontWeight: FontWeight.bold,
                              alignment: AlignmentDirectional.centerStart,
                              color: AppColors.accent,
                              text: w.word.isEmpty ? '' : '${w.word}:',
                              fontSize: AppTextSize.body,
                            ),
                          ),
                          Expanded(
                            child: CustomText(
                              fontWeight: FontWeight.normal,
                              alignment: AlignmentDirectional.centerStart,
                              text: w.meaning,
                              fontSize: AppTextSize.body,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
                if (d.reference.isNotEmpty)
                  _SectionRow(
                    title: l10n.sources,
                    onTap: () =>
                        _showTextSheet(context, l10n.sourcesTitle, d.reference),
                  ),
                const SizedBox(height: AppSpacing.lg),
                CustomText(
                  fontWeight: FontWeight.normal,
                  alignment: Alignment.center,
                  color: AppColors.inkMuted,
                  text: l10n.sourceCredit,
                  fontSize: AppTextSize.meta,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tappable row that opens a secondary section.
class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomText(
                    fontWeight: FontWeight.bold,
                    alignment: AlignmentDirectional.centerStart,
                    color: AppColors.heading,
                    text: title,
                    fontSize: AppTextSize.heading,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: AppColors.heading),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showTextSheet(BuildContext context, String title, String text) {
  final credit = context.l10n.sourceCredit;
  showModalBottomSheet<void>(
    isScrollControlled: true,
    context: context,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.modal),
    ),
    builder: (context) => HadithTextSheet(
      title: title,
      text: text,
      onShare: () => SharePlus.instance.share(
        ShareParams(text: sectionShareText(text, credit: credit)),
      ),
    ),
  );
}

void _showHintsSheet(BuildContext context, List<String> hints) {
  final credit = context.l10n.sourceCredit;
  final numbered = [
    for (var i = 0; i < hints.length; i++) '${i + 1}:  ${hints[i]}',
  ];
  showModalBottomSheet<void>(
    isScrollControlled: true,
    enableDrag: true,
    context: context,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.modal),
    ),
    builder: (context) => HadithTextSheet(
      title: context.l10n.benefits,
      text: numbered.join('\n\n'),
      onShare: () => SharePlus.instance.share(
        ShareParams(
          text: sectionShareText(numbered.join('\n'), credit: credit),
        ),
      ),
    ),
  );
}
