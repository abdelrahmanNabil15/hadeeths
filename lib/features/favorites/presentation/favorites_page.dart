import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/core/widgets/animated_state_switcher.dart';
import 'package:mynewapp/core/widgets/app_tile.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/favorites/domain/favorites_repository.dart';
import 'package:mynewapp/features/hadiths/domain/hadiths_repository.dart';
import 'package:mynewapp/features/hadiths/presentation/pages/hadith_details_page.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// The hadiths the user kept, newest first. Only ids are stored, so each title is read the same
/// way as when the hadith is opened (saved copies make that work offline for hadiths already read).
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key, required this.repository});

  final FavoritesRepository repository;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<String>? _ids;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ids = await widget.repository.all();
      if (!mounted) return;
      setState(() {
        _ids = ids;
        _failed = false;
      });
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _open(String id) async {
    await Navigator.of(
      context,
    ).push(appRoute<void>(builder: (_) => HadithDetailsPage(id: id)));
    // The bookmark may have been removed on the hadith's page.
    await _load();
  }

  Future<void> _confirmClear() async {
    final l10n = context.l10n;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.favoritesClearTitle),
        content: Text(l10n.favoritesClearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.favoritesClearConfirm),
          ),
        ],
      ),
    );
    if (agreed ?? false) {
      await widget.repository.clear();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ids = _ids;
    final Widget body;
    if (_failed) {
      body = EmptyView(
        key: const ValueKey('failed'),
        message: l10n.trackerUnavailable,
        icon: Icons.storage_outlined,
      );
    } else if (ids == null) {
      body = const LoadingView(key: ValueKey('loading'));
    } else if (ids.isEmpty) {
      body = EmptyView(
        key: const ValueKey('empty'),
        message: l10n.favoritesEmpty,
        icon: Icons.bookmark_border,
      );
    } else {
      body = ListView(
        key: const ValueKey('list'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          for (final id in ids) ...[
            _FavoriteTile(key: ValueKey(id), id: id, onTap: () => _open(id)),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: _confirmClear,
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.favoritesClear),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.favoritesTitle)),
      body: ContentWidth(child: AnimatedStateSwitcher(child: body)),
    );
  }
}

/// One kept hadith. Its title is fetched once; until then (or if it cannot be read) the row says
/// which hadith it is by number, and it can still be opened.
class _FavoriteTile extends StatefulWidget {
  const _FavoriteTile({super.key, required this.id, required this.onTap});

  final String id;
  final VoidCallback onTap;

  @override
  State<_FavoriteTile> createState() => _FavoriteTileState();
}

class _FavoriteTileState extends State<_FavoriteTile> {
  String? _title;
  String? _language;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = context.apiLanguage;
    if (language != _language) {
      _language = language;
      _title = null;
      _fetch(language);
    }
  }

  Future<void> _fetch(String language) async {
    final result = await context.read<HadithsRepository>().getHadithDetails(
      widget.id,
      language: language,
    );
    if (!mounted || language != _language) return;
    if (result case Success(:final value) when value.title.isNotEmpty) {
      setState(() => _title = value.title);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = _title;
    return AppTile(
      title: title ?? l10n.favoritesFallbackTitle(widget.id),
      maxTitleLines: 4,
      onTap: widget.onTap,
    );
  }
}
