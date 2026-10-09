import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/motion.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/haptics/haptics.dart';
import 'package:mynewapp/features/favorites/domain/favorites_repository.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// The bookmark in a hadith's app bar. Nothing is shown when favourites are not available (their
/// section is off, or the user's storage could not be opened).
class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    super.key,
    required this.hadithId,
    this.haptics = const SystemHaptics(),
  });

  final String hadithId;
  final Haptics haptics;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  FavoritesRepository? _repository;
  bool? _on;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = context.read<FavoritesRepository?>();
    if (repository != _repository) {
      _repository = repository;
      _read();
    }
  }

  Future<void> _read() async {
    final repository = _repository;
    if (repository == null) return;
    try {
      final on = await repository.contains(widget.hadithId);
      if (mounted) setState(() => _on = on);
    } on Object {
      // Leave the button out rather than show a state that may be wrong.
    }
  }

  Future<void> _toggle() async {
    final repository = _repository;
    final was = _on;
    if (repository == null || was == null) return;
    setState(() => _on = !was);
    widget.haptics.selection();
    try {
      await repository.setFavorite(widget.hadithId, favorite: !was);
    } on Object {
      if (mounted) setState(() => _on = was);
    }
  }

  @override
  Widget build(BuildContext context) {
    final on = _on;
    if (_repository == null || on == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // One node for the button and its on/off state, so a screen reader says both together.
    return MergeSemantics(
      child: Semantics(
        toggled: on,
        child: IconButton(
          tooltip: on ? l10n.favoriteRemove : l10n.favoriteAdd,
          onPressed: _toggle,
          icon: AnimatedSwitcher(
            duration: context.motion(AppMotion.short),
            switchInCurve: AppMotion.enter,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              on ? Icons.bookmark : Icons.bookmark_border,
              key: ValueKey(on),
              color: on ? scheme.primary : null,
            ),
          ),
        ),
      ),
    );
  }
}
