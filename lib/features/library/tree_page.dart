import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../library/screen_search.dart';
import '../../library/screen_tree.dart';
import '../../locale/languages.dart';
import '../code/code_modal.dart';
import 'library_menu_page.dart';
import 'tip_modal.dart';
import 'tree_map.dart';
import 'tree_search.dart';

const treePath = '/library/tree';

/// Address of the tree with [node] picked. The home screen is the default and
/// stays out of the query.
String treeLocation(String node) {
  return Uri(
    path: treePath,
    queryParameters: node == screenRoot ? null : {'node': node},
  ).toString();
}

String _t(String language, String ru, String en) =>
    phrase(language, {'ru': ru, 'en': en});

/// Whether this session may go to [node]: its section is open on the chosen
/// instance, and the account has what the row asks. A creator is told apart
/// by the record, which the tree does not know, so a signed-in account passes.
bool treeAccess(
  ScreenNode node,
  ScreenMap map, {
  required bool hasTarget,
  required bool signedIn,
  String? role,
  bool? notifications,
  bool? grafana,
}) {
  if (node.section.isNotEmpty &&
      !menuSectionEnabled(
        node.section,
        hasTarget: hasTarget,
        signedIn: signedIn,
        notifications: notifications,
        grafana: grafana,
      )) {
    return false;
  }
  switch (map.needOf(node.path)) {
    case ScreenNeed.open:
      return true;
    case ScreenNeed.signedIn:
    case ScreenNeed.creator:
      return signedIn;
    case ScreenNeed.staff:
      return signedIn && (role == 'Admin' || role == 'Owner');
    case ScreenNeed.owner:
      return signedIn && role == 'Owner';
  }
}

/// Why a row is closed, in a few words, or null when it is open.
String? _closedWhy(String language, ScreenNode node, ScreenMap map) {
  final need = map.needOf(node.path);
  if (need == ScreenNeed.open) {
    return switch (node.section) {
      'alerts' => _t(
        language,
        'нужны вход и включённые уведомления',
        'a sign-in and enabled alerts are needed',
      ),
      _ => _t(language, 'нужен выбранный экземпляр', 'a chosen instance'),
    };
  }
  return screenNeedLabel(language, need).toLowerCase();
}

/// The card of a row as markdown: a few short lines, not a document.
String treeCardText(
  String language,
  ScreenNode node,
  ScreenMap map, {
  required bool available,
}) {
  final lines = <String>[
    '`${node.screenPath}`',
    '',
    '- ${_t(language, 'Вид', 'Kind')}: ${screenKindLabel(language, node.kind)}',
  ];
  if (node.path != screenRoot) {
    lines.add(
      '- ${_t(language, 'Путь', 'Path')}: '
      '${screenRouteText(language, map, node.path)}',
    );
  }
  if (node.isCell) {
    final screen = map.node(node.screenPath);
    if (screen != null) {
      lines.add(
        '- ${_t(language, 'На экране', 'On the screen')}: '
        '${screen.title(language)}',
      );
    }
  }
  lines.add(
    '- ${_t(language, 'Доступ', 'Access')}: ${available ? _t(language, 'есть', 'yes') : _t(language, 'нет', 'no')}'
    '${available ? '' : ', ${_closedWhy(language, node, map)}'}',
  );
  final inside = map.childrenOf(node.path);
  if (inside.isNotEmpty) {
    final shown = inside.take(8).map((item) => item.title(language));
    lines.add(
      '- ${_t(language, 'Внутри', 'Inside')}: ${shown.join(', ')}'
      '${inside.length > 8 ? ', …' : ''}',
    );
  }
  if (!node.isCell && !node.open) {
    lines.add(
      '- ${_t(language, 'Открывается только через родителя: нужна запись или данные предыдущего экрана.', 'Opens only through its parent: it needs a record or the data of the screen before it.')}',
    );
  }
  return lines.join('\n');
}

/// The tree of 6 paths: every screen and cell of the client on one full
/// screen: the round map (`ScreenTreeMap`), a switch of what it shows (all,
/// available, closed) at the bottom right, the path search, Fit and Close on
/// top. A picked row, by a tap or by the search, wears the way from the home
/// screen drawn white. A tap on a row opens its small card; the card offers Open for
/// a screen that really opens. `?node=` opens the page with a row already
/// picked.
class TreePage extends StatefulWidget {
  const TreePage({required this.node, super.key});

  /// Address of the picked row. An unknown one picks nothing.
  final String node;

  @override
  State<TreePage> createState() => _TreePageState();
}

class _TreePageState extends State<TreePage> {
  final _mapKey = GlobalKey<ScreenTreeMapState>();
  late ScreenNode? _picked = widget.node == screenRoot
      ? null
      : screenMap.node(widget.node);

