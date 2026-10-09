import 'package:flutter/material.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Stands in for a section that is not built yet. Only reachable when its feature flag is on
/// (previews and tests); the released app never shows it.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ContentWidth(
        child: EmptyView(
          message: '${l10n.comingSoon}\n${l10n.comingSoonBody}',
          icon: icon,
        ),
      ),
    );
  }
}
