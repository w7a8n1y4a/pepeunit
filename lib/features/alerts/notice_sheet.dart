import 'dart:math';

import 'package:flutter/material.dart';

import '../../hive/hex_scene.dart';
import 'alerts_chrome.dart';
import 'notice_copy.dart';

/// Notice table. The panel follows the text until it meets the screen, then
/// scrolls. A tap outside closes it.
class NoticeSheet extends StatelessWidget {
  const NoticeSheet({
    required this.text,
    required this.title,
    required this.color,
    required this.copyLabel,
    required this.closeLabel,
    required this.onClose,
    super.key,
  });

  final String text;
  final String title;
  final Color color;
  final String copyLabel;
  final String closeLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final margin = min(size.width, size.height) * 0.06;
        final font = max(12.0, size.shortestSide * 0.018);
        final tableFont = max(11.0, font * 0.72);
        final button = font * 2.2;
        final gap = font * 0.35;
        final padL = font;
        final padT = font * 0.6;
        final padR = font * 0.85;
        final padB = font;
        final maxW = max(0.0, size.width - margin * 2);
        final maxH = max(0.0, size.height - margin * 2);
        final maxTableW = max(0.0, maxW - padL - padR);
        final maxTableH = max(0.0, maxH - padT - padB - button - gap);
        final scaler = MediaQuery.textScalerOf(context);
        final titleStyle = TextStyle(
          color: const Color(0xFFFFFFFF),
          fontFamily: 'OpenGost Type B',
          fontSize: font * 1.55,
          decoration: TextDecoration.none,
        );
        final tableStyle = noticeMono(tableFont);
        final titleW = _painted(title, titleStyle, scaler).width;
        final table = _painted(text, tableStyle, scaler);
        final headerMin = titleW + font * 0.9 + button * 2;
        const bar = 8.0;
        const tail = bar + 6;
        const side = bar + 4;
        final tooWide = table.width > maxTableW + 1;
        final tooTall = table.height > maxTableH + 1;
        final scrollX = tooWide || (tooTall && table.width + side > maxTableW);
        final scrollY = tooTall || (scrollX && table.height + tail > maxTableH);
        final rightGap = scrollY ? side : 0.0;
        final bottomGap = scrollX ? tail : 0.0;
        final viewW = min(max(table.width + rightGap, headerMin), maxTableW);
        final viewH = min(table.height + bottomGap, maxTableH);
        final panelW = min(viewW + padL + padR, maxW);
        final panelH = min(viewH + padT + padB + button + gap, maxH);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
              ),
            ),
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: SizedBox(
                  width: panelW,
                  height: panelH,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: hexFill,
                      border: Border.all(
                        color: color,
                        width: max(1.4, font * 0.12),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(padL, padT, padR, padB),
                      child: Column(
                        children: [
                          SizedBox(
                            height: button,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: titleStyle,
                                  ),
                                ),
                                SizedBox(width: font * 0.45),
                                NoticeCopyButton(
                                  text: text,
                                  label: copyLabel,
                                  extent: button,
                                ),
                                SizedBox(width: font * 0.45),
                                NoticeCloseButton(
                                  label: closeLabel,
                                  extent: button,
                                  onTap: onClose,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: gap),
                          Expanded(
                            child: _TableBody(
                              text: text,
                              style: tableStyle,
                              textSize: table,
                              scrollX: scrollX,
                              scrollY: scrollY,
                              rightGap: rightGap,
                              bottomGap: bottomGap,
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

class _TableBody extends StatelessWidget {
  const _TableBody({
    required this.text,
    required this.style,
    required this.textSize,
    required this.scrollX,
    required this.scrollY,
    required this.rightGap,
    required this.bottomGap,
  });

  final String text;
  final TextStyle style;
  final Size textSize;
  final bool scrollX;
  final bool scrollY;
  final double rightGap;
  final double bottomGap;

  @override
  Widget build(BuildContext context) {
    const bar = 8.0;
    final theme = ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(bar),
      radius: const Radius.circular(4),
      thumbColor: const WidgetStatePropertyAll(Color(0xFF8A8A92)),
      trackColor: const WidgetStatePropertyAll(Color(0xFF2C2C32)),
      trackBorderColor: const WidgetStatePropertyAll(Color(0x00000000)),
    );
    return ScrollbarTheme(
      data: theme,
      child: Scrollbar(
        thumbVisibility: scrollY,
        trackVisibility: scrollY,
        notificationPredicate: (notification) =>
            notification.metrics.axis == Axis.vertical,
        child: Scrollbar(
          thumbVisibility: scrollX,
          trackVisibility: scrollX,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            physics: scrollY ? null : const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: bottomGap),
            child: SizedBox(
              height: max(textSize.height, 1),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: scrollX ? null : const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: max(textSize.width + rightGap, 1),
                  height: max(textSize.height, 1),
                  child: SelectionArea(
                    child: Text(
                      text,
                      key: const ValueKey('notice-sheet'),
                      softWrap: false,
                      style: style,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Size _painted(String text, TextStyle style, TextScaler scaler) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
  )..layout();
  final size = painter.size;
  painter.dispose();
  return size;
}
