import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../features/account/account_nav.dart';
import '../../features/account/error_reader.dart';
import '../../hive/hex_scene.dart';
import '../../instances/instance.dart';
import '../../instances/network_view.dart';
import 'line_cell.dart';
import 'network_chrome.dart';

class NetworkListsPage extends StatefulWidget {
  const NetworkListsPage({super.key});

  @override
  State<NetworkListsPage> createState() => _NetworkListsPageState();
}

class _NetworkListsPageState extends State<NetworkListsPage> {
  String? _failure;
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = networkColor;
    final allow = model.vault.allow.length;
    final deny = model.vault.deny.length;
    final slots = <HexSlot>[
      HexSlot(
        id: 'allow',
        title: netText(language, 'Белый список', 'Allow list'),
        footer: allow == 0 ? netText(language, 'все', 'all') : '$allow',
        color: color,
        q: -1,
        r: 1,
        icon: 'assets/icons/check.svg',
      ),
      HexSlot(
        id: 'deny',
        title: netText(language, 'Чёрный список', 'Deny list'),
        footer: '$deny',
        color: color,
        q: 0,
        r: 1,
        icon: 'assets/icons/ban.svg',
      ),
      HexSlot(
        id: 'pin',
        title: netText(language, 'Добавить адрес', 'Add address'),
        color: color,
        q: 0,
        r: -1,
        body: LineCell(hint: 'host', color: color, onSubmit: _pin),
      ),
      HexSlot(
        id: 'back',
        title: netText(language, 'Назад', 'Back'),
        color: hexMuted,
        q: 0,
        r: 0,
        icon: 'assets/icons/back.svg',
      ),
    ];
    if (_failure != null) {
      slots.add(
        HexSlot(
          id: 'error',
          title: netText(language, 'Ошибка', 'Error'),
          color: errorColor,
          titleColor: errorColor,
          q: 1,
          r: -1,
          icon: 'assets/icons/error.svg',
          iconScale: 1.2,
          body: _open
              ? ErrorCell(
                  message: _failure!,
                  copyLabel: netText(language, 'Скопировать', 'Copy'),
                )
              : null,
        ),
      );
    }
    return ColoredBox(
      color: sceneBackground,
      child: HexScene(
        slots: slots,
        onTap: (id) {
          switch (id) {
            case 'back':
              popOrHome(context);
            case 'allow':
              context.push('/peers/allow');
            case 'deny':
              context.push('/peers/deny');
            case 'error':
              setState(() => _open = true);
          }
        },
      ),
    );
  }

  Future<void> _pin(String value) async {
    try {
      await AppScope.of(context).pin(value);
      if (!mounted) return;
      setState(() {
        _failure = null;
        _open = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _failure = '$error';
        _open = false;
      });
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
    final board = catalogBoard(
      scope: widget.scope,
      urls: model.catalog(),
      page: _page,
    );
    final slots = <HexSlot>[
      for (final slot in board.slots)
        _slot(slot, model, language, color, board),
    ];
    if (_failure != null) {
      final spot = errorSpot(board.slots);
      slots.add(
        HexSlot(
          id: 'error',
          title: netText(language, 'Ошибка', 'Error'),
          color: errorColor,
          titleColor: errorColor,
          q: spot.$1,
          r: spot.$2,
          icon: 'assets/icons/error.svg',
          iconScale: 1.2,
          body: _open
              ? ErrorCell(
                  message: _failure!,
                  copyLabel: netText(language, 'Скопировать', 'Copy'),
                )
              : null,
        ),
      );
    }
    final path = widget.deny ? '/peers/deny' : '/peers/allow';
    return ColoredBox(
      color: sceneBackground,
      child: ScopeFrame(
        scope: widget.scope,
        canZoomIn: board.canZoomIn,
        path: path,
        child: HexScene(slots: slots, onTap: (id) => _tap(id, board)),
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
        return HexSlot(
          id: 'back',
          title: netText(language, 'Назад', 'Back'),
          color: hexMuted,
          q: 0,
          r: 0,
          icon: 'assets/icons/back.svg',
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
          icon: model.iconOf(url) == null ? 'assets/icons/instances.svg' : null,
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
