import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/features/quran/domain/quran_search.dart';
import 'package:mynewapp/features/quran/domain/quran_text.dart';
import 'package:mynewapp/features/quran/presentation/pages/sura_reader_page.dart';
import 'package:mynewapp/features/quran/presentation/quran_labels.dart';
import 'package:mynewapp/features/quran/presentation/state/quran_cubit.dart';
import 'package:mynewapp/features/settings/presentation/state/settings_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Search by words, on the device. Results show each verse exactly as in the source.
class QuranSearchPage extends StatefulWidget {
  const QuranSearchPage({super.key});

  @override
  State<QuranSearchPage> createState() => _QuranSearchPageState();
}

class _QuranSearchPageState extends State<QuranSearchPage> {
  final _field = TextEditingController();
  List<Verse> _results = const [];

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _run(String query) {
    final search = context.read<QuranCubit>().search;
    setState(() => _results = search?.search(query) ?? const []);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final digits = context.digits;
    final query = _field.text.trim();
    final tooShort = query.isNotEmpty && query.length < QuranSearch.minLength;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.quranSearchHint)),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextField(
              controller: _field,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.quranSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: _run,
            ),
            const SizedBox(height: AppSpacing.md),
            if (tooShort)
              Text(
                l10n.quranSearchTooShort,
                style: AppTypography.of(context).meta,
              )
            else if (query.isNotEmpty)
              Semantics(
                liveRegion: true,
                child: Text(
                  _results.isEmpty
                      ? l10n.quranNoResults
                      : digits.localize(l10n.quranSearchCount(_results.length)),
                  style: AppTypography.of(context).meta,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            for (final verse in _results) ...[
              VerseResultTile(verse: verse, digits: digits),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

/// A verse in a list (search results, bookmarks): where it is, and its text unchanged.
class VerseResultTile extends StatelessWidget {
  const VerseResultTile({super.key, required this.verse, required this.digits});

  final Verse verse;
  final Digits digits;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scale = context.select((SettingsCubit c) => c.state.readingScale);
    final where =
        '${suraName(context, verse.sura)} ${digits.format(verse.sura)}:'
        '${digits.format(verse.number)}';
    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openSura(context, verse.sura, verse: verse.number),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(where, style: AppTypography.of(context).label),
              const SizedBox(height: AppSpacing.sm),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  verse.text,
                  style: quranTextStyle(context, scale: scale * 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
