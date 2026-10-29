import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../account/login_name.dart';
import '../../app_scope.dart';
import '../../locale/languages.dart';
import '../line_input.dart';

/// The login field. A valid value is stored as it is typed.
class LoginCell extends StatefulWidget {
  const LoginCell({required this.color, super.key});

  final Color color;

  @override
  State<LoginCell> createState() => _LoginCellState();
}

class _LoginCellState extends State<LoginCell> {
  late final TextEditingController _controller;
  var _rejected = false;
  var _loaded = false;
  var _shown = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final login = AppScope.of(context).vault.login;
    if (!_loaded) {
      _loaded = true;
      _shown = login;
      _controller = TextEditingController(text: login);
      return;
    }
    if (login == _shown) return;
    _shown = login;
    _rejected = false;
    if (_controller.text == login) return;
    _controller.value = TextEditingValue(
      text: login,
      selection: TextSelection.collapsed(offset: login.length),
    );
  }

  @override
  void dispose() {
    if (_loaded) _controller.dispose();
    super.dispose();
  }

  void _reject(bool rejected) {
    if (_rejected == rejected) return;
    setState(() => _rejected = rejected);
  }

  void _changed(String text) {
    setState(() {});
    if (!loginStorable(text)) return;
    AppScope.of(context).setLogin(text);
  }

  String? _issue(String language) {
    final text = _loaded ? _controller.text : '';
    if (text.isNotEmpty && text.length < loginMin) {
      return phrase(language, {
        'ru': 'От 4 до 20 символов',
        'en': '4 to 20 characters',
      });
    }
    if (_rejected) {
      return phrase(language, {
        'ru': 'Недопустимый символ',
        'en': 'Character not allowed',
      });
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    return LineInput(
      color: widget.color,
      controller: _controller,
      fieldKey: const ValueKey('login-field'),
      issue: _issue(language) ?? '',
      inputFormatters: [_LoginFormatter(_reject)],
      onChanged: _changed,
      blink: true,
    );
  }
}

class _LoginFormatter extends TextInputFormatter {
  _LoginFormatter(this.onReject);

  final ValueChanged<bool> onReject;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = cleanLogin(newValue.text);
    final rejected = cleaned != newValue.text;
    onReject(rejected);
    if (!rejected) return newValue;
    final offset = min(newValue.selection.end, cleaned.length);
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: max(0, offset)),
    );
  }
}
