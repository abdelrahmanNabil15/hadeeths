import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/core/state/load_status.dart';
import 'package:mynewapp/core/widgets/app_card.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/quran/domain/quran_search.dart';
import 'package:mynewapp/features/quran/domain/quran_text.dart';
import 'package:mynewapp/features/quran/domain/quran_translation_search.dart';
import 'package:mynewapp/features/quran/presentation/pages/sura_reader_page.dart';
import 'package:mynewapp/features/quran/presentation/pages/translation_edition_picker_page.dart';
import 'package:mynewapp/features/quran/presentation/quran_labels.dart';
import 'package:mynewapp/features/quran/presentation/state/quran_content_cubit.dart';
import 'package:mynewapp/features/quran/presentation/state/quran_cubit.dart';
import 'package:mynewapp/features/settings/presentation/state/settings_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

enum _SearchTab { quran, translation }

/// Search by words. Always offers the on-device Arabic search over the verified text; also
/// offers searching inside the reader's chosen translation (the Quran Foundation Search API)
/// when `quranTranslationSearch` and `quranTranslations` are both on and an edition is chosen.
class QuranSearchPage extends StatefulWidget {
  const QuranSearchPage({super.key});

  @override
  State<QuranSearchPage> createState() => _QuranSearchPageState();
}

class _QuranSearchPageState extends State<QuranSearchPage> {
  final _field = TextEditingController();
  List<Verse> _results = const [];
  var _tab = _SearchTab.quran;

  /// Not null only when the owning `QuranCubit` was given a `QuranContentRepository`.
  QuranContentCubit? _contentCubit;

  @override
  void initState() {
    super.initState();
    final content = context.read<QuranCubit>().content;
    if (content != null) _contentCubit = QuranContentCubit(content);
  }

  @override
  void dispose() {
    _contentCubit?.close();
    _field.dispose();
    super.dispose();
  }

  void _runOnDevice(String query) {
    final search = context.read<QuranCubit>().search;
    setState(() => _results = search?.search(query) ?? const []);
  }

  void _runTranslationSearch(String query, int editionId) {
    _contentCubit!.searchTranslation(editionId: editionId, query: query);
  }

  void _switchTab(_SearchTab tab) {
    if (tab == _tab) return;
    setState(() {
      _tab = tab;
      _field.clear();
      _results = const [];
    });
    _contentCubit?.clearSearch();
  }

