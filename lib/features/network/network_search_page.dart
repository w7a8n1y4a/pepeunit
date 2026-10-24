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
    final board = searchBoard(
      scope: widget.scope,
      staff: staff,
      scanAll: staff && federation && target != null,
      urls: urls,
      page: _page,
    );
    final slots = [
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
          title: netText(language, 'Строка', 'Text'),
          color: color,
          q: slot.q,
          r: slot.r,
          body: LineSearch(color: color),
        );
      case 'Trust':
      case 'Pending':
      case 'Blocking':
        return HexSlot(
          id: slot.id,
          title: slot.id,
          color: model.query.trust.contains(slot.id) ? color : hexMuted,
          q: slot.q,
          r: slot.r,
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
        return HexSlot(
          id: 'prev',
          title: netText(language, 'Предыдущие', 'Previous'),
          color: color,
          q: slot.q,
          r: slot.r,
          enabled: board.page > 0,
        );
      case 'next':
        return HexSlot(
          id: 'next',
          title: netText(language, 'Следующие', 'Next'),
          color: color,
          q: slot.q,
          r: slot.r,
          enabled: board.page + 1 < board.pages,
        );
      case 'instance':
        final url = slot.url!;
        return instanceMark(
          id: 'open:$url',
          url: url,
          language: language,
          q: slot.q,
          r: slot.r,
          color: color,
          current: false,
          version: model.portraitOf(url)?.version ?? model.peers[url]?.trust,
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
      onChanged: model.setSearch,
    );
  }
}

class LineField extends StatefulWidget {
  const LineField({
    required this.color,
    required this.value,
    required this.hint,
    required this.onChanged,
    super.key,
  });

  final Color color;
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;

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
        final font = side * 0.07;
        return Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: side * 0.16,
              vertical: side * 0.22,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: side * 0.16,
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
                SizedBox(height: side * 0.04),
                Container(height: max(1, side * 0.008), color: widget.color),
              ],
            ),
          ),
        );
      },
    );
  }
}
