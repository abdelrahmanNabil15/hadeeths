import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/core/widgets/app_sheet.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/ornament_divider.dart';
import 'package:mynewapp/features/quran/domain/quran_text.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';
import 'package:mynewapp/features/quran/presentation/quran_labels.dart';
import 'package:mynewapp/features/quran/presentation/state/quran_cubit.dart';
import 'package:mynewapp/features/quran/presentation/widgets/verse_marker.dart';
import 'package:mynewapp/features/settings/presentation/state/settings_cubit.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Opens the reader at [sura] (and [verse], if given), sharing the section's state.
void openSura(BuildContext context, int sura, {int verse = 1}) {
  final cubit = context.read<QuranCubit>();
  Navigator.of(context).push(
    appRoute<void>(
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: SuraReaderPage(sura: sura, initialVerse: verse),
      ),
    ),
  );
}

/// One sura, verse by verse. The text of each verse is shown exactly as in the source; the verse
/// number is drawn beside it and is never added to the text. The Tanzil file already begins verse 1
/// of every sura except al-Fatihah and at-Tawbah with the basmala, so nothing is added above it. The page remembers where the reader
/// stopped. Long-press a verse to bookmark it.
class SuraReaderPage extends StatefulWidget {
  const SuraReaderPage({super.key, required this.sura, this.initialVerse = 1});

  final int sura;
  final int initialVerse;

  @override
  State<SuraReaderPage> createState() => _SuraReaderPageState();
}

class _SuraReaderPageState extends State<SuraReaderPage> {
  late final QuranText _text = context.read<QuranCubit>().state.text!;
  late final List<Verse> _verses = _text.sura(widget.sura);
  late final List<GlobalKey> _keys = [for (final _ in _verses) GlobalKey()];
  final _viewport = GlobalKey();

  @override
  void initState() {
    super.initState();
    final start = widget.initialVerse.clamp(1, _verses.length);
    context.read<QuranCubit>().setLastRead(VerseRef(widget.sura, start));
    if (start > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _keys[start - 1].currentContext;
        if (target != null) Scrollable.ensureVisible(target);
      });
    }
  }

  /// The first verse whose top is on screen, saved as the place to continue from.
  bool _onScrollEnd(ScrollEndNotification _) {
    final box = _viewport.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return false;
    final top = box.localToGlobal(Offset.zero).dy;
    for (var i = 0; i < _keys.length; i++) {
      final verseBox =
          _keys[i].currentContext?.findRenderObject() as RenderBox?;
      if (verseBox == null) continue;
      final verseBottom =
          verseBox.localToGlobal(Offset.zero).dy + verseBox.size.height;
      if (verseBottom > top + 1) {
        context.read<QuranCubit>().setLastRead(VerseRef(widget.sura, i + 1));
        break;
      }
    }
    return false;
  }

  Future<void> _verseActions(Verse verse) async {
    final l10n = context.l10n;
    final cubit = context.read<QuranCubit>();
    final place = VerseRef(verse.sura, verse.number);
    final marked = cubit.isBookmarked(place);
    // The same options sheet as the rest of the app, titled with the verse it acts on.
    final toggle = await showOptionsSheet<bool>(
      context,
      title:
          '${suraName(context, verse.sura)} · '
          '${l10n.quranVerseLabel(context.digits.format(verse.number))}',
      options: [
        SheetOption(
          value: true,
          label: marked ? l10n.quranBookmarkRemove : l10n.quranBookmarkAdd,
          icon: marked ? Icons.bookmark_remove : Icons.bookmark_add,
        ),
      ],
    );
    if (toggle ?? false) await cubit.toggleBookmark(place);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final scale = context.select((SettingsCubit c) => c.state.readingScale);
    final style = quranTextStyle(context, scale: scale);
    final bookmarks = context.select((QuranCubit c) => c.state.bookmarks);
    final appDirection = Directionality.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(suraName(context, widget.sura))),
      body: NotificationListener<ScrollEndNotification>(
        onNotification: _onScrollEnd,
        child: ContentWidth(
          key: _viewport,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Directionality(
              // Quran text is right to left whatever the interface language.
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The header is interface text: it keeps the app's direction, not the verses'.
                  Directionality(
                    textDirection: appDirection,
                    child: _SuraHeader(
                      sura: widget.sura,
                      verses: _verses.length,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final verse in _verses)
                    _VerseBlock(
                      key: _keys[verse.number - 1],
                      verse: verse,
                      style: style,
                      bookmarked: bookmarks.contains(
                        VerseRef(verse.sura, verse.number),
                      ),
                      label: l10n.quranVerseLabel(
                        context.digits.format(verse.number),
                      ),
                      onLongPress: () => _verseActions(verse),
                      scheme: scheme,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerseBlock extends StatelessWidget {
  const _VerseBlock({
    super.key,
    required this.verse,
    required this.style,
    required this.bookmarked,
    required this.label,
    required this.onLongPress,
    required this.scheme,
  });

  final Verse verse;
  final TextStyle style;
  final bool bookmarked;
  final String label;
  final VoidCallback onLongPress;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      onLongPressHint: bookmarked
          ? context.l10n.quranBookmarkRemove
          : context.l10n.quranBookmarkAdd,
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(verse.text, style: style)),
              const SizedBox(width: AppSpacing.sm),
              Column(
                children: [
                  VerseMarker(number: verse.number, bookmarked: bookmarked),
                  if (bookmarked)
                    Icon(
                      Icons.bookmark,
                      size: AppSizes.iconSmall,
                      color: AppColors.of(context).gold,
                      semanticLabel: context.l10n.quranBookmarkRemove,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The head of a sura: its name in the editorial face, its number of verses, and a fine ornament
/// before the text. Nothing here is Quran text.
class _SuraHeader extends StatelessWidget {
  const _SuraHeader({required this.sura, required this.verses});

  final int sura;
  final int verses;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    final count = context.l10n
        .quranVerses(verses)
        .replaceAllMapped(
          RegExp(r'\d+'),
          (m) => context.digits.format(int.parse(m[0]!)),
        );
    return Column(
      children: [
        Semantics(
          header: true,
          child: Text(
            suraName(context, sura),
            textAlign: TextAlign.center,
            style: type.editorialTitle,
          ),
        ),
        Text(count, textAlign: TextAlign.center, style: type.meta),
        const SizedBox(height: AppSpacing.md),
        const OrnamentDivider(width: 160),
      ],
    );
  }
}
