import 'dart:math';

import 'package:flutter/material.dart';

import '../../hive/hex_scene.dart';
import '../../library/screen_tree.dart';
import '../../library/tree_layout.dart';
import '../../navigation/sections.dart';
import '../units/units_chrome.dart';

/// The tree is drawn on a canvas whose shorter side is this many units, and
/// scaled to the screen. Every size below is in these units, so the picture
/// keeps its shape. The longer side follows the screen, so the branches use
/// the available width and height.
const treeBase = 1800.0;
const _outer = 760.0;

const _rootHex = 24.0;
const _sectionHex = 17.0;
const _innerHex = 13.0;
const _leafHex = 10.0;
const _cellHex = 8.0;

/// Names are drawn on the picture, in its own units, so they grow and shrink
/// with the zoom like the hexagons. Leaves use smaller captions.
const _nameBig = 20.0;
const _nameInner = 13.0;
const _nameLeaf = 10.0;

/// A name shorter than this many pixels on the screen is not drawn: it could
/// not be read. Section headings remain visible at the overview scale;
/// a picked row and its way are never smaller than [_namePicked].
const _nameLeast = 6.5;
const _namePicked = 10.0;

/// The canvas for a viewport of this shape.
Size treeCanvasFor(Size viewport) {
  final aspect = viewport.width / viewport.height;
  if (aspect.isNaN || aspect <= 0) return const Size.square(treeBase);
  final clamped = aspect.clamp(0.5, 2.5);
  return clamped >= 1
      ? Size(treeBase * clamped, treeBase)
      : Size(treeBase, treeBase / clamped);
}

/// Scale that puts the whole canvas inside [viewport].
double treeFitScale(Size viewport) {
  final canvas = treeCanvasFor(viewport);
  return min(viewport.width / canvas.width, viewport.height / canvas.height);
}

/// The transform that shows the whole canvas in the middle of [viewport].
Matrix4 treeFit(Size viewport) {
  final scale = treeFitScale(viewport);
  final canvas = treeCanvasFor(viewport);
  final dx = (viewport.width - canvas.width * scale) / 2;
  final dy = (viewport.height - canvas.height * scale) / 2;
  // The depth axis scales too, the way the viewer scales its own matrix.
  return Matrix4(scale, 0, 0, 0, 0, scale, 0, 0, 0, 0, scale, 0, dx, dy, 0, 1);
}

/// The color a row wears: the color of its tone, or of its section. The home
/// screen takes the color of the Library, the section the tool lives in.
Color treeColorOf(ScreenNode node, ScreenMap map) {
  switch (map.toneOf(node.path)) {
    case 'add':
      return addColor;
    case 'danger':
      return errorColor;
    case 'groups':
      return unitGroupsColor;
    case 'io':
      return unitIoColor;
    case 'pipe':
      return unitPipeColor;
    case 'link':
      return unitLinkColor;
    case 'access':
      return accessColor;
    case 'people':
      return peopleColor;
    case 'registry':
      return sectionById('registry')!.color;
    case 'units':
      return unitsColor;
  }
  return sectionById(node.section)?.color ?? sectionById('library')!.color;
}

double _hexOf(TreeSpot spot) {
  if (spot.node.isCell) return _cellHex;
  if (spot.depth == 0) return _rootHex;
  if (spot.depth == 1) return _sectionHex;
  return spot.isLeaf ? _leafHex : _innerHex;
}

/// Home in the middle, with compact branches around each section.
/// Wheel and pinch zoom, a drag moves, a tap picks a row.
///
/// A filled hexagon is a screen that opens from its address and may be opened
/// now; a hollow one needs a chosen record or the screen before it. A small
/// hexagon is a cell on a screen. A dim one is closed for this session. Names
/// keep the size of the text on the screen and appear where there is room, so
/// zooming in always brings more of them.
class ScreenTreeMap extends StatefulWidget {
  const ScreenTreeMap({
    required this.map,
    required this.language,
    required this.selected,
    required this.available,
    required this.onSelect,
    super.key,
  });

