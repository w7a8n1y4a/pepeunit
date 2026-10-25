import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../features/account/account_nav.dart';
import '../../features/account/error_reader.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../instances/portrait.dart';
import 'network_chrome.dart';

class NetworkSearchPage extends StatefulWidget {
  const NetworkSearchPage({required this.scope, super.key});

  final int scope;

  @override
  State<NetworkSearchPage> createState() => _NetworkSearchPageState();
}

class _NetworkSearchPageState extends State<NetworkSearchPage> {
  var _page = 0;
  String? _failure;
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = networkColor;
    final target = model.target;
    final staff = target?.managesPeers ?? false;
    final federation = model.portraitOf(target?.url ?? '')?.federation != false;
    final urls = [
      for (final url in model.visibleInstances())
        if (url != target?.url) url,
    ];
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = searchBoard(
      scope: widget.scope,
      staff: staff,
      scanAll: staff && federation && target != null,
      urls: urls,
      page: _page,
      wide: wide,
    );
    final slots = [
      for (final slot in board.slots)
        _slot(slot, model, language, color, board),
    ];
    if (_failure != null) {
      final spot = errorSpot(board.slots, wide: wide);
      slots.add(
        HexSlot(
          id: 'error',
          title: netText(language, 'Ошибка', 'Error'),
          color: errorColor,
          titleColor: errorColor,
          q: spot.$1,
          r: spot.$2,
          icon: 'assets/icons/error.svg',
          iconScale: 1.62,
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
      child: ScopeFrame(
        scope: widget.scope,
        canZoomIn: board.canZoomIn,
        path: '/peers/search',
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
    final busy = model.networkBusy ? const Color(0xFFFFFFFF) : color;
    switch (slot.id) {
      case 'back':
        return HexSlot(
          id: 'back',
          title: netText(language, 'Назад', 'Back'),
          color: hexMuted,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/back.svg',
        );
      case 'text':
        return HexSlot(
          id: 'text',
          title: netText(language, 'Фильтр', 'Filter'),
          color: color,
          q: slot.q,
          r: slot.r,
          body: LineSearch(color: color),
        );
      case 'add':
        return HexSlot(
          id: 'add',
          title: netText(language, 'Добавить', 'Add'),
          color: busy,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/plus.svg',
        );
      case 'scan-all':
        return HexSlot(
          id: 'scan-all',
          title: netText(language, 'Опросить все', 'Scan all'),
          color: busy,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/reload.svg',
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
      case 'instance':
        final url = slot.url!;
        final peer = model.peers[url];
        final portrait = model.portraitOf(url);
        final ping = peer?.lastPing;
        final String? leftCaption;
        if (peer != null && peer.trust != 'Trust') {
          leftCaption = trustLabel(language, peer.trust);
        } else if (ping != null) {
          leftCaption = '${ping.round()} ${netText(language, 'мс', 'ms')}';
        } else {
          leftCaption = null;
        }
        return instanceMark(
          id: 'open:$url',
          url: url,
          language: language,
          q: slot.q,
          r: slot.r,
          color: trustColor(peer?.trust, color),
          current: false,
          footerLeft: leftCaption,
          footerLeftColor: trustColor(peer?.trust, const Color(0xFFFFFFFF)),
          version: portrait?.version ?? peer?.trust,
          image: model.iconOf(url),
        );
      default:
        return HexSlot(
          id: slot.id,
          title: slot.id,
          color: color,
          q: slot.q,
          r: slot.r,
        );
    }
  }

  Future<void> _tap(String id, NetworkBoard board) async {
    final model = AppScope.of(context);
    if (id.startsWith('open:')) {
      final url = id.substring(5);
      context.push('/peers/instance?url=${Uri.encodeQueryComponent(url)}');
      return;
    }
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'add':
        context.push('/peers/add');
      case 'error':
        setState(() => _open = true);
      case 'prev':
        setState(() => _page = board.page - 1);
      case 'next':
        setState(() => _page = board.page + 1);
      case 'scan-all':
        await _scan(model);
      default:
        if (trustStatuses.contains(id)) model.toggleTrust(id);
    }
  }

  Future<void> _scan(AppModel model) async {
    setState(() {
      _failure = null;
      _open = false;
    });
    try {
      await model.scanAll();
    } catch (error) {
      if (!mounted) return;
      setState(() => _failure = '$error');
    }
  }
}

/// Combines host search input and the three trust status toggles inside one
/// cell so the surrounding ring stays open for peer cards.
class LineSearch extends StatelessWidget {
  const LineSearch({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    return LineField(
      color: color,
      value: model.query.text,
      hint: netText(model.vault.language, 'хост', 'host'),
      activeTrust: model.query.trust,
      onChanged: model.setSearch,
      onToggleTrust: model.toggleTrust,
    );
  }
}

class LineField extends StatefulWidget {
  const LineField({
    required this.color,
    required this.value,
    required this.hint,
    required this.onChanged,
    this.activeTrust = const {'Trust', 'Pending', 'Blocking'},
    this.onToggleTrust,
    super.key,
  });

  final Color color;
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;
  final Set<String> activeTrust;
  final ValueChanged<String>? onToggleTrust;

  @override
  State<LineField> createState() => _LineFieldState();
}

class _LineFieldState extends State<LineField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(LineField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final font = max(10.0, side * 0.068);
        final chipFont = max(8.5, side * 0.052);
        return Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              side * 0.14,
              side * 0.24,
              side * 0.14,
              side * 0.16,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: side * 0.15,
                  child: TextField(
                    key: const ValueKey('network-search'),
                    controller: _controller,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFFFFFFF),
                      fontFamily: 'OpenGost Type B',
                      fontSize: font,
                      height: 1,
                      decoration: TextDecoration.none,
                    ),
                    cursorColor: widget.color,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: widget.hint,
                      hintStyle: TextStyle(
                        color: hexMuted,
                        fontFamily: 'OpenGost Type B',
                        fontSize: font,
                        height: 1,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: widget.onChanged,
                  ),
                ),
                SizedBox(height: side * 0.025),
                Container(height: max(1, side * 0.008), color: widget.color),
                if (widget.onToggleTrust != null) ...[
                  SizedBox(height: side * 0.045),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final status in trustStatuses)
                        _TrustToggle(
                          status: status,
                          shortLabel: _shortTrust(status),
                          selected: widget.activeTrust.contains(status),
                          color: widget.color,
                          fontSize: chipFont,
                          onTap: () => widget.onToggleTrust!(status),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _shortTrust(String status) {
    switch (status) {
      case 'Trust':
        return 'T';
      case 'Pending':
        return 'P';
      case 'Blocking':
        return 'B';
      default:
        return status;
    }
  }
}

class _TrustToggle extends StatelessWidget {
  const _TrustToggle({
    required this.status,
    required this.shortLabel,
    required this.selected,
    required this.color,
    required this.fontSize,
    required this.onTap,
  });

  final String status;
  final String shortLabel;
  final bool selected;
  final Color color;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: status,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? color : hexMuted, width: 1.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            shortLabel,
            style: TextStyle(
              color: selected ? const Color(0xFFFFFFFF) : hexMuted,
              fontFamily: 'OpenGost Type B',
              fontSize: fontSize,
              height: 1.05,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
