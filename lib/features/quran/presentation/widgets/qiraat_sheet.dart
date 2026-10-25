import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/quran/domain/qiraat.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';
import 'package:mynewapp/features/quran/presentation/state/qiraat_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Opens [verse]'s approved Qira'at (recitation-variant) comparison in a resizable, scrollable
/// bottom sheet: a loading state, the comparison once fetched (every juncture, its readings and
/// who holds each one, with a disclaimer and credit), an explicit "none" state (most verses have
/// no approved variations -- that is normal, not an error), or a fetch error with retry.
Future<void> showQiraatSheet(
  BuildContext context, {
  required QiraatCubit cubit,
  required VerseRef verse,
  required String title,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (sheetContext) => BlocProvider.value(
    value: cubit,
    child: DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      expand: false,
      builder: (sheetContext, scrollController) => _QiraatSheetContent(
        verse: verse,
        title: title,
        scrollController: scrollController,
      ),
    ),
  ),
);

class _QiraatSheetContent extends StatefulWidget {
  const _QiraatSheetContent({
    required this.verse,
    required this.title,
    required this.scrollController,
  });

  final VerseRef verse;
  final String title;
  final ScrollController scrollController;

  @override
  State<_QiraatSheetContent> createState() => _QiraatSheetContentState();
}

class _QiraatSheetContentState extends State<_QiraatSheetContent> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => context.read<QiraatCubit>().load(widget.verse);

  void _retry() {
    context.read<QiraatCubit>().retry(widget.verse);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.watch<QiraatCubit>();
    final matrix = cubit.matrixFor(widget.verse);
    final failure = cubit.failureFor(widget.verse);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                widget.title,
                style: AppTypography.of(context).heading,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: failure != null
                  ? SingleChildScrollView(
                      controller: widget.scrollController,
                      child: ErrorView(failure: failure, onRetry: _retry),
                    )
                  : matrix == null
                  ? const Center(child: LoadingView())
                  : !matrix.hasVariations
                  ? SingleChildScrollView(
                      controller: widget.scrollController,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xl,
                          ),
                          child: Text(
                            l10n.quranQiraatNone,
                            textAlign: TextAlign.center,
                            style: AppTypography.of(context).body,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      controller: widget.scrollController,
                      children: [
                        for (final juncture in matrix.junctures) ...[
                          _JunctureView(juncture: juncture),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        Text(
                          l10n.quranQiraatDisclaimer,
                          style: AppTypography.of(context).meta,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.quranQiraatCredit,
                          style: AppTypography.of(context).meta,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

String _categoryLabel(AppLocalizations l10n, QiraatCategory category) =>
    switch (category) {
      QiraatCategory.meaning => l10n.quranQiraatCategoryMeaning,
      QiraatCategory.wording => l10n.quranQiraatCategoryWording,
      QiraatCategory.pronunciation => l10n.quranQiraatCategoryPronunciation,
      QiraatCategory.unknown => '',
    };

class _JunctureView extends StatelessWidget {
  const _JunctureView({required this.juncture});

  final QiraatJuncture juncture;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final categoryLabel = _categoryLabel(l10n, juncture.category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categoryLabel.isNotEmpty)
          Text(
            categoryLabel,
            style: AppTypography.of(
              context,
            ).label.copyWith(color: scheme.primary),
          ),
        const SizedBox(height: AppSpacing.xs),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(juncture.text, style: AppTypography.of(context).body),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final reading in juncture.readings) ...[
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(reading.text, style: AppTypography.of(context).body),
          ),
          Text(
            reading.attributions.join(', '),
            style: AppTypography.of(context).meta,
          ),
          if (reading.translation != null)
            Text(reading.translation!, style: AppTypography.of(context).meta),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (juncture.commentary != null)
          Text(juncture.commentary!, style: AppTypography.of(context).meta),
      ],
    );
  }
}
