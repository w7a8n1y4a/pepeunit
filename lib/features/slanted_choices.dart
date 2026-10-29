import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../hive/hex_scene.dart';

/// Shallowest lean of a search enum, rising to the right.
const _leanFloor = 6 * pi / 180;

/// Steepest lean. Past this the row scales down instead of standing up.
const _leanCeil = 62 * pi / 180;

const _tight = ui.TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);

/// One value in a search enum.
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

/// Search enums under one line.
///
/// Each row is one enum. The block stays within [maxWidth] (the search
/// stroke). In a row, every first letter sits on one horizontal line. The
/// clear gap between stacked words is a third of a capital. A short row
/// leans less, so it stays short; a long row leans more until it fits.
/// Once a word has ended, the next word starts just after that ink instead
/// of waiting on an imaginary continuation of the line. Rows sit half a
/// font apart.
///
/// [spanLine] keeps the largest size that still fills [maxWidth] and,
/// when set, [maxBlockHeight]. [lineGapShare] is the clear gap between
/// stacked words, as a share of a capital. A smaller share lets the row
/// lean less and stay shorter at the same width.
class SlantedChoices extends StatelessWidget {
  const SlantedChoices({
    required this.fontSize,
    required this.maxWidth,
    required this.rows,
    this.rowGap,
    this.rowGapShare,
    this.spanLine = false,
    this.spanRows,
    this.rowWidthShare = const {},
    this.rowLineGap = const {},
    this.lineGapShare = 1 / 3,
    this.maxBlockHeight,
    super.key,
  });

  final double fontSize;
  final double maxWidth;
  final List<List<SlantedChoice>> rows;

  /// Gap between enums. Defaults to half the fitted font, or [rowGapShare].
  final double? rowGap;

  /// Gap between enums as a share of the fitted font. A negative share
  /// pulls the next row up. The font itself stays sized for half a font.
  final double? rowGapShare;

  /// Uses the full search stroke. The lean rises only as far as the size needs.
  final bool spanLine;

  /// Rows that spread out to the stroke. Defaults to every row when
  /// [spanLine] is set.
  final Set<int>? spanRows;

  /// Max width of a row, as a share of the stroke. Missing rows use the stroke.
  final Map<int, double> rowWidthShare;

  /// Clear-gap share for one row. Missing rows use [lineGapShare].
  final Map<int, double> rowLineGap;

  /// Clear gap between stacked words, as a share of a capital.
  final double lineGapShare;

