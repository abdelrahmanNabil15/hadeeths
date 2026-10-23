import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';
import 'package:mynewapp/features/quran/presentation/state/quran_content_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// [editionId]'s translation of [verse], fetched on demand and shown under the Arabic verse in
/// the UI language's own font -- never interleaved with or styled to look like the Arabic.
/// Shows nothing while loading or if the fetch failed: a translation is a supplement to the
/// reading, not something an error banner should interrupt it for.
class TranslationBlock extends StatefulWidget {
  const TranslationBlock({
    super.key,
    required this.editionId,
    required this.editionName,
    required this.verse,
  });

  final int editionId;
  final String editionName;
  final VerseRef verse;

  @override
  State<TranslationBlock> createState() => _TranslationBlockState();
}

class _TranslationBlockState extends State<TranslationBlock> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TranslationBlock old) {
    super.didUpdateWidget(old);
    if (old.editionId != widget.editionId || old.verse != widget.verse) {
      _load();
    }
  }

  void _load() => context.read<QuranContentCubit>().loadTranslation(
    editionId: widget.editionId,
    verse: widget.verse,
  );

  @override
  Widget build(BuildContext context) {
    final text = context.select(
      (QuranContentCubit c) => c.translationFor(widget.editionId, widget.verse),
    );
    if (text == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: AppTypography.of(
              context,
            ).body.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.quranTranslationCredit(widget.editionName),
            style: AppTypography.of(context).meta,
          ),
        ],
      ),
    );
  }
}
