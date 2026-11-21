import 'dart:async';

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
import 'package:mynewapp/core/widgets/ornament_divider.dart';
import 'package:mynewapp/features/quran/domain/mushaf_lines.dart';
import 'package:mynewapp/features/quran/domain/quran_structure.dart';
import 'package:mynewapp/features/quran/domain/quran_text.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';
import 'package:mynewapp/features/quran/presentation/pages/reciter_picker_page.dart';
import 'package:mynewapp/features/quran/presentation/pages/tafsir_edition_picker_page.dart';
import 'package:mynewapp/features/quran/presentation/pages/translation_edition_picker_page.dart';
import 'package:mynewapp/features/quran/presentation/quran_labels.dart';
import 'package:mynewapp/features/quran/presentation/state/qiraat_cubit.dart';
import 'package:mynewapp/features/quran/presentation/state/quran_audio_cubit.dart';
import 'package:mynewapp/features/quran/presentation/state/quran_content_cubit.dart';
import 'package:mynewapp/features/quran/presentation/state/quran_cubit.dart';
import 'package:mynewapp/features/quran/presentation/widgets/audio_mini_player.dart';
import 'package:mynewapp/features/quran/presentation/widgets/mushaf_line_page.dart';
import 'package:mynewapp/features/quran/presentation/widgets/mushaf_page_frame_decoration.dart';
import 'package:mynewapp/features/quran/presentation/widgets/mushaf_surah_header.dart';
import 'package:mynewapp/features/quran/presentation/widgets/qiraat_sheet.dart';
import 'package:mynewapp/features/quran/presentation/widgets/tafsir_sheet.dart';
import 'package:mynewapp/features/quran/presentation/widgets/translation_block.dart';
import 'package:mynewapp/features/quran/presentation/widgets/verse_flow.dart';
import 'package:mynewapp/features/settings/domain/app_settings.dart';
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

/// The reader for one sura, in either of two layouts the reader chooses in `SettingsCubit`
/// ([QuranReadingMode]):
///
/// - **Mushaf** (default): the printed page, turned like a real mushaf. Opened at the page that
///   holds [sura]:[initialVerse]; swipe to turn the page. Each page is set as in a printed mushaf:
///   the verses run on as one justified paragraph, each ending with its number in a rosette, and a
///   sura that begins on the page gets its banner and opening line. With the default reading size
///   and text scale the page is fitted to the screen, so it always shows whole, like a page of
///   paper; with a larger reading size or system text size it scrolls instead.
/// - **Verse by verse**: the same sura's verses, one block per verse, scrolled instead of paged, for
///   study rather than page-turning.
///
/// Both layouts show the same text, exactly as in the source; numbers, banners and page numbers are
/// drawn beside it and never added to it. Long-press a verse to bookmark it in either layout. The
/// reader remembers the verse it was on, regardless of which layout was showing.
class SuraReaderPage extends StatefulWidget {
  const SuraReaderPage({super.key, required this.sura, this.initialVerse = 1});

  final int sura;
  final int initialVerse;

  @override
  State<SuraReaderPage> createState() => _SuraReaderPageState();
}

enum _VerseSheetAction { bookmark, tafsir, listen, qiraat }

class _SuraReaderPageState extends State<SuraReaderPage> {
  static final _structure = QuranStructure.madinah;

  late final QuranText _text = context.read<QuranCubit>().state.text!;

  /// The 15-line mushaf's lines, when this build has them (the page then follows the print line
  /// for line, see [MushafLayoutStyle]).
  late final MushafLines? _lines = context.read<QuranCubit>().state.lines;

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

  /// Not null only when the owning `QuranCubit` was given a `QuranContentRepository`
  /// (`features.quranTranslations` on): translations, tafsir and recitation-audio content.
  QuranContentCubit? _contentCubit;

  /// Not null only when `features.quranAudio` is also on: playback for the mini player. Built
  /// fresh here (like [_contentCubit]) so it, and the player it owns, is disposed with the
  /// reader -- foreground playback only, see `docs/QURAN_API_REFACTOR_PLAN.md` flag D.
  QuranAudioCubit? _audioCubit;

