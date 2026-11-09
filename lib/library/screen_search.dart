import 'screen_tree.dart';

/// Most rows a search gives back. The list is sorted before it is cut.
const screenSearchLimit = 200;

/// The search over [ScreenMap], built once per map: every row keeps its depth
/// and its names and address in lower case, so a key typed in the field costs
/// one pass of substring tests and a sort, no allocation per row.
class ScreenSearchIndex {
  ScreenSearchIndex._(ScreenMap map) {
    var order = 0;
    for (final node in map.nodes) {
      final screen = node.isCell ? map.node(node.screenPath) : null;
      final ru = node.ru.toLowerCase();
      final en = node.en.toLowerCase();
      _entries.add(
        _Entry(
          node: node,
          depth: map.trail(node.path).length,
          order: order++,
          ru: ru,
          en: en,
          haystack: [
            ru,
            en,
            node.path.toLowerCase(),
            if (screen != null) screen.ru.toLowerCase(),
            if (screen != null) screen.en.toLowerCase(),
          ].join(' '),
        ),
      );
    }
  }

  static final _built = Expando<ScreenSearchIndex>();

  /// The index of [map]; the same object while the map lives.
  static ScreenSearchIndex of(ScreenMap map) =>
      _built[map] ??= ScreenSearchIndex._(map);

  final _entries = <_Entry>[];

  /// Rows that answer [query]. A row answers when every word of the query
  /// meets in its names (both languages) or its address; a cell also takes
  /// the names of the screen it stands on, so `аппарат создать` finds the
  /// Create cell of the new unit.
  ///
  /// The order is the distance from the home screen: the row with fewer steps
  /// to it first. Rows at the same distance go alphabetically by their name in
  /// [language], and what is left keeps the order of the tree.
  List<ScreenNode> search(
    String query, {
    String language = 'ru',
    int limit = screenSearchLimit,
  }) {
    final words = [
      for (final word in query.toLowerCase().split(RegExp(r'\s+')))
        if (word.isNotEmpty) word,
    ];
    if (words.isEmpty) return const [];
    final found = <_Entry>[
      for (final entry in _entries)
        if (words.every(entry.haystack.contains)) entry,
    ];
    final english = language == 'en';
    found.sort((a, b) {
      if (a.depth != b.depth) return a.depth - b.depth;
      final byName = english ? a.en.compareTo(b.en) : a.ru.compareTo(b.ru);
      if (byName != 0) return byName;
      return a.order - b.order;
    });
    return [for (final entry in found.take(limit)) entry.node];
  }
}

class _Entry {
  const _Entry({
    required this.node,
    required this.depth,
    required this.order,
    required this.ru,
    required this.en,
    required this.haystack,
  });

  final ScreenNode node;
  final int depth;
  final int order;
  final String ru;
  final String en;
  final String haystack;
}

/// Rows of [map] that answer [query], the nearest to the home screen first,
/// at most [limit]. See [ScreenSearchIndex.search].
List<ScreenNode> searchScreens(
  ScreenMap map,
  String query, {
  String language = 'ru',
  int limit = screenSearchLimit,
}) => ScreenSearchIndex.of(map).search(query, language: language, limit: limit);

/// The way from the home screen to [path] as words: `Главная › Аппараты › …`.
/// Empty when the row is unknown.
String screenRouteText(String language, ScreenMap map, String path) {
  return map.trail(path).map((node) => node.title(language)).join(' › ');
}
