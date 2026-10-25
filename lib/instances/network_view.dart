import 'instance.dart';
import 'portrait.dart';

/// Sections that stay available before a target instance is chosen.
const openSections = {'people', 'peers', 'library'};

bool menuSectionEnabled(
  String id, {
  required bool hasTarget,
  bool? notifications,
  bool? grafana,
}) {
  if (openSections.contains(id)) return true;
  if (!hasTarget) return false;
  if (id == 'alerts' && notifications == false) return false;
  if (id == 'dashboards' && grafana == false) return false;
  return true;
}

class InstancePolicy {
  const InstancePolicy({this.allow = const [], this.deny = const []});

  final List<String> allow;
  final List<String> deny;

  /// An empty allow list admits every url that is not denied.
  bool admits(String url) {
    if (deny.contains(url)) return false;
    if (allow.isEmpty) return true;
    return allow.contains(url);
  }
}

class NetworkQuery {
  String text = '';
  final Set<String> trust = {...trustStatuses};

  bool matches(String url, String? trustStatus) {
    final needle = text.trim().toLowerCase();
    if (needle.isNotEmpty) {
      final host = instanceHost(url).toLowerCase();
      if (!host.contains(needle) && !url.toLowerCase().contains(needle)) {
        return false;
      }
    }
    if (trustStatus == null) return trust.contains('Trust');
    return trust.contains(trustStatus);
  }

  void toggleTrust(String status) {
    if (!trustStatuses.contains(status)) return;
    if (trust.contains(status)) {
      if (trust.length == 1) return;
      trust.remove(status);
    } else {
      trust.add(status);
    }
  }
}

/// Primary actions on the root instance card. Always fits on a single ring
/// (at most 6 cells around Back); role-specific administration and peer
/// moderation live in dedicated submenus so the card never bloats into 2 rings.
List<String> cardActions({
  required bool isTarget,
  required bool owner,
  required bool staff,
  required bool federation,
  required bool telegram,
  required String? trust,
}) {
  final actions = <String>['metrics', 'relogin'];
  actions.add(isTarget ? 'clear' : 'target');
  if (telegram) actions.add('telegram');
  if (isTarget && (owner || staff)) {
    actions.add('settings');
  } else if (!isTarget && staff && trust != null) {
    actions.add('peer');
  }
  return actions;
}

/// Moderation actions for an external peer when opened by Admin or Owner.
List<String> peerActions({
  required String? trust,
  required bool federation,
}) {
  switch (trust) {
    case 'Pending':
      return const ['trust', 'block', 'delete'];
    case 'Trust':
      return ['block', if (federation) 'scan', 'delete'];
    case 'Blocking':
      return const ['trust', 'delete'];
    default:
      return const [];
  }
}

/// Top-level items on `/peers/tune` for Owner and Admin. Always fits in 1 ring.
List<String> tuneActions({
  required bool owner,
  required bool staff,
  required bool federation,
}) {
  if (owner) {
    return const ['icon', 'ops', 'flags', 'core', 'services', 'transport'];
  }
  if (staff) {
    return ['identity', 'tests', if (federation) 'scan-all'];
  }
  return const [];
}

/// Instance operation commands inside `/peers/tune/ops` (or Admin `/peers/tune`).
List<String> operationActions({
  required bool owner,
  required bool staff,
  required bool federation,
}) {
  if (!owner && !staff) return const [];
  return [
    'tests',
    if (federation) 'scan-all',
    if (owner) 'reboot',
  ];
}

const _dirs = <(int, int)>[(1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)];

/// Center plus [rings] surrounding rings. Ring 1 has 6 cells, then 12, then 18.
List<(int, int)> hexDisk(int rings) {
  final cells = <(int, int)>[(0, 0)];
  for (var radius = 1; radius <= rings; radius++) {
    var q = _dirs[4].$1 * radius;
    var r = _dirs[4].$2 * radius;
    for (final dir in _dirs) {
      for (var step = 0; step < radius; step++) {
        cells.add((q, r));
        q += dir.$1;
        r += dir.$2;
      }
    }
  }
  return cells;
}

class BoardSlot {
  const BoardSlot(this.id, this.q, this.r, {this.url});

  final String id;
  final int q;
  final int r;
  final String? url;
}

class NetworkBoard {
  const NetworkBoard({
    required this.slots,
    required this.canZoomIn,
    required this.page,
    required this.pages,
  });

  final List<BoardSlot> slots;
  final bool canZoomIn;
  final int page;
  final int pages;
}

/// Bottom-left cell of the network menu, used by the error mark.
const networkErrorCell = (-1, 1);

/// Search at the top right, settings in the center, back at the bottom
/// right, and the current instance at the top left.
NetworkBoard networkBoard({required String? target}) {
  return NetworkBoard(
    slots: [
      const BoardSlot('settings', 0, 0),
      const BoardSlot('back', 0, 1),
      BoardSlot(target == null ? 'address' : 'target', 0, -1, url: target),
      const BoardSlot('search', 1, -1),
    ],
    canZoomIn: false,
    page: 0,
    pages: 1,
  );
}