  void _openTranslationPicker(BuildContext context) {
    final cubit = _contentCubit;
    if (cubit == null) return;
    Navigator.of(context).push(
      appRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const TranslationEditionPickerPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final features = context.read<QuranCubit>().features;
    final editionId = context
        .watch<SettingsCubit>()
        .state
        .quranTranslationEditionId;
    final editionName = context
        .watch<SettingsCubit>()
        .state
        .quranTranslationEditionName;
    final offersTranslationSearch =
        features.quranTranslationSearch &&
        features.quranTranslations &&
        _contentCubit != null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.quranSearchHint)),
      body: ContentWidth(
        child: Column(
          children: [
            if (offersTranslationSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                child: _SearchModeSwitch(
                  tab: _tab,
                  onChanged: _switchTab,
                  quranLabel: l10n.quranSearchTabQuran,
                  translationLabel: l10n.quranTranslation,
                ),
              ),
            Expanded(
              child: _tab == _SearchTab.quran || !offersTranslationSearch
                  ? _QuranTab(
                      field: _field,
                      results: _results,
                      onChanged: _runOnDevice,
                    )
                  : _TranslationTab(
                      field: _field,
                      editionId: editionId,
                      editionName: editionName,
                      cubit: _contentCubit!,
                      onSubmitted: (q) => _runTranslationSearch(q, editionId!),
                      onChooseEdition: () => _openTranslationPicker(context),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A two-way switch between the on-device Qur'an-text search and the translation search.
class _SearchModeSwitch extends StatelessWidget {
  const _SearchModeSwitch({
    required this.tab,
    required this.onChanged,
    required this.quranLabel,
    required this.translationLabel,
  });

  final _SearchTab tab;
  final ValueChanged<_SearchTab> onChanged;
  final String quranLabel;
  final String translationLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget segment(_SearchTab value, String label) {
      final selected = value == tab;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: selected ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTypography.of(context).label.copyWith(
                color: selected ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          segment(_SearchTab.quran, quranLabel),
          segment(_SearchTab.translation, translationLabel),
        ],
      ),
    );
  }
}

class _QuranTab extends StatelessWidget {
  const _QuranTab({
    required this.field,
    required this.results,
    required this.onChanged,
  });

  final TextEditingController field;
  final List<Verse> results;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final digits = context.digits;
    final query = field.text.trim();
    final tooShort = query.isNotEmpty && query.length < QuranSearch.minLength;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        TextField(
          controller: field,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.quranSearchHint,
            prefixIcon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        if (query.isEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          const Center(child: StateMedallion(icon: Icons.search)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.quranSearchPrompt,
            textAlign: TextAlign.center,
            style: AppTypography.of(context).body,
          ),
        ] else if (tooShort)
          Text(l10n.quranSearchTooShort, style: AppTypography.of(context).meta)
        else if (query.isNotEmpty)
          Semantics(
            liveRegion: true,
            child: Text(
              results.isEmpty
                  ? l10n.quranNoResults
                  : digits.localize(l10n.quranSearchCount(results.length)),
              style: AppTypography.of(context).meta,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        for (final verse in results) ...[
          VerseResultTile(verse: verse, digits: digits),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _TranslationTab extends StatelessWidget {
  const _TranslationTab({
    required this.field,
    required this.editionId,
    required this.editionName,
    required this.cubit,
    required this.onSubmitted,
    required this.onChooseEdition,
  });

  final TextEditingController field;
  final int? editionId;
  final String? editionName;
  final QuranContentCubit cubit;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onChooseEdition;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (editionId == null) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.xxl),
          const Center(child: StateMedallion(icon: Icons.translate)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.quranTranslationSearchNeedsEdition,
            textAlign: TextAlign.center,
            style: AppTypography.of(context).body,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: FilledButton(
              onPressed: onChooseEdition,
              child: Text(l10n.quranChooseTranslation),
            ),
          ),
        ],
      );
    }

    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<QuranContentCubit, QuranContentState>(
        builder: (context, state) {
          final digits = context.digits;
          final query = field.text.trim();
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              TextField(
                controller: field,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.quranSearchHint,
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onSubmitted: onSubmitted,
              ),
              const SizedBox(height: AppSpacing.md),
              if (query.isEmpty &&
                  state.searchStatus == LoadStatus.initial) ...[
                const SizedBox(height: AppSpacing.xxl),
                const Center(child: StateMedallion(icon: Icons.search)),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.quranTranslationSearchPrompt,
                  textAlign: TextAlign.center,
                  style: AppTypography.of(context).body,
                ),
              ] else
                ..._resultsFor(context, state, digits: digits),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _resultsFor(
    BuildContext context,
    QuranContentState state, {
    required Digits digits,
  }) {
    final l10n = context.l10n;
    switch (state.searchStatus) {
      case LoadStatus.initial:
        return const [];
      case LoadStatus.loading when state.searchMatches.isEmpty:
        return const [LoadingView()];
      case LoadStatus.failure when state.searchMatches.isEmpty:
        return [
          ErrorView(
            failure: state.searchFailure!,
            onRetry: () => onSubmitted(field.text),
          ),
        ];
      case LoadStatus.loading:
      case LoadStatus.success:
      case LoadStatus.failure:
        final matches = state.searchMatches;
        return [
          Semantics(
            liveRegion: true,
            child: Text(
              matches.isEmpty
                  ? l10n.quranNoResults
                  : digits.localize(l10n.quranSearchCount(matches.length)),
              style: AppTypography.of(context).meta,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final match in matches) ...[
            TranslationSearchResultTile(
              match: match,
              editionName: editionName,
              digits: digits,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (state.searchStatus == LoadStatus.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: LoadingView(),
            )
          else if (state.searchStatus == LoadStatus.failure)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                children: [
                  Text(
                    l10n.quranSearchLoadMoreFailed,
                    style: AppTypography.of(context).meta,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => cubit.loadMoreSearchResults(
                      editionId: editionId!,
                      query: field.text,
                    ),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            )
          else if (state.searchHasMore)
            Center(
              child: OutlinedButton(
                onPressed: () => cubit.loadMoreSearchResults(
                  editionId: editionId!,
                  query: field.text,
                ),
                child: Text(l10n.quranSearchLoadMore),
              ),
            ),
        ];
    }
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
    return AppCard(
      onTap: () => openSura(context, verse.sura, verse: verse.number),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            where,
            style: AppTypography.of(
              context,
            ).label.copyWith(color: scheme.primary),
          ),
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
    );
  }
}

/// A verse whose translation matched a search, with the edition's credit line.
class TranslationSearchResultTile extends StatelessWidget {
  const TranslationSearchResultTile({
    super.key,
    required this.match,
    required this.editionName,
    required this.digits,
  });

  final TranslationSearchMatch match;
  final String? editionName;
  final Digits digits;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final verse = match.verse;
    final where =
        '${suraName(context, verse.sura)} ${digits.format(verse.sura)}:'
        '${digits.format(verse.verse)}';
    return AppCard(
      onTap: () => openSura(context, verse.sura, verse: verse.verse),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            where,
            style: AppTypography.of(
              context,
            ).label.copyWith(color: scheme.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(match.snippet, style: AppTypography.of(context).body),
          if (editionName != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.quranTranslationCredit(editionName!),
              style: AppTypography.of(context).meta,
            ),
          ],
        ],
      ),
    );
  }
}
