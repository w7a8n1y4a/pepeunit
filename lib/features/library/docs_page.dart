import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/bevel.dart';
import '../../hive/grain.dart';
import '../../hive/hex_scene.dart';
import '../../hive/hint.dart';
import '../../account/vault.dart';
import '../../locale/languages.dart';
import '../../library/doc_search.dart';
import '../../library/library.dart';
import '../../library/markdown.dart';
import '../code/code_modal.dart';
import '../code/code_view.dart';
import 'doc_find_bar.dart';
import 'doc_reader.dart';
import 'doc_search_panel.dart';
import 'library_menu_page.dart';
import 'md_view.dart';

/// The language of the documentation: its own choice, or the language of the
/// client while the person has not made one.
String docsLanguageOf(Vault vault) => vault.docsLanguage ?? vault.language;

/// The address of the documentation at an article, and at a heading of it.
String docsAddress({String? doc, String? anchor}) {
  return Uri(
    path: '/library/docs',
    queryParameters: {
      'doc': ?doc,
      'anchor': ?((anchor ?? '').isEmpty ? null : anchor),
    },
  ).toString();
}

/// The address a person can send: with the host of the page on the web, with
/// the host of the instance the client works with elsewhere, and without a
/// host when there is none.
String docsLink({required String doc, String? anchor, String? instance}) {
  final path = docsAddress(doc: doc, anchor: anchor);
  Uri? base;
  if (kIsWeb) {
    base = Uri.base;
  } else if (instance != null) {
    base = Uri.tryParse(instance);
  }
  if (base == null || !base.hasScheme || base.host.isEmpty) return path;
  return Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
  ).resolve(path).toString();
}

/// The three stages of the screen, the way VitePress lays out a page. The
/// widths are logical pixels.
///
/// - From [_wideDocs] the sidebar stands at the left edge and the text takes
///   the rest, centered in it. Below it the sidebar is not drawn beside the
///   text: a mark on the bar opens it over the text.
/// - From [_centeredDocs] the sidebar and the text are one block as wide as
///   [_blockFonts] font sizes, centered on the screen. The sidebar grows
///   to the left by what the screen has over the block, so the two stay
///   near each other. On a 1920 px screen the block is 1440 px.
/// - From [_centeredDocs] the outline of the article stands at the right end
///   of the block, behind a line of its own: the headings of level two to
///   four, nested, each scrolling the text to itself. It is [_outlineFonts]
///   font sizes wide and the block grows by as much, so the text keeps its
///   room.
const _wideDocs = 960.0;
const _centeredDocs = 1440.0;
const _blockFonts = 74.2;
const _outlineFonts = 13.5;

/// The documentation: a modal over the whole screen, with no frame and no
/// fill of its own, so the scene and the mosaic show behind it. A tree of
/// articles on the left and the open article in the middle.
///
/// - The tree is `sidebar.json` of the language, see [DocsTree]. A row opens
///   its article; a group folds and unfolds.
/// - The article is drawn as every Library text is ([DocBody]), always
///   rendered. Its scroll bar stands at the right edge of the screen. The
///   bar above it holds Back (after links and rows led from one article to
///   another) and the close mark.
/// - The article opens at `?doc=<path>`, or at the first row of the tree;
///   `&anchor=<heading>` scrolls it to a heading. The address follows the
///   article that is open, so the page can be sent or reloaded. The title of
///   the article and every heading of level two to four have a mark that
///   copies that address.
/// - The language of the documentation is chosen on the bar ([_LanguageMark]),
///   apart from the language of the client. The article that is open stays
///   open in the other language.
/// - The search stands at the top of the sidebar (a mark on the bar on a
///   narrow screen). It, Ctrl+K (Cmd+K) and `/` open a panel over the page
///   that finds the words of a query in every article and leads to the
///   article and the heading ([DocSearchPanel]).
/// - Ctrl+F (Cmd+F) finds in the open article ([DocFindBar], a strip under
///   the bar, so it covers no text): the matches
///   are marked in the text and the view scrolls to the current one. The
///   browser's own find does not see the text, which is drawn on a canvas.
class DocsPage extends StatefulWidget {
  const DocsPage({this.doc, this.anchor, super.key});

  /// Path of the article to open first.
  final String? doc;

