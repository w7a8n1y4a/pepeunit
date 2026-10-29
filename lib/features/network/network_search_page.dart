import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../instances/portrait.dart';
import '../../navigation/back.dart';
import '../hex_page.dart';
import '../line_input.dart';
import '../slanted_choices.dart';
import 'network_chrome.dart';

class NetworkSearchPage extends StatefulWidget {
  const NetworkSearchPage({required this.scope, super.key});

  final int scope;

  @override
  State<NetworkSearchPage> createState() => _NetworkSearchPageState();
}

class _NetworkSearchPageState extends State<NetworkSearchPage> {
  var _page = 0;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = networkColor;
    final urls = model.visibleInstances();
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = searchBoard(
      scope: widget.scope,
      urls: urls,
      page: _page,
      wide: wide,
    );
    final slots = [
      for (final slot in board.slots)
        _slot(slot, model, language, color, board),
    ];
    return HexPage(
      slots: slots,
      onTap: (id) => _tap(id, board),
      frame: (scene) => ScopeFrame(
        scope: widget.scope,
        canZoomIn: board.canZoomIn,
        path: '/peers/search',
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
      case 'text':
        return HexSlot(
          id: 'text',
          title: netText(language, 'Фильтр', 'Filter'),
          color: color,
          q: slot.q,
          r: slot.r,
          body: LineSearch(color: color),
        );
      case 'settings':
        return HexSlot(
          id: 'settings',
          title: netText(language, 'Настройки', 'Settings'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/settings.svg',
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
        final favorite = model.target?.url == url;
        final versionText = portrait?.version ?? '';
        final pingText = ping == null
            ? null
            : '${ping.round()} ${netText(language, 'мс', 'ms')}';
        return instanceMark(
          id: 'open:$url',
          url: url,
          language: language,
          q: slot.q,
          r: slot.r,
          color: favorite ? color : trustColor(peer?.trust, color),
          current: favorite,
          footerLeft: favorite ? null : pingText,
          version: versionText.isEmpty ? null : versionText,
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
      case 'settings':
        context.push('/peers/search/settings');
      case 'prev':
        setState(() => _page = board.page - 1);
      case 'next':
        setState(() => _page = board.page + 1);
      default:
        if (model.target?.managesPeers == true && trustStatuses.contains(id)) {
          model.toggleTrust(id);
        }
    }
  }
}

/// Combines peer search input with trust status toggles inside one cell so
/// the surrounding ring stays open for peer cards. The status words are an
/// Admin and Owner control; other roles get the field alone.
class LineSearch extends StatelessWidget {
  const LineSearch({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final staff = model.target?.managesPeers ?? false;
    return LineField(
      color: color,
      value: model.query.text,
      hint: netText(language, 'Поиск', 'Search'),
      language: language,
      activeTrust: model.query.trust,
      onChanged: model.setSearch,
      onToggleTrust: staff ? model.toggleTrust : null,
    );
  }
}

class LineField extends StatefulWidget {
  const LineField({
    required this.color,
    required this.value,
    required this.hint,
    required this.language,
    required this.onChanged,
    this.activeTrust = const {'Trust', 'Pending'},
    this.onToggleTrust,
    super.key,
  });

  final Color color;
  final String value;
  final String hint;
  final String language;
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
      final next = widget.value;
      final selection = _controller.selection;
      _controller.value = TextEditingValue(
        text: next,
        selection: selection.isValid && selection.end <= next.length
            ? selection
            : TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toggle = widget.onToggleTrust;
    return LineInput(
      color: widget.color,
      controller: _controller,
      fieldKey: const ValueKey('network-search'),
      hint: widget.hint,
      issue: '',
      leading: 'assets/icons/search.svg',
      onChanged: widget.onChanged,
      roomyCaption: toggle != null,
      caption: toggle == null
          ? null
          : _TrustWords(
              language: widget.language,
              active: widget.activeTrust,
              onToggle: toggle,
            ),
    );
  }
}

class _TrustWords extends StatelessWidget {
  const _TrustWords({
    required this.language,
    required this.active,
    required this.onToggle,
  });

  final String language;
  final Set<String> active;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final font = cellFont(constraints.maxWidth) * 1.25;
        return SlantedChoices(
          fontSize: font,
          maxWidth: searchLineWidth(constraints.maxWidth),
          choices: [
            for (final status in trustStatuses)
              SlantedChoice(
                label: trustLabel(language, status),
                selected: active.contains(status),
                onTap: () => onToggle(status),
              ),
          ],
        );
      },
    );
  }
}
