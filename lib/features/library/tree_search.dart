import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../hive/bevel.dart';
import '../../hive/hex_scene.dart';
import '../../hive/hint.dart';
import '../../library/screen_search.dart';
import '../../library/screen_tree.dart';
import '../../locale/languages.dart';
import 'library_menu_page.dart';
import 'search_panel.dart';
import 'tree_map.dart';

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
                        style: searchStyle(font * 0.95, hexMuted),
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
class TreeSearchPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SearchPanel<ScreenNode>(
      font: font,
      rowExtent: 4.2,
      fieldLabel: localized(language, 'Поиск пути', 'Path search'),
      closeLabel: localized(language, 'Закрыть поиск', 'Close search'),
      search: (text) => searchScreens(map, text, language: language),
      emptyText: (asked) => asked.isEmpty
          ? localized(
              language,
              'Введите название соты или адрес',
              'Type the name of a cell or an address',
            )
          : localized(
              language,
              'Ничего не найдено по запросу «$asked»',
              'No results for “$asked”',
            ),
      rowBuilder: (context, node, lit, onHover, onTap) => _Row(
        node: node,
        map: map,
        language: language,
        font: font,
        open: available.contains(node.path),
        lit: lit,
        onHover: onHover,
        onTap: onTap,
      ),
      onPick: onPick,
      onClose: onClose,
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
    return SearchRowFrame(
      font: font,
      lit: lit,
      label: title,
      verticalPad: 0.3,
      excludeSemantics: true,
      onHover: onHover,
      onTap: onTap,
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
                  '$title  ·  ${screenKindLabel(language, node.kind)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: searchStyle(
                    font * 1.05,
                    open ? const Color(0xFFFFFFFF) : const Color(0xFFA1A1AA),
                    height: 1.25,
                  ),
                ),
                SizedBox(height: font * 0.2),
                Text(
                  screenRouteText(language, map, node.path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: searchStyle(font * 0.88, hexMuted, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
