import 'dart:math';

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../hive/bevel.dart';
import '../../hive/grain.dart';
import '../../hive/hex_scene.dart';
import '../../library/library.dart';
import '../../locale/languages.dart';
import '../code/code_modal.dart';
import '../code/code_view.dart';
import 'doc_reader.dart';
import 'md_view.dart';

/// The panel of a tip: a small framed card in the middle of the screen, as
/// tall as its text, not a screen of its own. A tip is a few lines, so the
/// card has no Render or Source switch, no copy and no download; it has the
/// title, the text with room on both sides, and the close mark.
///
/// A link to an article opens it in the same card, which then grows to the
/// height the article asks for, up to the screen. Back on the bar returns to
/// the tip. A tap outside closes the card.
class TipModal extends StatefulWidget {
  const TipModal({
    required this.title,
    required this.color,
    required this.source,
    required this.onClose,
    this.docs,
    this.actions,
    super.key,
  });

  /// Title of a tip that has no `# ` heading of its own: the name of the
  /// cell.
  final String title;
  final Color color;
  final String source;
  final VoidCallback onClose;

  /// Where links to articles lead. Without it only outside links work.
  final DocsTree? docs;

  /// Word buttons between the title and the close mark, for a card that
  /// offers an action. A tip has none.
  final List<Widget> Function(double font)? actions;

  @override
  State<TipModal> createState() => _TipModalState();
}

/// Width of the card in modal fonts, before the screen narrows it.
const _cardWidth = 34.0;

/// Empty room between the frame and the text, on each side, in modal fonts.
const _textSides = 1.6;

class _TipModalState extends State<TipModal> {
  late final DocReader _reader = DocReader(
    first: DocPage(title: widget.title, source: widget.source),
    docs: widget.docs,
    onChange: () => setState(() {}),
  );

  @override
  void didUpdateWidget(TipModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reader.docs = widget.docs;
  }

  /// How tall the text of [source] is at [width], drawn at [font]. The view
  /// scrolls and builds its blocks lazily, so it cannot tell; this is a
  /// measure of the plain words with room for the gaps between paragraphs.
  double _textHeight(String source, double font, double width) {
    var plain = source.replaceFirst(RegExp(r'^\s*#[^\n]*\n'), '');
    plain = plain
        .replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m[1]!)
        .replaceAll(RegExp(r'[`*_>]'), '');
    final painter = TextPainter(
      text: TextSpan(
        text: plain.trim(),
        style: TextStyle(fontFamily: 'OpenGost Type B', fontSize: font),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: max(font * 4, width));
    final paragraphs = RegExp(r'\n\s*\n').allMatches(plain.trim()).length;
    final lines = painter.computeLineMetrics().length;
    painter.dispose();
    // The view sets the text with a line height of 1.5.
    return lines * font * 1.5 + paragraphs * font * 0.9 + font * 1.8;
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final page = _reader.page;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final font = max(12.0, size.shortestSide * 0.018);
        final codeFont = max(11.0, font * 0.72);
        final docFont = docFontOf(codeFont);
        final margin = min(size.width, size.height) * 0.06;
        final width = min(size.width - margin * 2, font * _cardWidth);
        final frame = max(1.4, font * 0.12);
        final padding = EdgeInsets.fromLTRB(
          font * 1.2,
          font * 0.6,
          font * 0.4,
          font * 0.8,
        );
        final sides = font * _textSides;
        final textWidth = min(
          docFont * mdWidth,
          width - padding.horizontal - sides * 2 - codeBarRoom,
        );
        final rowH = font * 2.35;
        final chrome = padding.vertical + rowH + font * 0.35;
        final maxH = max(chrome + font * 4, size.height - margin * 2);
        final wanted =
            _textHeight(page.source, docFont, textWidth) + font * 0.6;
        final height = (chrome + wanted).clamp(chrome + font * 4, maxH);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onClose,
              ),
            ),
            Center(
              child: SizedBox(
                width: width,
                height: height.toDouble(),
                child: BevelFrame(
                  color: widget.color,
                  width: frame,
                  radius: font,
                  child: GrainBox(
                    tile: cellGrain,
                    opacity: modalFillOpacity,
                    child: Padding(
                      padding: padding,
                      child: Column(
                        children: [
                          SizedBox(
                            height: rowH,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    page.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: const Color(0xFFFFFFFF),
                                      fontFamily: 'OpenGost Type B',
                                      fontSize: font * 1.55,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                                if (_reader.canBack)
                                  CodeWordButton(
                                    label: phrase(language, {
                                      'ru': 'Назад',
                                      'en': 'Back',
                                    }),
                                    font: font,
                                    onTap: _reader.back,
                                    hint: 'button-doc-back',
                                  ),
                                ...?widget.actions?.call(font),
                                CodeCloseMark(
                                  label: phrase(language, {
                                    'ru': 'Закрыть',
                                    'en': 'Close',
                                  }),
                                  extent: font * 2.2,
                                  onTap: widget.onClose,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: font * 0.35),
                          Expanded(
                            child: DocBody(
                              reader: _reader,
                              raw: false,
                              codeFont: codeFont,
                              accent: widget.color,
                              sides: sides,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
