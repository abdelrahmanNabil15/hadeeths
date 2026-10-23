import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/state/load_status.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/quran/domain/quran_editions.dart';
import 'package:mynewapp/features/quran/presentation/state/quran_content_cubit.dart';
import 'package:mynewapp/features/quran/presentation/widgets/edition_tile.dart';
import 'package:mynewapp/features/settings/presentation/state/settings_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Every reciter the API has (owner's decision, 2026-10-17: none excluded -- a dozen or so, so
/// unlike the translation/tafsir pickers this is a plain list, no search field needed).
class ReciterPickerPage extends StatefulWidget {
  const ReciterPickerPage({super.key});

  @override
  State<ReciterPickerPage> createState() => _ReciterPickerPageState();
}

class _ReciterPickerPageState extends State<ReciterPickerPage> {
  @override
  void initState() {
    super.initState();
    context.read<QuranContentCubit>().loadReciters();
  }

  void _choose(Reciter? reciter) {
    context.read<SettingsCubit>().setQuranReciter(
      reciter?.id,
      name: reciter?.name,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<QuranContentCubit>().state;
    final selectedId = context.watch<SettingsCubit>().state.quranReciterId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.quranChooseReciter)),
      body: ContentWidth(
        child: switch (state.reciterStatus) {
          LoadStatus.initial || LoadStatus.loading => const SkeletonList(),
          LoadStatus.failure => ErrorView(
            failure: state.reciterFailure!,
            onRetry: () => context.read<QuranContentCubit>().loadReciters(),
          ),
          LoadStatus.success => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              EditionTile(
                title: l10n.quranReciterNone,
                selected: selectedId == null,
                onTap: () => _choose(null),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final reciter in state.reciters) ...[
                EditionTile(
                  title: reciter.name,
                  subtitle: reciter.style,
                  selected: reciter.id == selectedId,
                  onTap: () => _choose(reciter),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        },
      ),
    );
  }
}
