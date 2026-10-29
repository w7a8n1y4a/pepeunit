import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/instance.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../hex_page.dart';
import 'network_chrome.dart';

/// Search settings: allow list, deny list, then local add.
///
/// Back stays in the center. Local add is available to every role.
class NetworkSearchSettingsPage extends StatelessWidget {
  const NetworkSearchSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = networkColor;
    final allow = model.vault.allow.length;
    final deny = model.vault.deny.length;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final ids = <String>['allow', 'deny', 'add'];
    final frame = hexFrame(count: ids.length, back: HexBack.center, wide: wide);
    final back = frame.back!;
    final slots = <HexSlot>[
      for (var i = 0; i < ids.length; i++)
        _slot(ids[i], frame.cells[i], language, color, allow, deny),
      backSlot(
        title: netText(language, 'Назад', 'Back'),
        q: back.$1,
        r: back.$2,
      ),
    ];
    return HexPage(
      slots: slots,
      onTap: (id) {
        switch (id) {
          case 'back':
            popOrHome(context);
          case 'add':
            context.push('/peers/add');
          case 'allow':
            context.push('/peers/allow');
          case 'deny':
            context.push('/peers/deny');
        }
      },
    );
  }

  HexSlot _slot(
    String id,
    (int, int) at,
    String language,
    Color color,
    int allow,
    int deny,
  ) {
    switch (id) {
      case 'add':
        return HexSlot(
          id: 'add',
          title: netText(language, 'Добавить локально', 'Add locally'),
          color: color,
          q: at.$1,
          r: at.$2,
          icon: 'assets/icons/plus.svg',
        );
      case 'allow':
        return HexSlot(
          id: 'allow',
          title: netText(language, 'Белый список', 'Allow list'),
          footer: allow == 0 ? netText(language, 'все', 'all') : '$allow',
          color: color,
          q: at.$1,
          r: at.$2,
          icon: 'assets/icons/check.svg',
        );
      case 'deny':
        return HexSlot(
          id: 'deny',
          title: netText(language, 'Чёрный список', 'Deny list'),
          footer: '$deny',
          color: color,
          q: at.$1,
          r: at.$2,
          icon: 'assets/icons/ban.svg',
        );
      default:
        return HexSlot(id: id, title: id, color: color, q: at.$1, r: at.$2);
    }
  }
}

class NetworkListPage extends StatefulWidget {
  const NetworkListPage({required this.deny, required this.scope, super.key});

  final bool deny;
  final int scope;

  @override
  State<NetworkListPage> createState() => _NetworkListPageState();
}

class _NetworkListPageState extends State<NetworkListPage> {
  var _page = 0;
  String? _failure;
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = networkColor;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = catalogBoard(
      tick: widget.scope,
      urls: model.catalog(),
      page: _page,
      wide: wide,
    );
    final slots = <HexSlot>[
      for (final slot in board.slots)
        _slot(slot, model, language, color, board),
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: netText,
      wide: wide,
    );
    final path = widget.deny ? '/peers/deny' : '/peers/allow';
    return HexPage(
      slots: slots,
      onTap: (id) => _tap(id, board),
      frame: (scene) => ScopeFrame(
        scope: widget.scope,
        canZoomIn: board.canZoomIn,
        path: path,
        child: scene,
      ),
    );
  }

  HexSlot _slot(
    BoardSlot slot,
    AppModel model,
    String language,
    Color color,
    NetworkBoard board,
  ) {
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: netText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'prev':
        return pageStepSlot(
          id: 'prev',
          left: true,
          language: language,
          color: color,
          q: slot.q,
          r: slot.r,
          page: board.page,
          pages: board.pages,
          enabled: board.page > 0,
          onTap: () => setState(() => _page = board.page - 1),
        );
      case 'next':
        return pageStepSlot(
          id: 'next',
          left: false,
          language: language,
          color: color,
          q: slot.q,
          r: slot.r,
          page: board.page,
          pages: board.pages,
          enabled: board.page + 1 < board.pages,
          onTap: () => setState(() => _page = board.page + 1),
        );
      default:
        final url = slot.url!;
        final listed = widget.deny
            ? model.vault.deny.contains(url)
            : model.vault.allow.contains(url);
        return HexSlot(
          id: 'url:$url',
          title: instanceHost(url),
          footer: listed ? netText(language, 'в списке', 'listed') : null,
          color: listed ? const Color(0xFFFFFFFF) : color,
          q: slot.q,
          r: slot.r,
          icon: model.iconOf(url) == null ? 'assets/icons/instance.svg' : null,
          image: model.iconOf(url),
        );
    }
  }

  Future<void> _tap(String id, NetworkBoard board) async {
    final model = AppScope.of(context);
    switch (id) {
      case 'back':
        popOrHome(context);
        return;
      case 'error':
        setState(() => _open = true);
        return;
      case 'prev':
        setState(() => _page = board.page - 1);
        return;
      case 'next':
        setState(() => _page = board.page + 1);
        return;
    }
    if (!id.startsWith('url:')) return;
    final url = id.substring(4);
    try {
      final listed = widget.deny
          ? model.vault.deny.contains(url)
          : model.vault.allow.contains(url);
      if (listed) {
        await model.forgetList(url, deny: widget.deny);
      } else if (widget.deny) {
        await model.denyInstance(url);
      } else {
        await model.allowInstance(url);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _failure = '$error';
        _open = false;
      });
    }
  }
}
