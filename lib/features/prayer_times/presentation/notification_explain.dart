import 'package:flutter/material.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Explains why the app needs to show notifications, before the system asks. True when the user
/// chooses to continue.
Future<bool> explainNotifications(BuildContext context) async {
  final l10n = context.l10n;
  final agreed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.remindersExplainTitle),
      content: Text(l10n.remindersExplainBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.notNow),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.continueAction),
        ),
      ],
    ),
  );
  return agreed ?? false;
}