  /// Largest block height. The letters shrink until the rows fit.
  final double? maxBlockHeight;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final widthCap = min(
          maxWidth.isFinite ? maxWidth : constraints.maxWidth,
          constraints.maxWidth,
        );
        final limit = widthCap.isFinite ? widthCap : maxWidth;
        final font = spanLine || maxBlockHeight != null
            ? _fontThatFits(limit, scaler)
            : fontSize;
        final gap = rowGap ?? font * (rowGapShare ?? 0.5);
        final laid = _laidRows(font, limit, scaler, paint: true);
        if (laid.isEmpty) return const SizedBox.shrink();
        var blockWidth = 0.0;
        for (final row in laid) {
          blockWidth = max(blockWidth, row.layout.size.width);
        }
        final built = <Widget>[];
        var lift = 0.0;
        for (final row in laid) {
          var child = _rowStack(
            words: row.words,
            layout: row.layout,
            width: blockWidth,
            scaler: scaler,
          );
          if (built.isNotEmpty) {
            if (gap > 0) {
              built.add(SizedBox(height: gap));
            } else if (gap < 0) {
              lift -= gap;
              child = Transform.translate(
                offset: Offset(0, -lift),
                child: child,
              );
            }
          }
          built.add(child);
        }
        final block = Column(mainAxisSize: MainAxisSize.min, children: built);
        if (spanLine) return block;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: widthCap.isFinite ? widthCap : double.infinity,
              maxHeight: constraints.maxHeight,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: block,
            ),
          ),
        );
      },
    );
  }

  double _rowLimit(int index, double limit) {
    final share = rowWidthShare[index];
    if (share == null || !limit.isFinite) return limit;
    return limit * share;
  }

  List<_LaidRow> _laidRows(
    double font,
    double limit,
    TextScaler scaler, {
    bool paint = false,
  }) {
    final laid = <_LaidRow>[];
    for (var i = 0; i < rows.length; i++) {
      final laidRow = _layRow(
        row: rows[i],
        font: font,
        maxWidth: paint ? _rowLimit(i, limit) : limit,
        scaler: scaler,
        span: spanLine && (spanRows == null || spanRows!.contains(i)),
        lineGapShare: paint ? (rowLineGap[i] ?? lineGapShare) : lineGapShare,
      );
      if (laidRow != null) laid.add(laidRow);
    }
    return laid;
  }

  double _blockHeight(List<_LaidRow> laid, double font) {
    if (laid.isEmpty) return 0;
    // Size the letters for the default gap. A tighter painted gap must
    // not grow or shrink them.
    final gap = font * 0.5;
    var height = 0.0;
    for (var i = 0; i < laid.length; i++) {
      if (i > 0) height += gap;
      height += laid[i].layout.size.height;
    }
    return height;
  }

  /// Largest size at or under [fontSize] that keeps the stroke and the band.
  double _fontThatFits(double limit, TextScaler scaler) {
    if (!limit.isFinite || limit <= 0) return fontSize;
    final band = maxBlockHeight;
    bool fits(double font) {
      final laid = _laidRows(font, limit, scaler);
      var width = 0.0;
      for (final row in laid) {
        width = max(width, row.layout.size.width);
      }
      if (width > limit + 0.5) return false;
      if (band != null &&
          band.isFinite &&
          _blockHeight(laid, font) > band + 0.5) {
        return false;
      }
      return true;
    }

    if (fits(fontSize)) return fontSize;
    var low = 1.0;
    var high = fontSize;
    if (high <= low || !fits(low)) return max(1.0, low);
    for (var step = 0; step < 14; step++) {
      final mid = (low + high) / 2;
      if (fits(mid)) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return low;
  }
}

class _Word {
  const _Word(this.choice, this.style, this.measured);

  final SlantedChoice choice;
  final TextStyle style;
  final SlantedMeasure measured;

  SlantedInk get ink => measured.ink;
}

class _LaidRow {
  const _LaidRow(this.words, this.layout);

  final List<_Word> words;
  final SlantedRowLayout layout;
}

_LaidRow? _layRow({
  required List<SlantedChoice> row,
  required double font,
  required double maxWidth,
  required TextScaler scaler,
  bool span = false,
  double lineGapShare = 1 / 3,
}) {
  final words = <_Word>[];
  for (final choice in row) {
    if (choice.label.isEmpty) continue;
    final style = _choiceStyle(choice, font);
    final measured = _measureWord(choice.label, style, scaler);
    if (measured == null) continue;
    words.add(_Word(choice, style, measured));
  }
  if (words.isEmpty) return null;
  final cap = _capitalHeight(font, scaler);
  var layout = placeSlantedRow(
    words: [for (final word in words) word.ink],
    maxWidth: maxWidth,
    lineGap: cap * lineGapShare,
    touchGap: max(1.0, cap * 0.12),
  );
  if (span) layout = spanSlantedRow(layout, maxWidth);
  return _LaidRow(words, layout);
}

Widget _rowStack({
  required List<_Word> words,
  required SlantedRowLayout layout,
  required double width,
  required TextScaler scaler,
}) {
  final shift = max(0.0, (width - layout.size.width) / 2);
  return SizedBox(
    width: width,
    height: layout.size.height,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < words.length; i++)
          _placedWord(
            word: words[i],
            spot: layout.spots[i],
            lean: layout.lean,
            shift: shift,
            scaler: scaler,
          ),
      ],
    ),
  );
}