  final ScreenMap map;
  final String language;

  /// Address of the picked row, drawn with a white edge.
  final String? selected;

  /// Addresses of the rows this session may use.
  final Set<String> available;

  /// A tap on a row picks it; a tap on nothing picks null.
  final ValueChanged<ScreenNode?> onSelect;

  @override
  State<ScreenTreeMap> createState() => ScreenTreeMapState();
}

class ScreenTreeMapState extends State<ScreenTreeMap> {
  final controller = TransformationController();
  late List<TreeSpot> _spots = radialTree(widget.map);
  final _names = <_Label>[];
  var _points = const <String, Offset>{};
  var _canvas = Size.zero;
  var _size = Size.zero;

  @override
  void didUpdateWidget(ScreenTreeMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.map == widget.map) return;
    _spots = radialTree(widget.map);
    _names.clear();
    if (!_canvas.isEmpty) _points = _place(_canvas);
  }

  /// Shows the whole tree again.
  void fit() => controller.value = treeFit(_size);

  /// Brings the row at [path] to the middle of the viewport, zoomed in until
  /// its neighbours are told apart, and never farther out than it was.
  void focus(String path) {
    final at = _points[path];
    if (at == null || _size.isEmpty) return;
    final zoom = max(
      controller.value.getMaxScaleOnAxis(),
      treeFitScale(_size) * 5,
    );
    final dx = _size.width / 2 - at.dx * zoom;
    final dy = _size.height / 2 - at.dy * zoom;
    controller.value = Matrix4(
      zoom, 0, 0, 0, //
      0, zoom, 0, 0, //
      0, 0, zoom, 0, //
      dx, dy, 0, 1,
    );
  }

  /// Stretch the branches to use the viewport's aspect ratio.
  Map<String, Offset> _place(Size canvas) {
    final wide = canvas.width / canvas.height;
    final radiusX = _outer * (wide >= 1 ? wide : 1);
    final radiusY = _outer * (wide < 1 ? 1 / wide : 1);
    return {
      for (final spot in _spots)
        spot.node.path: () {
          final point = spot.at(radiusX, radiusY);
          return Offset(
            canvas.width / 2 + point.x,
            canvas.height / 2 + point.y,
          );
        }(),
    };
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _tap(Offset at) {
    for (final label in _names) {
      if (label.contains(at)) {
        widget.onSelect(widget.map.node(label.path)!);
        return;
      }
    }
    final zoom = controller.value.getMaxScaleOnAxis();
    TreeSpot? best;
    var bestGap = double.infinity;
    for (final spot in _spots) {
      final reach = max(_hexOf(spot) * 1.4, 14 / zoom);
      final gap = (_points[spot.node.path]! - at).distance / reach;
      if (gap <= 1 && gap < bestGap) {
        best = spot;
        bestGap = gap;
      }
    }
    widget.onSelect(best?.node);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (size != _size) {
          _size = size;
          // After the frame: the viewer listens to the controller.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _size == size) fit();
          });
        }
        final scale = treeFitScale(size);
        final canvas = treeCanvasFor(size);
        if (canvas != _canvas) {
          _canvas = canvas;
          _points = _place(canvas);
        }
        return ClipRect(
          child: InteractiveViewer(
            transformationController: controller,
            constrained: false,
            minScale: scale * 0.9,
            maxScale: scale * 24,
            boundaryMargin: const EdgeInsets.all(treeBase * 0.4),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _tap(details.localPosition),
              child: SizedBox.fromSize(
                size: canvas,
                child: CustomPaint(
                  painter: _TreePainter(
                    spots: _spots,
                    points: _points,
                    map: widget.map,
                    language: widget.language,
                    selected: widget.selected,
                    available: widget.available,
                    controller: controller,
                    fit: scale,
                    viewport: size,
                    names: _names,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A name on the picture: a box of half sides [hw] and [hh] around [at],
/// turned by [angle] radians.
class _Label {
  _Label(this.path, this.at, this.angle, this.hw, this.hh)
    : _cos = cos(angle),
      _sin = sin(angle);

  final String path;
  final Offset at;
  final double angle;
  final double hw;
  final double hh;
  final double _cos;
  final double _sin;

  /// [point] in the frame of the box: along the text and across it.
  Offset _local(Offset point) {
    final d = point - at;
    return Offset(d.dx * _cos + d.dy * _sin, -d.dx * _sin + d.dy * _cos);
  }

  bool contains(Offset point) {
    final local = _local(point);
    return local.dx.abs() <= hw && local.dy.abs() <= hh;
  }

  /// How far [point] is from the box, zero inside.
  double near(Offset point) {
    final local = _local(point);
    final dx = max(local.dx.abs() - hw, 0.0);
    final dy = max(local.dy.abs() - hh, 0.0);
    return sqrt(dx * dx + dy * dy);
  }

  /// Whether two boxes share an area: no axis of either box parts them.
  bool overlaps(_Label other) {
    final d = other.at - at;
    for (final box in [this, other]) {
      for (final axis in [
        Offset(box._cos, box._sin),
        Offset(-box._sin, box._cos),
      ]) {
        final reach = _radiusOn(axis) + other._radiusOn(axis);
        if ((d.dx * axis.dx + d.dy * axis.dy).abs() > reach) return false;
      }
    }
    return true;
  }

  /// Half the width of the box when seen along the unit [axis].
  double _radiusOn(Offset axis) =>
      hw * (axis.dx * _cos + axis.dy * _sin).abs() +
      hh * (-axis.dx * _sin + axis.dy * _cos).abs();
}

class _TreePainter extends CustomPainter {
  _TreePainter({
    required this.spots,
    required this.points,
    required this.map,
    required this.language,
    required this.selected,
    required this.available,
    required this.controller,
    required this.fit,
    required this.viewport,
    required this.names,
  }) : route = {
         if (selected != null)
           for (final node in map.trail(selected)) node.path,
       },
       super(repaint: controller);

  final List<TreeSpot> spots;
  final Map<String, Offset> points;
  final ScreenMap map;
  final String language;
  final String? selected;
  final Set<String> available;
  final TransformationController controller;
  final double fit;
  final Size viewport;

  /// The way from the home screen to the picked row.
  final Set<String> route;

  /// Where the names were drawn, for the tap to find.
  final List<_Label> names;

  static const _base = 40.0;
  static final _text = <String, TextPainter>{};

  TextPainter _name(String text, Color color) {
    return _text.putIfAbsent('${color.toARGB32()}|$text', () {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontFamily: 'OpenGost Type B',
            fontSize: _base,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
    });
  }

  Path _hex(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = -pi / 2 + i * pi / 3;
      final point = center + Offset(cos(angle), sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  /// Unavailable rows stay on the map, dimmed, with their details accessible.
  double _strength(String path) => available.contains(path) ? 1 : 0.45;

  @override
  void paint(Canvas canvas, Size size) {
    final matrix = controller.value;
    final zoom = matrix.getMaxScaleOnAxis();
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final spot in spots) {
      final parent = map.parentPath(spot.node.path);
      if (parent == null) continue;
      final strength = min(_strength(spot.node.path), _strength(parent));
      edge.color = treeColorOf(
        spot.node,
        map,
      ).withValues(alpha: 0.5 * strength);
      canvas.drawLine(points[parent]!, points[spot.node.path]!, edge);
    }
    if (route.length > 1) {
      final way = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFFFFF);
      for (final path in route) {
        final parent = map.parentPath(path);
        if (parent == null) continue;
        canvas.drawLine(points[parent]!, points[path]!, way);
      }
    }
    for (final spot in spots) {
      final node = spot.node;
      final center = points[node.path]!;
      final radius = _hexOf(spot);
      final strength = _strength(node.path);
      final color = treeColorOf(node, map);
      final path = _hex(center, radius);
      canvas.drawPath(path, Paint()..color = hexFill);
      if (node.open && available.contains(node.path)) {
        canvas.drawPath(
          path,
          Paint()..color = color.withValues(alpha: 0.4 * strength),
        );
      }
      final picked = node.path == selected;
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = picked ? 4 : (node.isCell ? 2 : 3)
          ..color = picked
              ? const Color(0xFFFFFFFF)
              : color.withValues(alpha: strength),
      );
    }
    _paintNames(canvas, matrix, zoom);
  }

  /// Names along the radius, in the units of the picture, so they grow and
  /// shrink with the zoom like the hexagons. A name starts at its hexagon and
  /// runs outward, away from the home screen, and turns over on the left half
  /// so it is never upside down. The rows
  /// nearer the middle are named first; a name too small to read, or one that
  /// would lie on another name or on a hexagon, waits for a deeper zoom. The
  /// picked row and its way are always named. The home screen is named below
  /// itself, level.
  void _paintNames(Canvas canvas, Matrix4 matrix, double zoom) {
    names.clear();
    final inverse = Matrix4.copy(matrix);
    if (inverse.invert() == 0) return;
    final seen = MatrixUtils.transformRect(
      inverse,
      Offset.zero & viewport,
    ).inflate(max(60 / zoom, 160));
    final inView = [
      for (final spot in spots)
        if (seen.contains(points[spot.node.path]!))
          spot,
    ];
    final circles = [
      for (final spot in inView) (points[spot.node.path]!, _hexOf(spot)),
    ];
    final order = [...inView]
      ..sort((a, b) {
        int rank(TreeSpot spot) => spot.node.path == selected
            ? 0
            : route.contains(spot.node.path)
            ? 1
            : 2;
        final pickedA = rank(a);
        final pickedB = rank(b);
        if (pickedA != pickedB) return pickedA - pickedB;
        return a.depth - b.depth;
      });
    final middle = points[screenRoot]!;
    final placed = <_Label>[];
    const gap = 5.0;
    for (final spot in order) {
      final node = spot.node;
      final center = points[node.path]!;
      final radius = _hexOf(spot);
      final base = spot.depth <= 1
          ? _nameBig
          : spot.isLeaf
          ? _nameLeaf
          : _nameInner;
      final heading = spot.depth <= 1;
      final strong = heading || node.path == selected || route.contains(node.path);
      // A name too small to read waits for a deeper zoom, except the way.
      if (!strong && base * zoom < _nameLeast) continue;
      final units = strong
          ? max(base, (heading ? 12 : _namePicked) / zoom)
          : base;
      final text = _name(
        node.title(language),
        available.contains(node.path)
            ? const Color(0xFFFFFFFF)
            : const Color(0xFFA1A1AA),
      );
      final k = units / _base;
      final width = text.width * k;
      final height = text.height * k;
      final Offset at;
      final double angle;
      if (spot.depth == 0) {
        at = center + Offset(0, radius + gap + height / 2);
        angle = 0;
      } else {
        // The way out is the line from the middle through the row, so an oval
        // picture keeps its names on its rays.
        final out = center - middle;
        final ray = out.distance == 0 ? 0.0 : atan2(out.dy, out.dx);
        final reach = radius + gap + width / 2;
        at = center + Offset(cos(ray), sin(ray)) * reach;
        angle = ray;
      }
      final label = _Label(
        node.path,
        at,
        angle,
        width / 2 + gap / 2,
        height / 2 + gap / 2,
      );
      var free = true;
      for (final other in placed) {
        if (label.overlaps(other)) {
          free = false;
          break;
        }
      }
      if (free) {
        for (final (circle, size) in circles) {
          if (circle == center) continue;
          if (label.near(circle) < size) {
            free = false;
            break;
          }
        }
      }
      if (!free) continue;
      placed.add(label);
      names.add(label);
      // Text reads left to right: a name on the left half turns over.
      final flip = cos(angle) < 0;
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(flip ? angle + pi : angle);
      canvas.scale(k);
      text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_TreePainter old) =>
      old.selected != selected ||
      old.language != language ||
      old.fit != fit ||
      !identical(old.available, available) ||
      old.viewport != viewport ||
      old.points != points ||
      old.map != map;
}
