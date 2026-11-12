import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../hive/bevel.dart';
import '../../hive/grain.dart';
import '../../hive/hex_scene.dart';
import '../code/code_modal.dart';
import 'library_menu_page.dart';

/// Text of the search panels, sized by the panel font.
TextStyle searchStyle(double size, Color color, {double? height}) => TextStyle(
  color: color,
  fontFamily: 'OpenGost Type B',
  fontSize: size,
  height: height,
  decoration: TextDecoration.none,
);

/// The bare text field of the library's search bars: no frame, the text of
/// [searchStyle], and no help from the keyboard. Autocorrect, suggestions and
/// smart punctuation are off on every platform, so a query reaches the search
/// as it was typed, not as a phone keyboard rewrote it.
class QuietField extends StatelessWidget {
  const QuietField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.size,
    required this.onChanged,
    required this.onSubmitted,
    this.onEditingComplete,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;

  /// Font size of the typed text and of the hint.
  final double size;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onEditingComplete;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      autocorrect: false,
      enableSuggestions: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      cursorColor: libraryColor,
      style: searchStyle(size, const Color(0xFFFFFFFF)),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration.collapsed(
        hintText: hint,
        hintStyle: searchStyle(size, hexMuted),
      ),
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
    );
  }
}

/// A modal search over the screen: a field on top and the rows that answer
/// under it. It is the body of the documentation search and of the path
/// search of the tree; they differ in what is searched and how a row looks.
///
/// - Typing searches at once; only this panel is rebuilt. Up and Down move
///   along the rows, Enter picks the lit one, Escape closes. A pointer lights
///   the row it moves over.
/// - A tap on a row, or Enter, calls [onPick]; the owner closes the panel.
/// - A tap outside the panel calls [onClose].
class SearchPanel<T> extends StatefulWidget {
  const SearchPanel({
    required this.font,
    required this.rowExtent,
    required this.fieldLabel,
    required this.closeLabel,
    required this.search,
    required this.emptyText,
    required this.rowBuilder,
    required this.onPick,
    required this.onClose,
    super.key,
  });

  /// Size of the text of a row. The rest follows it.
  final double font;

  /// Height of a row, in [font]s.
  final double rowExtent;

  /// Hint and label of the field.
  final String fieldLabel;
  final String closeLabel;

  /// Rows that answer [text], in the order to show them.
  final List<T> Function(String text) search;

  /// What an empty list says; [asked] is the trimmed query.
  final String Function(String asked) emptyText;

  /// One row. [lit] is the row the keys point at; [onHover] lights it, and
  /// [onTap] picks it.
  final Widget Function(
    BuildContext context,
    T hit,
    bool lit,
    VoidCallback onHover,
    VoidCallback onTap,
  )
  rowBuilder;
  final ValueChanged<T> onPick;
  final VoidCallback onClose;

  @override
  State<SearchPanel<T>> createState() => _SearchPanelState<T>();
}

class _SearchPanelState<T> extends State<SearchPanel<T>> {
  final _field = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  List<T> _hits = const [];
  var _asked = '';
  var _lit = 0;

  @override
  void initState() {
    super.initState();
    // The page under the panel holds the focus, so the field's autofocus is
    // not taken: ask for it, and typing starts at once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _typed(String text) {
    setState(() {
      _asked = text.trim();
      _hits = widget.search(text);
      _lit = 0;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _move(int step, double rowH, double viewport) {
    if (_hits.isEmpty) return;
    setState(() => _lit = (_lit + step).clamp(0, _hits.length - 1));
    if (!_scroll.hasClients) return;
    final top = _lit * rowH;
    final bottom = top + rowH;
    final from = _scroll.offset;
    if (top < from) {
      _scroll.jumpTo(top);
    } else if (bottom > from + viewport) {
      _scroll.jumpTo(bottom - viewport);
    }
  }

  void _pick(int at) {
    if (at < 0 || at >= _hits.length) return;
    widget.onPick(_hits[at]);
  }

  KeyEventResult _key(KeyEvent event, double rowH, double viewport) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1, rowH, viewport);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1, rowH, viewport);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final font = widget.font;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final margin = min(font * 1.2, size.width * 0.03);
        final width = min(size.width - margin * 2, font * 52);
        final top = max(margin, size.height * 0.07);
        final barH = font * 3.4;
        final rowH = font * widget.rowExtent;
        final room = max(font * 6, size.height - top - margin - barH - 1);
        final natural = _hits.isEmpty ? font * 5.5 : _hits.length * rowH;
        final listH = min(room, natural + font * 0.6);
        final viewport = listH - font * 0.6;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onClose,
                child: const ColoredBox(color: Color(0xB3000000)),
              ),
            ),
            Positioned(
              top: top,
              left: (size.width - width) / 2,
              width: width,
              height: barH + 1 + listH,
              child: Focus(
                onKeyEvent: (node, event) => _key(event, rowH, viewport),
                child: BevelFrame(
                  color: libraryColor,
                  width: max(1.4, font * 0.12),
                  radius: font,
                  child: GrainBox(
                    tile: cellGrain,
                    opacity: modalFillOpacity,
                    child: Column(
                      children: [
                        SizedBox(height: barH, child: _bar(font)),
                        Container(height: 1, color: const Color(0x33FFFFFF)),
                        Expanded(child: _list(font, rowH)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _bar(double font) {
    return Padding(
      padding: EdgeInsets.fromLTRB(font * 1.1, 0, font * 0.4, 0),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/actions/search.svg',
            width: font * 1.5,
            height: font * 1.5,
          ),
          SizedBox(width: font * 0.8),
          Expanded(
            child: Semantics(
              textField: true,
              label: widget.fieldLabel,
              child: QuietField(
                controller: _field,
                focusNode: _focus,
                hint: widget.fieldLabel,
                size: font * 1.25,
                onChanged: _typed,
                onSubmitted: (_) => _pick(_lit),
              ),
            ),
          ),
          CodeCloseMark(
            label: widget.closeLabel,
            extent: font * 2.2,
            onTap: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _list(double font, double rowH) {
    if (_hits.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: font),
          child: Text(
            widget.emptyText(_asked),
            textAlign: TextAlign.center,
            style: searchStyle(font * 1.05, hexMuted),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: EdgeInsets.symmetric(vertical: font * 0.3),
      itemExtent: rowH,
      itemCount: _hits.length,
      itemBuilder: (context, i) => widget.rowBuilder(
        context,
        _hits[i],
        i == _lit,
        () {
          if (_lit != i) setState(() => _lit = i);
        },
        () => _pick(i),
      ),
    );
  }
}

/// The frame every search row shares: a pointer-lit border, a tap, and the
/// semantics of a button.
class SearchRowFrame extends StatelessWidget {
  const SearchRowFrame({
    required this.font,
    required this.lit,
    required this.label,
    required this.verticalPad,
    required this.onHover,
    required this.onTap,
    required this.child,
    this.excludeSemantics = false,
    super.key,
  });

  final double font;
  final bool lit;
  final String label;

  /// Padding inside the border, in [font]s.
  final double verticalPad;
  final VoidCallback onHover;
  final VoidCallback onTap;
  final bool excludeSemantics;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: lit,
      label: label,
      excludeSemantics: excludeSemantics,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onHover: (_) => onHover(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: font * 0.6,
              vertical: font * 0.15,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: lit ? const Color(0x14FFFFFF) : null,
                border: Border.all(
                  color: lit ? libraryColor : const Color(0x00000000),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: font * 0.7,
                  vertical: font * verticalPad,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
