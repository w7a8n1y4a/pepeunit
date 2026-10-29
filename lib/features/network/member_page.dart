import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/directory_user.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../hex_page.dart';
import 'network_chrome.dart';

class MemberPage extends StatefulWidget {
  const MemberPage({required this.uuid, super.key});

  final String uuid;

  @override
  State<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage> {
  DirectoryUser? _user;
  String? _failure;
  var _open = false;
  String? _pending;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = networkColor;
    final target = model.target;
    final user = _user;
    final actions = user == null
        ? const <String>['card']
        : memberActions(
            owner: target?.ownsInstance ?? false,
            staff: target?.managesPeers ?? false,
            role: user.role,
            status: user.status,
          );
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(actions, wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        _slot(slot, language, color, user, model.cachedIcon(user?.iconUuid)),
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: netText,
      wide: wide,
    );
    return HexPage(slots: slots, onTap: (id) => _tap(id, language));
  }

  HexSlot _slot(
    BoardSlot slot,
    String language,
    Color color,
    DirectoryUser? user,
    Uint8List? image,
  ) {
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: netText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'card':
        if (user == null) {
          return HexSlot(
            id: 'card',
            title: netText(language, 'Пользователь', 'User'),
            color: color,
            busy: _loading,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/account.svg',
            tappable: false,
          );
        }
        return userMark(
          id: 'card',
          user: user,
          language: language,
          q: slot.q,
          r: slot.r,
          accent: color,
          image: image,
          tappable: false,
          busy: _loading,
        );
      case 'grant':
        return _action(
          slot,
          language,
          'Назначить админом',
          'Make admin',
          color,
          'assets/icons/admin.svg',
        );
      case 'revoke':
        return _action(
          slot,
          language,
          'Снять админа',
          'Remove admin',
          errorColor,
          'assets/icons/demote.svg',
        );
      case 'block':
        return _action(
          slot,
          language,
          'Заблокировать',
          'Block',
          errorColor,
          'assets/icons/ban.svg',
        );
      case 'unblock':
        return _action(
          slot,
          language,
          'Разблокировать',
          'Unblock',
          color,
          'assets/icons/check.svg',
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
      busy: _pending == slot.id,
      q: slot.q,
      r: slot.r,
      icon: icon,
    );
  }

  Future<void> _tap(String id, String language) async {
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'grant':
        await _run('grant', (model, uuid) => model.grantMember(uuid));
      case 'revoke':
        await _run('revoke', (model, uuid) => model.revokeMember(uuid));
      case 'block':
        await _run('block', (model, uuid) => model.blockMember(uuid));
      case 'unblock':
        await _run('unblock', (model, uuid) => model.unblockMember(uuid));
    }
  }

  Future<void> _load() async {
    final model = AppScope.of(context);
    final language = model.vault.language;
    if (widget.uuid.isEmpty) {
      setState(() {
        _loading = false;
        _failure = netText(language, 'Нет пользователя', 'No user');
      });
      return;
    }
    if (model.target?.signedIn != true) {
      setState(() {
        _loading = false;
        _failure = netText(language, 'Нет входа', 'Not signed in');
      });
      return;
    }
    try {
      final user = await model.readMember(widget.uuid);
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
        _failure = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failure = '$error';
      });
    }
  }

  Future<void> _run(
    String id,
    Future<DirectoryUser> Function(AppModel model, String uuid) action,
  ) async {
    if (_pending != null) return;
    setState(() {
      _pending = id;
      _failure = null;
      _open = false;
    });
    try {
      final user = await action(AppScope.of(context), widget.uuid);
      if (!mounted) return;
      setState(() {
        _user = user;
        _pending = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
    }
  }
}
