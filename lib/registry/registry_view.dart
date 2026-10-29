import '../instances/network_view.dart';

/// `is_public_repository` is one flag. Both kinds on means the filter is off.
const repoKinds = ['public', 'private'];

/// Search of `GET /repo`. Only `order_by_repository_url` is sent, ascending first.
class RepoQuery {
  String text = '';
  final Set<String> kinds = {'public', 'private'};
  String order = 'asc';

  /// `true` public, `false` private, `null` when both kinds stay on.
  bool? get publicOnly {
    final public = kinds.contains('public');
    final private = kinds.contains('private');
    if (public == private) return null;
    return public;
  }

  bool toggleKind(String kind) {
    if (!repoKinds.contains(kind)) return false;
    if (kinds.contains(kind)) {
      if (kinds.length == 1) return false;
      kinds.remove(kind);
    } else {
      kinds.add(kind);
    }
    return true;
  }

  bool setOrder(String value) {
    if ((value != 'asc' && value != 'desc') || value == order) return false;
    order = value;
    return true;
  }
}

/// Rings 1 and 2 hold 16 cards. Ring 3 adds 18. Same room as the user search.
int repoPageLimit(int scope) => scope >= 2 ? 34 : 16;

String repoWindowText({
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

bool repoCanPageBack({required int offset, required int count}) =>
    count > 16 && offset > 0;

bool repoCanPageForward({
  required int offset,
  required int limit,
  required int count,
}) => count > 16 && offset + limit < count;

/// Back, filter, page window, then repo cards. Scope 1 is two rings.
NetworkBoard reposBoard({
  required int scope,
  required List<String> uuids,
  bool wide = false,
}) {
  final rings = scope.clamp(1, 2) + 1;
  final ids = <String>[
    'query',
    'window',
    for (final uuid in uuids) 'repo:$uuid',
  ];
  final frame = hexFrame(
    count: ids.length,
    back: HexBack.center,
    wide: wide,
    rings: rings,
  );
  final back = frame.back!;
  return NetworkBoard(
    slots: [
      BoardSlot('back', back.$1, back.$2),
      for (var i = 0; i < ids.length && i < frame.cells.length; i++)
        BoardSlot(ids[i], frame.cells[i].$1, frame.cells[i].$2),
    ],
    canZoomIn: scope < 2,
    page: 0,
    pages: 1,
  );
}

/// Cells inside a repository. Credentials stay on a private repo.
/// Delete stays when the signed-in user is the creator.
List<String> repoMenuIds({required bool private, required bool owned}) {
  return [
    'card',
    'summary',
    'unit',
    'sync',
    if (private) 'credentials',
    'branches',
    if (owned) 'delete',
  ];
}

/// One cell per branch. Scope 0 is one ring. At scope 2 a pager takes the tail
/// when the names still do not fit.
NetworkBoard branchesBoard({
  required int scope,
  required int page,
  required List<String> names,
  bool wide = false,
}) {
  final rings = scope.clamp(0, 2) + 1;
  final free = hexDisk(rings, wide: wide).length - 1;
  final overflow = names.length > free;
  final paging = scope >= 2 && overflow && free >= 3;
  final room = free - (paging ? 2 : 0);
  final pages = paging && room > 0 ? (names.length / room).ceil() : 1;
  final safePage = page.clamp(0, pages - 1);
  final slice = paging
      ? names.skip(safePage * room).take(room).toList()
      : names.take(room).toList();
  final frame = hexFrame(
    count: slice.length,
    back: HexBack.center,
    wide: wide,
    rings: rings,
    tail: paging ? 2 : 0,
  );
  final back = frame.back!;
  return NetworkBoard(
    slots: [
      BoardSlot('back', back.$1, back.$2),
      for (var i = 0; i < slice.length; i++)
        BoardSlot(
          'branch:$i',
          frame.cells[i].$1,
          frame.cells[i].$2,
          url: slice[i],
        ),
      if (frame.tail.length == 2) ...[
        BoardSlot('prev', frame.tail[0].$1, frame.tail[0].$2),
        BoardSlot('next', frame.tail[1].$1, frame.tail[1].$2),
      ],
    ],
    canZoomIn: scope < 2 && overflow,
    page: safePage,
    pages: pages,
  );
}
