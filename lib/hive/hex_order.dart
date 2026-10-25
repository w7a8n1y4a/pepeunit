import 'dart:math';
import 'dart:ui' show Size;

const _dirs = <(int, int)>[(1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)];

/// True when the screen is wider than it is tall. A square is tall.
bool hexWide(Size size) => size.width > size.height;

/// Cells in appearance order: the center, then each full ring.
///
/// A tall screen fills a ring from the top (120° toward 60°), then the bottom
/// (300° toward 240°), then the left side, then the right side through 0°.
/// A wide screen uses the same arcs in the order left, right, top, bottom.
/// From the third ring, a slot is the lattice cell closest to that angle.
List<(int, int)> hexDisk(int rings, {bool wide = false}) {
  final cells = <(int, int)>[(0, 0)];
  for (var radius = 1; radius <= rings; radius++) {
    cells.addAll(_ring(radius, wide: wide));
  }
  return cells;
}

/// The first [count] cells in appearance order that are not [reserved].
List<(int, int)> hexSlots(
  int count, {
  Iterable<(int, int)> reserved = const [],
  bool wide = false,
}) {
  if (count < 1) return const [];
  final used = reserved.toSet();
  final slots = <(int, int)>[];
  for (final cell in hexDisk(8, wide: wide)) {
    if (used.contains(cell)) continue;
    slots.add(cell);
    if (slots.length == count) break;
  }
  return slots;
}

/// The next free cell in appearance order.
(int, int) nextHex(Iterable<(int, int)> taken, {bool wide = false}) {
  final slot = hexSlots(1, reserved: taken, wide: wide);
  return slot.isEmpty ? (0, 0) : slot.first;
}

/// Where Back sits. Every screen that has Back keeps it in the center.
enum HexBack { none, center }

(int, int)? hexBackCell(HexBack back) {
  switch (back) {
    case HexBack.none:
      return null;
    case HexBack.center:
      return (0, 0);
  }
}

class HexFrame {
  const HexFrame({required this.cells, this.back, this.tail = const []});

  /// Content cells, in the order the screen listed them.
  final List<(int, int)> cells;

  final (int, int)? back;

  /// Pager cells, last free slots of a fixed disk.
  final List<(int, int)> tail;
}

/// Places [count] content cells after reserving Back.
///
/// [rings] above zero clips the cluster to that disk and, when [tail] is
/// positive, keeps the last free slots for a pager. Otherwise the cluster grows.
HexFrame hexFrame({
  required int count,
  HexBack back = HexBack.none,
  bool wide = false,
  int rings = 0,
  int tail = 0,
}) {
  final backCell = hexBackCell(back);
  if (rings <= 0) {
    return HexFrame(
      cells: hexSlots(count, reserved: [?backCell], wide: wide),
      back: backCell,
    );
  }
  final free = [
    for (final cell in hexDisk(rings, wide: wide))
      if (cell != backCell) cell,
  ];
  final tailCount = tail > 0 && free.length >= tail ? tail : 0;
  final room = tailCount == 0 ? free : free.sublist(0, free.length - tailCount);
  final n = count < room.length ? count : room.length;
  return HexFrame(
    cells: room.take(n).toList(),
    back: backCell,
    tail: tailCount == 0 ? const [] : free.sublist(free.length - tailCount),
  );
}

class _Spoke {
  const _Spoke(this.angle, this.cell);

  final double angle;
  final (int, int) cell;
}

List<(int, int)> _ring(int radius, {required bool wide}) {
  final cells = <(int, int)>[];
  var q = -radius;
  var r = radius;
  for (final dir in _dirs) {
    for (var step = 0; step < radius; step++) {
      cells.add((q, r));
      q += dir.$1;
      r += dir.$2;
    }
  }
  final used = <int>{};
  final spokes = <_Spoke>[];
  for (var k = 0; k < cells.length; k++) {
    final nominal = k * 60 / radius;
    var best = 0;
    var bestTurn = double.infinity;
    for (var i = 0; i < cells.length; i++) {
      if (used.contains(i)) continue;
      final cell = cells[i];
      final turn = _turn(_angle(cell.$1, cell.$2), nominal);
      if (turn < bestTurn) {
        bestTurn = turn;
        best = i;
      }
    }
    used.add(best);
    spokes.add(_Spoke(nominal, cells[best]));
  }
  final top = <_Spoke>[];
  final bottom = <_Spoke>[];
  final left = <_Spoke>[];
  final right = <_Spoke>[];
  for (final spoke in spokes) {
    final angle = spoke.angle;
    if (angle >= 60 && angle <= 120) {
      top.add(spoke);
    } else if (angle >= 240 && angle <= 300) {
      bottom.add(spoke);
    } else if (angle > 120 && angle < 240) {
      left.add(spoke);
    } else {
      right.add(spoke);
    }
  }
  top.sort((a, b) => b.angle.compareTo(a.angle));
  bottom.sort((a, b) => b.angle.compareTo(a.angle));
  left.sort((a, b) => a.angle.compareTo(b.angle));
  right.sort((a, b) => _fromSixty(a.angle).compareTo(_fromSixty(b.angle)));
  final arcs = wide ? [left, right, top, bottom] : [top, bottom, left, right];
  return [
    for (final arc in arcs)
      for (final spoke in arc) spoke.cell,
  ];
}

double _angle(int q, int r) {
  final x = sqrt(3) * (q + r / 2);
  final y = -1.5 * r;
  var degrees = atan2(y, x) * 180 / pi;
  if (degrees < 0) degrees += 360;
  if (degrees >= 360 - 1e-8) return 0;
  return degrees;
}

double _turn(double a, double b) {
  final delta = (a - b).abs() % 360;
  return delta > 180 ? 360 - delta : delta;
}

/// How far [angle] sits along the short arc from 60° through 0° toward 300°.
double _fromSixty(double angle) {
  if (angle <= 60) return 60 - angle;
  return 60 + (360 - angle);
}
