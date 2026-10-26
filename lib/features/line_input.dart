import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../hive/hex_scene.dart';

/// Centered cell field: accent stroke and a validation line under it.
/// Material's outline is not drawn.
class LineInput extends StatefulWidget {
  const LineInput({
    required this.color,
    required this.controller,
    this.focusNode,
    this.fieldKey,
    this.hint,
    this.issue,
    this.caption,
    this.lineColor,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.blink = false,
    this.roomyCaption = false,
    this.leading,
    super.key,
  });

  final Color color;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final Key? fieldKey;
  final String? hint;

  /// Validation text under the stroke. An empty string keeps the line in place.
  final String? issue;

  /// Replaces [issue] in the same band, for example an action or toggles.
  final Widget? caption;

  final Color? lineColor;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Blinking caret when the field is empty and unfocused.
  final bool blink;

  /// Gives the caption the lower part of the cell, for a short list of choices.
  /// The field itself stays on the vertical center, clear of the edge title.
  final bool roomyCaption;

  /// Small SVG drawn at the start of the field, for example a search mark.
  final String? leading;

  @override
  State<LineInput> createState() => _LineInputState();
}

class _LineInputState extends State<LineInput>
    with SingleTickerProviderStateMixin {
  late FocusNode _focus;
  var _ownsFocus = false;
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _bindFocus(widget.focusNode);
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    );
    widget.controller.addListener(_onInput);
    _syncBlink();
  }

  void _bindFocus(FocusNode? node) {
    if (node == null) {
      _focus = FocusNode();
      _ownsFocus = true;
    } else {
      _focus = node;
      _ownsFocus = false;
    }
    _focus.addListener(_onInput);
  }

  @override
  void didUpdateWidget(LineInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onInput);
      widget.controller.addListener(_onInput);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _focus.removeListener(_onInput);
      if (_ownsFocus) _focus.dispose();
      _bindFocus(widget.focusNode);
    }
    _syncBlink();
  }

  bool get _showBlink =>
      widget.blink && widget.controller.text.isEmpty && !_focus.hasFocus;

  void _syncBlink() {
    if (_showBlink) {
      if (!_blink.isAnimating) _blink.repeat(reverse: true);
    } else if (_blink.isAnimating) {
      _blink.stop();
    }
  }

  void _onInput() {
    _syncBlink();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_onInput);
    widget.controller.removeListener(_onInput);
    _blink.dispose();
    if (_ownsFocus) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showBand = widget.issue != null || widget.caption != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final font = cellFont(side);
        final bar = max(1.6, side * 0.008);
        final accent = widget.color;
        final highlight = accent.withValues(alpha: 0.40);
        final selection = Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: accent),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: accent,
            selectionColor: highlight,
            selectionHandleColor: accent,
          ),
        );
        final roomy = widget.roomyCaption;
        final icon = font * 1.25;
        final fieldHeight = widget.leading == null ? font : icon;
        final rule = Container(
          height: max(1.2, side * 0.008),
          margin: EdgeInsets.symmetric(horizontal: side * 0.08),
          color: widget.lineColor ?? widget.color,
        );
        final input = HoverPop(
          enabled: !_focus.hasFocus,
          child: SizedBox(
            height: fieldHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Theme(
                  data: selection,
                  child: DefaultSelectionStyle(
                    cursorColor: accent,
                    selectionColor: highlight,
                    child: _field(font: font, bar: bar, accent: accent),
                  ),
                ),
                if (_showBlink)
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _blink,
                      builder: (context, _) => Opacity(
                        opacity: _blink.value > 0.5 ? 1 : 0,
                        child: SizedBox(
                          width: bar,
                          height: font,
                          child: ColoredBox(color: widget.color),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
        final bandChild =
            widget.caption ??
            Center(
              child: Text(
                widget.issue ?? '',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.color,
                  decoration: TextDecoration.none,
                  fontFamily: 'OpenGost Type B',
                  fontSize: min(max(10.0, side * 0.055), side * 0.064),
                  height: 1.15,
                ),
              ),
            );
        return Material(
          type: MaterialType.transparency,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _focus.requestFocus(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                side * (roomy ? 0.1 : 0.18),
                side * (roomy ? 0.12 : 0.28),
                side * (roomy ? 0.1 : 0.18),
                side * (roomy ? 0.12 : 0.2),
              ),
              child: roomy && showBand
                  ? Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    bottom: side * 0.035,
                                  ),
                                  child: input,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: side * 0.04),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: bandChild,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Align(alignment: Alignment.center, child: rule),
                      ],
                    )
                  : Column(
                      children: [
                        const Spacer(),
                        input,
                        SizedBox(height: side * 0.035),
                        rule,
                        if (showBand)
                          SizedBox(
                            height: side * 0.16,
                            width: double.infinity,
                            child: bandChild,
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

  Widget _field({
    required double font,
    required double bar,
    required Color accent,
  }) {
    final leading = widget.leading;
    final hintStyle = TextStyle(
      color: leading == null ? hexMuted : const Color(0x00000000),
      fontFamily: 'OpenGost Type B',
      fontSize: font,
      height: 1,
      decoration: TextDecoration.none,
      overflow: TextOverflow.ellipsis,
    );
    final field = TextField(
      key: widget.fieldKey,
      controller: widget.controller,
      focusNode: _focus,
      textAlign: TextAlign.center,
      textAlignVertical: TextAlignVertical.center,
      maxLines: 1,
      autocorrect: false,
      enableSuggestions: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      textCapitalization: TextCapitalization.none,
      cursorColor: accent,
      cursorWidth: bar,
      cursorHeight: font,
      style: TextStyle(
        color: const Color(0xFFFFFFFF),
        fontFamily: 'OpenGost Type B',
        fontSize: font,
        decoration: TextDecoration.none,
        height: 1,
      ),
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        isCollapsed: true,
        isDense: true,
        counterText: '',
        filled: false,
        contentPadding: EdgeInsets.zero,
        hintText: widget.hint,
        hintStyle: hintStyle,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
      ),
    );
    if (leading == null) return field;
    final icon = font * 1.25;
    return Stack(
      alignment: Alignment.center,
      children: [
        field,
        if (widget.controller.text.isEmpty)
          ExcludeSemantics(
            child: IgnorePointer(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.translate(
                    offset: Offset(0, icon * 0.06),
                    child: SizedBox(
                      width: icon,
                      height: icon,
                      child: SvgPicture.asset(
                        leading,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        colorFilter: const ColorFilter.mode(
                          hexMuted,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: font * 0.28),
                  Text(
                    widget.hint ?? '',
                    style: hintStyle.copyWith(color: hexMuted, height: 1),
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
