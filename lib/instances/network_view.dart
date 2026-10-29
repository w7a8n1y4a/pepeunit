import '../hive/hex_order.dart';
import 'instance.dart';
import 'portrait.dart';

export '../hive/hex_order.dart'
    show
        HexBack,
        HexFrame,
        errorBudget,
        hexBackCell,
        hexBudget,
        hexDisk,
        hexFrame,
        hexSlots,
        hexWide,
        menuScaleTick,
        nextHex,
        scaleTickCells,
        scaleTickForCount,
        scaleTickMax,
        scaleTickMin,
        searchScaleTick;

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

  /// Blocked peers stay hidden until an Admin or Owner turns that status on.
  final Set<String> trust = {
    for (final status in trustStatuses)
      if (status != 'Blocking') status,
  };

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

/// `GET /users` is any signed-in user. Owner and Admin are signed in too.
const userRoles = ['User', 'Admin', 'Owner'];
const userStatuses = ['Active', 'Blocked'];

/// Filters for the instance directory. Newest accounts stay first so they
/// land closer to the center.
class UserQuery {
  String text = '';
  final Set<String> roles = {'User', 'Admin', 'Owner'};
  final Set<String> statuses = {'Active'};
  String order = 'desc';

  bool toggleRole(String role) => _toggle(roles, userRoles, role);

  bool toggleStatus(String status) => _toggle(statuses, userStatuses, status);

  bool setOrder(String value) {
    if ((value != 'asc' && value != 'desc') || value == order) return false;
    order = value;
    return true;
  }

  bool _toggle(Set<String> selected, List<String> allowed, String value) {
    if (!allowed.contains(value)) return false;
    if (selected.contains(value)) {
      if (selected.length == 1) return false;
      selected.remove(value);
    } else {
      selected.add(value);
    }
    return true;
  }
}

/// Cards beside Back, the filter, and the page window at this tick.
int userPageLimit(int tick) =>
    scaleTickCells(tick.clamp(scaleTickMin, scaleTickMax)) - 3;

String userWindowText({
  required int offset,
  required int limit,
  required int count,
  required String ofWord,
}) {
  if (count <= 0) return '0 $ofWord 0';
  final start = offset + 1;
  if (start > count) return '0 $ofWord $count';
  final end = offset + limit < count ? offset + limit : count;
  return '$start-$end $ofWord $count';
}

/// Arrows stay still until the directory is larger than the last scale tick.
bool userCanPageBack({required int offset, required int count}) =>
    count > userPageLimit(scaleTickMax) && offset > 0;

bool userCanPageForward({
  required int offset,
  required int limit,
  required int count,
}) => count > userPageLimit(scaleTickMax) && offset + limit < count;

