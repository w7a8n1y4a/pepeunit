import 'dart:math';

import 'package:flutter/material.dart';

import '../hive/hex_scene.dart';

/// How far a search choice leans, counterclockwise so it rises to the right.
///
/// The labels stay in one horizontal row. Each first letter sits on the same
/// line, and the lean lets the next word begin under the previous tail.
/// A crowded row leans more, up to [_leanMax].
const searchChoiceLean = -_leanMin;

const _leanMin = 20 * pi / 180;
const _leanMax = 34 * pi / 180;

const _tight = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);

class SlantedChoice {
  const SlantedChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
}

/// One enum of a search, laid out in a horizontal row at a shared lean.
///
/// Each first letter sits on one horizontal line. The lean lets the next
/// word begin under the previous tail, so the row stays short.
class SlantedChoices extends StatelessWidget {
  const SlantedChoices({
    required this.fontSize,
    required this.choices,
    this.maxWidth,
    this.span,
    super.key,
  });

  final double fontSize;
  final List<SlantedChoice> choices;

  /// Steepens the lean when the row would otherwise pass this width.
  final double? maxWidth;

  /// Shared lean for several rows. Wins over [maxWidth].
  final SlantedSpan? span;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final inks = [
      for (final choice in choices)
        _inkSize(choice.label, _choiceStyle(choice, fontSize), scaler),
    ];
    final span = this.span ?? _fitSpan([inks], maxWidth ?? double.infinity);
    final magnitude = span.lean.abs();
    final placed = <_PlacedChoice>[];
    var startX = 0.0;
    for (var i = 0; i < choices.length; i++) {
      final ink = inks[i];
      if (i > 0) startX += _startDx(inks[i - 1], ink, magnitude);
      final center = _center(startX, ink, magnitude);
      final bounds = _leanBounds(ink, magnitude);
      placed.add(
        _PlacedChoice(
          choice: choices[i],
          ink: ink,
          bounds: bounds,
          lean: span.lean,
          left: center.dx - bounds.width / 2,
          top: center.dy - bounds.height / 2,
        ),
      );
    }
    if (placed.isEmpty) return const SizedBox.shrink();
    final shiftX = placed.map((slot) => slot.left).reduce(min);
    final shiftY = placed.map((slot) => slot.top).reduce(min);
    var width = 0.0;
    var height = 0.0;
    for (final slot in placed) {
      slot.left -= shiftX;
      slot.top -= shiftY;
      width = max(width, slot.left + slot.bounds.width);
      height = max(height, slot.top + slot.bounds.height);
    }
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final slot in placed)
            Positioned(
              left: slot.left,
              top: slot.top,
              width: slot.bounds.width,
              height: slot.bounds.height,
              child: _SlantedLabel(slot: slot, fontSize: fontSize),
            ),
        ],
      ),
    );
  }
}

/// Lean shared by several horizontal rows.
class SlantedSpan {
  const SlantedSpan({required this.lean});

  final double lean;
}

/// One lean for several horizontal rows that share a width.
SlantedSpan spanForSlantedRows({
  required List<List<String>> rows,
  required double fontSize,
  required TextScaler scaler,
  required double maxWidth,
}) {
  final measured = [
    for (final row in rows)
      [
        for (final label in row)
          _inkSize(label, _measureStyle(fontSize), scaler),
      ],
  ];
  return _fitSpan(measured, maxWidth);
}

class _PlacedChoice {
  _PlacedChoice({
    required this.choice,
    required this.ink,
    required this.bounds,
    required this.lean,
    required this.left,
    required this.top,
  });

  final SlantedChoice choice;
  final Size ink;
  final Size bounds;
  final double lean;
  double left;
  double top;
}

class _SlantedLabel extends StatelessWidget {
  const _SlantedLabel({required this.slot, required this.fontSize});

  final _PlacedChoice slot;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final choice = slot.choice;
    final style = _choiceStyle(choice, fontSize);
    return Semantics(
      button: true,
      selected: choice.selected,
      label: choice.label,
      excludeSemantics: true,
      onTap: choice.onTap,
      child: Center(
        child: Transform.rotate(
          angle: slot.lean,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: choice.onTap,
            child: HoverPop(
              child: SizedBox(
                width: slot.ink.width,
                height: slot.ink.height,
                child: Text(
                  choice.label,
                  maxLines: 1,
                  softWrap: false,
                  textHeightBehavior: _tight,
                  style: style,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _choiceStyle(SlantedChoice choice, double fontSize) {
  return TextStyle(
    color: choice.selected ? const Color(0xFFFFFFFF) : hexMuted,
    fontFamily: 'OpenGost Type B',
    fontSize: fontSize,
    height: 1,
    decoration: TextDecoration.none,
  );
}

Size _inkSize(String label, TextStyle style, TextScaler scaler) {
  final painter = TextPainter(
    text: TextSpan(text: label, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    textHeightBehavior: _tight,
    maxLines: 1,
  )..layout();
  final size = painter.size;
  painter.dispose();
  return size;
}

TextStyle _measureStyle(double fontSize) {
  return TextStyle(
    fontFamily: 'OpenGost Type B',
    fontSize: fontSize,
    height: 1,
    decoration: TextDecoration.none,
  );
}

Size _leanBounds(Size ink, double magnitude) {
  final across = cos(magnitude);
  final rise = sin(magnitude);
  return Size(
    ink.width * across + ink.height * rise,
    ink.width * rise + ink.height * across,
  );
}

/// Rotation center when the first letter sits on the shared horizontal.
Offset _center(double startX, Size ink, double magnitude) {
  return Offset(
    startX + ink.width / 2 * cos(magnitude),
    -ink.width / 2 * sin(magnitude),
  );
}

/// Distance from one word's first letter to the next, along the row.
///
/// The slant keeps the glyphs apart, so a long word's tail still hangs over
/// the next word's first letter.
double _startDx(Size a, Size b, double magnitude) {
  final air = 0.16 * max(a.height, b.height);
  return ((a.height + b.height) / 2 + air) / sin(magnitude);
}

double _rowWidth(List<Size> inks, double magnitude) {
  if (inks.isEmpty) return 0;
  var startX = 0.0;
  var left = double.infinity;
  var right = double.negativeInfinity;
  for (var i = 0; i < inks.length; i++) {
    if (i > 0) startX += _startDx(inks[i - 1], inks[i], magnitude);
    final center = _center(startX, inks[i], magnitude);
    final half = _leanBounds(inks[i], magnitude).width / 2;
    left = min(left, center.dx - half);
    right = max(right, center.dx + half);
  }
  return right - left;
}

SlantedSpan _fitSpan(List<List<Size>> groups, double maxWidth) {
  if (groups.every((group) => group.isEmpty)) {
    return const SlantedSpan(lean: -_leanMin);
  }
  double widthAt(double magnitude) {
    var width = 0.0;
    for (final group in groups) {
      width = max(width, _rowWidth(group, magnitude));
    }
    return width;
  }

  if (!maxWidth.isFinite || widthAt(_leanMin) <= maxWidth) {
    return const SlantedSpan(lean: -_leanMin);
  }
  var low = _leanMin;
  var high = _leanMax;
  for (var step = 0; step < 14; step++) {
    final mid = (low + high) / 2;
    if (widthAt(mid) <= maxWidth) {
      high = mid;
    } else {
      low = mid;
    }
  }
  return SlantedSpan(lean: -high);
}
