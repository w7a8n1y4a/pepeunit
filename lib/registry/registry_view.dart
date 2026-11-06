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
    if (!takeSort(order, value)) return false;
    order = value;
    return true;
  }
}

/// Cards beside Back, the filter, and the page window at this tick.
int repoPageLimit(int tick) =>
    scaleTickCells(tick.clamp(scaleTickMin, scaleTickMax)) - 3;

String repoWindowText({
  required int offset,
  required int limit,
  required int count,
  required String ofWord,
}) =>
    pageWindowText(offset: offset, limit: limit, count: count, ofWord: ofWord);

bool repoCanPageBack({required int offset, required int count}) => pageCanBack(
  offset: offset,
  count: count,
  capacity: repoPageLimit(scaleTickMax),
);

bool repoCanPageForward({
  required int offset,
  required int limit,
  required int count,
}) => pageCanForward(
  offset: offset,
  limit: limit,
  count: count,
  capacity: repoPageLimit(scaleTickMax),
);

/// Back, filter, page window, then repo cards. The tick caps the disk.
NetworkBoard reposBoard({
  required int tick,
  required List<String> uuids,
  bool wide = false,
}) {
  final step = tick.clamp(scaleTickMin, scaleTickMax);
  final ids = <String>[
    'query',
    'window',
    for (final uuid in uuids) 'repo:$uuid',
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

/// Wire values of `platform` in `POST /repo`.
const repoPlatforms = ['Github', 'Gitlab'];

/// Menu of the section: add a repository, then search.
const registryMenuIds = ['add', 'search'];

/// A repository link starts with `http://` or `https://`, has a host, and
/// ends with `.git`. The backend refuses anything else.
bool repoUrlOk(String raw) {
  final text = raw.trim();
  if (!text.startsWith('https://') && !text.startsWith('http://')) {
    return false;
  }
  if (!text.endsWith('.git') || RegExp(r'\s').hasMatch(text)) return false;
  final uri = Uri.tryParse(text);
  if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return false;
  return uri.path.length > '/.git'.length;
}

/// Name and token typed on the credentials screen of the add form.
class RepoCredsDraft {
  const RepoCredsDraft({this.username = '', this.token = ''});

  final String username;
  final String token;

  /// Both parts are required, as on a saved repository.
  bool get ready => username.trim().isNotEmpty && token.trim().isNotEmpty;
}

/// Cells of the add form. The credentials menu goes with a private repository.
List<String> repoCreateIds({required bool public}) {
  return ['url', 'platform', 'access', if (!public) 'credentials', 'create'];
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

/// One cell per branch. Tick 1 is seven cells. The last tick pages the tail
/// when the names still do not fit.
NetworkBoard branchesBoard({
  required int tick,
  required int page,
  required List<String> names,
  bool wide = false,
}) {
  final step = tick.clamp(scaleTickMin, scaleTickMax);
  final free = scaleTickCells(step) - 1;
  final overflow = names.length > free;
  final paging = step >= scaleTickMax && overflow && free >= 3;
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
    cells: scaleTickCells(step),
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
    canZoomIn: step < scaleTickMax && overflow,
    page: safePage,
    pages: pages,
  );
}
