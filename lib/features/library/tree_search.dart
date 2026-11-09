import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../hive/bevel.dart';
import '../../hive/grain.dart';
import '../../hive/hex_scene.dart';
import '../../hive/hint.dart';
import '../../library/screen_search.dart';
import '../../library/screen_tree.dart';
import '../code/code_modal.dart';
import 'library_menu_page.dart';
import 'tree_map.dart';

TextStyle _style(double size, Color color, {double? height}) => TextStyle(
  color: color,
  fontFamily: 'OpenGost Type B',
  fontSize: size,
  height: height,
  decoration: TextDecoration.none,
);

/// The path search of the tree, as a button that is not a field: the mark and
/// the word in a cut frame. A tap opens [TreeSearchPanel].
class TreeSearchPill extends StatefulWidget {
  const TreeSearchPill({
    required this.label,
    required this.font,
    required this.onTap,
    super.key,
  });

  final String label;
  final double font;
  final VoidCallback onTap;

  @override
  State<TreeSearchPill> createState() => _TreeSearchPillState();
}

class _TreeSearchPillState extends State<TreeSearchPill> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final font = widget.font;
    return HintTarget(
      id: 'button-tree-search',
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
              color: _hover ? libraryColor : const Color(0x55FFFFFF),
              radius: font * 0.6,
              width: 1.2,
              child: Container(
                height: font * 2.4,
                padding: EdgeInsets.symmetric(horizontal: font * 0.8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/actions/search.svg',
                      width: font * 1.15,
                      height: font * 1.15,
                    ),
                    SizedBox(width: font * 0.6),
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _style(font * 0.95, hexMuted),
                      ),
                    ),
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

/// The modal of the path search: a panel over the screen with a field on top
/// and the rows that answer under it, each with the way to it from the home
/// screen. The nearest row to the home screen is first, rows at the same
/// distance go alphabetically.
///
/// - Typing searches at once; only this panel is rebuilt, never the map.
///   Up and Down move along the rows, Enter picks the lit one, Escape closes.
/// - A tap on a row, or Enter, calls [onPick]; the owner closes the panel.
/// - A tap outside the panel calls [onClose].
class TreeSearchPanel extends StatefulWidget {
  const TreeSearchPanel({
    required this.map,
    required this.language,
    required this.font,
    required this.available,
    required this.onPick,
    required this.onClose,
    super.key,
  });

  final ScreenMap map;
  final String language;

  /// Size of the text of a row. The rest follows it.
  final double font;

  /// Addresses of the rows this session may use: the closed ones are dim.
  final Set<String> available;
  final ValueChanged<ScreenNode> onPick;
  final VoidCallback onClose;

  @override
  State<TreeSearchPanel> createState() => _TreeSearchPanelState();
}

class _TreeSearchPanelState extends State<TreeSearchPanel> {
  final _field = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  var _hits = const <ScreenNode>[];
  var _asked = '';
  var _lit = 0;

