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
}) => listBoard(
  tick: tick,
  head: const ['query', 'filter', 'window'],
  ids: uuids,
  prefix: 'unit:',
  wide: wide,
);

/// One cell per id. Tick 1 is the short list. The last tick pages the tail.
NetworkBoard tailBoard({
  required int tick,
  required int page,
  required List<String> ids,
  List<String> head = const [],
  bool wide = false,
}) => pagedBoard<String>(
  tick: tick,
  page: page,
  items: ids,
  head: head,
  slot: (id, _, at) => BoardSlot(id, at.$1, at.$2),
  wide: wide,
);

/// Creator sees the card, the info, settings, device control, the nodes and
/// the environment, and for a private unit the access grants. Everyone sees
/// the parent repository; a guest also sees the card, the info and the nodes.
List<String> unitMenuIds({required bool owned, bool private = false}) {
  return [
    'card',
    'info',
    if (owned) 'settings',
    if (owned) 'operate',
    'nodes',
    if (owned) 'env',
    'repo',
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
