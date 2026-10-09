import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/option_group.dart';
import 'package:mynewapp/features/prayer_times/domain/calculation_settings.dart';
import 'package:mynewapp/features/prayer_times/presentation/prayer_labels.dart';
import 'package:mynewapp/features/prayer_times/presentation/state/prayer_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Choose the calculation method. Each choice shows the numbers it uses. The choice is the
/// user's from then on: the app never changes it by itself.
class MethodPage extends StatelessWidget {
  const MethodPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final digits = context.digits;
    final cubit = context.read<PrayerCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.methodHeading)),
      body: ContentWidth(
        child: BlocBuilder<PrayerCubit, PrayerState>(
          builder: (context, state) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              OptionGroup<CalculationMethodId>(
                selected: state.preferences.settings.method,
                onSelected: cubit.chooseMethod,
                options: [
                  for (final id in CalculationMethodId.values)
                    (id, methodName(l10n, id)),
                ],
                subtitles: [
                  for (final id in CalculationMethodId.values)
                    methodDetail(l10n, digits, id),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.prayerDisclaimer,
                style: TextStyle(
                  fontSize: AppTextSize.meta,
                  height: AppLineHeight.body,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