Widget _placedWord({
  required _Word word,
  required SlantedWordSpot spot,
  required double lean,
  required double shift,
  required TextScaler scaler,
}) {
  final box = spot.box.shift(Offset(shift, 0));
  final pivot = spot.pivot + Offset(shift, 0);
  final matrix = Matrix4.identity()
    ..translateByDouble(pivot.dx - box.left, pivot.dy - box.top, 0, 1)
    ..rotateZ(-lean)
    ..translateByDouble(
      -word.measured.pivotInText.dx,
      -word.measured.pivotInText.dy,
      0,
      1,
    );
  final choice = word.choice;
  return Positioned(
    left: box.left,
    top: box.top,
    width: box.width,
    height: box.height,
    child: HoverPop(
      child: Semantics(
        button: true,
        selected: choice.selected,
        label: choice.label,
        onTap: choice.onTap,
        child: GestureDetector(
          onTap: choice.onTap,
          behavior: HitTestBehavior.deferToChild,
          child: _SlantedGlyph(
            label: choice.label,
            style: word.style,
            scaler: scaler,
            matrix: matrix,
          ),
        ),
      ),
    ),
  );
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

TextPainter _painterFor(String label, TextStyle style, TextScaler scaler) {
  return TextPainter(
    text: TextSpan(text: label, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    textHeightBehavior: _tight,
    maxLines: 1,
  )..layout();
}

double _capitalHeight(double fontSize, TextScaler scaler) {
  final style = TextStyle(
    fontFamily: 'OpenGost Type B',
    fontSize: fontSize,
    height: 1,
    decoration: TextDecoration.none,
  );
  final measured = _measureWord('Н', style, scaler);
  final cap = measured?.ink.ascent ?? 0;
  if (cap > 0) return cap;
  return fontSize * 0.7;
}

/// Ink of one word relative to its first letter.
class SlantedInk {
  const SlantedInk({
    required this.alongStart,
    required this.alongEnd,
    required this.ascent,
    required this.descent,
  });

  /// Left of the ink, along the baseline, from the first letter.
  final double alongStart;

  /// Right of the ink, along the baseline, from the first letter.
  final double alongEnd;

  /// Ink above the baseline.
  final double ascent;

  /// Ink below the baseline.
  final double descent;
}

/// Where one word sits in its row.
class SlantedWordSpot {
  const SlantedWordSpot({required this.box, required this.pivot});

  final Rect box;

  /// First letter, on the shared horizontal.
  final Offset pivot;
}

/// A laid-out enum row.
class SlantedRowLayout {
  const SlantedRowLayout({
    required this.lean,
    required this.size,
    required this.spots,
  });

  /// Radians, rising to the right.
  final double lean;
  final Size size;
  final List<SlantedWordSpot> spots;
}

/// Measured label. [pivotInText] is the first letter on the baseline.
class SlantedMeasure {
  const SlantedMeasure({required this.ink, required this.pivotInText});

  final SlantedInk ink;
  final Offset pivotInText;
}

@visibleForTesting
SlantedMeasure? measureSlantedWord(
  String label,
  TextStyle style,
  TextScaler scaler,
) {
  return _measureWord(label, style, scaler);
}

SlantedMeasure? _measureWord(String label, TextStyle style, TextScaler scaler) {
  if (label.isEmpty) return null;
  final painter = _painterFor(label, style, scaler);
  final metrics = painter.computeLineMetrics();
  final baseline = metrics.isEmpty
      ? painter.height * 0.8
      : metrics.first.baseline;
  final boxes = painter.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: label.length),
  );
  final first = painter.getBoxesForSelection(
    const TextSelection(baseOffset: 0, extentOffset: 1),
  );
  final textWidth = painter.width;
  final textHeight = painter.height;
  painter.dispose();
  final left = boxes.isEmpty ? 0.0 : boxes.map((box) => box.left).reduce(min);
  final right = boxes.isEmpty
      ? textWidth
      : boxes.map((box) => box.right).reduce(max);
  final top = boxes.isEmpty ? 0.0 : boxes.map((box) => box.top).reduce(min);
  final bottom = boxes.isEmpty
      ? textHeight
      : boxes.map((box) => box.bottom).reduce(max);
  final origin = first.isEmpty ? left : first.first.left;
  return SlantedMeasure(
    pivotInText: Offset(origin, baseline),
    ink: SlantedInk(
      alongStart: left - origin,
      alongEnd: max(right - origin, left - origin + 1),
      ascent: max(0.0, baseline - top),
      descent: max(0.0, bottom - baseline),
    ),
  );
}

