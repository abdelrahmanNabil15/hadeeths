import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/haptics/haptics.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/option_group.dart';
import 'package:mynewapp/core/widgets/section_heading.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/core/widgets/status_banner.dart';
import 'package:mynewapp/features/tasbeeh/domain/tasbeeh_counter.dart';
import 'package:mynewapp/features/tasbeeh/domain/tasbeeh_repository.dart';
import 'package:mynewapp/features/tasbeeh/presentation/state/tasbeeh_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// A counter to tap, with an optional target. It carries no words of its own.
class TasbeehPage extends StatelessWidget {
  const TasbeehPage({
    super.key,
    required this.repository,
    this.haptics = const SystemHaptics(),
  });

  final TasbeehRepository repository;
  final Haptics haptics;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TasbeehCubit(repository: repository, haptics: haptics)..load(),
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.tasbeehTitle)),
        body: ContentWidth(
          child: BlocBuilder<TasbeehCubit, TasbeehState>(
            builder: (context, state) =>
                state.loaded ? _Counter(state: state) : const LoadingView(),
          ),
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.state});

  final TasbeehState state;

  static const double _size = 240;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final digits = context.digits;
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<TasbeehCubit>();
    final type = AppTypography.of(context);
    final counter = state.counter;
    final count = digits.format(counter.count);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(l10n.tasbeehHint, style: type.meta),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: SizedBox(
            width: _size + 24,
            height: _size + 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ExcludeSemantics(
                  child: SizedBox(
                    width: _size + 16,
                    height: _size + 16,
                    child: CircularProgressIndicator(
                      value: counter.progress,
                      strokeWidth: 8,
                      backgroundColor: scheme.outlineVariant,
                      color: counter.onTarget
                          ? scheme.secondary
                          : scheme.primary,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: l10n.tasbeehCountLabel(count),
                  hint: l10n.tasbeehTapHint,
                  liveRegion: true,
                  excludeSemantics: true,
                  onTap: cubit.tap,
                  // The count goes up the moment a finger touches down, not when it lifts, so
                  // quick taps are never merged or dropped.
                  child: Listener(
                    onPointerDown: (_) => cubit.tap(),
                    child: Container(
                      width: _size,
                      height: _size,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primaryContainer,
                        border: Border.all(color: scheme.primary, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            count,
                            style: type.number.copyWith(
                              fontSize: AppTextSize.counter,
                              fontWeight: FontWeight.w700,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (counter.target != null)
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                if (counter.onTarget)
                  Icon(Icons.check_circle, color: scheme.secondary),
                Text(
                  counter.onTarget
                      ? l10n.tasbeehTargetReached
                      : l10n.tasbeehRounds(digits.format(counter.rounds)),
                  style: type.meta,
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: counter.count == 0 ? null : cubit.undo,
              icon: const Icon(Icons.undo),
              label: Text(l10n.tasbeehUndo),
            ),
            OutlinedButton.icon(
              onPressed: counter.count == 0
                  ? null
                  : () => _confirmReset(context, cubit),
              icon: const Icon(Icons.restart_alt),
              label: Text(l10n.tasbeehReset),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeading(l10n.tasbeehTargetHeading),
        const SizedBox(height: AppSpacing.sm),
        OptionGroup<int?>(
          selected: counter.target,
          onSelected: cubit.setTarget,
          options: [
            (null, l10n.tasbeehNoTarget),
            for (final t in TasbeehCounter.targets) (t, digits.format(t)),
          ],
        ),
        if (state.saveFailed) ...[
          const SizedBox(height: AppSpacing.lg),
          StatusBanner(
            message: l10n.tasbeehSaveFailed,
            kind: StatusKind.warning,
          ),
        ],
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context, TasbeehCubit cubit) async {
    final l10n = context.l10n;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.tasbeehResetTitle),
        content: Text(l10n.tasbeehResetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.tasbeehReset),
          ),
        ],
      ),
    );
    if (agreed ?? false) await cubit.reset();
  }
}
