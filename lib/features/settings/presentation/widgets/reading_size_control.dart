import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';
import 'package:mynewapp/features/settings/presentation/state/settings_cubit.dart';
import 'package:mynewapp/features/settings/presentation/widgets/reading_text.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Smaller / larger buttons around a slider, with a live sample line. It changes the size of
/// the reading text (hadith and explanation) on top of the device's text-size setting.
class ReadingSizeControl extends StatelessWidget {
  const ReadingSizeControl({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();
    return BlocBuilder<SettingsCubit, AppSettings>(
      builder: (context, settings) {
        final lastIndex = AppSettings.readingScales.length - 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: l10n.textSizeSmaller,
                  icon: const Icon(Icons.text_decrease),
                  onPressed: settings.canDecreaseReadingScale
                      ? cubit.decreaseReadingScale
                      : null,
                ),
                Expanded(
                  child: Slider(
                    value: settings.readingScaleIndex.toDouble(),
                    min: 0,
                    max: lastIndex.toDouble(),
                    divisions: lastIndex,
                    label: context.digits.localize(
                      '${(settings.readingScale * 100).round()}%',
                    ),
                    semanticFormatterCallback: (value) => context.digits.localize(
                      '${(AppSettings.readingScales[value.round()] * 100).round()}%',
                    ),
                    onChanged: (value) => cubit.setReadingScale(
                      AppSettings.readingScales[value.round()],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.textSizeLarger,
                  icon: const Icon(Icons.text_increase),
                  onPressed: settings.canIncreaseReadingScale
                      ? cubit.increaseReadingScale
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.textSizeSample,
              style: readingTextStyle(context, scale: settings.readingScale),
            ),
          ],
        );
      },
    );
  }
}

/// App-bar button that opens [ReadingSizeControl] in a bottom sheet.
class ReadingSizeButton extends StatelessWidget {
  const ReadingSizeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IconButton(
      tooltip: l10n.textSize,
      icon: const Icon(Icons.text_fields),
      onPressed: () {
        final cubit = context.read<SettingsCubit>();
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (sheetContext) => BlocProvider.value(
            value: cubit,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.textSize,
                        style: const TextStyle(
                          fontSize: AppTextSize.heading,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const ReadingSizeControl(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