/// Peer cards live on the search menu. The search + trust filter shares a
/// single cell at (0, -1), so peer instances are visible right on the first
/// ring even when Admin or Owner is signed in.
NetworkBoard searchBoard({
  required int scope,
  required bool staff,
  required bool scanAll,
  required List<String> urls,
  required int page,
}) {
  final rings = scope.clamp(0, 2) + 1;
  final disk = hexDisk(rings);
  final reserved = <(int, int), String>{
    (0, 0): 'back',
    (0, -1): 'text',
  };
  if (staff) reserved[(1, -1)] = 'add';
  if (scanAll) reserved[(-1, 0)] = 'scan-all';
  final free = [
    for (final cell in disk)
      if (!reserved.containsKey(cell)) cell,
  ];
  final overflow = urls.length > free.length;
  final paging = scope >= 2 && overflow && free.length >= 3;
  final room = paging ? free.sublist(0, free.length - 2) : free;
  final pages = paging && room.isNotEmpty
      ? (urls.length / room.length).ceil()
      : 1;
  final safePage = page.clamp(0, pages - 1);
  final slice = paging
      ? urls.skip(safePage * room.length).take(room.length).toList()
      : urls.take(room.length).toList();
  final slots = <BoardSlot>[
    for (final entry in reserved.entries)
      if (disk.contains(entry.key))
        BoardSlot(entry.value, entry.key.$1, entry.key.$2),
    for (var i = 0; i < slice.length; i++)
      BoardSlot('instance', room[i].$1, room[i].$2, url: slice[i]),
  ];
  if (paging) {
    slots
      ..add(
        BoardSlot('prev', free[free.length - 2].$1, free[free.length - 2].$2),
      )
      ..add(
        BoardSlot('next', free[free.length - 1].$1, free[free.length - 1].$2),
      );
  }
  return NetworkBoard(
    slots: slots,
    canZoomIn: scope < 2 && overflow,
    page: safePage,
    pages: pages,
  );
}

/// Back in the center, the rest of the disk is one url per cell.
NetworkBoard catalogBoard({
  required int scope,
  required List<String> urls,
  required int page,
}) {
  final rings = scope.clamp(0, 2) + 1;
  final disk = hexDisk(rings);
  final free = disk.skip(1).toList();
  final overflow = urls.length > free.length;
  final paging = scope >= 2 && overflow && free.length >= 3;
  final room = paging ? free.sublist(0, free.length - 2) : free;
  final pages = paging && room.isNotEmpty
      ? (urls.length / room.length).ceil()
      : 1;
  final safePage = page.clamp(0, pages - 1);
  final slice = paging
      ? urls.skip(safePage * room.length).take(room.length).toList()
      : urls.take(room.length).toList();
  final slots = <BoardSlot>[
    const BoardSlot('back', 0, 0),
    for (var i = 0; i < slice.length; i++)
      BoardSlot('url', room[i].$1, room[i].$2, url: slice[i]),
  ];
  if (paging) {
    slots
      ..add(
        BoardSlot('prev', free[free.length - 2].$1, free[free.length - 2].$2),
      )
      ..add(
        BoardSlot('next', free[free.length - 1].$1, free[free.length - 1].$2),
      );
  }
  return NetworkBoard(
    slots: slots,
    canZoomIn: scope < 2 && overflow,
    page: safePage,
    pages: pages,
  );
}

/// Single-ring layout around Back (0, 0). Anchored actions stay at fixed
/// positions so the instance card has a consistent, balanced geometry.
List<BoardSlot> cardBoard(List<String> ids) {
  const anchored = <String, (int, int)>{
    'identity': (0, -1),
    'metrics': (1, -1),
    'target': (1, 0),
    'clear': (1, 0),
    'relogin': (0, 1),
    'telegram': (-1, 1),
    'settings': (-1, 0),
    'peer': (-1, 0),
  };
  final placed = <BoardSlot>[const BoardSlot('back', 0, 0)];
  final taken = <(int, int)>{(0, 0)};
  final rest = <String>[];
  for (final id in ids) {
    final spot = anchored[id];
    if (spot != null && !taken.contains(spot)) {
      placed.add(BoardSlot(id, spot.$1, spot.$2));
      taken.add(spot);
    } else {
      rest.add(id);
    }
  }
  const ringOrder = <(int, int)>[
    (0, -1),
    (1, -1),
    (1, 0),
    (0, 1),
    (-1, 1),
    (-1, 0),
  ];
  final spots = [
    for (final cell in ringOrder)
      if (!taken.contains(cell)) cell,
  ];
  for (var i = 0; i < rest.length && i < spots.length; i++) {
    placed.add(BoardSlot(rest[i], spots[i].$1, spots[i].$2));
  }
  return placed;
}

Future<List<T>> collectPages<T>({
  required Future<({int total, List<T> items})> Function(int offset, int limit)
  fetch,
  required int limit,
}) async {
  final pageLimit = limit < 1 ? 1 : limit;
  final all = <T>[];
  var offset = 0;
  while (offset < 100000) {
    final page = await fetch(offset, pageLimit);
    all.addAll(page.items);
    offset += page.items.length;
    if (page.items.isEmpty || offset >= page.total) break;
  }
  return all;
}