/// Back, two filter cells, then user cards. The tick caps the disk.
NetworkBoard usersBoard({
  required int tick,
  required List<String> uuids,
  bool wide = false,
}) {
  final step = tick.clamp(scaleTickMin, scaleTickMax);
  final ids = <String>[
    'query',
    'window',
    for (final uuid in uuids) 'user:$uuid',
  ];
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

/// Inside a user card. Grant and revoke are owner-only. Block is Admin and
/// Owner. A plain user only sees the card again.
List<String> memberActions({
  required bool owner,
  required bool staff,
  required String role,
  required String status,
}) {
  final actions = <String>['card'];
  if (owner && role != 'Owner') {
    actions.add(role == 'Admin' ? 'revoke' : 'grant');
  }
  if (staff) actions.add(status == 'Blocked' ? 'unblock' : 'block');
  return actions;
}

/// Actions on the instance card, after the identity cell.
///
/// Order: summary, management, users, telegram, then demote or favorite.
/// Peer moderation takes the administration slot on another instance.
/// Identity plus these actions stay on one ring around Back.
/// The users cell is any signed-in session on the favorite instance.
List<String> cardActions({
  required bool isTarget,
  required bool owner,
  required bool staff,
  required bool telegram,
  required String? trust,
  bool signedIn = false,
}) {
  final actions = <String>['metrics'];
  if (isTarget && owner) actions.add('settings');
  if (isTarget && (signedIn || owner || staff)) actions.add('users');
  if (!isTarget && staff && trust != null) actions.add('peer');
  if (telegram) actions.add('telegram');
  actions.add(isTarget ? 'clear' : 'target');
  return actions;
}

/// Moderation actions for an external peer when opened by Admin or Owner.
List<String> peerActions({required String? trust, required bool federation}) {
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

/// Owner controls on `/peers/tune`: settings, then commands.
/// Avatar upload lives inside settings.
List<String> tuneActions({required bool owner}) {
  if (!owner) return const [];
  return const ['settings', 'ops'];
}

/// Screens gathered under `/peers/tune/settings`. Avatar is the last cell.
const ownerSettingSections = <String>[
  'instance',
  'mqtt',
  'datapipe',
  'notifications',
  'telegram',
  'icon',
];

/// Commands inside `/peers/tune/ops`. Tracking a peer is owner-only.
List<String> operationActions({
  required bool owner,
  required bool staff,
  required bool federation,
}) {
  if (!owner && !staff) return const [];
  return [
    'tests',
    if (federation) 'scan-all',
    'update-repos',
    if (owner) 'track',
    if (owner) 'reboot',
  ];
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

/// The current instance, then peer search. Back stays in the center.
///
/// On a tall screen the instance sits at 120° and search at 60°.
/// Without a target the first cell is the plain network section.
NetworkBoard networkBoard({required String? target, bool wide = false}) {
  final ids = <String>[target == null ? 'idle' : 'target', 'search'];
  final frame = hexFrame(count: ids.length, back: HexBack.center, wide: wide);
  final back = frame.back!;
  return NetworkBoard(
    slots: [
      for (var i = 0; i < ids.length; i++)
        BoardSlot(
          ids[i],
          frame.cells[i].$1,
          frame.cells[i].$2,
          url: ids[i] == 'target' ? target : null,
        ),
      BoardSlot('back', back.$1, back.$2),
    ],
    canZoomIn: false,
    page: 0,
    pages: 1,
  );
}

/// Filter, then search settings, then peer cards.
/// Back stays in the center. The last tick may give its tail to a pager.
NetworkBoard searchBoard({
  required int tick,
  required List<String> urls,
  required int page,
  bool wide = false,
}) {
  final step = tick.clamp(scaleTickMin, scaleTickMax);
  final chrome = <String>['text', 'settings'];
  final free = scaleTickCells(step) - 1;
  final instanceCap = free - chrome.length;
  final overflow = urls.length > instanceCap;
  final paging = step >= scaleTickMax && overflow && instanceCap >= 3;
  final urlRoom = instanceCap - (paging ? 2 : 0);
  final pages = paging && urlRoom > 0 ? (urls.length / urlRoom).ceil() : 1;
  final safePage = page.clamp(0, pages - 1);
  final slice = paging
      ? urls.skip(safePage * urlRoom).take(urlRoom).toList()
      : urls.take(urlRoom).toList();
  final frame = hexFrame(
    count: chrome.length + slice.length,
    back: HexBack.center,
    wide: wide,
    cells: scaleTickCells(step),
    tail: paging ? 2 : 0,
  );
  final back = frame.back!;
  final slots = <BoardSlot>[
    BoardSlot('back', back.$1, back.$2),
    for (var i = 0; i < chrome.length; i++)
      BoardSlot(chrome[i], frame.cells[i].$1, frame.cells[i].$2),
    for (var i = 0; i < slice.length; i++)
      BoardSlot(
        'instance',
        frame.cells[chrome.length + i].$1,
        frame.cells[chrome.length + i].$2,
        url: slice[i],
      ),
    if (frame.tail.length == 2) ...[
      BoardSlot('prev', frame.tail[0].$1, frame.tail[0].$2),
      BoardSlot('next', frame.tail[1].$1, frame.tail[1].$2),
    ],
  ];
  return NetworkBoard(
    slots: slots,
    canZoomIn: step < scaleTickMax,
    page: safePage,
    pages: pages,
  );
}

/// One url per free cell. Back sits in the center. A pager takes the tail.
NetworkBoard catalogBoard({
  required int tick,
  required List<String> urls,
  required int page,
  bool wide = false,
}) {
  final step = tick.clamp(scaleTickMin, scaleTickMax);
  final free = scaleTickCells(step) - 1;
  final overflow = urls.length > free;
  final paging = step >= scaleTickMax && overflow && free >= 3;
  final room = free - (paging ? 2 : 0);
  final pages = paging && room > 0 ? (urls.length / room).ceil() : 1;
  final safePage = page.clamp(0, pages - 1);
  final slice = paging
      ? urls.skip(safePage * room).take(room).toList()
      : urls.take(room).toList();
  final frame = hexFrame(
    count: slice.length,
    back: HexBack.center,
    wide: wide,
    cells: scaleTickCells(step),
    tail: paging ? 2 : 0,
  );
  final back = frame.back!;
  final slots = <BoardSlot>[
    BoardSlot('back', back.$1, back.$2),
    for (var i = 0; i < slice.length; i++)
      BoardSlot('url', frame.cells[i].$1, frame.cells[i].$2, url: slice[i]),
    if (frame.tail.length == 2) ...[
      BoardSlot('prev', frame.tail[0].$1, frame.tail[0].$2),
      BoardSlot('next', frame.tail[1].$1, frame.tail[1].$2),
    ],
  ];
  return NetworkBoard(
    slots: slots,
    canZoomIn: step < scaleTickMax && overflow,
    page: safePage,
    pages: pages,
  );
}

/// Actions in list order around Back in the center.
List<BoardSlot> cardBoard(List<String> ids, {bool wide = false}) {
  final frame = hexFrame(count: ids.length, back: HexBack.center, wide: wide);
  final back = frame.back!;
  return [
    for (var i = 0; i < ids.length; i++)
      BoardSlot(ids[i], frame.cells[i].$1, frame.cells[i].$2),
    BoardSlot('back', back.$1, back.$2),
  ];
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