  @override
  void initState() {
    super.initState();
    // The page under the panel holds the focus: ask for it, and typing
    // starts at once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _typed(String text) {
    setState(() {
      _asked = text.trim();
      _hits = searchScreens(widget.map, text, language: widget.language);
      _lit = 0;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _move(int step, double rowH, double viewport) {
    if (_hits.isEmpty) return;
    setState(() => _lit = (_lit + step).clamp(0, _hits.length - 1));
    if (!_scroll.hasClients) return;
    final top = _lit * rowH;
    final bottom = top + rowH;
    final from = _scroll.offset;
    if (top < from) {
      _scroll.jumpTo(top);
    } else if (bottom > from + viewport) {
      _scroll.jumpTo(bottom - viewport);
    }
  }

  void _pick(int at) {
    if (at < 0 || at >= _hits.length) return;
    widget.onPick(_hits[at]);
  }

  String _text(String ru, String en) => libErrorText(widget.language, ru, en);

  @override
  Widget build(BuildContext context) {
    final font = widget.font;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final margin = min(font * 1.2, size.width * 0.03);
        final width = min(size.width - margin * 2, font * 52);
        final top = max(margin, size.height * 0.07);
        final barH = font * 3.4;
        final rowH = font * 4.2;
        final room = max(font * 6, size.height - top - margin - barH - 1);
        final natural = _hits.isEmpty ? font * 5.5 : _hits.length * rowH;
        final listH = min(room, natural + font * 0.6);
        final viewport = listH - font * 0.6;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onClose,
                child: const ColoredBox(color: Color(0xB3000000)),
              ),
            ),
            Positioned(
              top: top,
              left: (size.width - width) / 2,
              width: width,
              height: barH + 1 + listH,
              child: Focus(
                onKeyEvent: (node, event) {
                  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                    return KeyEventResult.ignored;
                  }
                  final key = event.logicalKey;
                  if (key == LogicalKeyboardKey.escape) {
                    widget.onClose();
                    return KeyEventResult.handled;
                  }
                  if (key == LogicalKeyboardKey.arrowDown) {
                    _move(1, rowH, viewport);
                    return KeyEventResult.handled;
                  }
                  if (key == LogicalKeyboardKey.arrowUp) {
                    _move(-1, rowH, viewport);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: BevelFrame(
                  color: libraryColor,
                  width: max(1.4, font * 0.12),
                  radius: font,
                  child: GrainBox(
                    tile: cellGrain,
                    opacity: modalFillOpacity,
                    child: Column(
                      children: [
                        SizedBox(
                          height: barH,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              font * 1.1,
                              0,
                              font * 0.4,
                              0,
                            ),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/actions/search.svg',
                                  width: font * 1.5,
                                  height: font * 1.5,
                                ),
                                SizedBox(width: font * 0.8),
                                Expanded(
                                  child: Semantics(
                                    textField: true,
                                    label: _text('Поиск пути', 'Path search'),
                                    child: TextField(
                                      controller: _field,
                                      focusNode: _focus,
                                      autofocus: true,
                                      cursorColor: libraryColor,
                                      style: _style(
                                        font * 1.25,
                                        const Color(0xFFFFFFFF),
                                      ),
                                      textInputAction: TextInputAction.search,
                                      decoration: InputDecoration.collapsed(
                                        hintText: _text(
                                          'Поиск пути',
                                          'Path search',
                                        ),
                                        hintStyle: _style(
                                          font * 1.25,
                                          hexMuted,
                                        ),
                                      ),
                                      onChanged: _typed,
                                      onSubmitted: (_) => _pick(_lit),
                                    ),
                                  ),
                                ),
                                CodeCloseMark(
                                  label: _text('Закрыть поиск', 'Close search'),
                                  extent: font * 2.2,
                                  onTap: widget.onClose,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(height: 1, color: const Color(0x33FFFFFF)),
                        Expanded(
                          child: _hits.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: font,
                                    ),
                                    child: Text(
                                      _asked.isEmpty
                                          ? _text(
                                              'Введите название соты или адрес',
                                              'Type the name of a cell or an address',
                                            )
                                          : _text(
                                              'Ничего не найдено по запросу «$_asked»',
                                              'No results for “$_asked”',
                                            ),
                                      textAlign: TextAlign.center,
                                      style: _style(font * 1.05, hexMuted),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scroll,
                                  padding: EdgeInsets.symmetric(
                                    vertical: font * 0.3,
                                  ),
                                  itemExtent: rowH,
                                  itemCount: _hits.length,
                                  itemBuilder: (context, i) => _Row(
                                    node: _hits[i],
                                    map: widget.map,
                                    language: widget.language,
                                    font: font,
                                    open: widget.available.contains(
                                      _hits[i].path,
                                    ),
                                    lit: i == _lit,
                                    onHover: () {
                                      if (_lit != i) setState(() => _lit = i);
                                    },
                                    onTap: () => _pick(i),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One answer: the name and the kind on the first line, the way from the home
/// screen on the second.
class _Row extends StatelessWidget {
  const _Row({
    required this.node,
    required this.map,
    required this.language,
    required this.font,
    required this.open,
    required this.lit,
    required this.onHover,
    required this.onTap,
  });

  final ScreenNode node;
  final ScreenMap map;
  final String language;
  final double font;
  final bool open;
  final bool lit;
  final VoidCallback onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = node.title(language);
    final color = treeColorOf(node, map);
    return Semantics(
      button: true,
      selected: lit,
      label: title,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onHover: (_) => onHover(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: font * 0.6,
              vertical: font * 0.15,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: lit ? const Color(0x14FFFFFF) : null,
                border: Border.all(
                  color: lit ? libraryColor : const Color(0x00000000),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: font * 0.7,
                  vertical: font * 0.3,
                ),
                child: Row(
                  children: [
                    Container(
                      width: font * 0.75,
                      height: font * 0.75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: open ? 1 : 0.45),
                      ),
                    ),
                    SizedBox(width: font * 0.7),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$title  ·  '
                            '${screenKindLabel(language, node.kind)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _style(
                              font * 1.05,
                              open
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFFA1A1AA),
                              height: 1.25,
                            ),
                          ),
                          SizedBox(height: font * 0.2),
                          Text(
                            screenRouteText(language, map, node.path),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _style(font * 0.88, hexMuted, height: 1.25),
                          ),
                        ],
                      ),
                    ),
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
