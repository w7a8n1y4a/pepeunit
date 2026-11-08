import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'markdown.dart';

/// Where the Library texts live in the app bundle.
///
/// - Documentation: `docs/<language>/**.md`. These are the folders of the
///   documentation sources, so the tree is the folders and nothing else
///   lists an article. The names and the order of folders are one static
///   file, `docs/<language>/_tree.json`: folder path to title, in the order
///   the folders stand. A folder it does not list keeps its own name and
///   comes after the listed ones. An article takes its name from its first
///   `# ` heading.
/// - Tips: `assets/library/tips/<language>/<screen>.<cell>.md`
/// - Everything else (presentation, about): `assets/library/<language>/`.
///
/// A text that has no translation falls back to Russian.
const docsRoot = 'docs';
const libraryRoot = 'assets/library';
const fallbackLanguage = 'ru';
const _treeFile = '_tree.json';

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

class DocFolder {
  DocFolder({required this.path, required this.title, this.order = 100});

  /// Path inside the tree: empty for the root.
  final String path;
  String title;
  int order;
  final List<DocFolder> folders = [];
  final List<DocArticle> articles = [];

  /// Everything one level down, folders first.
  int get count => folders.length + articles.length;
}

class DocsTree {
  DocsTree._(this.root, this._articles, this._folders);

  final DocFolder root;
  final Map<String, DocArticle> _articles;
  final Map<String, DocFolder> _folders;

  DocArticle? article(String path) => _articles[path];

  DocFolder? folder(String path) => path.isEmpty ? root : _folders[path];

  Iterable<DocArticle> get articles => _articles.values;

  /// Builds the tree of [language] from the bundle keys and their texts.
  /// Paths that exist only in Russian are kept, with the Russian text.
  static DocsTree build({
    required Iterable<String> keys,
    required String language,
    required String Function(String key) read,
  }) {
    final byPath = <String, String>{};
    // Folder path to title; the place in the map is the place in the tree.
    final names = <String, String>{};
    for (final lang in {fallbackLanguage, language}) {
      final prefix = '$docsRoot/$lang/';
      for (final key in keys) {
        if (!key.startsWith(prefix)) continue;
        final path = key.substring(prefix.length);
        if (path == _treeFile) {
          final decoded = jsonDecode(read(key));
          if (decoded is Map) {
            for (final entry in decoded.entries) {
              names['${entry.key}'] = '${entry.value}';
            }
          }
        } else if (path.endsWith('.md')) {
          byPath[path.substring(0, path.length - 3)] = key;
        }
      }
    }
    final root = DocFolder(path: '', title: '');
    final folders = <String, DocFolder>{};
    final articles = <String, DocArticle>{};

    DocFolder folderAt(String path) {
      if (path.isEmpty) return root;
      final known = folders[path];
      if (known != null) return known;
      final slash = path.lastIndexOf('/');
      final parent = folderAt(slash < 0 ? '' : path.substring(0, slash));
      final name = slash < 0 ? path : path.substring(slash + 1);
      final made = DocFolder(path: path, title: name);
      final title = names[path];
      if (title != null && title.trim().isNotEmpty) {
        made.title = title.trim();
        made.order = names.keys.toList().indexOf(path);
      }
      folders[path] = made;
      parent.folders.add(made);
      return made;
    }

    for (final entry in byPath.entries) {
      final path = entry.key;
      final source = read(entry.value);
      final slash = path.lastIndexOf('/');
      final parent = folderAt(slash < 0 ? '' : path.substring(0, slash));
      final name = slash < 0 ? path : path.substring(slash + 1);
      final article = DocArticle(
        path: path,
        title: markdownTitle(source) ?? name,
        source: source,
      );
      articles[path] = article;
      parent.articles.add(article);
    }
    void sort(DocFolder folder) {
      folder.folders.sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        return byOrder != 0 ? byOrder : a.title.compareTo(b.title);
      });
      folder.articles.sort((a, b) => a.title.compareTo(b.title));
      for (final child in folder.folders) {
        sort(child);
      }
    }

    // A folder without articles has nothing to show.
    bool prune(DocFolder folder) {
      folder.folders.removeWhere((child) {
        final empty = !prune(child);
        if (empty) folders.remove(child.path);
        return empty;
      });
      return folder.count > 0;
    }

    prune(root);
    sort(root);
    return DocsTree._(root, articles, folders);
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
            (key.endsWith('.md') || key.endsWith('/$_treeFile')))
          key,
    ];
    for (final key in keys) {
      await text(key);
    }
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
