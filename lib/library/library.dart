import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'markdown.dart';

/// Where the Library texts live in the app bundle.
///
/// - Documentation: `docs/<language>/**.md`, and next to them
///   `docs/<language>/sidebar.json`. The articles are the files. The sidebar
///   is that one JSON file, in the shape of a VitePress sidebar: a list of
///   `{ "text", "link", "collapsed", "items" }`. It binds a file to its place
///   and its name in the tree. A link is the path of an article without
///   `.md`. A link to a file that is not in the bundle is left out. An
///   article that no row links to has no place in the tree, but a link in a
///   text still opens it. An article takes the title of its panel from its
///   first `# ` heading.
/// - Tips: `assets/library/tips/<language>/<screen>.<cell>.md`
/// - Everything else (presentation, about): `assets/library/<language>/`.
///
/// A text that has no translation falls back to Russian, and so does the
/// sidebar.
const docsRoot = 'docs';
const libraryRoot = 'assets/library';
const fallbackLanguage = 'ru';
const sidebarFile = 'sidebar.json';

class DocArticle {
  const DocArticle({
    required this.path,
    required this.title,
    required this.source,
  });

  /// Path inside the tree without `.md`: `deployment/docker/deploy`.
  final String path;
  final String title;
  final String source;

  String get name => path.split('/').last;
}

/// One row of the sidebar: an article ([path]), a group ([items]), or a
/// group whose name is an article too.
class DocNode {
  const DocNode({
    required this.id,
    required this.text,
    required this.items,
    this.path,
    this.collapsed = false,
  });

  /// Place in the file: `2.0.1` is the second row, its first row, its
  /// second row. It does not change when a row is left out.
  final String id;
  final String text;
  final String? path;
  final bool collapsed;
  final List<DocNode> items;

  bool get isGroup => items.isNotEmpty;
}

/// A link to an article as a path of the tree: `/a/b.md` and `a/b/` are
/// `a/b`.
String docPathOf(String link) {
  var path = link;
  if (path.startsWith('/')) path = path.substring(1);
  if (path.endsWith('.md')) path = path.substring(0, path.length - 3);
  if (path.endsWith('.html')) path = path.substring(0, path.length - 5);
  if (path.endsWith('/')) path = path.substring(0, path.length - 1);
  return path;
}

/// Reads `sidebar.json`. [exists] says whether an article is in the bundle.
/// A file that is not a list of rows with a `text` is a mistake of the
/// author, not something to hide, so it throws a [FormatException].
List<DocNode> parseSidebar(String json, bool Function(String path) exists) {
  final Object? data;
  try {
    data = jsonDecode(json);
  } on FormatException catch (error) {
    throw FormatException('$sidebarFile: ${error.message}');
  }
  if (data is! List) {
    throw const FormatException('$sidebarFile: a list of rows is expected');
  }
  List<DocNode> read(List<Object?> rows, String prefix) {
    final nodes = <DocNode>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final id = prefix.isEmpty ? '$i' : '$prefix.$i';
      if (row is! Map) {
        throw FormatException('$sidebarFile: row $id is not an object');
      }
      final text = row['text'];
      if (text is! String || text.trim().isEmpty) {
        throw FormatException('$sidebarFile: row $id has no text');
      }
      final link = row['link'];
      String? path;
      if (link is String) {
        final found = docPathOf(link);
        if (exists(found)) path = found;
      }
      final children = row['items'];
      final items = children is List ? read(children, id) : const <DocNode>[];
      // A row with no article and nothing under it has nothing to show.
      if (path == null && items.isEmpty) continue;
      nodes.add(
        DocNode(
          id: id,
          text: text.trim(),
          path: path,
          collapsed: row['collapsed'] == true,
          items: items,
        ),
      );
    }
    return nodes;
  }

  return read(data, '');
}

/// Where a link inside a text leads.
class DocLink {
  const DocLink({this.article, this.anchor, this.outside});

