import 'dart:math';
import 'dart:typed_data';

import 'screen_tree.dart';

/// Where one row stands in the compact branch layout.
class TreeSpot {
  const TreeSpot(
    this.node,
    this.depth,
    this.angle,
    this.ring, {
    required this.isLeaf,
  });

  final ScreenNode node;

  /// Steps from the home screen. The home screen is 0.
  final int depth;

  /// Radians, clockwise from the top.
  final double angle;

  /// Distance from the home screen, normalized to the farthest node.
  final double ring;

  final bool isLeaf;

  /// The point of the spot on a picture whose outer ring is [radiusX] wide
  /// and [radiusY] high, from the middle.
  Point<double> at(double radiusX, double radiusY) =>
      Point(sin(angle) * ring * radiusX, -cos(angle) * ring * radiusY);
}

final _layouts = Expando<List<TreeSpot>>();

/// Stable branches around Home, with short links and space between neighbours.
/// Sections start in menu order. Springs pull children toward their parent;
/// local repulsion opens dense branches without pushing every leaf to a rim.
/// Computed once per map, never during pan, zoom, search or filtering.
List<TreeSpot> radialTree(ScreenMap map) =>
    _layouts[map] ??= _branchLayout(map);

List<TreeSpot> _branchLayout(ScreenMap map) {
  final mass = <String, int>{};
  int measure(ScreenNode node) => mass[node.path] =
      1 +
      map.childrenOf(node.path).fold(0, (sum, child) => sum + measure(child));
  measure(map.root);

  final nodes = <ScreenNode>[];
  final depths = <int>[];
  final parents = <int>[];
  final points = <Point<double>>[];
  void seed(
    ScreenNode node,
    int parent,
    int depth,
    double start,
    double sweep,
  ) {
    final index = nodes.length;
    final angle = start + sweep / 2;
    final length = depth == 1 ? 190.0 : 55 + sqrt(mass[node.path]!) * 12;
    final origin = parent < 0 ? const Point(0.0, 0.0) : points[parent];
    nodes.add(node);
    parents.add(parent);
    depths.add(depth);
    points.add(
      parent < 0 ? origin : origin + Point(sin(angle), -cos(angle)) * length,
    );
    final children = map.childrenOf(node.path);
    final weights = [for (final child in children) sqrt(mass[child.path]!)];
    final total = weights.fold(0.0, (sum, weight) => sum + weight);
    var cursor = start;
    for (var i = 0; i < children.length; i++) {
      final arc = sweep * weights[i] / total;
      seed(children[i], index, depth + 1, cursor, arc);
      cursor += arc;
    }
  }

  seed(map.root, -1, 0, 0, 2 * pi);
  final anchors = List<Point<double>>.of(points);
  final count = nodes.length;
  final x = Float64List.fromList([for (final point in points) point.x]);
  final y = Float64List.fromList([for (final point in points) point.y]);
  final fx = Float64List(count);
  final fy = Float64List(count);
  for (var pass = 0; pass < 280; pass++) {
    fx.fillRange(0, count, 0);
    fy.fillRange(0, count, 0);
    for (var i = 0; i < count; i++) {
      for (var j = i + 1; j < count; j++) {
        var dx = x[i] - x[j];
        var dy = y[i] - y[j];
        final squared = dx * dx + dy * dy;
        if (squared >= 180 * 180) continue;
        var distance = sqrt(squared);
        if (distance < 0.01) {
          final angle = (i + j) * 2.3999632297;
          dx = cos(angle);
          dy = sin(angle);
          distance = 1;
        }
        final push =
            (12000 / (distance * distance) - 12000 / (180 * 180)) / distance;
        fx[i] += dx * push;
        fy[i] += dy * push;
        fx[j] -= dx * push;
        fy[j] -= dy * push;
      }
    }
    for (var i = 1; i < count; i++) {
      final parent = parents[i];
      final dx = x[parent] - x[i];
      final dy = y[parent] - y[i];
      final distance = max(sqrt(dx * dx + dy * dy), 0.01);
      final length = nodes[i].isCell
          ? 42.0
          : 65 + sqrt(mass[nodes[i].path]!) * 5;
      final pull = 0.12 * (distance - length) / distance;
      fx[i] += dx * pull;
      fy[i] += dy * pull;
      fx[parent] -= dx * pull;
      fy[parent] -= dy * pull;
    }
    final step = 8 * (1 - pass / 320);
    for (var i = 1; i < count; i++) {
      // Keep section headings in menu order and prevent whole branches drifting.
      final anchor = depths[i] == 1 ? 0.35 : 0.008;
      final dx = fx[i] + (anchors[i].x - x[i]) * anchor;
      final dy = fy[i] + (anchors[i].y - y[i]) * anchor;
      final pace = min(0.7, step / max(sqrt(dx * dx + dy * dy), 0.01));
      x[i] += dx * pace;
      y[i] += dy * pace;
    }
  }
  for (var i = 0; i < count; i++) {
    points[i] = Point(x[i], y[i]);
  }
  final extent = points.fold(
    1.0,
    (radius, point) => max(radius, point.magnitude),
  );
  return List.unmodifiable([
    for (var i = 0; i < count; i++)
      TreeSpot(
        nodes[i],
        depths[i],
        (atan2(points[i].x, -points[i].y) + 2 * pi) % (2 * pi),
        points[i].magnitude / extent,
        isLeaf: map.childrenOf(nodes[i].path).isEmpty,
      ),
  ]);
}

/// The tree as an indented list, one row a line with its address.
String treeOutline(String language, ScreenMap map) {
  final lines = <String>[];
  void walk(ScreenNode node, int depth) {
    lines.add('${'  ' * depth}- ${node.title(language)} `${node.path}`');
    for (final kid in map.childrenOf(node.path)) {
      walk(kid, depth + 1);
    }
  }

  walk(map.root, 0);
  return lines.join('\n');
}
