import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/design_system/app_colors.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/design_system/typography.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/navigation/app_route.dart';
import 'package:mynewapp/core/widgets/app_sheet.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/geometric_pattern.dart';
import 'package:mynewapp/features/quran/domain/quran_structure.dart';
import 'package:mynewapp/features/quran/domain/quran_text.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';
import 'package:mynewapp/features/quran/presentation/quran_labels.dart';
import 'package:mynewapp/features/quran/presentation/state/quran_cubit.dart';
import 'package:mynewapp/features/quran/presentation/widgets/verse_flow.dart';
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

/// The mushaf, page by page, opened at the page that holds [sura]:[initialVerse]. Swipe to turn the
/// page. Each page is set as in a printed mushaf: the verses run on as one justified paragraph, each
/// ending with its number in a rosette, and a sura that begins on the page gets its banner and
/// opening line. The text of each verse is shown exactly as in the source; numbers, banners and
/// page numbers are drawn beside it and never added to it. The reader remembers the page it was on.
/// Long-press a verse to bookmark it.
///
/// With the default reading size and text scale the page is fitted to the screen, so it always shows
/// whole, like a page of paper. With a larger reading size or system text size it is shown at that
/// size and scrolls instead.
class SuraReaderPage extends StatefulWidget {
  const SuraReaderPage({super.key, required this.sura, this.initialVerse = 1});

  final int sura;
  final int initialVerse;

  @override
  State<SuraReaderPage> createState() => _SuraReaderPageState();
}

class _SuraReaderPageState extends State<SuraReaderPage> {
  static final _structure = QuranStructure.madinah;

  late final QuranText _text = context.read<QuranCubit>().state.text!;

  /// The pages that have any verse in the text (all 604 for the real file).
  late final List<int> _pages = [
    for (var page = 1; page <= QuranStructure.pageCount; page++)
      if (_structure.versesOnPage(_text, page).isNotEmpty) page,
  ];
  final _versesOnPage = <int, List<Verse>>{};
  late final PageController _controller;
  late int _index;

  List<Verse> _verses(int page) =>
      _versesOnPage[page] ??= _structure.versesOnPage(_text, page);

  @override
  void initState() {
    super.initState();
    final start = widget.initialVerse.clamp(1, _text.versesIn(widget.sura));
    context.read<QuranCubit>().setLastRead(VerseRef(widget.sura, start));
    final target = _structure.pageOf(VerseRef(widget.sura, start));
    _index = _pages.lastIndexWhere((page) => page <= target).clamp(0, 604);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
    final first = _verses(_pages[index]).first;
    context.read<QuranCubit>().setLastRead(VerseRef(first.sura, first.number));
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
    final colors = AppColors.of(context);
    final appDirection = Directionality.of(context);
    final first = _verses(_pages[_index]).first;
    final juz = _structure.juzOf(VerseRef(first.sura, first.number));
    return Scaffold(
      backgroundColor: colors.readingSurface,
      appBar: AppBar(
        backgroundColor: colors.readingSurface,
        title: Text(suraName(context, first.sura)),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.lg),
            child: Center(
              child: Text(
                context.l10n.quranJuz(context.digits.format(juz)),
                style: AppTypography.of(context).meta,
              ),
            ),
          ),
        ],
      ),
      body: ContentWidth(
        // Pages turn the way the mushaf does: the next page is to the left.
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) => Directionality(
              textDirection: appDirection,
              child: _MushafPageView(
                page: _pages[index],
                verses: _verses(_pages[index]),
                text: _text,
                onVerseActions: _verseActions,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One mushaf page.
class _MushafPageView extends StatelessWidget {
  const _MushafPageView({
    required this.page,
    required this.verses,
    required this.text,
    required this.onVerseActions,
  });

  final int page;
  final List<Verse> verses;
  final QuranText text;
  final void Function(Verse verse) onVerseActions;

  /// The width the page is laid out at, then scaled to the screen: about fifteen lines of the Quran
  /// font at [_fitFontSize], as in the printed page.
  static const _designWidth = 360.0;
  static const _fitFontSize = 22.0;

  @override
  Widget build(BuildContext context) {
    final scale = context.select((SettingsCubit c) => c.state.readingScale);
    final bookmarks = context.select((QuranCubit c) => c.state.bookmarks);
    final fitted =
        scale == 1 && MediaQuery.textScalerOf(context).scale(10) == 10;
    final style = fitted
        ? quranTextStyle(
            context,
            scale: 1,
          ).copyWith(fontSize: _fitFontSize, height: 1.85)
        : quranTextStyle(context, scale: scale);

    // The verses of each sura on the page; a sura that begins here also gets its banner.
    final groups = <List<Verse>>[];
    for (final verse in verses) {
      if (groups.isNotEmpty && groups.last.first.sura == verse.sura) {
        groups.last.add(verse);
      } else {
        groups.add([verse]);
      }
    }
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups) ...[
          if (group.first.number == 1) ...[
            _SuraBanner(sura: group.first.sura),
            const SizedBox(height: AppSpacing.sm),
          ],
          // Quran text is right to left whatever the interface language.
          Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (group.first.number == 1 &&
                    leadingBasmala(text, group.first.sura) != null)
                  Text(
                    leadingBasmala(text, group.first.sura)!,
                    textAlign: TextAlign.center,
                    style: style,
                  ),
                VerseFlow(
                  verses: group,
                  style: style,
                  bookmarks: bookmarks,
                  onVerseActions: onVerseActions,
                  skipFromFirst: group.first.number == 1
                      ? (leadingBasmala(text, group.first.sura) ?? '')
                      : '',
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        _PageNumber(page: page),
      ],
    );
    if (fitted) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: FittedBox(
          child: SizedBox(width: _designWidth, child: content),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: content,
    );
  }
}

/// The page number at the foot of the page, in a small gold-edged pill. Read as "Page n".
class _PageNumber extends StatelessWidget {
  const _PageNumber({required this.page});

  final int page;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Semantics(
        container: true,
        label: context.l10n.quranPage(context.digits.format(page)),
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: colors.gold, width: AppBorders.hairline),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              context.digits.format(page),
              style: AppTypography.of(context).meta,
            ),
          ),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      eightPointStar(size.center(Offset.zero), size.shortestSide / 2),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}

/// The banner at the head of a sura, like the cartouche above the first verses of a mushaf page: a
/// framed band with the sura's title between two stars. Nothing here is Quran text.
class _SuraBanner extends StatelessWidget {
  const _SuraBanner({required this.sura});

  final int sura;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    Widget star() => ExcludeSemantics(
      child: CustomPaint(
        size: const Size.square(AppSpacing.lg),
        painter: _StarPainter(colors.gold),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.goldSoft.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: colors.gold, width: AppBorders.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            star(),
            Expanded(
              child: Semantics(
                container: true,
                header: true,
                child: Text(
                  context.l10n.quranSuraTitle(suraName(context, sura)),
                  textAlign: TextAlign.center,
                  style: AppTypography.of(context).editorialTitle,
                ),
              ),
            ),
            star(),
          ],
        ),
      ),
    );
  }
}