  /// The article the link points at. Null for a heading of the text the link
  /// stands in, or an outside address.
  final DocArticle? article;

  /// Heading in lower case, as the text spells it after `#`.
  final String? anchor;
  final Uri? outside;
}

/// Where [url], found in the text at [from], leads. Null for a link the
/// client cannot follow: an article that is not in [tree], or a bare `#`.
/// Without a [tree] only outside addresses and headings of the same text
/// work.
DocLink? resolveDocLink(String url, {DocsTree? tree, String? from}) {
  if (url.startsWith('http://') ||
      url.startsWith('https://') ||
      url.startsWith('mailto:')) {
    return DocLink(outside: Uri.tryParse(url));
  }
  final hash = url.indexOf('#');
  String? anchor;
  if (hash >= 0) {
    var raw = url.substring(hash + 1);
    try {
      raw = Uri.decodeComponent(raw);
    } catch (_) {}
    anchor = raw.toLowerCase();
  }
  final target = hash < 0 ? url : url.substring(0, hash);
  if (target.isEmpty) {
    return anchor == null || anchor.isEmpty ? null : DocLink(anchor: anchor);
  }
  if (tree == null) return null;
  var path = target;
  if (!path.startsWith('/')) {
    final slash = (from ?? '').lastIndexOf('/');
    final parts = [if (slash > 0) ...from!.substring(0, slash).split('/')];
    for (final part in target.split('/')) {
      if (part == '..') {
        if (parts.isNotEmpty) parts.removeLast();
      } else if (part != '.' && part.isNotEmpty) {
        parts.add(part);
      }
    }
    path = parts.join('/');
  }
  final article = tree.article(docPathOf(path));
  if (article == null) return null;
  return DocLink(article: article, anchor: anchor);
}

class DocsTree {
  DocsTree._(this.sidebar, this._articles);

  /// The rows of the sidebar, as the file lists them.
  final List<DocNode> sidebar;
  final Map<String, DocArticle> _articles;

  DocArticle? article(String path) => _articles[path];

  /// Every article of the bundle, the ones the sidebar leaves out too.
  Iterable<DocArticle> get articles => _articles.values;

  /// The first article of the sidebar, the one the documentation opens at.
  /// Without a sidebar, the first article by path.
  DocArticle? get first {
    String? find(List<DocNode> nodes) {
      for (final node in nodes) {
        final found = node.path ?? find(node.items);
        if (found != null) return found;
      }
      return null;
    }

    final path = find(sidebar);
    if (path != null) return _articles[path];
    if (_articles.isEmpty) return null;
    return _articles[(_articles.keys.toList()..sort()).first];
  }

  /// Ids of the groups that hold the article at [path], outermost first.
  /// Empty when the sidebar does not list it.
  List<String> groupsOf(String path) {
    List<String>? walk(List<DocNode> nodes, List<String> above) {
      for (final node in nodes) {
        if (node.path == path) return above;
        final inside = walk(node.items, [...above, node.id]);
        if (inside != null) return inside;
      }
      return null;
    }

    return walk(sidebar, const []) ?? const [];
  }

  /// Builds the tree of [language] from the bundle keys and their texts.
  /// Paths that exist only in Russian are kept, with the Russian text.
  static DocsTree build({
    required Iterable<String> keys,
    required String language,
    required String Function(String key) read,
  }) {
    final byPath = <String, String>{};
    for (final lang in {fallbackLanguage, language}) {
      final prefix = '$docsRoot/$lang/';
      for (final key in keys) {
        if (!key.startsWith(prefix)) continue;
        final path = key.substring(prefix.length);
        if (path.endsWith('.md')) {
          byPath[path.substring(0, path.length - 3)] = key;
        }
      }
    }
    final articles = <String, DocArticle>{};
    for (final entry in byPath.entries) {
      final source = read(entry.value);
      articles[entry.key] = DocArticle(
        path: entry.key,
        title: markdownTitle(source) ?? entry.key.split('/').last,
        source: source,
      );
    }
    final keySet = keys.toSet();
    String? sidebarKey;
    for (final lang in [language, fallbackLanguage]) {
      final key = '$docsRoot/$lang/$sidebarFile';
      if (keySet.contains(key)) {
        sidebarKey = key;
        break;
      }
    }
    final sidebar = sidebarKey == null
        ? const <DocNode>[]
        : parseSidebar(read(sidebarKey), articles.containsKey);
    return DocsTree._(sidebar, articles);
  }
}

