import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../account/login_name.dart';
import '../../app_scope.dart';
import '../../locale/languages.dart';

/// The login field. A valid value is stored as it is typed.
class LoginCell extends StatefulWidget {
  const LoginCell({required this.color, super.key});

  final Color color;

  @override
  State<LoginCell> createState() => _LoginCellState();
}

class _LoginCellState extends State<LoginCell>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  late final AnimationController _blink;
  var _rejected = false;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    );
  }

  void _syncBlink() {
    final show = _loaded && _controller.text.isEmpty && !_focus.hasFocus;
    if (show && !_blink.isAnimating) {
      _blink.repeat(reverse: true);
    } else if (!show && _blink.isAnimating) {
      _blink.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _controller = TextEditingController(text: AppScope.of(context).vault.login);
    _focus = FocusNode()..addListener(_onFocus);
    _syncBlink();
  }

  void _onFocus() {
    _syncBlink();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _blink.dispose();
    if (_loaded) {
      _focus.removeListener(_onFocus);
      _controller.dispose();
      _focus.dispose();
    }
    super.dispose();
  }

  void _reject(bool rejected) {
    if (_rejected == rejected) return;
    setState(() => _rejected = rejected);
  }

  void _changed(String text) {
    _syncBlink();
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
    final issue = _issue(language);
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final font = max(14.0, side * 0.085);
        return Material(
          type: MaterialType.transparency,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _focus.requestFocus(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                side * 0.18,
                side * 0.28,
                side * 0.18,
                side * 0.2,
              ),
              child: Column(
                children: [
                  const Spacer(),
                  SizedBox(
                    height: font,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TextField(
                          key: const ValueKey('login-field'),
                          controller: _controller,
                          focusNode: _focus,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          autocorrect: false,
                          enableSuggestions: false,
                          smartDashesType: SmartDashesType.disabled,
                          smartQuotesType: SmartQuotesType.disabled,
                          textCapitalization: TextCapitalization.none,
                          cursorColor: widget.color,
                          cursorWidth: max(1.6, side * 0.008),
                          cursorHeight: font,
                          style: TextStyle(
                            color: const Color(0xFFFFFFFF),
                            fontFamily: 'OpenGost Type B',
                            fontSize: font,
                            decoration: TextDecoration.none,
                            height: 1,
                          ),
                          inputFormatters: [_LoginFormatter(_reject)],
                          onChanged: _changed,
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            isDense: true,
                            counterText: '',
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                          ),
                        ),
                        if (_controller.text.isEmpty && !_focus.hasFocus)
                          IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _blink,
                              builder: (context, _) => Opacity(
                                opacity: _blink.value > 0.5 ? 1 : 0,
                                child: SizedBox(
                                  width: max(1.6, side * 0.008),
                                  height: font,
                                  child: ColoredBox(color: widget.color),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: side * 0.035),
                  Container(
                    height: max(1.2, side * 0.008),
                    margin: EdgeInsets.symmetric(horizontal: side * 0.08),
                    color: widget.color,
                  ),
                  SizedBox(
                    height: side * 0.16,
                    child: Center(
                      child: Text(
                        issue ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.color,
                          decoration: TextDecoration.none,
                          fontFamily: 'OpenGost Type B',
                          fontSize: max(10, side * 0.055),
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
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
