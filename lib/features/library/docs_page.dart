import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../library/library.dart';
import '../code/code_modal.dart';
import 'doc_reader.dart';
import 'library_menu_page.dart';

String docsAddress({String? doc}) {
  return Uri(path: '/library/docs', queryParameters: {'doc': ?doc}).toString();
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
const _wideDocs = 960.0;
const _centeredDocs = 1440.0;
const _blockFonts = 74.2;

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
/// - The article opens at `?doc=<path>`, or at the first row of the tree.
class DocsPage extends StatefulWidget {
  const DocsPage({this.doc, super.key});

  /// Path of the article to open first.
  final String? doc;

  @override
  State<DocsPage> createState() => _DocsPageState();
}

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
    final doc = widget.doc;
    if (tree == null || doc == null || doc == oldWidget.doc) return;
    final article = tree.article(doc);
    if (article != null) _reader?.show(article);
  }

  Future<void> _load() async {
    final language = AppScope.of(context).vault.language;
    try {
      final tree = await Library.instance.docs(language);
      if (!mounted) return;
      final wanted = widget.doc;
      final first =
          (wanted == null ? null : tree.article(wanted)) ?? tree.first;
      setState(() {
        _tree = tree;
        if (first != null) {
          _reader = DocReader(
            first: DocPage.of(first),
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
    } catch (error) {
      if (!mounted) return;
      setState(() => _failure = '$error');
    }
  }

  void _changed() => setState(_reveal);

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
    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final font = max(12.0, size.shortestSide * 0.018);
          final codeFont = max(11.0, font * 0.72);
          final headerH = font * 3.55;
          final wide = size.width >= _wideDocs;
          final side = min(font * 15.5, size.width * (wide ? 0.4 : 0.84));
          // What the screen has over the block, on the left of the sidebar.
          final gap = size.width >= _centeredDocs
              ? max(0.0, (size.width - font * _blockFonts) / 2)
              : 0.0;
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
                font * 0.6,
                font * 0.5,
                font * 0.3,
                font * 0.8,
              ),
              children: [
                for (final row in _rows(tree.sidebar))
                  _SideRow(
                    key: keyOf(row.node),
                    node: row.node,
                    depth: row.depth,
                    font: font,
                    open: _open.contains(row.node.id),
                    selected:
                        row.node.path != null &&
                        row.node.path == reader?.page.path,
                    onTap: () => _tapRow(row.node),
                  ),
              ],
            );
          }

          final tools = Row(
            children: [
              if (reader != null && reader.canBack)
                _BackMark(
                  label: word('Назад'),
                  extent: font * 2.2,
                  onTap: reader.back,
                ),
              SizedBox(width: font * 0.2),
              CodeCloseMark(
                label: libErrorText(language, 'Закрыть', 'Close'),
                extent: font * 2.2,
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
                            extent: font * 2.2,
                            onTap: () => setState(() => _menu = !_menu),
                          ),
                        Expanded(
                          child: Text(
                            reader?.page.title ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _style(font * 1.55, const Color(0xFFFFFFFF)),
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
              ],
            ),
          );

          // The text starts at the top, however short it is. The view takes
          // the whole width, so its scroll bar stands at the screen edge; it
          // centers the column of the text itself.
          final article = Padding(
            padding: EdgeInsets.only(left: font, top: font * 0.6),
            child: reader != null
                ? DocBody(
                    reader: reader,
                    raw: false,
                    codeFont: codeFont,
                    accent: libraryColor,
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
                                child: ColoredBox(
                                  color: sceneBackground,
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
    required this.open,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final DocNode node;
  final int depth;
  final double font;
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
