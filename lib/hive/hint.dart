import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The tip service of the app. It sits once above the router and knows two
/// things: whether a cell has a tip, and how to show it. `lib/hive` does not
/// know what a tip is made of.
///
/// The context passed in is the cell's own, so the opener can find the
/// navigator and the route the cell stands on.
class HintHost extends InheritedWidget {
  const HintHost({
    required this.has,
    required this.open,
    required super.child,
    super.key,
  });

  final bool Function(BuildContext context, String id) has;

  /// Shows the tip. [title] and [color] are the cell's own, so the panel
  /// carries its name and its border.
  final void Function(
    BuildContext context,
    String id,
    String title,
    Color color,
  )
  open;

  static HintHost? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HintHost>();

  @override
  bool updateShouldNotify(HintHost oldWidget) => false;
}

/// Opens the tip of [id] on a click of the mouse wheel or a long press, by
/// touch or by mouse. A cursor resting on the cell opens nothing. Wrap a cell
/// or a lone button with it. Without a tip for [id] it adds nothing, so a
/// tap and a scroll behave as they did.
class HintTarget extends StatefulWidget {
  const HintTarget({
    required this.id,
    required this.title,
    required this.color,
    required this.child,
    super.key,
  });

  final String id;
  final String title;
  final Color color;
  final Widget child;

  @override
  State<HintTarget> createState() => _HintTargetState();
}

class _HintTargetState extends State<HintTarget> {
  /// How long a finger rests before the tip opens: shorter than the system
  /// 500 ms, which feels like nothing happens on a phone.
  static const _hold = Duration(milliseconds: 380);

  bool _overSelectableText(PointerDownEvent event) {
    final box = context.findRenderObject();
    if (box is! RenderBox) return false;
    final hit = BoxHitTestResult();
    box.hitTest(hit, position: box.globalToLocal(event.position));
    return hit.path.any(
      (entry) =>
          entry.target is RenderParagraph &&
          (entry.target as RenderParagraph).registrar != null,
    );
  }

  void _open({bool held = false}) {
    final host = HintHost.maybeOf(context);
    if (host == null || !host.has(context, widget.id)) return;
    // A short buzz tells the finger that the hold was taken. Desktop has none.
    if (held) HapticFeedback.mediumImpact();
    host.open(context, widget.id, widget.title, widget.color);
  }

  @override
  Widget build(BuildContext context) {
    final host = HintHost.maybeOf(context);
    if (host == null || !host.has(context, widget.id)) return widget.child;
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        // Any pointer: a finger, a pen, or the primary button of a mouse.
        _HintLongPressRecognizer:
            GestureRecognizerFactoryWithHandlers<_HintLongPressRecognizer>(
              () => _HintLongPressRecognizer(
                duration: _hold,
                overSelectableText: _overSelectableText,
              ),
              (recognizer) => recognizer.onLongPress = () => _open(held: true),
            ),
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          if (event.kind == PointerDeviceKind.mouse &&
              event.buttons == kMiddleMouseButton) {
            _open();
          }
        },
        child: widget.child,
      ),
    );
  }
}

/// Text selection owns a hold on selectable text; the rest of the cell
/// continues to open its hint, as does a middle click anywhere in the cell.
class _HintLongPressRecognizer extends LongPressGestureRecognizer {
  _HintLongPressRecognizer({
    required super.duration,
    required this.overSelectableText,
  });

  final bool Function(PointerDownEvent) overSelectableText;

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      !overSelectableText(event) && super.isPointerAllowed(event);
}
