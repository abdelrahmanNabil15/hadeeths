import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/quran/presentation/pages/quran_search_page.dart';
import 'package:mynewapp/features/quran/presentation/state/quran_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Bookmarked verses in Mushaf order, each with its text exactly as in the source.
class QuranBookmarksPage extends StatelessWidget {
  const QuranBookmarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<QuranCubit>().state;
    final text = state.text!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.quranBookmarks)),
      body: state.bookmarks.isEmpty
          ? EmptyView(
              message: l10n.quranNoBookmarks,
              icon: Icons.bookmark_border,
            )
          : ContentWidth(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  for (final place in state.bookmarks) ...[
                    VerseResultTile(
                      verse: text.verse(place.sura, place.verse),
                      digits: context.digits,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
    );
  }
}