/// Lays one enum into a row of [maxWidth].
@visibleForTesting
SlantedRowLayout placeSlantedRow({
  required List<SlantedInk> words,
  required double maxWidth,
  required double lineGap,
  required double touchGap,
}) {
  if (words.isEmpty) {
    return const SlantedRowLayout(lean: _leanFloor, size: Size.zero, spots: []);
  }
  final lean = _pickLean(words, maxWidth, lineGap, touchGap);
  return _layoutAt(words, lean, lineGap, touchGap);
}

/// Spreads [laid] so it meets [maxWidth]. Lean and height stay put.
@visibleForTesting
SlantedRowLayout spanSlantedRow(SlantedRowLayout laid, double maxWidth) {
  if (!maxWidth.isFinite || laid.spots.length < 2) return laid;
  final slack = maxWidth - laid.size.width;
  if (slack <= 0.5) return laid;
  final extra = slack / (laid.spots.length - 1);
  final spots = <SlantedWordSpot>[];
  for (var i = 0; i < laid.spots.length; i++) {
    final shift = extra * i;
    final spot = laid.spots[i];
    spots.add(
      SlantedWordSpot(
        box: spot.box.shift(Offset(shift, 0)),
        pivot: spot.pivot + Offset(shift, 0),
      ),
    );
  }
  return SlantedRowLayout(
    lean: laid.lean,
    size: Size(maxWidth, laid.size.height),
    spots: spots,
  );
}

/// Horizontal step from one first letter to the next.
///
/// A long word still passes over the next letter, so that letter stays
/// [lineGap] under the ink. A word that has already ended does not keep a
/// place on an imaginary line: the next letter starts [touchGap] after the
/// ink, and the step is whichever of the two is closer.
@visibleForTesting
double slantedStep(
  SlantedInk previous,
  SlantedInk next,
  double lean,
  double lineGap,
  double touchGap,
) {
  final sinLean = sin(lean);
  final cosLean = cos(lean);
  final stacked = sinLean < 1e-4
      ? double.infinity
      : (previous.descent + next.ascent + lineGap) / sinLean;
  final ended = cosLean < 1e-4
      ? double.infinity
      : (previous.alongEnd + touchGap - next.alongStart) / cosLean;
  return min(stacked, max(0.0, ended));
}

double _pickLean(
  List<SlantedInk> words,
  double maxWidth,
  double lineGap,
  double touchGap,
) {
  if (!maxWidth.isFinite) return _leanFloor;
  const steps = 32;
  var fitted = -1.0;
  var fittedAt = _leanCeil;
  var packed = double.infinity;
  var packedAt = _leanCeil;
  for (var i = 0; i <= steps; i++) {
    final lean = _leanFloor + (_leanCeil - _leanFloor) * i / steps;
    final laid = _layoutAt(words, lean, lineGap, touchGap);
    if (laid.size.width <= maxWidth) {
      fitted = i == 0
          ? _leanFloor
          : _leanFloor + (_leanCeil - _leanFloor) * (i - 1) / steps;
      fittedAt = lean;
      break;
    }
    final aspect = laid.size.height / max(laid.size.width, 1);
    if (aspect < packed) {
      packed = aspect;
      packedAt = lean;
    }
  }
  if (fitted < 0) return packedAt;
  var low = fitted;
  var high = fittedAt;
  for (var step = 0; step < 10; step++) {
    final mid = (low + high) / 2;
    if (_layoutAt(words, mid, lineGap, touchGap).size.width <= maxWidth) {
      high = mid;
    } else {
      low = mid;
    }
  }
  if (_layoutAt(words, high, lineGap, touchGap).size.width <= maxWidth) {
    return high;
  }
  return fittedAt;
}

