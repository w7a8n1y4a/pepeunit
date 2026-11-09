import 'dart:math';

import 'screen_tree.dart';

/// Where one row of the tree stands on the round picture.
class TreeSpot {
  const TreeSpot(this.node, this.depth, this.angle, this.ring);

  final ScreenNode node;

  /// Steps from the home screen. The home screen is 0.
  final int depth;

  /// Radians, clockwise from the top.
  final double angle;

  /// Distance from the middle as a part of the outer ring, 0 to 1. A row with
  /// nothing under it stands on the outer ring, so the last rows are spread
  /// evenly on one circle and none is squeezed.
  final double ring;

  bool get isLeaf => ring >= 1;

  /// The point of the spot on a picture whose outer ring is [radiusX] wide
  /// and [radiusY] high, from the middle.
  Point<double> at(double radiusX, double radiusY) =>
      Point(sin(angle) * ring * radiusX, -cos(angle) * ring * radiusY);
}

/// How many empty slots stand between two sections on the outer ring.
const _sectionGap = 2;

/// Lays the whole tree on rings around the home screen.
///
/// Every row that has nothing under it takes one slot on the outer ring, in
/// the order of the tree; a gap of [_sectionGap] slots parts the sections.
/// A row with children stands in the middle of their arc, on the ring of its
/// depth. The spots come parent first, in the order of
/// [ScreenMap.childrenOf].
List<TreeSpot> radialTree(ScreenMap map) {
  // The deepest row that has children: the rings are spread up to it.
  var deepest = 0;
  void measure(ScreenNode node, int depth) {
    final kids = map.childrenOf(node.path);
    if (kids.isEmpty) return;
    deepest = max(deepest, depth);
    for (final kid in kids) {
      measure(kid, depth + 1);
    }
  }

  measure(map.root, 0);

  var slots = 0;
  void count(ScreenNode node, int depth) {
    final kids = map.childrenOf(node.path);
    if (kids.isEmpty) {
      slots++;
      return;
    }
    for (var i = 0; i < kids.length; i++) {
      if (depth == 0 && i > 0) slots += _sectionGap;
      count(kids[i], depth + 1);
    }
  }

  count(map.root, 0);

  final spots = <TreeSpot>[];
  var slot = 0;
  double angleOf(int at) => 2 * pi * (at + 0.5) / slots;

  /// Places [node] and returns the angles of its first and last last-row.
  (double, double) place(ScreenNode node, int depth) {
    final kids = map.childrenOf(node.path);
    final index = spots.length;
    // Reserved now, so a parent comes before its children.
    spots.add(TreeSpot(node, depth, 0, 0));
    if (kids.isEmpty) {
      final angle = angleOf(slot++);
      spots[index] = TreeSpot(node, depth, angle, 1);
      return (angle, angle);
    }
    double? first;
    double? last;
    for (var i = 0; i < kids.length; i++) {
      if (depth == 0 && i > 0) slot += _sectionGap;
      final span = place(kids[i], depth + 1);
      first ??= span.$1;
      last = span.$2;
    }
    final angle = (first! + last!) / 2;
    spots[index] = TreeSpot(
      node,
      depth,
      angle,
      depth == 0 ? 0 : depth / (deepest + 1),
    );
    return (first, last);
  }

  place(map.root, 0);
  return spots;
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
