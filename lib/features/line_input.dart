import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../hive/hex_scene.dart';

/// Side inset of a roomy search cell, as a share of the cell.
const roomySideInset = 0.10;

/// Search stroke inset from the cell edge, as a share of the cell.
const searchRuleInset = 0.08;

/// How far a roomy enum sits under the search stroke, as a share of the cell.
const _searchCaptionGap = 0.014;

/// Width of the search stroke inside a roomy caption of [captionWidth].
double searchLineWidth(double captionWidth) {
  final side = captionWidth / (1 - 2 * roomySideInset);
  return max(0.0, captionWidth - 2 * side * searchRuleInset);
}

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
    this.captionGap,
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
  /// The stroke sits just above that list. The field rests on the stroke,
  /// clear of the top of the cell.
  final bool roomyCaption;

  /// Gap under the stroke, as a share of the cell. The roomy caption uses
  /// a small default when this is omitted.
  final double? captionGap;

  /// Search mark. Its center stays a fifth of the line in from the left.
  /// The hint and the typed text stay on the center of the line, a tenth
  /// of the row below that center. A long line stays centered and is cut
  /// off on the left before it reaches the mark.
  final String? leading;

  @override
  State<LineInput> createState() => _LineInputState();
}

class _LineInputState extends State<LineInput>
    with SingleTickerProviderStateMixin {
  late FocusNode _focus;
  var _ownsFocus = false;
  late final AnimationController _blink;
  final ScrollController _searchScroll = ScrollController();

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
    _searchScroll.dispose();
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
          margin: EdgeInsets.symmetric(horizontal: side * searchRuleInset),
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
                side * (roomy ? roomySideInset : 0.18),
                side * (roomy ? 0.12 : 0.28),
                side * (roomy ? roomySideInset : 0.18),
                side * (roomy ? 0.12 : 0.2),
              ),
              child: roomy && showBand
                  ? Column(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: EdgeInsets.only(bottom: side * 0.035),
                              child: input,
                            ),
                          ),
                        ),
                        rule,
                        Expanded(
                          flex: 8,
                          child: Padding(
                            padding: EdgeInsets.only(
                              top:
                                  side *
                                  (widget.captionGap ?? _searchCaptionGap),
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: bandChild,
                            ),
                          ),
                        ),
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

  void _pinSearchText() {
    if (!mounted || widget.leading == null || !_searchScroll.hasClients) return;
    final position = _searchScroll.position;
    if (!position.hasContentDimensions) return;
    final target = position.maxScrollExtent / 2;
    if ((position.pixels - target).abs() < 0.5) return;
    position.jumpTo(target);
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
    Widget editor(
      EdgeInsets padding, {
      double? size,
      ScrollController? scroll,
      ScrollPhysics? physics,
    }) {
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
        scrollController: scroll,
        scrollPhysics: physics,
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
    final row = font * _searchMark;
    final glyph = row * _searchMarkScale;
    final showPrompt = widget.controller.text.isEmpty && !_focus.hasFocus;
    final prompt = widget.hint ?? '';
    final lower = Offset(0, row * _searchTextLower);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final markLeft = (width / 5 - glyph / 2)
            .clamp(0.0, max(0.0, width - glyph))
            .toDouble();
        final markTop = _searchMarkTop(
          row: row,
          glyph: glyph,
          lineInset: lineInset,
        );
        final fieldLeft = lineInset.clamp(0.0, width / 2).toDouble();
        final markRight = markLeft + glyph * _searchGlassRight;
        final clipLeft = (markRight + font * 0.28 - fieldLeft)
            .clamp(0.0, width / 2)
            .toDouble();
        WidgetsBinding.instance.addPostFrameCallback((_) => _pinSearchText());
        return SizedBox(
          width: width,
          height: row,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: fieldLeft,
                right: fieldLeft,
                top: 0,
                bottom: 0,
                child: ClipRect(
                  key: const ValueKey('search-text-clip'),
                  clipper: _SearchInkClip(clipLeft),
                  child: Align(
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: lower,
                      child: SizedBox(
                        height: type,
                        child: DefaultTextHeightBehavior(
                          textHeightBehavior: const TextHeightBehavior(
                            applyHeightToFirstAscent: false,
                            applyHeightToLastDescent: false,
                          ),
                          child: editor(
                            EdgeInsets.zero,
                            size: type,
                            scroll: _searchScroll,
                            physics: const NeverScrollableScrollPhysics(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: markLeft,
                top: markTop,
                width: glyph,
                height: glyph,
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
                  left: fieldLeft,
                  right: fieldLeft,
                  top: 0,
                  bottom: 0,
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: Align(
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: lower,
                          child: Text(
                            prompt,
                            key: const ValueKey('line-prompt'),
                            textAlign: TextAlign.center,
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
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Glass plus handle, in font heights. This is the search row.
const _searchMark = 1.98;

/// The drawn mark is a tenth smaller than the row.
const _searchMarkScale = 0.9;

/// Nudge that seats the full-size mark in the row.
const _searchMarkDrop = 0.07;

/// Lowest ink of `search.svg`, as a share of its view box.
/// The handle ends at (52, 52); the round cap adds half the stroke on the diagonal.
const _searchInkTip = (52 + 1.41421356237) / 64;

/// How much of the gap between the handle and the stroke is closed.
const _searchLineCloser = 0.10;

/// Search hint and typed text, relative to the cell font.
const _searchType = 1.25;

/// How far the hint and the typed text sit below the row center,
/// as a share of the row height.
const _searchTextLower = 0.10;

/// Right edge of the glass in `search.svg`, as a share of the view box.
/// The handle continues past this, below the typed line.
const _searchGlassRight = 42 / 64;

/// Keeps a long search line centered, and hides it before the glass.
class _SearchInkClip extends CustomClipper<Rect> {
  const _SearchInkClip(this.left);

  final double left;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(left, 0, size.width, size.height);

  @override
  bool shouldReclip(covariant _SearchInkClip oldClipper) =>
      oldClipper.left != left;
}

/// Top of the mark. The glyph is [_searchMarkScale] of the row, and its
/// handle sits [_searchLineCloser] closer to the stroke than the full-size mark.
double _searchMarkTop({
  required double row,
  required double glyph,
  required double lineInset,
}) {
  final side = lineInset / 0.08;
  final stroke = max(1.2, side * 0.008);
  final under = side * 0.035 - stroke / 2;
  final inkNow = row * _searchMarkDrop + _searchInkTip * row;
  final gap = max(0.0, row + under - inkNow);
  return inkNow + gap * _searchLineCloser - _searchInkTip * glyph;
}
