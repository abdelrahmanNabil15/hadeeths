import 'package:flutter/material.dart';
import 'package:mynewapp/core/format/clock_format.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/widgets/app_tile.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// A row showing a time of day (minutes after midnight) that opens the system time picker. The
/// time is shown in the user's digits and clock style.
class TimeOfDayTile extends StatelessWidget {
  const TimeOfDayTile({
    super.key,
    required this.label,
    required this.minute,
    required this.onChanged,
  });

  final String label;
  final int minute;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final time = formatClock(
      DateTime.utc(2000, 1, 1, minute ~/ 60, minute % 60),
      arabic: context.apiLanguage == 'ar',
      use24Hour: MediaQuery.alwaysUse24HourFormatOf(context),
      digits: context.digits,
    );
    return AppTile(
      title: label,
      trailingText: time,
      semanticLabel: '$label, $time',
      onTap: onChanged == null ? () {} : () => _pick(context),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
    );
    if (picked != null) onChanged?.call(picked.hour * 60 + picked.minute);
  }
}