SlantedRowLayout _layoutAt(
  List<SlantedInk> words,
  double lean,
  double lineGap,
  double touchGap,
) {
  final pivots = <Offset>[Offset.zero];
  for (var i = 1; i < words.length; i++) {
    final dx = slantedStep(words[i - 1], words[i], lean, lineGap, touchGap);
    pivots.add(Offset(pivots.last.dx + dx, 0));
  }
  final corners = <List<Offset>>[];
  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = double.negativeInfinity;
  var maxY = double.negativeInfinity;
  for (var i = 0; i < words.length; i++) {
    final points = _corners(words[i], pivots[i], lean);
    corners.add(points);
    for (final point in points) {
      minX = min(minX, point.dx);
      minY = min(minY, point.dy);
      maxX = max(maxX, point.dx);
      maxY = max(maxY, point.dy);
    }
  }
  const pad = 0.75;
  final spots = <SlantedWordSpot>[];
  for (var i = 0; i < words.length; i++) {
    var left = double.infinity;
    var top = double.infinity;
    var right = double.negativeInfinity;
    var bottom = double.negativeInfinity;
    for (final point in corners[i]) {
      left = min(left, point.dx);
      top = min(top, point.dy);
      right = max(right, point.dx);
      bottom = max(bottom, point.dy);
    }
    spots.add(
      SlantedWordSpot(
        box: Rect.fromLTRB(
          left - minX + pad,
          top - minY + pad,
          right - minX + pad,
          bottom - minY + pad,
        ),
        pivot: Offset(pivots[i].dx - minX + pad, pivots[i].dy - minY + pad),
      ),
    );
  }
  return SlantedRowLayout(
    lean: lean,
    size: Size(max(0, maxX - minX + pad * 2), max(0, maxY - minY + pad * 2)),
    spots: spots,
  );
}

List<Offset> _corners(SlantedInk ink, Offset pivot, double lean) {
  final across = cos(lean);
  final rise = sin(lean);
  final points = <Offset>[];
  for (final along in [ink.alongStart, ink.alongEnd]) {
    for (final up in [-ink.descent, ink.ascent]) {
      points.add(
        Offset(
          pivot.dx + along * across - up * rise,
          pivot.dy - along * rise - up * across,
        ),
      );
    }
  }
  return points;
}

class _SlantedGlyph extends LeafRenderObjectWidget {
  const _SlantedGlyph({
    required this.label,
    required this.style,
    required this.scaler,
    required this.matrix,
  });

  final String label;
  final TextStyle style;
  final TextScaler scaler;
  final Matrix4 matrix;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _SlantedGlyphBox(
      label: label,
      style: style,
      scaler: scaler,
      matrix: matrix,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _SlantedGlyphBox renderObject) {
    renderObject
      ..label = label
      ..style = style
      ..scaler = scaler
      ..matrix = matrix;
  }
}

class _SlantedGlyphBox extends RenderBox {
  _SlantedGlyphBox({
    required this._label,
    required this._style,
    required this._scaler,
    required this._matrix,
  }) {
    _layoutPainter();
  }

  String _label;
  TextStyle _style;
  TextScaler _scaler;
  Matrix4 _matrix;
  TextPainter? _painter;

  set label(String value) {
    if (_label == value) return;
    _label = value;
    _layoutPainter();
    markNeedsPaint();
  }

  set style(TextStyle value) {
    if (_style == value) return;
    _style = value;
    _layoutPainter();
    markNeedsPaint();
  }

  set scaler(TextScaler value) {
    if (_scaler == value) return;
    _scaler = value;
    _layoutPainter();
    markNeedsPaint();
  }

  set matrix(Matrix4 value) {
    if (_sameMatrix(_matrix, value)) return;
    _matrix = value;
    markNeedsPaint();
  }

  void _layoutPainter() {
    _painter?.dispose();
    _painter = _painterFor(_label, _style, _scaler);
  }

  @override
  void performLayout() {
    size = constraints.biggest;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    final painter = _painter;
    if (painter == null) return false;
    final inverse = Matrix4.tryInvert(Matrix4.copy(_matrix));
    if (inverse == null) return false;
    final local = MatrixUtils.transformPoint(inverse, position);
    if (!(Offset.zero & painter.size).inflate(1.5).contains(local)) {
      return false;
    }
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final painter = _painter;
    if (painter == null) return;
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.transform(_matrix.storage);
    painter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  void dispose() {
    _painter?.dispose();
    super.dispose();
  }
}

bool _sameMatrix(Matrix4 a, Matrix4 b) {
  final left = a.storage;
  final right = b.storage;
  for (var i = 0; i < 16; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}
