import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../hive/marks.dart';
import '../../locale/languages.dart';
import 'code_view.dart';

/// The one frame for every panel that shows text or code: logs, storage,
/// values, editors, notices. Change its look here and every panel follows.
///
/// - Title at the upper left. The tools stand at the upper right in a fixed
///   order: [actions], download, copy, close.
/// - The body takes the rest and scrolls when the text is long. A panel that
///   knows its text hands it as [text] and shrinks to it; [rows] does the
///   same for a list; without either the body fills the screen.
/// - A note stands under the body. An error is that note in [errorColor].
/// - A tap outside closes the panel when [barrierCloses] allows.
class CodeModal extends StatelessWidget {
  const CodeModal({
    required this.title,
    required this.color,
    required this.onClose,
    required this.copy,
    required this.body,
    this.text,
    this.rows,
    this.actions,
    this.onDownload,
    this.downloading = false,
    this.note,
    this.noteColor = errorColor,
    this.noteLines = 2,
    this.barrierCloses = true,
    this.stackActions = false,
    super.key,
  });

  final String title;
  final Color color;
  final VoidCallback onClose;

  /// What the copy mark puts on the clipboard, read when it is tapped.
  final String Function() copy;

  /// The body. It gets the code font and, with [text], the layout of that
  /// text at the width the body has.
  final Widget Function(double codeFont, CodeLayout? layout) body;

  /// The text the body shows or edits. The panel is as tall as its wrapped
  /// rows, up to the screen.
  final String? text;

  /// Row count of a body that is not [text]. A row is one line of code.
  final int? rows;

  /// Words and chips before the marks, such as Save or a level filter.
  final List<Widget> Function(double font)? actions;

  /// The download mark. Hidden when null.
  final VoidCallback? onDownload;
  final bool downloading;
  final String? note;
  final Color noteColor;

  /// Lines the note keeps in view. A longer note scrolls.
  final int noteLines;
  final bool barrierCloses;

  /// Many actions: on a narrow screen they take a row under the title, so
  /// the title keeps its place.
  final bool stackActions;

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final margin = min(size.width, size.height) * 0.06;
        final font = max(12.0, size.shortestSide * 0.018);
        final codeFont = max(11.0, font * 0.72);
        final shown = note?.trim() ?? '';
        final rowH = font * 2.35;
        final gap = font * 0.35;
        final noteH = font * 1.25 * noteLines;
        final noteStyle = TextStyle(
          color: noteColor,
          fontFamily: 'OpenGost Type B',
          fontSize: font,
          decoration: TextDecoration.none,
        );
        final stacked = stackActions && size.width < 640;
        final chrome =
            font * 0.6 + rowH * (stacked ? 2 : 1) + gap + gap + noteH + font;
        final maxH = max(chrome + font * 4, size.height - margin * 2);
        final bodyWidth = size.width - margin * 2 - font * 1.4;
        final layout = text == null
            ? null
            : CodeLayout.of(
                context,
                text: text!,
                fontSize: codeFont,
                width: bodyWidth - codeBarRoom,
              );
        final wanted = layout != null
            ? max(layout.total, layout.lineHeight * 4) + 8
            : rows != null
            ? max(4, rows!) * codeFont * 1.35 + font * 0.4
            : maxH - chrome;
        final bodyH = wanted.clamp(font * 4, maxH - chrome).toDouble();
        final height = (chrome + bodyH)
            .clamp(chrome + font * 4, maxH)
            .toDouble();
        final tools = Row(
          children: [
            ...?actions?.call(font),
            if (onDownload != null)
              _DownloadMark(
                label: phrase(language, {'ru': 'Скачать', 'en': 'Download'}),
                extent: font * 2.2,
                busy: downloading,
                onTap: onDownload!,
              ),
            _CopyMark(
              text: copy,
              label: phrase(language, {'ru': 'Скопировать', 'en': 'Copy'}),
              extent: font * 2.2,
            ),
            SizedBox(width: font * 0.2),
            _CloseMark(
              label: phrase(language, {'ru': 'Закрыть', 'en': 'Close'}),
              extent: font * 2.2,
              onTap: onClose,
            ),
          ],
        );
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (barrierCloses) onClose();
                },
              ),
            ),
            Positioned(
              left: margin,
              top: margin,
              right: margin,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: hexFill,
                  border: Border.all(
                    color: color,
                    width: max(1.4, font * 0.12),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    font,
                    font * 0.6,
                    font * 0.4,
                    font,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: rowH,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
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
                            if (!stacked) _scrolling(tools),
                          ],
                        ),
                      ),
                      if (stacked)
                        SizedBox(
                          height: rowH,
                          width: double.infinity,
                          child: _scrolling(tools),
                        ),
                      SizedBox(height: gap),
                      Expanded(child: body(codeFont, layout)),
                      SizedBox(height: gap),
                      SizedBox(
                        height: noteH,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: noteLines > 2
                              ? SingleChildScrollView(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Text(shown, style: noteStyle),
                                  ),
                                )
                              : Text(
                                  shown,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: noteStyle,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _scrolling(Widget tools) =>
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: tools);
}

