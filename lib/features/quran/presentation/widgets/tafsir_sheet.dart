import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';
import 'package:mynewapp/features/quran/presentation/state/quran_content_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Opens [editionId]'s tafsir of [verse] in a resizable, scrollable bottom sheet: a loading
/// state, the text once fetched (with a credit line and a note that it is a scholar's
/// interpretation, not the Quran itself), or an error with retry.
///
/// Unlike `TranslationBlock` (ambient, ever-present, silent on failure), this is open because the
/// reader explicitly asked to read the tafsir, so it always shows what happened.
Future<void> showTafsirSheet(
  BuildContext context, {
  required QuranContentCubit contentCubit,
  required int editionId,
  required String editionName,
  required VerseRef verse,
  required String title,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (sheetContext) => BlocProvider.value(
    value: contentCubit,
    child: DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      expand: false,
      builder: (sheetContext, scrollController) => _TafsirSheetContent(
        editionId: editionId,
        editionName: editionName,
        verse: verse,
        title: title,
        scrollController: scrollController,
      ),
    ),
  ),
);

class _TafsirSheetContent extends StatefulWidget {
  const _TafsirSheetContent({
    required this.editionId,
    required this.editionName,
    required this.verse,
    required this.title,
    required this.scrollController,
  });

  final int editionId;
  final String editionName;
  final VerseRef verse;
  final String title;
  final ScrollController scrollController;

  @override
  State<_TafsirSheetContent> createState() => _TafsirSheetContentState();
}

class _TafsirSheetContentState extends State<_TafsirSheetContent> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => context.read<QuranContentCubit>().loadTafsir(
    editionId: widget.editionId,
    verse: widget.verse,
  );

  void _retry() {
    context.read<QuranContentCubit>().retryTafsir(
      widget.editionId,
      widget.verse,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.watch<QuranContentCubit>();
    final text = cubit.tafsirFor(widget.editionId, widget.verse);
    final failure = cubit.tafsirFailureFor(widget.editionId, widget.verse);
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
                  : text == null
                  ? const Center(child: LoadingView())
                  : ListView(
                      controller: widget.scrollController,
                      children: [
                        Text(text, style: AppTypography.of(context).body),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.quranTafsirDisclaimer,
                          style: AppTypography.of(context).meta,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.quranTafsirCredit(widget.editionName),
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
