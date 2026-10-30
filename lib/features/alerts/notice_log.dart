import 'dart:math';

import 'package:flutter/material.dart';

import '../../hive/hex_scene.dart';
import 'alerts_chrome.dart';
import 'notice_copy.dart';

/// Integration-test log. Line numbers stay put while the text scrolls
/// up, down, left, and right. The log can be selected. A tap outside the
/// panel closes it.
class NoticeLog extends StatefulWidget {
  const NoticeLog({
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
  State<NoticeLog> createState() => _NoticeLogState();
}

class _NoticeLogState extends State<NoticeLog> {
  final _vertical = ScrollController();
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final margin = min(size.width, size.height) * 0.06;
        final font = max(12.0, size.shortestSide * 0.018);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onClose,
              ),
            ),
            Positioned(
              left: margin,
              top: margin,
              right: margin,
              bottom: margin,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: hexFill,
                  border: Border.all(
                    color: widget.color,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFFFFFFFF),
                                fontFamily: 'OpenGost Type B',
                                fontSize: font * 1.15,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                          NoticeCopyButton(
                            text: widget.text,
                            label: widget.copyLabel,
                            extent: font * 2.2,
                          ),
                          SizedBox(width: font * 0.45),
                          NoticeCloseButton(
                            label: widget.closeLabel,
                            extent: font * 2.2,
                            onTap: widget.onClose,
                          ),
                        ],
                      ),
                      SizedBox(height: font * 0.35),
                      Expanded(
                        child: _LogBody(
                          text: widget.text,
                          fontSize: font,
                          vertical: _vertical,
                          horizontal: _horizontal,
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
}

class _LogBody extends StatelessWidget {
  const _LogBody({
    required this.text,
    required this.fontSize,
    required this.vertical,
    required this.horizontal,
  });

  final String text;
  final double fontSize;
  final ScrollController vertical;
  final ScrollController horizontal;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final style = noticeMono(fontSize);
    final numberStyle = style.copyWith(color: hexMuted);
    final sample = TextPainter(
      text: TextSpan(text: '0', style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final lineHeight = sample.height;
    sample.dispose();
    final digits = lines.length.toString().length;
    final gutter = TextPainter(
      text: TextSpan(text: '0' * digits, style: numberStyle),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final gutterWidth = gutter.width + fontSize;
    gutter.dispose();
    var codeWidth = 0.0;
    for (final line in lines) {
      if (line.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(text: line, style: style),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      if (painter.width > codeWidth) codeWidth = painter.width;
      painter.dispose();
    }
    final theme = ScrollbarThemeData(
      thumbVisibility: const WidgetStatePropertyAll(true),
      trackVisibility: const WidgetStatePropertyAll(true),
      thickness: const WidgetStatePropertyAll(8),
      radius: const Radius.circular(4),
      thumbColor: const WidgetStatePropertyAll(Color(0xFF8A8A92)),
      trackColor: const WidgetStatePropertyAll(Color(0xFF2C2C32)),
      trackBorderColor: const WidgetStatePropertyAll(Color(0x00000000)),
    );
    return ScrollbarTheme(
      data: theme,
      child: Scrollbar(
        controller: vertical,
        thumbVisibility: true,
        child: Scrollbar(
          controller: horizontal,
          thumbVisibility: true,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: vertical,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: gutterWidth,
                  child: Column(
                    children: [
                      for (var i = 0; i < lines.length; i++)
                        SizedBox(
                          height: lineHeight,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.only(right: fontSize * 0.7),
                              child: Text('${i + 1}', style: numberStyle),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: horizontal,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: max(codeWidth, 1) + fontSize,
                      child: SelectionArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final line in lines)
                              SizedBox(
                                height: lineHeight,
                                child: Text(line, style: style, maxLines: 1),
                              ),
                          ],
                        ),
                      ),
                    ),
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