/// A word on a modal bar. While [busy] a spinner stands before it and the
/// label keeps its color.
class CodeWordButton extends StatelessWidget {
  /// Every word on a bar is this many times the modal font.
  static const scale = 1.4;

  const CodeWordButton({
    required this.label,
    required this.font,
    required this.onTap,
    this.color = const Color(0xFFFFFFFF),
    this.enabled = true,
    this.busy = false,
    super.key,
  });

  final String label;
  final double font;
  final VoidCallback onTap;
  final Color color;
  final bool enabled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return HoverPop(
      enabled: enabled,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: font * 0.45),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy) ...[
                  SizedBox(
                    width: font * scale * 0.8,
                    height: font * scale * 0.8,
                    child: CircularProgressIndicator(
                      strokeWidth: max(1.5, font * scale * 0.8 * 0.14),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  SizedBox(width: font * 0.4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: enabled || busy ? color : hexMuted,
                    fontFamily: 'OpenGost Type B',
                    fontSize: font * scale,
                    decoration: TextDecoration.none,
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

/// A word that filters, lit while on.
class CodeChip extends StatelessWidget {
  const CodeChip({
    required this.label,
    required this.on,
    required this.font,
    required this.color,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool on;
  final double font;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverPop(
      child: Semantics(
        button: true,
        selected: on,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: font * 0.35),
            child: Text(
              label,
              style: codeMono(font * 0.95, color: on ? color : hexMuted),
            ),
          ),
        ),
      ),
    );
  }
}

/// How long a modal button keeps its spinner at least. A fast answer would
/// otherwise end it before a frame is drawn.
const _spinnerMin = Duration(milliseconds: 600);

/// Waits out what is left of the minimum spinner time since [watch] started.
Future<void> holdSpinner(Stopwatch watch) async {
  final left = _spinnerMin - watch.elapsed;
  if (left > Duration.zero) await Future<void>.delayed(left);
}

/// A square mark with the shared hover and semantics.
class _Mark extends StatelessWidget {
  const _Mark({
    required this.label,
    required this.extent,
    required this.onTap,
    required this.child,
  });

  final String label;
  final double extent;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: HoverPop(
          child: SizedBox(width: extent, height: extent, child: child),
        ),
      ),
    );
  }
}

class _CloseMark extends StatelessWidget {
  const _CloseMark({
    required this.label,
    required this.extent,
    required this.onTap,
  });

  final String label;
  final double extent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Mark(
      label: label,
      extent: extent,
      onTap: onTap,
      child: SvgPicture.asset(
        'assets/icons/actions/close.svg',
        width: extent,
        height: extent,
      ),
    );
  }
}

/// Copy mark. It turns green for a moment after the text lands on the
/// clipboard.
class _CopyMark extends StatefulWidget {
  const _CopyMark({
    required this.text,
    required this.label,
    required this.extent,
  });

  final String Function() text;
  final String label;
  final double extent;

  @override
  State<_CopyMark> createState() => _CopyMarkState();
}

class _CopyMarkState extends State<_CopyMark> {
  Timer? _reset;
  var _copied = false;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text()));
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _Mark(
      label: widget.label,
      extent: widget.extent,
      onTap: _copy,
      child: CustomPaint(
        painter: CopyMarkPainter(
          _copied ? const Color(0xFF4CAF50) : const Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}

/// Download mark. A spinner takes its place while the file is made.
class _DownloadMark extends StatelessWidget {
  const _DownloadMark({
    required this.label,
    required this.extent,
    required this.onTap,
    required this.busy,
  });

  final String label;
  final double extent;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return _Mark(
      label: label,
      extent: extent,
      onTap: busy ? null : onTap,
      child: busy
          ? Padding(
              padding: EdgeInsets.all(extent * 0.26),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFFFFF)),
              ),
            )
          : const CustomPaint(painter: _DownloadPainter()),
    );
  }
}

class _DownloadPainter extends CustomPainter {
  const _DownloadPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final h = size.height;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.14),
      Offset(w * 0.5, h * 0.58),
      paint,
    );
    canvas.drawLine(Offset(w * 0.28, h * 0.4), Offset(w * 0.5, h * 0.6), paint);
    canvas.drawLine(Offset(w * 0.72, h * 0.4), Offset(w * 0.5, h * 0.6), paint);
    final tray = Path()
      ..moveTo(w * 0.18, h * 0.72)
      ..lineTo(w * 0.18, h * 0.88)
      ..lineTo(w * 0.82, h * 0.88)
      ..lineTo(w * 0.82, h * 0.72);
    canvas.drawPath(tray, paint);
  }

  @override
  bool shouldRepaint(covariant _DownloadPainter oldDelegate) => false;
}
