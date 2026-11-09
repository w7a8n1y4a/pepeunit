import 'dart:convert';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_motion.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../file_drop.dart';
import '../hex_page.dart';
import 'library_menu_page.dart';

/// The tools of the Library: the README.md generator.
class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  String? _failure;
  var _failureOpen = false;
  var _busy = false;
  var _dragHot = false;
  HexEcho? _echo;

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = cardBoard(const ['readme'], wide: wide);
    final slots = [for (final slot in board) _slot(slot, language)];
    appendError(
      slots,
      message: _failure,
      open: _failureOpen,
      language: language,
      text: libErrorText,
      wide: wide,
    );
    return HexPage(
      slots: slots,
      echo: _echo,
      onTap: (id) => _tap(id, language),
      wrap: (slot, child) {
        if (slot.id != 'readme') return child;
        return FileDrop(
          enable: !_busy,
          hot: _dragHot,
          onHot: (hot) => setState(() => _dragHot = hot),
          onDrop: _dropped,
          child: child,
        );
      },
    );
  }

  HexSlot _slot(BoardSlot slot, String language) {
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: libText(language, 'Назад'),
          q: slot.q,
          r: slot.r,
        );
      default:
        return HexSlot(
          id: 'readme',
          title: libText(language, 'Генератор README'),
          color: dropColor(_dragHot, libraryColor),
          busy: _busy,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/objects/file.svg',
          center: '.md',
        );
    }
  }

  Future<void> _tap(String id, String language) async {
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _failureOpen = true);
      case 'readme':
        await _pick(language);
    }
  }

  Future<void> _pick(String language) async {
    if (_busy) return;
    final model = AppScope.of(context);
    if (!model.signedIn) {
      _fail(model.notSignedIn);
      return;
    }
    setState(() => _busy = true);
    try {
      final bytes = await model.files.pick(
        dialogTitle: libText(language, 'Выбрать pepeunit.toml'),
      );
      if (!mounted) return;
      if (bytes == null) {
        setState(() => _busy = false);
        return;
      }
      await _generate(bytes, language);
    } catch (_) {
      if (!mounted) return;
      _fail(libText(language, 'Не удалось прочитать файл'));
    }
  }

  Future<void> _dropped(DropDoneDetails detail) async {
    if (_dragHot) setState(() => _dragHot = false);
    if (_busy || detail.files.isEmpty) return;
    final model = AppScope.of(context);
    final language = model.vault.language;
    if (!model.signedIn) {
      _fail(model.notSignedIn);
      return;
    }
    setState(() => _busy = true);
    try {
      final bytes = await detail.files.first.readAsBytes();
      if (!mounted) return;
      await _generate(bytes, language);
    } catch (_) {
      if (!mounted) return;
      _fail(libText(language, 'Не удалось прочитать файл'));
    }
  }

  Future<void> _generate(Uint8List bytes, String language) async {
    final model = AppScope.of(context);
    if (bytes.isEmpty) {
      _fail(libText(language, 'Файл пустой'));
      return;
    }
    try {
      final text = await model.readmeFromToml(bytes);
      final saved = await model.saveBytes(
        'README.md',
        Uint8List.fromList(utf8.encode(text)),
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = null;
        _failureOpen = false;
        // A dismissed save dialog is not a failure and plays no echo.
        if (saved) _echo = HexEcho(ok: true);
      });
    } catch (error) {
      if (!mounted) return;
      _fail('$error');
    }
  }

  void _fail(String message) {
    setState(() {
      _busy = false;
      _failure = message;
      _failureOpen = false;
      _echo = HexEcho(ok: false);
    });
  }
}
