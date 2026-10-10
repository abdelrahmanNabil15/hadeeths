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
  late final String? _basmala = leadingBasmala(_text, widget.sura);
  final _viewport = GlobalKey();

  @override
  void initState() {
    super.initState();
    final start = widget.initialVerse.clamp(1, _verses.length);
    context.read<QuranCubit>().setLastRead(VerseRef(widget.sura, start));
    if (start > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // The verse starts where the one before it ends.
        final target = _keys[start - 2].currentContext;
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
      final markBottom =
          verseBox.localToGlobal(Offset.zero).dy + verseBox.size.height;
      if (markBottom > top + 1) {
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
    final style = quranTextStyle(
      context,
      scale: context.select((SettingsCubit c) => c.state.readingScale),
    );
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MushafPage(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // The banner is interface text: it keeps the app's direction.
                      Directionality(
                        textDirection: appDirection,
                        child: _SuraBanner(
                          sura: widget.sura,
                          verses: _verses.length,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Quran text is right to left whatever the interface language.
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_basmala != null) ...[
                              Text(
                                _basmala,
                                textAlign: TextAlign.center,
                                style: style,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            VerseFlow(
                              verses: _verses,
                              style: style,
                              bookmarks: bookmarks,
                              markerKeys: _keys,
                              onVerseActions: _verseActions,
                              skipFromFirst: _basmala ?? '',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The page the verses are set on, framed as a mushaf page is: a broad band in pale gold between two
/// gold rules, with a small star in each corner. Decoration only; the text sits on the plain reading
/// surface inside it.
class _MushafPage extends StatelessWidget {
  const _MushafPage({required this.child});

  final Widget child;

  static const _band = AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    Widget corner(Alignment at) => Align(
      alignment: at,
      child: ExcludeSemantics(
        child: CustomPaint(
          size: const Size.square(_band + AppSpacing.xs),
          painter: _CornerStarPainter(colors.gold),
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.goldSoft.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.gold, width: AppBorders.emphasis),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(_band),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.readingSurface,
                border: Border.all(
                  color: colors.gold,
                  width: AppBorders.hairline,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.lg,
                ),
                child: child,
              ),
            ),
          ),
          Positioned.fill(
            child: Stack(
              children: [
                corner(Alignment.topLeft),
                corner(Alignment.topRight),
                corner(Alignment.bottomLeft),
                corner(Alignment.bottomRight),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerStarPainter extends CustomPainter {
  const _CornerStarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      eightPointStar(size.center(Offset.zero), size.shortestSide / 2),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_CornerStarPainter old) => old.color != color;
}

/// The banner at the head of a sura, like the cartouche above the first verses of a mushaf page: a
/// framed band with the sura's title between two stars, and its number of verses. Nothing here is
/// Quran text.
class _SuraBanner extends StatelessWidget {
  const _SuraBanner({required this.sura, required this.verses});

  final int sura;
  final int verses;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final type = AppTypography.of(context);
    final count = context.l10n
        .quranVerses(verses)
        .replaceAllMapped(
          RegExp(r'\d+'),
          (m) => context.digits.format(int.parse(m[0]!)),
        );
    Widget star() => ExcludeSemantics(
      child: CustomPaint(
        size: const Size.square(AppSpacing.lg),
        painter: _CornerStarPainter(colors.gold),
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
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            star(),
            Expanded(
              child: Column(
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      context.l10n.quranSuraTitle(suraName(context, sura)),
                      textAlign: TextAlign.center,
                      style: type.editorialTitle,
                    ),
                  ),
                  Text(count, textAlign: TextAlign.center, style: type.meta),
                ],
              ),
            ),
            star(),
          ],
        ),
      ),
    );
  }
}