  /// Not null only when `features.quranQiraat` is also on: per-verse recitation-variant
  /// comparisons, see flag F.
  QiraatCubit? _qiraatCubit;

  @override
  void initState() {
    super.initState();
    final start = widget.initialVerse.clamp(1, _text.versesIn(widget.sura));
    context.read<QuranCubit>().setLastRead(VerseRef(widget.sura, start));
    final place = VerseRef(widget.sura, start);
    final target = _lines?.pageOf(place) ?? _structure.pageOf(place);
    _index = _pages.lastIndexWhere((page) => page <= target).clamp(0, 604);
    _controller = PageController(initialPage: _index);
    final quranCubit = context.read<QuranCubit>();
    final content = quranCubit.content;
    if (content != null) {
      _contentCubit = QuranContentCubit(content);
      _qiraatCubit = QiraatCubit(content);
    }
    final audioPlayerFactory = quranCubit.audioPlayerFactory;
    if (content != null && audioPlayerFactory != null) {
      _audioCubit = QuranAudioCubit(content, audioPlayerFactory());
    }
  }

  @override
  void dispose() {
    unawaited(_audioCubit?.close());
    _qiraatCubit?.close();
    _contentCubit?.close();
    _controller.dispose();
    super.dispose();
  }

  void _openTranslationPicker(BuildContext context) {
    final cubit = _contentCubit;
    if (cubit == null) return;
    Navigator.of(context).push(
      appRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const TranslationEditionPickerPage(),
        ),
      ),
    );
  }

  void _openTafsirPicker(BuildContext context) {
    final cubit = _contentCubit;
    if (cubit == null) return;
    Navigator.of(context).push(
      appRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const TafsirEditionPickerPage(),
        ),
      ),
    );
  }

  void _openReciterPicker(BuildContext context) {
    final cubit = _contentCubit;
    if (cubit == null) return;
    Navigator.of(context).push(
      appRoute<void>(
        builder: (_) =>
            BlocProvider.value(value: cubit, child: const ReciterPickerPage()),
      ),
    );
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
    final features = cubit.features;
    final tafsirEditionId = _contentCubit != null && features.quranTafsir
        ? context.read<SettingsCubit>().state.quranTafsirEditionId
        : null;
    final tafsirEditionName = context
        .read<SettingsCubit>()
        .state
        .quranTafsirEditionName;
    final reciterId = _audioCubit != null && features.quranAudio
        ? context.read<SettingsCubit>().state.quranReciterId
        : null;
    final qiraatOn = _qiraatCubit != null && features.quranQiraat;
    final title =
        '${suraName(context, verse.sura)} · '
        '${l10n.quranVerseLabel(context.digits.format(verse.number))}';
    // The same options sheet as the rest of the app, titled with the verse it acts on.
    final action = await showOptionsSheet<_VerseSheetAction>(
      context,
      title: title,
      options: [
        SheetOption(
          value: _VerseSheetAction.bookmark,
          label: marked ? l10n.quranBookmarkRemove : l10n.quranBookmarkAdd,
          icon: marked ? Icons.bookmark_remove : Icons.bookmark_add,
        ),
        if (tafsirEditionId != null)
          SheetOption(
            value: _VerseSheetAction.tafsir,
            label: l10n.quranTafsirRead,
            icon: Icons.menu_book_outlined,
          ),
        if (reciterId != null)
          SheetOption(
            value: _VerseSheetAction.listen,
            label: l10n.quranListen,
            icon: Icons.headphones,
          ),
        if (qiraatOn)
          SheetOption(
            value: _VerseSheetAction.qiraat,
            label: l10n.quranQiraat,
            icon: Icons.compare_arrows,
          ),
      ],
    );
    switch (action) {
      case _VerseSheetAction.bookmark:
        await cubit.toggleBookmark(place);
      case _VerseSheetAction.listen:
        await _audioCubit!.play(
          reciterId: reciterId!,
          verse: place,
          firstVerse: 1,
          lastVerse: _text.versesIn(verse.sura),
        );
      case _VerseSheetAction.tafsir:
        if (mounted) {
          await showTafsirSheet(
            context,
            contentCubit: _contentCubit!,
            editionId: tafsirEditionId!,
            editionName: tafsirEditionName ?? '',
            verse: place,
            title: title,
          );
        }
      case _VerseSheetAction.qiraat:
        if (mounted) {
          await showQiraatSheet(
            context,
            cubit: _qiraatCubit!,
            verse: place,
            title: title,
          );
        }
      case null:
        break;
    }
  }

  /// The mode last built, so switching mode can resync the other layout's position once (not on
  /// every rebuild).
  QuranReadingMode? _lastBuiltMode;

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<SettingsCubit>().state.quranReadingMode;
    final previous = _lastBuiltMode;
    _lastBuiltMode = mode;
    if (mode == QuranReadingMode.mushaf &&
        previous == QuranReadingMode.verseByVerse) {
      // Coming back from verse-by-verse: jump the mushaf page to wherever reading got to there,
      // via the same path a swipe would use, so `_index` and the last-read mark stay in step.
      final current = context.read<QuranCubit>().state.lastRead;
      if (current != null) {
        final target = _structure.pageOf(current);
        final page = _pages.lastIndexWhere((p) => p <= target).clamp(0, 604);
        if (page != _index) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _controller.jumpToPage(page);
          });
        }
      }
    }
    var body = mode == QuranReadingMode.verseByVerse
        ? _buildVerseByVerse(context)
        : _buildMushaf(context);
    final audioCubit = _audioCubit;
    if (audioCubit != null) {
      body = BlocProvider.value(value: audioCubit, child: body);
    }
    final qiraatCubit = _qiraatCubit;
    if (qiraatCubit != null) {
      body = BlocProvider.value(value: qiraatCubit, child: body);
    }
    final contentCubit = _contentCubit;
    if (contentCubit != null) {
      body = BlocProvider.value(value: contentCubit, child: body);
    }
    return body;
  }

  Widget _buildMushaf(BuildContext context) {
    final colors = AppColors.of(context);
    final appDirection = Directionality.of(context);
    final first = _verses(_pages[_index]).first;
    final juz = _structure.juzOf(VerseRef(first.sura, first.number));
    final features = context.watch<QuranCubit>().features;
    return Scaffold(
      backgroundColor: colors.readingSurface,
      appBar: AppBar(
        backgroundColor: colors.readingSurface,
        title: Text(suraName(context, first.sura)),
        actions: [
          if (_contentCubit != null && features.quranTafsir)
            IconButton(
              tooltip: context.l10n.quranTafsir,
              icon: const Icon(Icons.menu_book_outlined),
              onPressed: () => _openTafsirPicker(context),
            ),
          if (_audioCubit != null && features.quranAudio)
            IconButton(
              tooltip: context.l10n.quranRecitation,
              icon: const Icon(Icons.headphones),
              onPressed: () => _openReciterPicker(context),
            ),
          const _ReadingModeToggle(mode: QuranReadingMode.mushaf),
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
                lines: _lines?.page(_pages[index]),
                text: _text,
                onVerseActions: _verseActions,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _audioCubit == null ? null : const AudioMiniPlayer(),
    );
  }

  Widget _buildVerseByVerse(BuildContext context) {
    final colors = AppColors.of(context);
    final current = context.watch<QuranCubit>().state.lastRead;
    final verseHere = current != null && current.sura == widget.sura
        ? current.verse
        : widget.initialVerse;
    final juz = _structure.juzOf(VerseRef(widget.sura, verseHere));
    final features = context.watch<QuranCubit>().features;
    // A stale saved choice from before a flag was last off must not reach `TranslationBlock`,
    // which needs `_contentCubit` provided above it.
    final settings = context.watch<SettingsCubit>().state;
    final translationsOn = _contentCubit != null && features.quranTranslations;
    final translationEditionId = translationsOn
        ? settings.quranTranslationEditionId
        : null;
    return Scaffold(
      backgroundColor: colors.readingSurface,
      appBar: AppBar(
        backgroundColor: colors.readingSurface,
        title: Text(suraName(context, widget.sura)),
        actions: [
          if (_contentCubit != null && features.quranTafsir)
            IconButton(
              tooltip: context.l10n.quranTafsir,
              icon: const Icon(Icons.menu_book_outlined),
              onPressed: () => _openTafsirPicker(context),
            ),
          if (translationsOn)
            IconButton(
              tooltip: context.l10n.quranTranslation,
              icon: Icon(
                translationEditionId == null
                    ? Icons.translate_outlined
                    : Icons.translate,
              ),
              onPressed: () => _openTranslationPicker(context),
            ),
          if (_audioCubit != null && features.quranAudio)
            IconButton(
              tooltip: context.l10n.quranRecitation,
              icon: const Icon(Icons.headphones),
              onPressed: () => _openReciterPicker(context),
            ),
          const _ReadingModeToggle(mode: QuranReadingMode.verseByVerse),
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
        child: _VerseByVerseView(
          key: ValueKey(widget.sura),
          sura: widget.sura,
          initialVerse: verseHere,
          text: _text,
          onVerseActions: _verseActions,
          translationEditionId: translationEditionId,
          translationEditionName: settings.quranTranslationEditionName,
        ),
      ),
      bottomNavigationBar: _audioCubit == null ? null : const AudioMiniPlayer(),
    );
  }
}

/// The two-way choice between [QuranReadingMode]s, as a pair of icon buttons in the reader's app
/// bar. Selecting the mode already showing does nothing.
class _ReadingModeToggle extends StatelessWidget {
  const _ReadingModeToggle({required this.mode});

  final QuranReadingMode mode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
      child: SegmentedButton<QuranReadingMode>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: QuranReadingMode.mushaf,
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: l10n.quranReadingModeMushaf,
          ),
          ButtonSegment(
            value: QuranReadingMode.verseByVerse,
            icon: const Icon(Icons.view_agenda_outlined),
            tooltip: l10n.quranReadingModeVerseByVerse,
          ),
        ],
        selected: {mode},
        onSelectionChanged: (selection) =>
            context.read<SettingsCubit>().setQuranReadingMode(selection.first),
      ),
    );
  }
}

