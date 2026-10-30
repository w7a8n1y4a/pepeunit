import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../hive/hex_scene.dart';
import '../../hive/marks.dart';

/// Copy mark. It turns green for a moment after the text lands on the clipboard.
class NoticeCopyButton extends StatefulWidget {
  const NoticeCopyButton({
    required this.text,
    required this.label,
    required this.extent,
    super.key,
  });

  final String text;
  final String label;
  final double extent;

  @override
  State<NoticeCopyButton> createState() => _NoticeCopyButtonState();
}

class _NoticeCopyButtonState extends State<NoticeCopyButton> {
  Timer? _copiedReset;
  var _copied = false;

  @override
  void dispose() {
    _copiedReset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    _copiedReset?.cancel();
    _copiedReset = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTap: _copy,
        behavior: HitTestBehavior.opaque,
        child: HoverPop(
          child: SizedBox(
            width: widget.extent,
            height: widget.extent,
            child: CustomPaint(
              painter: CopyMarkPainter(
                _copied ? const Color(0xFF4CAF50) : const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Close mark for a notice table and the test log.
class NoticeCloseButton extends StatelessWidget {
  const NoticeCloseButton({
    required this.label,
    required this.extent,
    required this.onTap,
    super.key,
  });

  final String label;
  final double extent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: HoverPop(
          child: SizedBox(
            width: extent,
            height: extent,
            child: SvgPicture.asset(
              'assets/icons/close.svg',
              width: extent,
              height: extent,
            ),
          ),
        ),
      ),
    );
  }
}
