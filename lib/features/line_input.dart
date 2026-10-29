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

  /// Search mark. It sits beside the hint, on the text midline. Once the
  /// field has text, it slides left to about a fifth of the line. The text
  /// itself scrolls along the line, as in a plain field, and stays clear of
  /// the mark.
  final String? leading;

  @override
  State<LineInput> createState() => _LineInputState();
}

class _LineInputState extends State<LineInput> with TickerProviderStateMixin {
  late FocusNode _focus;
  var _ownsFocus = false;
  late final AnimationController _blink;
  late final AnimationController _park;

  @override
  void initState() {
    super.initState();
    _bindFocus(widget.focusNode);
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    );
    _park = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    if (widget.controller.text.isNotEmpty) _park.value = 1;
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
    _syncPark();
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

  void _syncPark() {
    if (widget.leading == null) return;
    if (widget.controller.text.isNotEmpty) {
      _park.forward();
    } else {
      _park.reverse();
    }
  }

  void _onInput() {
    _syncBlink();
    _syncPark();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_onInput);
    widget.controller.removeListener(_onInput);
    _blink.dispose();
    _park.dispose();
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
        final mark = font * _searchMark;
        final fieldHeight = widget.leading == null ? font : mark;
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
              clipBehavior: Clip.none,
              children: [
                Theme(
                  data: selection,
                  child: DefaultSelectionStyle(
                    cursorColor: accent,
                    selectionColor: highlight,
                    child: _field(
                      font: font,
                      bar: bar,
                      accent: accent,
                      lineInset: side * 0.08,
                    ),
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
    required double lineInset,
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
    Widget editor(EdgeInsets padding, {double? size}) {
      final type = size ?? font;
      return TextField(
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
        cursorHeight: type,
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontFamily: 'OpenGost Type B',
          fontSize: type,
          decoration: TextDecoration.none,
          height: 1,
        ),
        strutStyle: StrutStyle(
          fontFamily: 'OpenGost Type B',
          fontSize: type,
          height: 1,
          leading: 0,
          forceStrutHeight: true,
        ),
        inputFormatters: widget.inputFormatters,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          isCollapsed: true,
          isDense: true,
          counterText: '',
          filled: false,
          contentPadding: padding,
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
    }

    if (leading == null) return editor(EdgeInsets.zero);
    final type = font * _searchType;
    final icon = font * _searchMark;
    final gap = font * 0.35;
    final drop = icon * _searchMarkDrop;
    final showPrompt = widget.controller.text.isEmpty && !_focus.hasFocus;
    final prompt = widget.hint ?? '';
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final promptWidth = _inkWidth(prompt, type);
        final idleLeft = max(0.0, (width - icon - gap - promptWidth) / 2);
        final parkedLeft = (width / 5 - icon / 2).clamp(
          0.0,
          max(0.0, width - icon),
        );
        final fieldLeft = lineInset.clamp(0.0, width / 2).toDouble();
        return SizedBox(
          width: width,
          height: icon,
          child: AnimatedBuilder(
            animation: _park,
            builder: (context, child) {
              final travel = Curves.easeInOut.transform(_park.value);
              final left = (idleLeft + (parkedLeft - idleLeft) * travel)
                  .toDouble();
              final textStart = widget.controller.text.isEmpty
                  ? fieldLeft
                  : min(left + icon + gap, width - fieldLeft).toDouble();
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: textStart,
                    right: fieldLeft,
                    top: 0,
                    bottom: 0,
                    child: Align(
                      alignment: const Alignment(0, _searchTypeDrop),
                      child: SizedBox(height: type, child: child),
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: drop,
                    width: icon,
                    height: icon,
                    child: IgnorePointer(
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
                  if (showPrompt)
                    Positioned(
                      left: left + icon + gap,
                      top: 0,
                      bottom: 0,
                      child: ExcludeSemantics(
                        child: IgnorePointer(
                          child: Align(
                            alignment: const Alignment(0, _searchTypeDrop),
                            child: Text(
                              prompt,
                              key: const ValueKey('line-prompt'),
                              style: hintStyle.copyWith(
                                color: hexMuted,
                                height: 1,
                                fontSize: type,
                              ),
                              textHeightBehavior: const TextHeightBehavior(
                                applyHeightToFirstAscent: false,
                                applyHeightToLastDescent: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
            child: DefaultTextHeightBehavior(
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
              child: editor(EdgeInsets.zero, size: type),
            ),
          ),
        );
      },
    );
  }
}

/// Glass plus handle, in font heights. The glass sits above the box center.
const _searchMark = 1.98;

/// Share of the mark height that brings the glass onto the text midline.
const _searchMarkDrop = 0.07;

/// Search hint and typed text, relative to the cell font.
const _searchType = 1.25;

/// Align value that lowers a child by [_searchMarkDrop] of the icon box.
const _searchTypeDrop = _searchMarkDrop * 2;

double _inkWidth(String text, double font) {
  if (text.isEmpty) return 0;
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'OpenGost Type B',
        fontSize: font,
        height: 1,
        decoration: TextDecoration.none,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.width;
}