/// The verses of one sura, one block per verse, scrolled instead of paged, for study rather than
/// page-turning. Same text, same font, same bookmark/long-press rules as the mushaf view (reuses
/// `VerseFlow` one verse at a time); only the layout differs. Tracks which verse is nearest the top
/// of the viewport as "last read", the same role the mushaf view's current page plays.
class _VerseByVerseView extends StatefulWidget {
  const _VerseByVerseView({
    super.key,
    required this.sura,
    required this.initialVerse,
    required this.text,
    required this.onVerseActions,
    this.translationEditionId,
    this.translationEditionName,
  });

  final int sura;
  final int initialVerse;
  final QuranText text;
  final void Function(Verse verse) onVerseActions;

  /// The chosen translation edition, if any (`null` shows no translation); its name is shown as
  /// a credit under each verse's translation.
  final int? translationEditionId;
  final String? translationEditionName;

  @override
  State<_VerseByVerseView> createState() => _VerseByVerseViewState();
}

class _VerseByVerseViewState extends State<_VerseByVerseView> {
  final _viewportKey = GlobalKey();
  final _verseKeys = <int, GlobalKey>{};

  GlobalKey _keyFor(int verse) => _verseKeys[verse] ??= GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.initialVerse > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToInitial());
    }
  }

  void _scrollToInitial() {
    if (!mounted) return;
    final target = _verseKeys[widget.initialVerse]?.currentContext;
    if (target != null) Scrollable.ensureVisible(target, alignment: 0.1);
  }

  void _onScrollEnd() {
    final viewport =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null || !viewport.attached) return;
    int? nearest;
    var nearestDistance = double.infinity;
    for (final entry in _verseKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final distance = box
          .localToGlobal(Offset.zero, ancestor: viewport)
          .dy
          .abs();
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = entry.key;
      }
    }
    if (nearest != null) {
      context.read<QuranCubit>().setLastRead(VerseRef(widget.sura, nearest));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = context.select((SettingsCubit c) => c.state.readingScale);
    final bookmarks = context.select((QuranCubit c) => c.state.bookmarks);
    final style = quranTextStyle(context, scale: scale);
    final verses = widget.text.sura(widget.sura);
    final basmala = leadingBasmala(widget.text, widget.sura);
    return NotificationListener<ScrollEndNotification>(
      onNotification: (_) {
        _onScrollEnd();
        return false;
      },
      child: SizedBox(
        key: _viewportKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _SuraBanner(sura: widget.sura),
            const SizedBox(height: AppSpacing.md),
            if (basmala != null)
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(basmala, textAlign: TextAlign.center, style: style),
              ),
            for (var i = 0; i < verses.length; i++) ...[
              if (i > 0) const OrnamentDivider(),
              Padding(
                key: _keyFor(verses[i].number),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: VerseFlow(
                        verses: [verses[i]],
                        style: style,
                        bookmarks: bookmarks,
                        onVerseActions: widget.onVerseActions,
                        skipFromFirst: i == 0 ? (basmala ?? '') : '',
                      ),
                    ),
                    if (widget.translationEditionId != null)
                      TranslationBlock(
                        key: ValueKey(
                          '${widget.translationEditionId}-${verses[i].number}',
                        ),
                        editionId: widget.translationEditionId!,
                        editionName: widget.translationEditionName ?? '',
                        verse: VerseRef(verses[i].sura, verses[i].number),
                      ),
                  ],
                ),
              ),
            ],
          ],
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
    required this.lines,
    required this.text,
    required this.onVerseActions,
  });

  final int page;
  final List<Verse> verses;

  /// The page's lines in the 15-line mushaf; null when this build does not have them.
  final List<MushafLine>? lines;
  final QuranText text;
  final void Function(Verse verse) onVerseActions;

  /// The width the page is laid out at, then scaled to the screen: about fifteen lines of the Quran
  /// font at [_fitFontSize], as in the printed page.
  static const _designWidth = 360.0;
  static const _fitFontSize = 22.0;

  @override
  Widget build(BuildContext context) {
    final scale = context.select((SettingsCubit c) => c.state.readingScale);
    final markerStyle = context.select(
      (SettingsCubit c) => c.state.ayahMarkerStyle,
    );
    final headerStyle = context.select(
      (SettingsCubit c) => c.state.surahHeaderStyle,
    );
    final frameStyle = context.select(
      (SettingsCubit c) => c.state.pageFrameStyle,
    );
    final layoutStyle = context.select(
      (SettingsCubit c) => c.state.mushafLayoutStyle,
    );
    final bookmarks = context.select((QuranCubit c) => c.state.bookmarks);
    final fitted =
        scale == 1 && MediaQuery.textScalerOf(context).scale(10) == 10;
    Widget framed(Widget page) => frameStyle == PageFrameStyle.madinah
        ? MushafPageFrame(child: page)
        : page;
    final pageLines = lines;
    // The 15-line page is a sheet of paper scaled whole to the screen, so the system text size
    // does not change it (the page never wraps); only a larger in-app reading size asks for the
    // running paragraph instead.
    if (scale == 1 &&
        pageLines != null &&
        layoutStyle == MushafLayoutStyle.madinah15) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: FittedBox(
          child: framed(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MushafLinePage(
                  lines: pageLines,
                  page: page,
                  width: _designWidth,
                  bookmarks: bookmarks,
                  markerStyle: markerStyle,
                  onVerseActions: (ref) =>
                      onVerseActions(text.verse(ref.sura, ref.verse)),
                ),
                const SizedBox(height: AppSpacing.sm),
                _PageNumber(page: page),
              ],
            ),
          ),
        ),
      );
    }
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
            headerStyle == SurahHeaderStyle.madinah
                ? MushafSuraHeader(sura: group.first.sura)
                : _SuraBanner(sura: group.first.sura),
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
                  markerStyle: markerStyle,
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
          child: framed(SizedBox(width: _designWidth, child: content)),
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
