import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/grain.dart';
import '../../hive/hex_scene.dart';
import '../../library/library.dart';
import '../../library/markdown.dart';
import '../code/code_modal.dart';
import '../code/code_view.dart';
import 'doc_reader.dart';
import 'library_menu_page.dart';
import 'md_view.dart';

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
  var _menu = false;

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

  Future<void> _load() async {
    final language = AppScope.of(context).vault.language;
    try {
      final tree = await Library.instance.docs(language);
      if (!mounted) return;
      final wanted = widget.doc;
      final asked = wanted == null ? null : tree.article(wanted);
      final first = asked ?? tree.first;
      setState(() {
        _tree = tree;
        if (first != null) {
          _reader = DocReader(
            first: DocPage.of(
              first,
              anchor: asked == null ? null : _clean(widget.anchor),
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
    } catch (error) {
      if (!mounted) return;
      setState(() => _failure = '$error');
    }
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
    final language = model.vault.language;
    String word(String ru) => libText(language, ru);
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
              ? max(0.0, (size.width - font * (_blockFonts + _outlineFonts)) / 2)
              : 0.0;
          // The outline panel: its room at the right end of the block. The
          // scroll bar of the text keeps the last strip of the screen.
          final outlineWidth = outlined ? gap + font * _outlineFonts : 0.0;
          final outlineRoom = outlined ? outlineWidth + codeBarRoom : 0.0;
          final line = const Color(0x33FFFFFF);
          final vline = Container(width: 1, color: line);

          Widget sidebar() {
            // A path can stand twice in the file; one row takes the key.
            var keyed = false;
            Key? keyOf(DocNode node) {
              if (keyed || node.path == null) return null;
              if (node.path != reader?.page.path) return null;
              keyed = true;
              return _selected;
            }

            if (tree == null) return const SizedBox.shrink();
            return ListView(
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

          final tools = Row(
            children: [
              if (reader != null && reader.canBack)
                _BackMark(
                  label: word('Назад'),
                  extent: mark,
                  onTap: reader.back,
                ),
              SizedBox(width: font * 0.2),
              CodeCloseMark(
                label: libErrorText(language, 'Закрыть', 'Close'),
                extent: mark,
                onTap: () => closeLibrary(context, '/library'),
              ),
            ],
          );

          // The bar: the name of the section above the sidebar, the title of
          // the article and the tools above the text. One line under it.
          final header = SizedBox(
            height: headerH,
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
                          word('Документация'),
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
                            label: word('Разделы'),
                            extent: mark,
                            onTap: () => setState(() => _menu = !_menu),
                          ),
                        if (reader?.page.path != null)
                          CopyLinkMark(
                            link: () => linkTo(null),
                            label: libErrorText(
                              language,
                              'Скопировать ссылку',
                              'Copy link',
                            ),
                            width: mark,
                            height: mark,
                          ),
                        SizedBox(width: font * 0.3),
                        // The title is text a person may select and copy.
                        Expanded(
                          child: SelectionArea(
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
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: tools,
                        ),
                      ],
                    ),
                  ),
                ),
                if (outlined) ...[
                  vline,
                  SizedBox(
                    width: outlineRoom,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: font * 0.8,
                        right: gap + codeBarRoom,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          libErrorText(
                            language,
                            'На этой странице',
                            'On this page',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _style(font * 1.2, const Color(0xFFFFFFFF)),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
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
                            word('Пусто'),
                            style: _style(font * 1.1, hexMuted),
                          ),
                  ),
          );

          // No frame and no fill: the scene under the router, its grain and
          // the mosaic, is the background, as on every other screen.
          return SafeArea(
            child: Column(
              children: [
                header,
                Container(height: 1, color: line),
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
                                child: sidebar(),
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
                                  child: sidebar(),
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
        },
      ),
    );
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
    return Semantics(
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
    return Semantics(
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

/// Back: the picture of the Back cell, on the bar.
class _BackMark extends StatelessWidget {
  const _BackMark({
    required this.label,
    required this.extent,
    required this.onTap,
  });

  final String label;
  final double extent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: HoverPop(
          child: SvgPicture.asset(
            'assets/icons/actions/back.svg',
            width: extent,
            height: extent,
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
    return Semantics(
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
