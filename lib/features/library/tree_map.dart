import 'dart:math';

import 'package:flutter/material.dart';

import '../../hive/hex_scene.dart';
import '../../library/screen_tree.dart';
import '../../library/tree_layout.dart';
import '../../navigation/sections.dart';
import '../units/units_chrome.dart';

/// The tree is drawn on a canvas whose shorter side is this many units, and
/// scaled to the screen. Every size below is in these units, so the picture
/// keeps its shape. The longer side follows the screen: the rings of a wide
/// screen are ovals, so the tree uses the width and not only the height.
const treeBase = 1800.0;
const _outer = 760.0;

const _rootHex = 24.0;
const _sectionHex = 17.0;
const _innerHex = 13.0;
const _leafHex = 10.0;
const _cellHex = 8.0;

/// Names stay this tall on the screen, whatever the zoom, in pixels.
const _nameBig = 14.0;
const _nameSmall = 12.0;

/// Which rows the picture shows at full strength.
enum TreeShow { all, yes, no }

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

/// The whole tree on one round picture: the home screen in the middle, the
/// sections around it, and every screen and cell further out along its
/// branch. Wheel and pinch zoom, a drag moves, a tap picks a row.
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
    required this.show,
    required this.onSelect,
    super.key,
  });

  final ScreenMap map;
  final String language;

  /// Address of the picked row, drawn with a white edge.
  final String? selected;

  /// Addresses of the rows this session may use.
  final Set<String> available;
  final TreeShow show;
  final ValueChanged<ScreenNode> onSelect;

  @override
  State<ScreenTreeMap> createState() => ScreenTreeMapState();
}

class ScreenTreeMapState extends State<ScreenTreeMap> {
  final controller = TransformationController();
  late final List<TreeSpot> _spots = radialTree(widget.map);
  final _names = <(Rect, String)>[];
  var _points = const <String, Offset>{};
  var _canvas = Size.zero;
  var _size = Size.zero;

  /// Shows the whole tree again.
  void fit() => controller.value = treeFit(_size);

  /// The spots on a canvas of this shape: the outer ring is an oval on a
  /// screen that is not square.
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
    for (final (rect, path) in _names) {
      if (rect.contains(at)) {
        widget.onSelect(widget.map.node(path)!);
        return;
      }
    }
    final zoom = controller.value.getMaxScaleOnAxis();
    TreeSpot? best;
    var bestGap = double.infinity;
    for (final spot in _spots) {
      if (_faded(spot.node.path)) continue;
      final reach = max(_hexOf(spot) * 1.4, 14 / zoom);
      final gap = (_points[spot.node.path]! - at).distance / reach;
      if (gap <= 1 && gap < bestGap) {
        best = spot;
        bestGap = gap;
      }
    }
    if (best != null) widget.onSelect(best.node);
  }

  bool _faded(String path) => _fadedIn(widget.show, widget.available, path);

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
                    show: widget.show,
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

bool _fadedIn(TreeShow show, Set<String> available, String path) {
  switch (show) {
    case TreeShow.all:
      return false;
    case TreeShow.yes:
      return !available.contains(path);
    case TreeShow.no:
      return available.contains(path);
  }
}

class _TreePainter extends CustomPainter {
  _TreePainter({
    required this.spots,
    required this.points,
    required this.map,
    required this.language,
    required this.selected,
    required this.available,
    required this.show,
    required this.controller,
    required this.fit,
    required this.viewport,
    required this.names,
  }) : super(repaint: controller);

  final List<TreeSpot> spots;
  final Map<String, Offset> points;
  final ScreenMap map;
  final String language;
  final String? selected;
  final Set<String> available;
  final TreeShow show;
  final TransformationController controller;
  final double fit;
  final Size viewport;

  /// Where the names were drawn, for the tap to find.
  final List<(Rect, String)> names;

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

  /// How strong a row is drawn: closed rows are dim, and the rows the switch
  /// leaves out fade almost to nothing.
  double _strength(String path) {
    if (_fadedIn(show, available, path)) return 0.1;
    return available.contains(path) ? 1 : 0.45;
  }

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

  /// Names, horizontal, at the size of the text on the screen. The rows nearer
  /// the middle are named first, and a name that would lie on another name or
  /// on a hexagon is left for a deeper zoom.
  void _paintNames(Canvas canvas, Matrix4 matrix, double zoom) {
    names.clear();
    final inverse = Matrix4.copy(matrix);
    if (inverse.invert() == 0) return;
    final seen = MatrixUtils.transformRect(
      inverse,
      Offset.zero & viewport,
    ).inflate(60 / zoom);
    final inView = [
      for (final spot in spots)
        if (seen.contains(points[spot.node.path]!) &&
            _strength(spot.node.path) > 0.1)
          spot,
    ];
    final circles = [
      for (final spot in inView) (points[spot.node.path]!, _hexOf(spot)),
    ];
    final order = [...inView]
      ..sort((a, b) {
        final pickedA = a.node.path == selected ? 0 : 1;
        final pickedB = b.node.path == selected ? 0 : 1;
        if (pickedA != pickedB) return pickedA - pickedB;
        return a.depth - b.depth;
      });
    final middle = points[screenRoot]!.dx;
    final placed = <Rect>[];
    final gap = 4 / zoom;
    for (final spot in order) {
      final node = spot.node;
      final center = points[node.path]!;
      final radius = _hexOf(spot);
      final px = spot.depth <= 1 ? _nameBig : _nameSmall;
      final text = _name(
        node.title(language),
        available.contains(node.path)
            ? const Color(0xFFFFFFFF)
            : const Color(0xFFA1A1AA),
      );
      final k = px / zoom / _base;
      final width = text.width * k;
      final height = text.height * k;
      final right = spot.depth == 0 || center.dx >= middle;
      final left = spot.depth == 0
          ? center.dx - width / 2
          : right
          ? center.dx + radius + gap
          : center.dx - radius - gap - width;
      final top = spot.depth == 0
          ? center.dy + radius + gap
          : center.dy - height / 2;
      final rect = Rect.fromLTWH(left, top, width, height);
      final room = rect.inflate(gap / 2);
      var free = true;
      for (final other in placed) {
        if (room.overlaps(other)) {
          free = false;
          break;
        }
      }
      if (free) {
        for (final (at, size) in circles) {
          if (at == center) continue;
          final nearX = at.dx.clamp(room.left, room.right);
          final nearY = at.dy.clamp(room.top, room.bottom);
          if ((Offset(nearX, nearY) - at).distance < size) {
            free = false;
            break;
          }
        }
      }
      if (!free) continue;
      placed.add(rect);
      names.add((rect, node.path));
      canvas.save();
      canvas.translate(rect.left, rect.top);
      canvas.scale(k);
      text.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_TreePainter old) =>
      old.selected != selected ||
      old.language != language ||
      old.fit != fit ||
      old.show != show ||
      !identical(old.available, available) ||
      old.viewport != viewport ||
      old.points != points ||
      old.map != map;
}
