import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum EscapeKind { back, close }

/// Registers the same action as a visible Back cell or Close button.
/// Close wins over Back, and the frontmost Close wins over those below it.
/// An early handler works even when an editor owns keyboard focus.
class EscapeTarget extends StatefulWidget {
  const EscapeTarget({
    required this.kind,
    required this.onEscape,
    required this.child,
    super.key,
  });

  final EscapeKind kind;
  final VoidCallback? onEscape;
  final Widget child;

  @override
  State<EscapeTarget> createState() => _EscapeTargetState();
}

class _EscapeTargetState extends State<EscapeTarget> {
  static final _targets = <_EscapeTargetState>{};
  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    if (_targets.isEmpty) {
      FocusManager.instance.addEarlyKeyEventHandler(_handle);
    }
    _targets.add(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void dispose() {
    _targets.remove(this);
    if (_targets.isEmpty) {
      FocusManager.instance.removeEarlyKeyEventHandler(_handle);
    }
    super.dispose();
  }

  bool get _visible {
    if (!mounted || widget.onEscape == null || _route?.isCurrent == false) {
      return false;
    }
    RenderObject? render = context.findRenderObject();
    if (render is! RenderBox ||
        !render.attached ||
        !render.hasSize ||
        render.size.isEmpty) {
      return false;
    }
    while (render != null) {
      if (render is RenderOffstage && render.offstage) return false;
      render = render.parent;
    }
    return true;
  }

  /// Widget order follows layer order in the Stack and Overlay containers.
  /// Using it instead of mount time also handles resizing under an open modal.
  List<Element> get _ancestors {
    final result = <Element>[context as Element];
    context.visitAncestorElements((element) {
      result.add(element);
      return true;
    });
    return result.reversed.toList();
  }

  static int _compare(_EscapeTargetState a, _EscapeTargetState b) {
    final priority = a.widget.kind.index.compareTo(b.widget.kind.index);
    if (priority != 0) return priority;
    final left = a._ancestors;
    final right = b._ancestors;
    var at = 0;
    while (at < left.length && at < right.length && left[at] == right[at]) {
      at++;
    }
    if (at == left.length || at == right.length) {
      return left.length.compareTo(right.length);
    }
    if (at == 0) return 0;
    var result = 0;
    left[at - 1].visitChildren((child) {
      if (child == left[at]) result = 1;
      if (child == right[at]) result = -1;
    });
    return result;
  }

  static KeyEventResult _handle(KeyEvent event) {
    if (event.logicalKey != LogicalKeyboardKey.escape || event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    final targets = _targets.where((target) => target._visible).toList()
      ..sort(_compare);
    if (targets.isEmpty) return KeyEventResult.ignored;
    // Holding Escape must not close several layers or screens in succession.
    if (event is KeyDownEvent) targets.last.widget.onEscape!();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
