import '../instances/network_view.dart';
import 'unit.dart';

/// Search of `GET /units`. Own units stay on until the person switches to all.
class UnitQuery {
  String text = '';
  final Set<String> visibility = {...unitVisibilities};
  final Set<String> autos = {'on', 'off'};

  /// `mine` sends `creator_uuid`. `all` leaves it off.
  String owner = 'mine';
  String order = 'asc';

  /// Null when every visibility stays on.
  List<String>? get visibilityFilter {
    if (visibility.length >= unitVisibilities.length) return null;
    return [
      for (final item in unitVisibilities)
        if (visibility.contains(item)) item,
    ];
  }

  /// Null when both auto states stay on.
  bool? get autoOnly {
    final on = autos.contains('on');
    final off = autos.contains('off');
    if (on == off) return null;
    return on;
  }

  bool toggleVisibility(String value) {
    if (!unitVisibilities.contains(value)) return false;
    if (visibility.contains(value)) {
      if (visibility.length == 1) return false;
      visibility.remove(value);
    } else {
      visibility.add(value);
    }
    return true;
  }

  bool toggleAuto(String value) {
    if (value != 'on' && value != 'off') return false;
    if (autos.contains(value)) {
      if (autos.length == 1) return false;
      autos.remove(value);
    } else {
      autos.add(value);
    }
    return true;
  }

  bool setOwner(String value) {
    if ((value != 'mine' && value != 'all') || value == owner) return false;
    owner = value;
    return true;
  }

  bool setOrder(String value) {
    if (!takeSort(order, value)) return false;
    order = value;
    return true;
  }
}

/// Cards beside Back, the filter and the page window.
int headPageLimit(int tick, {int head = 2}) =>
    scaleTickCells(tick.clamp(scaleTickMin, scaleTickMax)) - 1 - head;

/// A zoomable list grows only while the next tick still shows another cell.
bool listCanZoom({required int tick, required int total, required int room}) {
  if (tick >= scaleTickMax) return false;
  return total > room;
}

/// Add, search and groups around Back. The menu stays on tick 1.
NetworkBoard unitsMenuBoard({bool wide = false}) {
  const ids = ['add', 'search', 'groups'];
  final frame = hexFrame(count: ids.length, back: HexBack.center, wide: wide);
  final back = frame.back!;
  return NetworkBoard(
    slots: [
      BoardSlot('back', back.$1, back.$2),
      for (var i = 0; i < ids.length; i++)
        BoardSlot(ids[i], frame.cells[i].$1, frame.cells[i].$2),
    ],
    canZoomIn: false,
    page: 0,
    pages: 1,
  );
}

/// Cells ahead of the unit cards: search, the owner and auto enums, the page.
const unitsHead = 3;

/// Search, show, page window and unit cards around Back.
NetworkBoard unitsBoard({
  required int tick,
  required List<String> uuids,
  bool wide = false,
}) {
  final step = tick.clamp(scaleTickMin, scaleTickMax);
  const head = ['query', 'filter', 'window'];
  final ids = <String>[...head, for (final uuid in uuids) 'unit:$uuid'];
  final frame = hexFrame(
    count: ids.length,
    back: HexBack.center,
    wide: wide,
    cells: scaleTickCells(step),
  );
  final back = frame.back!;
  return NetworkBoard(
    slots: [
      BoardSlot('back', back.$1, back.$2),
      for (var i = 0; i < ids.length && i < frame.cells.length; i++)
        BoardSlot(ids[i], frame.cells[i].$1, frame.cells[i].$2),
    ],
    canZoomIn: step < scaleTickMax,
    page: 0,
    pages: 1,
  );
}

NetworkBoard headBoard({
  required int tick,
  required List<String> head,
  required List<String> ids,
  required String prefix,
  required int total,
  bool wide = false,
}) {
  final step = tick.clamp(scaleTickMin, scaleTickMax);
  final names = <String>[...head, for (final id in ids) '$prefix$id'];
  final frame = hexFrame(
    count: names.length,
    back: HexBack.center,
    wide: wide,
    cells: scaleTickCells(step),
  );
  final back = frame.back!;
  final room = scaleTickCells(step) - 1 - head.length;
  return NetworkBoard(
    slots: [
      BoardSlot('back', back.$1, back.$2),
      for (var i = 0; i < names.length && i < frame.cells.length; i++)
        BoardSlot(names[i], frame.cells[i].$1, frame.cells[i].$2),
    ],
    canZoomIn: listCanZoom(tick: step, total: total, room: room),
    page: 0,
    pages: 1,
  );
}

/// One cell per id. Tick 1 is the short list. The last tick pages the tail.
NetworkBoard tailBoard({
  required int tick,
  required int page,
  required List<String> ids,
  List<String> head = const [],
  bool wide = false,
}) {
  final step = tick.clamp(scaleTickMin, scaleTickMax);
  final free = scaleTickCells(step) - 1 - head.length;
  final overflow = ids.length > free;
  final paging = step >= scaleTickMax && overflow && free >= 3;
  final room = free - (paging ? 2 : 0);
  final pages = paging && room > 0 ? (ids.length / room).ceil() : 1;
  final safePage = page.clamp(0, pages - 1);
  final slice = paging
      ? ids.skip(safePage * room).take(room).toList()
      : ids.take(room).toList();
  final frame = hexFrame(
    count: head.length + slice.length,
    back: HexBack.center,
    wide: wide,
    cells: scaleTickCells(step),
    tail: paging ? 2 : 0,
  );
  final back = frame.back!;
  return NetworkBoard(
    slots: [
      BoardSlot('back', back.$1, back.$2),
      for (var i = 0; i < head.length && i < frame.cells.length; i++)
        BoardSlot(head[i], frame.cells[i].$1, frame.cells[i].$2),
      for (var i = 0; i < slice.length; i++)
        BoardSlot(
          slice[i],
          frame.cells[head.length + i].$1,
          frame.cells[head.length + i].$2,
        ),
      if (frame.tail.length == 2) ...[
        BoardSlot('prev', frame.tail[0].$1, frame.tail[0].$2),
        BoardSlot('next', frame.tail[1].$1, frame.tail[1].$2),
      ],
    ],
    canZoomIn: step < scaleTickMax && overflow,
    page: safePage,
    pages: pages,
  );
}

/// Creator sees the card, the info, settings, device control, the nodes and
/// the environment, and for a private unit the access grants. A guest sees
/// the card, the info and the nodes.
List<String> unitMenuIds({required bool owned, bool private = false}) {
  return [
    'card',
    'info',
    if (owned) 'settings',
    if (owned) 'operate',
    'nodes',
    if (owned) 'env',
    if (owned && private) 'access',
  ];
}

const unitOperateIds = ['commands', 'logs', 'archives', 'state', 'delete'];

List<String> ioMenuIds({
  required bool owned,
  required bool input,
  required bool private,
  required bool datapipe,
}) {
  return [
    'card',
    'value',
    if (owned) 'settings',
    if (owned && datapipe) 'pipe',
    if (input) 'links',
    if (owned && private) 'access',
  ];
}

const pipeMenuIds = [
  'editor',
  'check',
  'save',
  'export',
  'import',
  'data',
  'csvOut',
  'csvIn',
  'clear',
];
