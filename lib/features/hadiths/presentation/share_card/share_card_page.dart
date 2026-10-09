import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/format/digits.dart';
import 'package:mynewapp/core/share/image_sharer.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/status_banner.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_details.dart';
import 'package:mynewapp/features/hadiths/presentation/share_card/card_pages.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// The size of one card in logical pixels (4:5, a common size for shared images). Saved at three
/// times this, 1080 x 1350.
const shareCardSize = Size(360, 450);
const _padding = 24.0;
const _footerHeight = 56.0;
const _sourceHeight = 48.0;
const _headerHeight = 32.0;

/// Shows the hadith as one or more cards and shares them as images. Every card carries the
/// credit; the grade and narrator are on the last card. The text is the hadith exactly as
/// received, split only between words when it does not fit on one card.
class ShareCardPage extends StatefulWidget {
  const ShareCardPage({
    super.key,
    required this.details,
    required this.arabic,
    required this.sharer,
  });

  final HadithDetails details;

  /// The hadith is in Arabic (right to left, reading font).
  final bool arabic;
  final ImageSharer sharer;

  @override
  State<ShareCardPage> createState() => _ShareCardPageState();
}

class _ShareCardPageState extends State<ShareCardPage> {
  List<String>? _pages;
  late List<GlobalKey> _keys;
  bool _busy = false;
  bool _failed = false;

  TextStyle get _bodyStyle => TextStyle(
    fontFamily: widget.arabic ? AppFonts.reading : AppFonts.ui,
    fontSize: widget.arabic ? 20 : 15,
    height: widget.arabic
        ? AppLineHeight.readingArabic
        : AppLineHeight.readingLatin,
    color: AppPalette.light.onSurface,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pages ??= splitIntoPages(
      widget.details.hadeeth,
      style: _bodyStyle,
      width: shareCardSize.width - 2 * _padding,
      maxHeight:
          shareCardSize.height -
          2 * _padding -
          _headerHeight -
          _footerHeight -
          _sourceHeight,
      direction: widget.arabic ? TextDirection.rtl : TextDirection.ltr,
    );
    _keys = [for (final _ in _pages!) GlobalKey()];
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    final credit = context.l10n.sourceCredit;
    try {
      final images = <Uint8List>[];
      for (final key in _keys) {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 3);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        images.add(data!.buffer.asUint8List());
      }
      await widget.sharer.sharePngs(images, text: credit);
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = false;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = _pages!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shareAsImage)),
      // Every card is built (not only those on screen), because each one is turned into an image.
      body: ContentWidth(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < pages.length; i++) ...[
                Center(
                  child: FittedBox(
                    // The frame is for the preview only; it is outside the captured image.
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: RepaintBoundary(
                        key: _keys[i],
                        child: ShareCard(
                          text: pages[i],
                          arabic: widget.arabic,
                          bodyStyle: _bodyStyle,
                          page: i + 1,
                          pageCount: pages.length,
                          details: widget.details,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ],
          ),
        ),
      ),
      // Always reachable, however many cards there are.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_failed) ...[
                StatusBanner(
                  message: l10n.shareCardFailed,
                  kind: StatusKind.warning,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              FilledButton.icon(
                onPressed: _busy ? null : _share,
                icon: const Icon(Icons.share),
                label: Text(
                  pages.length == 1
                      ? l10n.shareCardShareOne
                      : context.digits.localize(
                          l10n.shareCardShareMany(pages.length),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One card. Always drawn in the light palette and at a fixed size, whatever the phone's theme
/// and text size, so the shared image looks the same everywhere.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.text,
    required this.arabic,
    required this.bodyStyle,
    required this.page,
    required this.pageCount,
    required this.details,
  });

  final String text;
  final bool arabic;
  final TextStyle bodyStyle;
  final int page;
  final int pageCount;
  final HadithDetails details;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.light;
    final l10n = context.l10n;
    final digits = context.digits;
    final last = page == pageCount;
    final source = [
      details.grade,
      details.attribution,
    ].where((e) => e.isNotEmpty).join(' · ');
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Directionality(
        textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
        child: Container(
          width: shareCardSize.width,
          height: shareCardSize.height,
          color: colors.surface,
          padding: const EdgeInsets.all(_padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: _headerHeight,
                child: Row(
                  children: [
                    Container(width: 4, height: 18, color: colors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.appTitle,
                      style: TextStyle(
                        fontFamily: AppFonts.ui,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: Text(text, style: bodyStyle)),
              SizedBox(
                height: _sourceHeight,
                child: last && source.isNotEmpty
                    ? Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          source,
                          maxLines: 2,
                          style: TextStyle(
                            fontFamily: AppFonts.ui,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.secondary,
                          ),
                        ),
                      )
                    : null,
              ),
              SizedBox(
                height: _footerHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Divider(color: colors.outlineVariant, height: 1),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.sourceCredit,
                            style: TextStyle(
                              fontFamily: AppFonts.ui,
                              fontSize: 11,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (pageCount > 1)
                          Text(
                            '${digits.format(page)}/${digits.format(pageCount)}',
                            style: TextStyle(
                              fontFamily: AppFonts.ui,
                              fontSize: 11,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
