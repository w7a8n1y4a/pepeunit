import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/widgets.dart';

/// Drop target that reports whether a file is hovering over the cell.
class FileDrop extends StatelessWidget {
  const FileDrop({
    required this.enable,
    required this.hot,
    required this.onHot,
    required this.onDrop,
    required this.child,
    super.key,
  });

  final bool enable;
  final bool hot;
  final ValueChanged<bool> onHot;
  final ValueChanged<DropDoneDetails> onDrop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      enable: enable,
      onDragEntered: (_) {
        if (!hot) onHot(true);
      },
      onDragExited: (_) {
        if (hot) onHot(false);
      },
      onDragDone: onDrop,
      child: child,
    );
  }
}
