import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../account/icon_file.dart';
import '../../app_model.dart';
import '../../app_scope.dart';
import '../../features/account/account_nav.dart';
import '../../features/account/error_reader.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import 'line_cell.dart';
import 'network_chrome.dart';

class InstancePage extends StatefulWidget {
  const InstancePage({required this.url, super.key});

  final String url;

  @override
  State<InstancePage> createState() => _InstancePageState();
}

class _InstancePageState extends State<InstancePage> {
  String? _failure;
  String? _failureOn;
  var _open = false;
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = networkColor;
    final url = widget.url;
    final portrait = model.portraitOf(url);
    final target = model.target;
    final isTarget = target?.url == url;
    final owner = isTarget && (target?.ownsInstance ?? false);
    final staff = target?.managesPeers ?? false;
    final federation = model.portraitOf(target?.url ?? '')?.federation != false;
    final actions = [
      'identity',
      ...cardActions(
        isTarget: isTarget,
        owner: owner,
        staff: staff,
        federation: federation,
        telegram: portrait?.telegram == true,
        trust: model.peers[url]?.trust,
      ),
    ];
    final slots = <HexSlot>[
      for (final slot in cardBoard(actions))
        _slot(slot, model, language, color, url, owner && isTarget),
    ];
    if (_failure != null) {
      final spot = _failureOn == 'relogin'
          ? (1, 0)
          : errorSpot(slots.map((slot) => BoardSlot(slot.id, slot.q, slot.r)));
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
      child: HexScene(
        slots: slots,
        onTap: (id) => _tap(id, language, owner && isTarget),
        wrap: (slot, child) {
          if (slot.id != 'identity' || !owner) return child;
          return DropTarget(
            onDragDone: (detail) => _dropped(detail),
            child: child,
          );
        },
      ),
    );
  }

  HexSlot _slot(
    BoardSlot slot,
    AppModel model,
    String language,
    Color color,
    String url,
    bool iconEditable,
  ) {
    final portrait = model.portraitOf(url);
    final active = _busy ? const Color(0xFFFFFFFF) : color;
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
      case 'identity':
        return instanceMark(
          id: 'identity',
          url: url,
          language: language,
          q: slot.q,
          r: slot.r,
          color: color,
          current: model.target?.url == url,
          version: portrait?.version,
          image: model.iconOf(url),
          icon: iconEditable
              ? 'assets/icons/icon_load.svg'
              : 'assets/icons/instances.svg',
          tappable: iconEditable,
        );
      case 'relogin':
        return _action(
          slot,
          language,
          'Перезайти',
          'Sign in again',
          active,
          'assets/icons/reload.svg',
        );
      case 'metrics':
        return HexSlot(
          id: 'metrics',
          title: netText(language, 'Сводка', 'Summary'),
          color: color,
          q: slot.q,
          r: slot.r,
          tappable: false,
          body: MetricsCell(
            lines: [
              netText(
                language,
                'Юзеры ${portrait?.users ?? '—'}',
                'Users ${portrait?.users ?? '—'}',
              ),
              netText(
                language,
                'Устройства ${portrait?.units ?? '—'}',
                'Units ${portrait?.units ?? '—'}',
              ),
              netText(
                language,
                'Репозитории ${portrait?.repos ?? '—'}',
                'Repos ${portrait?.repos ?? '—'}',
              ),
              if (portrait?.testsStatus != null)
                '${portrait!.testsStatus} ${portrait.testsPercent?.round() ?? ''}%',
            ],
          ),
        );
      case 'target':
        return _action(
          slot,
          language,
          'Сделать Текущим',
          'Make current',
          color,
          'assets/icons/sight.svg',
        );
      case 'clear':
        return _action(
          slot,
          language,
          'Отменить выбор',
          'Clear selection',
          color,
          'assets/icons/close.svg',
        );
      case 'telegram':
        return _action(
          slot,
          language,
          'Telegram',
          'Telegram',
          active,
          'assets/icons/send.svg',
        );
      case 'settings':
        return _action(
          slot,
          language,
          'Параметры',
          'Parameters',
          color,
          'assets/icons/settings.svg',
        );
      case 'reboot':
        return _action(
          slot,
          language,
          'Перезапуск',
          'Reboot',
          active,
          'assets/icons/power.svg',
        );
      case 'tests':
        return _action(
          slot,
          language,
          'Тесты',
          'Tests',
          active,
          'assets/icons/reload.svg',
        );
      case 'trust':
        return _action(
          slot,
          language,
          'Доверять',
          'Trust',
          color,
          'assets/icons/check.svg',
        );
      case 'block':
        return _action(
          slot,
          language,
          'Блокировать',
          'Block',
          color,
          'assets/icons/ban.svg',
        );
      case 'delete':
        return _action(
          slot,
          language,
          'Удалить',
          'Delete',
          color,
          'assets/icons/close.svg',
        );
      case 'scan':
        return _action(
          slot,
          language,
          'Опрос',
          'Scan',
          active,
          'assets/icons/reload.svg',
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

  HexSlot _action(
    BoardSlot slot,
    String language,
    String ru,
    String en,
    Color color,
    String icon,
  ) {
    return HexSlot(
      id: slot.id,
      title: netText(language, ru, en),
      color: color,
      q: slot.q,
      r: slot.r,
      icon: icon,
    );
  }

  Future<void> _tap(String id, String language, bool iconEditable) async {
    final model = AppScope.of(context);
    final url = widget.url;
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'identity':
        if (iconEditable) await _pick(language);
      case 'relogin':
        if (!model.vault.hasKey) {
          setState(() {
            _failure = netText(language, 'Нет ключа', 'No key');
            _failureOn = 'relogin';
          });
          return;
        }
        await _run(() => model.resign(url), from: 'relogin');
      case 'target':
        await _run(() => model.selectTarget(url));
      case 'clear':
        await _run(model.clearTarget);
      case 'telegram':
        await _telegram();
      case 'settings':
        context.push('/peers/tune');
      case 'reboot':
        await _run(model.reboot);
      case 'tests':
        await _run(model.runIntegrationTests);
      case 'trust':
        await _run(() => model.setTrust(url, 'Trust'));
      case 'block':
        await _run(() => model.setTrust(url, 'Blocking'));
      case 'delete':
        await _run(() => model.deletePeer(url));
        if (mounted && _failure == null) popOrHome(context);
      case 'scan':
        await _run(() => model.scanPeer(url));
    }
  }

  Future<void> _telegram() async {
    final model = AppScope.of(context);
    await _run(() async {
      final link = await model.verificationLink(widget.url);
      await model.openExternal(Uri.parse(link));
    });
  }

  Future<void> _run(Future<void> Function() action, {String? from}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
      _failureOn = null;
      _open = false;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => _busy = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = '$error';
        _failureOn = from;
      });
    }
  }

  Future<void> _pick(String language) async {
    final model = AppScope.of(context);
    final bytes = await model.files.pick(
      dialogTitle: netText(language, 'Картинка инстанса', 'Instance picture'),
    );
    if (bytes == null || !mounted) return;
    await _accept(bytes);
  }

  Future<void> _dropped(DropDoneDetails detail) async {
    if (detail.files.isEmpty) return;
    final bytes = await detail.files.first.readAsBytes();
    if (!mounted) return;
    await _accept(bytes);
  }

  Future<void> _accept(Uint8List bytes) async {
    final problem = iconProblem(bytes);
    if (problem != null) {
      final language = AppScope.of(context).vault.language;
      setState(() => _failure = _iconText(problem, language));
      return;
    }
    await _run(() => AppScope.of(context).setInstanceIcon(bytes));
  }
}

String _iconText(String code, String language) {
  switch (code) {
    case 'empty':
      return netText(language, 'Файл пустой', 'The file is empty');
    case 'large':
      return netText(
        language,
        'Картинка больше 128 КБ',
        'The picture is larger than 128 KB',
      );
    case 'png':
      return netText(language, 'Нужен файл PNG', 'A PNG file is required');
    case 'size':
      return netText(
        language,
        'Нужен размер 192x192',
        'The picture must be 192x192',
      );
    default:
      return code;
  }
}