  /// The row whose small card is open. Closing the card keeps the pick.
  late ScreenNode? _card = _picked;

  /// Whether the modal of the path search is open.
  var _searching = false;
  var _show = TreeShow.all;
  String? _openedFor;
  var _available = <String>{};

  /// A row chosen in the search: the modal closes, the map moves to the row
  /// and draws the way to it, and the card of the row stays closed.
  void _found(ScreenNode node) {
    setState(() {
      _picked = node;
      _card = null;
      _searching = false;
    });
    _mapKey.currentState?.focus(node.path);
  }

  Set<String> _reach() {
    final model = AppScope.of(context);
    final target = model.target;
    final key =
        '${target != null}|${target?.signedIn}|${target?.role}|'
        '${target?.notifications}|${target?.grafana}';
    if (key == _openedFor) return _available;
    _openedFor = key;
    return _available = {
      for (final node in screenMap.nodes)
        if (treeAccess(
          node,
          screenMap,
          hasTarget: target != null,
          signedIn: target?.signedIn ?? false,
          role: target?.role,
          notifications: target?.notifications,
          grafana: target?.grafana,
        ))
          node.path,
    };
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final available = _reach();
    final card = _card;
    final picked = _picked;
    final size = MediaQuery.sizeOf(context);
    final font = max(12.0, size.shortestSide * 0.018);
    final total = screenMap.nodes.length;
    final yes = available.length;
    Widget chip(TreeShow show, String label, int count, String hint) {
      return CodeChip(
        label: '$label $count',
        on: _show == show,
        font: font,
        color: libraryColor,
        onTap: () => setState(() => _show = show),
        hint: hint,
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: ScreenTreeMap(
              key: _mapKey,
              map: screenMap,
              language: language,
              selected: picked?.path,
              available: available,
              show: _show,
              onSelect: (node) => setState(() {
                _picked = node;
                _card = node;
              }),
            ),
          ),
          Positioned(
            left: font,
            right: font * 0.6,
            top: font * 0.8,
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: font * 16),
                      child: TreeSearchPill(
                        label: _t(language, 'Поиск пути', 'Path search'),
                        font: font,
                        onTap: () => setState(() {
                          _card = null;
                          _searching = true;
                        }),
                      ),
                    ),
                  ),
                ),
                CodeWordButton(
                  label: _t(language, 'Целиком', 'Fit'),
                  font: font,
                  onTap: () => _mapKey.currentState?.fit(),
                  hint: 'button-tree-fit',
                ),
                CodeCloseMark(
                  label: _t(language, 'Закрыть', 'Close'),
                  extent: font * 2.2,
                  onTap: () => closeLibrary(context, '/library'),
                ),
              ],
            ),
          ),
          Positioned(
            left: font,
            right: font,
            bottom: font * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  alignment: WrapAlignment.end,
                  children: [
                    chip(
                      TreeShow.all,
                      _t(language, 'Все', 'All'),
                      total,
                      'button-tree-show-all',
                    ),
                    chip(
                      TreeShow.yes,
                      _t(language, 'Доступные', 'Available'),
                      yes,
                      'button-tree-show-yes',
                    ),
                    chip(
                      TreeShow.no,
                      _t(language, 'Недоступные', 'Closed'),
                      total - yes,
                      'button-tree-show-no',
                    ),
                  ],
                ),
                SizedBox(height: font * 0.3),
                SizedBox(
                  width: double.infinity,
                  child: IgnorePointer(
                    child: Text(
                      picked != null && picked.path != screenRoot
                          ? screenRouteText(language, screenMap, picked.path)
                          : _t(
                              language,
                              'Заливка: открывается по адресу. Малая сота: кнопка или поле экрана. Тусклая: закрыта для этой сессии.',
                              'Filled: opens from its address. Small: a button or a field of a screen. Dim: closed for this session.',
                            ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hexMuted,
                        fontFamily: 'OpenGost Type B',
                        fontSize: font * 0.85,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (card != null) _cardPanel(card, language, available),
          if (_searching)
            Positioned.fill(
              child: TreeSearchPanel(
                map: screenMap,
                language: language,
                font: font,
                available: available,
                onPick: _found,
                onClose: () => setState(() => _searching = false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cardPanel(ScreenNode card, String language, Set<String> available) {
    final map = screenMap;
    final yes = available.contains(card.path);
    return TipModal(
      title: card.title(language),
      color: treeColorOf(card, map),
      source: treeCardText(language, card, map, available: yes),
      onClose: () => setState(() => _card = null),
      actions: (font) => [
        if (!card.isCell && card.open && yes && card.path != treePath)
          CodeWordButton(
            label: _t(language, 'Открыть', 'Open'),
            font: font,
            onTap: () => context.push(card.path),
            hint: 'button-tree-open',
          ),
      ],
    );
  }
}
