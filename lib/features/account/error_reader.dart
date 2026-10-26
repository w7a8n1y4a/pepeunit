import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../hive/hex_scene.dart';
import '../../hive/marks.dart';

/// The error message, drawn inside its own cell. The rest of the menu stays put.
class ErrorCell extends StatefulWidget {
  const ErrorCell({required this.message, required this.copyLabel, super.key});

  final String message;
  final String copyLabel;

  @override
  State<ErrorCell> createState() => _ErrorCellState();
}

class _ErrorCellState extends State<ErrorCell> {
  Timer? _copiedReset;
  var _copied = false;

  @override
  void dispose() {
    _copiedReset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.message));
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            side * 0.16,
            side * 0.26,
            side * 0.16,
            side * 0.16,
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: errorColor,
                      decoration: TextDecoration.none,
                      fontFamily: 'OpenGost Type B',
                      fontSize: max(10, side * 0.055),
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: widget.copyLabel,
                child: GestureDetector(
                  onTap: _copy,
                  behavior: HitTestBehavior.opaque,
                  child: HoverPop(
                    child: SizedBox(
                      width: side * 0.18,
                      height: side * 0.16,
                      child: CustomPaint(
                        painter: CopyMarkPainter(
                          _copied
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
