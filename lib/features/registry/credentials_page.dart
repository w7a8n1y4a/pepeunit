import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../registry/repo.dart';
import '../hex_page.dart';
import '../line_input.dart';
import 'registry_chrome.dart';

class CredentialsPage extends StatefulWidget {
  const CredentialsPage({required this.uuid, super.key});

  final String uuid;

  @override
  State<CredentialsPage> createState() => _CredentialsPageState();
}

class _CredentialsPageState extends State<CredentialsPage> {
  final _name = TextEditingController();
  final _token = TextEditingController();
  final _nameFocus = FocusNode();
  final _tokenFocus = FocusNode();
  String? _status;
  String? _failure;
  var _open = false;
  String? _pending;
  var _loading = true;
  var _revision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _name.dispose();
    _token.dispose();
    _nameFocus.dispose();
    _tokenFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = registryColor;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(const ['name', 'token'], wide: wide);
    final status = credentialStatusLabel(language, _status ?? '');
    final slots = <HexSlot>[
      for (final slot in placed)
        switch (slot.id) {
          'back' => backSlot(
            title: regText(language, 'Назад', 'Back'),
            q: slot.q,
            r: slot.r,
          ),
          'name' => HexSlot(
            id: 'name',
            title: regText(language, 'Имя', 'Name'),
            color: color,
            busy: _loading || _pending == 'name',
            q: slot.q,
            r: slot.r,
            tappable: false,
            body: _Field(
              color: color,
              controller: _name,
              focusNode: _nameFocus,
              fieldKey: const ValueKey('repo-name'),
              hint: regText(language, 'имя', 'name'),
              language: language,
              revision: _revision,
              onSubmit: () => _save('name'),
            ),
          ),
          'token' => HexSlot(
            id: 'token',
            title: regText(language, 'Токен', 'Token'),
            footer: status.isEmpty ? null : status,
            footerColor: _status == 'Error'
                ? errorColor
                : const Color(0xFFFFFFFF),
            color: color,
            busy: _loading || _pending == 'token',
            q: slot.q,
            r: slot.r,
            tappable: false,
            body: _Field(
              color: color,
              controller: _token,
              focusNode: _tokenFocus,
              fieldKey: const ValueKey('repo-token'),
              hint: regText(language, 'токен', 'token'),
              language: language,
              revision: _revision,
              onSubmit: () => _save('token'),
            ),
          ),
          _ => HexSlot(
            id: slot.id,
            title: slot.id,
            color: color,
            q: slot.q,
            r: slot.r,
          ),
        },
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: regText,
      wide: wide,
    );
    return HexPage(
      slots: slots,
      onTap: (id) {
        switch (id) {
          case 'back':
            popOrHome(context);
          case 'error':
            setState(() => _open = true);
        }
      },
    );
  }

  Future<void> _load() async {
    final model = AppScope.of(context);
    final language = model.vault.language;
    if (model.target?.signedIn != true) {
      setState(() {
        _loading = false;
        _failure = regText(language, 'Нет входа', 'Not signed in');
      });
      return;
    }
    setState(() {
      _loading = true;
      _failure = null;
      _open = false;
    });
    try {
      final credentials = await model.readRepoCredentials(widget.uuid);
      if (!mounted) return;
      if (!_nameFocus.hasFocus) _name.text = credentials?.username ?? '';
      if (!_tokenFocus.hasFocus) _token.text = credentials?.token ?? '';
      setState(() {
        _status = credentials?.status;
        _loading = false;
        _revision++;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failure = '$error';
      });
    }
  }

  Future<void> _save(String field) async {
    if (_pending != null) return;
    final model = AppScope.of(context);
    final language = model.vault.language;
    final username = _name.text.trim();
    final pat = _token.text.trim();
    if (username.isEmpty || pat.isEmpty) {
      setState(() {
        _failure = regText(
          language,
          'Нужны имя и токен',
          'Name and token are required',
        );
        _open = false;
      });
      return;
    }
    setState(() {
      _pending = field;
      _failure = null;
      _open = false;
    });
    try {
      await model.saveRepoCredentials(widget.uuid, username, pat);
      if (!mounted) return;
      setState(() => _pending = null);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
    }
  }
}

class _Field extends StatefulWidget {
  const _Field({
    required this.color,
    required this.controller,
    required this.focusNode,
    required this.fieldKey,
    required this.hint,
    required this.language,
    required this.revision,
    required this.onSubmit,
  });

  final Color color;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Key fieldKey;
  final String hint;
  final String language;
  final int revision;
  final VoidCallback onSubmit;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  var _dirty = false;

  @override
  void didUpdateWidget(_Field oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revision != oldWidget.revision) _dirty = false;
  }

  @override
  Widget build(BuildContext context) {
    final ready = widget.controller.text.trim().isNotEmpty;
    return LineInput(
      color: widget.color,
      controller: widget.controller,
      focusNode: widget.focusNode,
      fieldKey: widget.fieldKey,
      hint: widget.hint,
      issue: '',
      lineColor: _dirty ? const Color(0xFFFFFFFF) : widget.color,
      caption: _dirty && ready ? _ok() : null,
      onChanged: (_) {
        if (!_dirty) setState(() => _dirty = true);
      },
      onSubmitted: (_) => widget.onSubmit(),
    );
  }

  Widget _ok() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final band = constraints.maxHeight;
        final font = band.isFinite
            ? (band * 0.42).clamp(10.0, 18.0).toDouble()
            : 14.0;
        return Semantics(
          button: true,
          label: regText(widget.language, 'Сохранить', 'Save'),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onSubmit,
            child: HoverPop(
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: widget.color,
                    fontFamily: 'OpenGost Type B',
                    fontSize: font,
                    height: 1,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