  /// Heading of that article to scroll to.
  final String? anchor;

  @override
  State<DocsPage> createState() => _DocsPageState();
}

String? _clean(String? anchor) =>
    anchor == null || anchor.isEmpty ? null : anchor;

class _DocsPageState extends State<DocsPage> {
  DocsTree? _tree;
  DocReader? _reader;
  String? _failure;
  final _open = <String>{};
  final _selected = GlobalKey();
  final _page = FocusNode(debugLabel: 'docs');
  var _menu = false;
  var _searching = false;
  final _findField = TextEditingController();
  final _findFocus = FocusNode(debugLabel: 'find');
  var _finding = false;
  var _findAt = 0;
  var _findCount = 0;

  /// The last load that was asked for; an older one that ends later is
  /// dropped.
  var _loads = 0;

  @override
  void dispose() {
    _page.dispose();
    _findField.dispose();
    _findFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(DocsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final tree = _tree;
    final reader = _reader;
    final doc = widget.doc;
    if (tree == null || reader == null || doc == null) return;
    if (doc == oldWidget.doc && widget.anchor == oldWidget.anchor) return;
    final article = tree.article(doc);
    if (article == null) return;
    final anchor = _clean(widget.anchor);
    if (article.path == reader.page.path) {
      // The address of the article that is open: only a heading may differ.
      if (anchor != null && anchor != _clean(reader.page.anchor)) {
        reader.controller.jump(anchor);
      }
      return;
    }
    reader.show(article, anchor: anchor);
  }

  /// Reads the tree of the language of the documentation. [keep] is the
  /// article to open in it, after a change of language: its headings are
  /// named in the other language, so no heading is kept.
  Future<void> _load({String? keep}) async {
    final load = ++_loads;
    final language = docsLanguageOf(AppScope.of(context).vault);
    try {
      final tree = await Library.instance.docs(language);
      if (!mounted || load != _loads) return;
      final wanted = keep ?? widget.doc;
      final asked = wanted == null ? null : tree.article(wanted);
      final first = asked ?? tree.first;
      setState(() {
        _tree = tree;
        if (first != null) {
          _reader = DocReader(
            first: DocPage.of(
              first,
              anchor: asked == null || keep != null
                  ? null
                  : _clean(widget.anchor),
            ),
            docs: tree,
            onChange: _changed,
          );
        }
        void unfold(List<DocNode> nodes) {
          for (final node in nodes) {
            if (!node.collapsed) _open.add(node.id);
            unfold(node.items);
          }
        }

        unfold(tree.sidebar);
        _reveal();
      });
      // The first article of the tree stands at an address with no `doc`.
      // The web page learns which one it is, without a new history entry.
      if (kIsWeb && asked == null && first != null) {
        SystemNavigator.routeInformationUpdated(
          uri: Uri.parse(docsAddress(doc: first.path)),
          replace: true,
        );
      }
      if (keep != null && first != null) {
        // The address drops a heading of the other language.
        final path = first.path;
        if (path != widget.doc || _clean(widget.anchor) != null) {
          GoRouter.of(context).go(docsAddress(doc: path));
        }
      }
    } catch (error) {
      if (!mounted || load != _loads) return;
      setState(() => _failure = '$error');
    }
  }

  /// The next language of the documentation, for the mark on the bar. The
  /// tree is read again and the open article stays open.
  Future<void> _switchLanguage() async {
    final model = AppScope.of(context);
    final now = docsLanguageOf(model.vault);
    final at = appLanguages.indexWhere((item) => item.code == now);
    final next = appLanguages[(at + 1) % appLanguages.length].code;
    if (next == now) return;
    final path = _reader?.page.path;
    _closeFind();
    setState(() {
      _tree = null;
      _reader = null;
      _failure = null;
      _open.clear();
      _menu = false;
      _searching = false;
    });
    await model.setDocsLanguage(next);
    if (!mounted) return;
    await _load(keep: path ?? widget.doc);
  }

  /// The trail moved: the sidebar follows, and so does the address.
  void _changed() {
    setState(_reveal);
    final page = _reader?.page;
    final path = page?.path;
    if (page == null || path == null) return;
    if (path == widget.doc && _clean(page.anchor) == _clean(widget.anchor)) {
      return;
    }
    GoRouter.of(context).go(docsAddress(doc: path, anchor: page.anchor));
  }

  /// Unfolds the groups of the article that is open and brings its row into
  /// view.
  void _reveal() {
    final path = _reader?.page.path;
    if (path == null) return;
    _open.addAll(_tree!.groupsOf(path));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final row = _selected.currentContext;
      if (row == null) return;
      Scrollable.ensureVisible(row, alignment: 0.5);
    });
  }

  void _openSearch() {
    if (_tree == null || _searching) return;
    setState(() {
      _searching = true;
      _menu = false;
    });
  }

  void _closeSearch() {
    if (!_searching) return;
    setState(() => _searching = false);
    _page.requestFocus();
  }

  void _openFind() {
    if (_reader == null || _searching) return;
    if (_finding) {
      _findFocus.requestFocus();
      _findField.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _findField.text.length,
      );
      return;
    }
    setState(() => _finding = true);
    // `autofocus` does not take the focus from the page that already holds
    // it, so the field asks for it once it is built: the person types at
    // once, with no click.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _finding) _findFocus.requestFocus();
    });
  }

  void _closeFind() {
    if (!_finding) return;
    _findField.clear();
    setState(() {
      _finding = false;
      _findAt = 0;
      _findCount = 0;
    });
    _page.requestFocus();
  }

  void _findTyped(String _) => setState(() => _findAt = 0);

  void _findStep(int step) {
    if (_findCount == 0) return;
    setState(() => _findAt = (_findAt + step) % _findCount);
  }

  /// The text counted its matches.
  void _findCounted(int count) {
    if (!mounted || count == _findCount) return;
    setState(() {
      _findCount = count;
      if (_findAt >= count) _findAt = 0;
    });
  }

  /// A hit was chosen: the article it stands in opens as the next text, or
  /// the open one scrolls to the heading.
  void _pick(DocSection section) {
    final reader = _reader;
    _closeSearch();
    if (reader == null) return;
    final anchor = section.anchor;
    if (section.article.path == reader.page.path) {
      if (anchor != null) reader.controller.jump(anchor);
      return;
    }
    reader.show(section.article, anchor: anchor);
  }

  /// Ctrl+K and Cmd+K, and `/` with no modifier, as on VitePress; Ctrl+F and
  /// Cmd+F, for the find in the article.
  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _searching || _tree == null) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    final command = keyboard.isControlPressed || keyboard.isMetaPressed;
    final key = event.logicalKey;
    if (command && key == LogicalKeyboardKey.keyF) {
      _openFind();
      return KeyEventResult.handled;
    }
    final asked = command
        ? key == LogicalKeyboardKey.keyK
        : key == LogicalKeyboardKey.slash &&
              !keyboard.isAltPressed &&
              !keyboard.isShiftPressed;
    if (!asked) return KeyEventResult.ignored;
    _openSearch();
    return KeyEventResult.handled;
  }

  void _tapRow(DocNode node) {
    setState(() {
      if (node.isGroup) {
        if (!_open.remove(node.id) || node.path != null) _open.add(node.id);
      }
    });
    final path = node.path;
    if (path != null) {
      final article = _tree!.article(path);
      if (article != null) _reader!.show(article);
      if (_menu) setState(() => _menu = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = docsLanguageOf(model.vault);
    final reader = _reader;
    final tree = _tree;
    String linkTo(String? anchor) => docsLink(
      doc: reader?.page.path ?? '',
      anchor: anchor,
      instance: model.vault.target?.url,
    );
    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final font = max(12.0, size.shortestSide * 0.018);
          final codeFont = max(11.0, font * 0.72);
          final wide = size.width >= _wideDocs;
          // A narrow screen is a touch screen: the bar, its marks and the
          // rows of the sidebar are drawn for a finger, not a pointer.
          final menuFont = wide ? font : max(font * 1.35, 17.0);
          final headerH = wide ? font * 3.55 : max(font * 3.55, 52.0);
          final mark = wide ? font * 2.2 : max(font * 2.2, 40.0);
          final side = min(menuFont * 15.5, size.width * (wide ? 0.4 : 0.86));
          // What the screen has over the block, on the left of the sidebar.
          final outlined = size.width >= _centeredDocs;
          final gap = outlined
              ? max(
                  0.0,
                  (size.width - font * (_blockFonts + _outlineFonts)) / 2,
                )
              : 0.0;
          // The outline panel: its room at the right end of the block. The
          // scroll bar of the text keeps the last strip of the screen.
          final outlineWidth = outlined ? gap + font * _outlineFonts : 0.0;
          final outlineRoom = outlined ? outlineWidth + codeBarRoom : 0.0;
          final line = const Color(0x33FFFFFF);
          final vline = Container(width: 1, color: line);

          Widget sidebar({required bool pill}) {
            // A path can stand twice in the file; one row takes the key.
            var keyed = false;
            Key? keyOf(DocNode node) {
              if (keyed || node.path == null) return null;
              if (node.path != reader?.page.path) return null;
              keyed = true;
              return _selected;
            }

            if (tree == null) return const SizedBox.shrink();
            final rows = ListView(
              padding: EdgeInsets.fromLTRB(
                menuFont * 0.6,
                menuFont * 0.5,
                menuFont * 0.3,
                menuFont * 0.8,
              ),
              children: [
                for (final row in _rows(tree.sidebar))
                  _SideRow(
                    key: keyOf(row.node),
                    node: row.node,
                    depth: row.depth,
                    font: menuFont,
                    minHeight: wide ? 0 : 44 / 1.5,
                    open: _open.contains(row.node.id),
                    selected:
                        row.node.path != null &&
                        row.node.path == reader?.page.path,
                    onTap: () => _tapRow(row.node),
                  ),
              ],
            );
            if (!pill) return rows;
            // The search stands over the tree and does not scroll with it.
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    menuFont * 0.6,
                    menuFont * 0.7,
                    menuFont * 0.6,
                    menuFont * 0.2,
                  ),
                  child: _SearchPill(
                    label: localized(language, 'Поиск', 'Search'),
                    hint: _searchKeys(),
                    font: menuFont,
                    onTap: _openSearch,
                  ),
                ),
                Expanded(child: rows),
              ],
            );
          }

          Widget outline() {
            final headings = [
              for (final heading in reader?.page.doc.headings ?? <MdHeading>[])
                if (heading.level >= 2 && heading.level <= 4) heading,
            ];
            return ListView(
              padding: EdgeInsets.fromLTRB(
                font * 0.8,
                font * 0.5,
                gap + font * 0.5,
                font * 0.8,
              ),
              children: [
                for (final heading in headings)
                  _OutlineRow(
                    key: ValueKey('${reader?.page.path}#${heading.slug}'),
                    heading: heading,
                    font: font,
                    onTap: () => reader?.controller.jump(heading.slug),
                  ),
              ],
            );
          }

          // Close stands at the right edge of the screen and never moves.
          // Back stands right before it (before the outline line on a wide
          // screen), so it appears and goes without shifting Close.
          final close = CodeCloseMark(
            label: localized(language, 'Закрыть', 'Close'),
            extent: mark * 0.9,
            onTap: () => closeLibrary(context, '/library'),
          );
          final back = reader != null && reader.canBack
              ? _IconMark(
                  asset: 'assets/icons/actions/back.svg',
                  label: localized(language, 'Назад', 'Back'),
                  extent: mark * 0.9,
                  onTap: reader.back,
                )
              : null;

          // The bar: the name of the section above the sidebar, the title of
          // the article and the tools above the text. One line under it.
          // Every word on it can be selected and copied, so the whole bar is
          // one selection area.
          final header = SizedBox(
            height: headerH,
            child: SelectionArea(
              child: Row(
                children: [
                  if (wide) ...[
                    SizedBox(
                      width: gap + side,
                      child: Padding(
                        padding: EdgeInsets.only(left: gap + font, right: font),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            localized(language, 'Документация', 'Documentation'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _style(font * 1.55, const Color(0xFFFFFFFF)),
                          ),
                        ),
                      ),
                    ),
                    vline,
                  ],
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(font, 0, font * 0.4, 0),
                      child: Row(
                        children: [
                          if (!wide)
                            _MenuMark(
                              label: localized(language, 'Разделы', 'Sections'),
                              extent: mark,
                              onTap: () => setState(() => _menu = !_menu),
                            ),
                          if (!wide && tree != null)
                            _IconMark(
                              asset: 'assets/icons/actions/search.svg',
                              label: localized(language, 'Поиск', 'Search'),
                              extent: mark,
                              onTap: _openSearch,
                            ),
                          if (reader?.page.path != null)
                            CopyLinkMark(
                              link: () => linkTo(null),
                              label: localized(
                                language,
                                'Скопировать ссылку',
                                'Copy link',
                              ),
                              width: mark,
                              height: mark,
                            ),
                          SizedBox(width: font * 0.3),
                          Expanded(
                            child: Text(
                              reader?.page.title ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _style(
                                font * 1.55,
                                const Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                          SizedBox(width: font * 0.3),
                          _LanguageMark(
                            code: language.toUpperCase(),
                            label: localized(
                              language,
                              'Язык документации',
                              'Documentation language',
                            ),
                            height: mark * 0.8,
                            font: font,
                            onTap: _switchLanguage,
                          ),
                          SizedBox(width: font * 0.3),
                          ?back,
                          // On a wide screen Close stands in the outline strip.
                          if (!outlined) ...[
                            SizedBox(width: font * 0.2),
                            close,
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (outlined) ...[
                    vline,
                    // The line takes one pixel of the room, so it stands on
                    // the same pixel as the line of the outline below it.
                    SizedBox(
                      width: outlineRoom - 1,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: font * 0.8,
                          right: font * 0.4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                localized(
                                  language,
                                  'На этой странице',
                                  'On this page',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _style(
                                  font * 1.2,
                                  const Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                            close,
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );

          // The text starts at the top, however short it is. The view takes
          // the whole width, so its scroll bar stands at the screen edge; it
          // keeps room on both sides of the column and leans the column
          // toward the middle of the screen itself.
          final article = Padding(
            padding: EdgeInsets.only(top: font * 0.6),
            child: reader != null
                ? DocBody(
                    reader: reader,
                    raw: false,
                    codeFont: codeFont,
                    accent: libraryColor,
                    linkOf: (slug) => linkTo(slug),
                    find: _finding && _findField.text.isNotEmpty
                        ? MdFind(_findField.text, _findAt)
                        : null,
                    onFound: _findCounted,
                    sides: max(font * 1.2, 16.0),
                    lead: wide ? gap + side + 1 : 0,
                    trail: outlineRoom,
                  )
                : Center(
                    child: _failure != null
                        ? Text(
                            _failure!,
                            textAlign: TextAlign.center,
                            style: _style(font * 1.1, errorColor),
                          )
                        : tree == null
                        ? CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              libraryColor,
                            ),
                          )
                        : Text(
                            localized(language, 'Пусто', 'Empty'),
                            style: _style(font * 1.1, hexMuted),
                          ),
                  ),
          );

          // No frame and no fill: the scene under the router, its grain and
          // the mosaic, is the background, as on every other screen.
          final page = SafeArea(
            child: Column(
              children: [
                header,
                Container(height: 1, color: line),
                // The find has a strip of its own: the text stands under it,
                // not behind it.
                if (_finding) ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      (wide ? gap + side + 1 : 0) + font,
                      font * 0.5,
                      font,
                      font * 0.5,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: font * 34),
                        child: DocFindBar(
                          controller: _findField,
                          focusNode: _findFocus,
                          language: language,
                          font: font,
                          count: _findCount,
                          current: _findAt,
                          onChanged: _findTyped,
                          onStep: _findStep,
                          onClose: _closeFind,
                        ),
                      ),
                    ),
                  ),
                  Container(height: 1, color: line),
                ],
                Expanded(
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          if (wide) ...[
                            SizedBox(
                              width: gap + side,
                              child: Padding(
                                padding: EdgeInsets.only(left: gap),
                                child: sidebar(pill: true),
                              ),
                            ),
                            vline,
                          ],
                          Expanded(child: article),
                        ],
                      ),
                      if (outlined)
                        Positioned(
                          top: 0,
                          bottom: 0,
                          right: codeBarRoom,
                          width: outlineWidth,
                          child: Row(
                            children: [
                              vline,
                              Expanded(child: outline()),
                            ],
                          ),
                        ),
                      if (!wide && _menu) ...[
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _menu = false),
                            child: const ColoredBox(color: Color(0x99000000)),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: side,
                          child: Row(
                            children: [
                              Expanded(
                                // The scene itself, grain included, but opaque:
                                // the article must not show through.
                                child: GrainBox(
                                  tile: sceneGrain,
                                  child: sidebar(pill: false),
                                ),
                              ),
                              vline,
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
          final searchTree = tree;
          // The keys reach the page while nothing else holds the focus.
          return Focus(
            focusNode: _page,
            autofocus: true,
            onKeyEvent: _key,
            child: Stack(
              children: [
                Positioned.fill(child: page),
                if (_searching && searchTree != null)
                  Positioned.fill(
                    child: DocSearchPanel(
                      index: DocSearchIndex.of(searchTree),
                      language: language,
                      font: menuFont,
                      onOpen: _pick,
                      onClose: _closeSearch,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// How the person is told to open the search: the key of the platform.
  String _searchKeys() {
    final apple =
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS;
    return apple ? 'Cmd K' : 'Ctrl K';
  }

  /// The rows the sidebar shows: a folded group hides what is under it.
  Iterable<({DocNode node, int depth})> _rows(
    List<DocNode> nodes, [
    int depth = 0,
  ]) sync* {
    for (final node in nodes) {
      yield (node: node, depth: depth);
      if (node.isGroup && _open.contains(node.id)) {
        yield* _rows(node.items, depth + 1);
      }
    }
  }
}

TextStyle _style(double size, Color color, {double? height}) => TextStyle(
  color: color,
  fontFamily: 'OpenGost Type B',
  fontSize: size,
  height: height,
  decoration: TextDecoration.none,
);

/// A row of the sidebar. The article that is open is in the library color.
class _SideRow extends StatefulWidget {
  const _SideRow({
    required this.node,
    required this.depth,
    required this.font,
    required this.minHeight,
    required this.open,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final DocNode node;
  final int depth;
  final double font;

  /// The least height of the row: a finger needs more than a pointer.
  final double minHeight;
  final bool open;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SideRow> createState() => _SideRowState();
}

class _SideRowState extends State<_SideRow> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final font = widget.font;
    final node = widget.node;
    final color = widget.selected
        ? libraryColor
        : node.isGroup
        ? const Color(0xFFFFFFFF)
        : hexMuted;
    return HintTarget(
      id: node.isGroup ? 'doc-group' : 'doc-article',
      title: node.text,
      color: color,
      child: Semantics(
        button: true,
        selected: widget.selected,
        label: node.text,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: Container(
              color: _hover ? const Color(0x14FFFFFF) : null,
              constraints: BoxConstraints(minHeight: widget.minHeight),
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(
                left: font * 0.3 + widget.depth * font * 0.9,
                top: font * 0.2,
                bottom: font * 0.2,
                right: font * 0.3,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: font * 0.9,
                    height: font * 1.125,
                    child: node.isGroup
                        ? CustomPaint(
                            painter: _ChevronPainter(color, widget.open),
                          )
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      node.text,
                      style: _style(font * 0.9, color, height: 1.25),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A heading in the outline, indented by its level under the first one.
class _OutlineRow extends StatefulWidget {
  const _OutlineRow({
    required this.heading,
    required this.font,
    required this.onTap,
    super.key,
  });

  final MdHeading heading;
  final double font;
  final VoidCallback onTap;

  @override
  State<_OutlineRow> createState() => _OutlineRowState();
}

class _OutlineRowState extends State<_OutlineRow> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final font = widget.font;
    final heading = widget.heading;
    return HintTarget(
      id: 'doc-heading',
      title: heading.text,
      color: libraryColor,
      child: Semantics(
        button: true,
        label: heading.text,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: Container(
              color: _hover ? const Color(0x14FFFFFF) : null,
              padding: EdgeInsets.only(
                left: font * 0.3 + (heading.level - 2) * font * 0.9,
                top: font * 0.2,
                bottom: font * 0.2,
                right: font * 0.3,
              ),
              child: Text(
                heading.text,
                style: _style(
                  font * 0.9,
                  _hover
                      ? libraryColor
                      : heading.level == 2
                      ? const Color(0xFFFFFFFF)
                      : hexMuted,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter(this.color, this.open);

  final Color color;
  final bool open;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.3, size.width * 0.12)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final c = Offset(size.width * 0.42, size.height * 0.5);
    final a = size.width * 0.2;
    final path = Path();
    if (open) {
      path
        ..moveTo(c.dx - a, c.dy - a * 0.5)
        ..lineTo(c.dx, c.dy + a * 0.7)
        ..lineTo(c.dx + a, c.dy - a * 0.5);
    } else {
      path
        ..moveTo(c.dx - a * 0.5, c.dy - a)
        ..lineTo(c.dx + a * 0.7, c.dy)
        ..lineTo(c.dx - a * 0.5, c.dy + a);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.open != open;
}

/// The search of the documentation, as a field that is not one: the mark, the
/// word, and the keys that open it, in a cut frame over the sidebar.
class _SearchPill extends StatefulWidget {
  const _SearchPill({
    required this.label,
    required this.hint,
    required this.font,
    required this.onTap,
  });

  final String label;
  final String hint;
  final double font;
  final VoidCallback onTap;

  @override
  State<_SearchPill> createState() => _SearchPillState();
}

class _SearchPillState extends State<_SearchPill> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final font = widget.font;
    final color = _hover ? libraryColor : const Color(0x55FFFFFF);
    return HintTarget(
      id: 'doc-search',
      title: widget.label,
      color: libraryColor,
      child: Semantics(
        button: true,
        label: widget.label,
        excludeSemantics: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: BevelFrame(
              color: color,
              radius: font * 0.6,
              width: 1.2,
              child: Container(
                height: font * 2.4,
                padding: EdgeInsets.symmetric(horizontal: font * 0.8),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/actions/search.svg',
                      width: font * 1.15,
                      height: font * 1.15,
                    ),
                    SizedBox(width: font * 0.6),
                    Expanded(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _style(font * 0.95, hexMuted),
                      ),
                    ),
                    Text(widget.hint, style: _style(font * 0.8, hexMuted)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The language of the documentation on the bar: its code in a cut frame. A
/// tap goes to the next language.
class _LanguageMark extends StatelessWidget {
  const _LanguageMark({
    required this.code,
    required this.label,
    required this.height,
    required this.font,
    required this.onTap,
  });

  final String code;
  final String label;
  final double height;
  final double font;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HintTarget(
      id: 'doc-language',
      title: label,
      color: libraryColor,
      child: Semantics(
        button: true,
        label: label,
        value: code,
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: HoverPop(
            child: BevelFrame(
              color: const Color(0x99FFFFFF),
              radius: height * 0.3,
              width: 1.2,
              child: Container(
                height: height,
                padding: EdgeInsets.symmetric(horizontal: font * 0.8),
                alignment: Alignment.center,
                // The bar is one selection area; the code is a button, not
                // a text to copy.
                child: SelectionContainer.disabled(
                  child: Text(
                    code,
                    maxLines: 1,
                    style: _style(font * 0.95, const Color(0xFFFFFFFF)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A mark of the bar drawn from an icon: Back, search.
class _IconMark extends StatelessWidget {
  const _IconMark({
    required this.asset,
    required this.label,
    required this.extent,
    required this.onTap,
  });

  final String asset;
  final String label;
  final double extent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HintTarget(
      id: asset.endsWith('/search.svg') ? 'doc-search' : 'doc-back',
      title: label,
      color: libraryColor,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: HoverPop(
            child: SvgPicture.asset(asset, width: extent, height: extent),
          ),
        ),
      ),
    );
  }
}

/// The mark that opens the sidebar on a narrow screen: three lines.
class _MenuMark extends StatelessWidget {
  const _MenuMark({
    required this.label,
    required this.extent,
    required this.onTap,
  });

  final String label;
  final double extent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HintTarget(
      id: 'doc-menu',
      title: label,
      color: libraryColor,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: HoverPop(
            child: SizedBox(
              width: extent,
              height: extent,
              child: const CustomPaint(painter: _MenuPainter()),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuPainter extends CustomPainter {
  const _MenuPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;
    for (final y in [0.3, 0.5, 0.7]) {
      canvas.drawLine(
        Offset(size.width * 0.22, size.height * y),
        Offset(size.width * 0.78, size.height * y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MenuPainter oldDelegate) => false;
}
