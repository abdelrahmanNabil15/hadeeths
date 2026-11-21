import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/state/load_status.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/quran/domain/quran_editions.dart';
import 'package:mynewapp/features/quran/presentation/state/quran_content_cubit.dart';
import 'package:mynewapp/features/quran/presentation/widgets/edition_tile.dart';
import 'package:mynewapp/features/settings/presentation/state/settings_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Every tafsir edition the API has (owner's decision, 2026-10-17: none excluded), searched by
/// name, author or language since there are too many to list unfiltered. Unfiltered shows the
/// interface's own language first, so the list is useful before anyone types anything. Mirrors
/// `TranslationEditionPickerPage` exactly; kept as its own page because it reads and writes a
/// separate choice (`quranTafsirEditionId`, not `quranTranslationEditionId`).
class TafsirEditionPickerPage extends StatefulWidget {
  const TafsirEditionPickerPage({super.key});

  @override
  State<TafsirEditionPickerPage> createState() =>
      _TafsirEditionPickerPageState();
}

class _TafsirEditionPickerPageState extends State<TafsirEditionPickerPage> {
  final _field = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<QuranContentCubit>().loadTafsirEditions();
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _choose(TafsirEdition? edition) {
    context.read<SettingsCubit>().setQuranTafsirEdition(
      edition?.id,
      name: edition?.name,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<QuranContentCubit>().state;
    final selectedId = context
        .watch<SettingsCubit>()
        .state
        .quranTafsirEditionId;
    final query = _field.text.trim().toLowerCase();
    final uiLanguage = context.apiLanguage == 'ar' ? 'arabic' : 'english';

    final editions = query.isEmpty
        ? state.tafsirEditions
              .where((e) => e.languageName == uiLanguage)
              .toList()
        : state.tafsirEditions
              .where(
                (e) =>
                    e.name.toLowerCase().contains(query) ||
                    (e.authorName?.toLowerCase().contains(query) ?? false) ||
                    e.languageName.toLowerCase().contains(query),
              )
              .toList();
    editions.sort(
      (a, b) => a.languageName == b.languageName
          ? a.name.compareTo(b.name)
          : a.languageName.compareTo(b.languageName),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.quranChooseTafsir)),
      body: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TextField(
                controller: _field,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.quranTafsirSearchHint,
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: switch (state.tafsirEditionsStatus) {
                LoadStatus.initial ||
                LoadStatus.loading => const SkeletonList(),
                LoadStatus.failure => ErrorView(
                  failure: state.tafsirEditionsFailure!,
                  onRetry: () =>
                      context.read<QuranContentCubit>().loadTafsirEditions(),
                ),
                LoadStatus.success => ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  children: [
                    EditionTile(
                      title: l10n.quranTafsirNone,
                      selected: selectedId == null,
                      onTap: () => _choose(null),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (editions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          l10n.quranTafsirNoMatch,
                          textAlign: TextAlign.center,
                          style: AppTypography.of(context).meta,
                        ),
                      )
                    else
                      for (final edition in editions) ...[
                        EditionTile(
                          title: edition.name,
                          subtitle: edition.authorName,
                          selected: edition.id == selectedId,
                          onTap: () => _choose(edition),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                  ],
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}