/// The Library texts of the running app.
class Library {
  Library(this.bundle);

  /// A library over texts held in memory, for tests: the keys are the
  /// bundle keys.
  @visibleForTesting
  Library.fromTexts(Map<String, String> files)
    : bundle = rootBundle,
      _keys = files.keys.toSet() {
    _texts.addAll(files);
  }

  /// The library the app uses. Tests may replace it.
  static Library instance = Library(rootBundle);

  final AssetBundle bundle;

  Set<String>? _keys;
  final _texts = <String, String>{};
  final _trees = <String, DocsTree>{};

  /// Reads the list of bundled files. Call once before the first screen.
  Future<void> load() async {
    if (_keys != null) return;
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    _keys = manifest.listAssets().toSet();
  }

  bool get ready => _keys != null;

  bool has(String key) => _keys?.contains(key) ?? false;

  Future<String> text(String key) async {
    final cached = _texts[key];
    if (cached != null) return cached;
    final text = await bundle.loadString(key);
    return _texts[key] = text;
  }

  /// A text of the Library folder, in [language] or in Russian.
  Future<String?> page(String language, String name) async {
    for (final lang in {language, fallbackLanguage}) {
      final key = '$libraryRoot/$lang/$name.md';
      if (has(key)) return text(key);
    }
    return null;
  }

  /// The slides of the presentation: `presentation/01`, `02`, ... until one
  /// is missing.
  Future<List<String>> presentation(String language) async {
    await load();
    final slides = <String>[];
    for (var n = 1; ; n++) {
      final text = await page(
        language,
        'presentation/${n.toString().padLeft(2, '0')}',
      );
      if (text == null) break;
      slides.add(text);
    }
    return slides;
  }

  /// The documentation tree of [language].
  Future<DocsTree> docs(String language) async {
    await load();
    final cached = _trees[language];
    if (cached != null) return cached;
    final keys = [
      for (final key in _keys!)
        if (key.startsWith('$docsRoot/') &&
            (key.endsWith('.md') || key.endsWith('/$sidebarFile')))
          key,
    ];
    // All at once: on the web every text is a request of its own, and one
    // after another they made the first open of the documentation slow.
    await Future.wait([for (final key in keys) text(key)]);
    return _trees[language] = DocsTree.build(
      keys: keys,
      language: language,
      read: (key) => _texts[key]!,
    );
  }

  /// Key of the tip file for [screen] and [cell], or null when there is none.
  /// A shared tip, `common.<cell>`, serves every screen.
  String? tipKey(String language, String screen, String cell) {
    for (final lang in {language, fallbackLanguage}) {
      for (final name in ['$screen.$cell', 'common.$cell']) {
        final key = '$libraryRoot/tips/$lang/$name.md';
        if (has(key)) return key;
      }
    }
    return null;
  }
}

/// The part of a tip file name that stands for a screen: its route pattern
/// without the slashes. `/` is `home`, `/units/:uuid/io` is `units.uuid.io`.
String tipScreenOf(String routePattern) {
  final cleaned = routePattern
      .split('/')
      .where((part) => part.isNotEmpty)
      .map((part) => part.replaceAll(':', ''))
      .join('.');
  return cleaned.isEmpty ? 'home' : cleaned;
}

/// Cell ids that name something typed by a person or sent by the backend
/// have no tip. Only plain words do.
bool tipCellOk(String id) => RegExp(r'^[a-z0-9_-]+$').hasMatch(id);
