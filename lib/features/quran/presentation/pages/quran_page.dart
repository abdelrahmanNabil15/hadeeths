import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/core/widgets/animated_state_switcher.dart';
import 'package:mynewapp/core/widgets/app_tile.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/section_heading.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/quran/domain/quran_source.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';
import 'package:mynewapp/features/quran/presentation/pages/quran_bookmarks_page.dart';
import 'package:mynewapp/features/quran/presentation/pages/quran_search_page.dart';
import 'package:mynewapp/features/quran/presentation/pages/sura_reader_page.dart';
import 'package:mynewapp/features/quran/presentation/quran_labels.dart';
import 'package:mynewapp/features/quran/presentation/state/quran_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// The Quran section: continue reading, bookmarks, search, go to a verse, and the list of suras.
/// If the verified text is not in this build, it says so and shows nothing else.
class QuranPage extends StatelessWidget {
  const QuranPage({super.key, required this.source, this.userData});

  final QuranSource source;
  final QuranUserData? userData;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuranCubit(source: source, userData: userData)..load(),
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.navQuran)),
        body: BlocBuilder<QuranCubit, QuranState>(
          builder: (context, state) => AnimatedStateSwitcher(
            child: switch (state.status) {
              QuranStatus.loading => const LoadingView(
                key: ValueKey('loading'),
              ),
              QuranStatus.unavailable => EmptyView(
                key: const ValueKey('unavailable'),
                message: context.l10n.quranUnavailable,
                icon: Icons.menu_book_outlined,
              ),
              QuranStatus.ready => _Index(
                key: const ValueKey('ready'),
                state: state,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _Index extends StatelessWidget {
  const _Index({super.key, required this.state});

  final QuranState state;

  void _push(BuildContext context, Widget page) {
    final cubit = context.read<QuranCubit>();
    Navigator.of(context).push(
      appRoute<void>(
        builder: (_) => BlocProvider.value(value: cubit, child: page),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final digits = context.digits;
    final text = state.text!;
    final last = state.lastRead;
    return ContentWidth(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (last != null) ...[
            AppTile(
              emphasized: true,
              pressFeedback: true,
              title: l10n.quranContinue,
              trailingText: l10n.quranContinueAt(
                suraName(context, last.sura),
                digits.format(last.verse),
              ),
              onTap: () => openSura(context, last.sura, verse: last.verse),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppTile(
            pressFeedback: true,
            title: l10n.quranSearchHint,
            onTap: () => _push(context, const QuranSearchPage()),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTile(
            pressFeedback: true,
            title: l10n.quranBookmarks,
            trailingText: digits.format(state.bookmarks.length),
            onTap: () => _push(context, const QuranBookmarksPage()),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTile(
            pressFeedback: true,
            title: l10n.quranJump,
            onTap: () => showGoToVerse(context),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeading(l10n.quranSurasHeading),
          const SizedBox(height: AppSpacing.sm),
          for (var s = 1; s <= text.suraTotal; s++) ...[
            AppTile(
              title: '${digits.format(s)}. ${suraName(context, s)}',
              trailingText: l10n
                  .quranVerses(text.versesIn(s))
                  .replaceAllMapped(
                    RegExp(r'\d+'),
                    (m) => digits.format(int.parse(m[0]!)),
                  ),
              onTap: () => openSura(context, s),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.quranCredit, style: AppTypography.of(context).meta),
        ],
      ),
    );
  }
}

/// Asks for a sura and a verse, then opens the reader there.
Future<void> showGoToVerse(BuildContext context) async {
  final text = context.read<QuranCubit>().state.text!;
  final place = await showDialog<VerseRef>(
    context: context,
    builder: (_) =>
        _GoToVerseDialog(suraTotal: text.suraTotal, versesIn: text.versesIn),
  );
  if (place != null && context.mounted) {
    openSura(context, place.sura, verse: place.verse);
  }
}

/// Owns its text fields, so they live exactly as long as the dialog (including its closing
/// animation).
class _GoToVerseDialog extends StatefulWidget {
  const _GoToVerseDialog({required this.suraTotal, required this.versesIn});

  final int suraTotal;
  final int Function(int sura) versesIn;

  @override
  State<_GoToVerseDialog> createState() => _GoToVerseDialogState();
}

class _GoToVerseDialogState extends State<_GoToVerseDialog> {
  final _suraField = TextEditingController();
  final _verseField = TextEditingController();

  @override
  void dispose() {
    _suraField.dispose();
    _verseField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sura = int.tryParse(_suraField.text);
    final validSura = sura != null && sura >= 1 && sura <= widget.suraTotal;
    final max = validSura ? widget.versesIn(sura) : null;
    final verse = int.tryParse(_verseField.text);
    final validVerse =
        _verseField.text.isEmpty ||
        (verse != null && verse >= 1 && verse <= max!);
    final valid = validSura && validVerse;
    return AlertDialog(
      title: Text(l10n.quranJump),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _suraField,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.quranJumpSura,
              helperText: validSura ? suraName(context, sura) : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _verseField,
            keyboardType: TextInputType.number,
            enabled: validSura,
            decoration: InputDecoration(
              labelText: max == null
                  ? l10n.quranJumpVerseLabel
                  : l10n.quranJumpVerse(context.digits.format(max)),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.notNow),
        ),
        FilledButton(
          onPressed: valid
              ? () => Navigator.of(context).pop(VerseRef(sura, verse ?? 1))
              : null,
          child: Text(l10n.quranGo),
        ),
      ],
    );
  }
}
