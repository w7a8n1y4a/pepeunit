import 'package:flutter/widgets.dart';

/// A panel with its four corners cut, the way a cell is cut: a thin border in
/// [color] drawn over [child], and everything inside clipped to the shape.
/// Every modal frame and every panel in a text is one of these, so a corner
/// is never a plain right angle.
///
/// [radius] is how far the cut runs along each side. Scale it with the font
/// of the panel. A [fill] sits under the child when the child brings none.
class BevelFrame extends StatelessWidget {
  const BevelFrame({
    required this.color,
    required this.radius,
    required this.child,
    this.width = 1.5,
    this.fill,
    super.key,
  });

  final Color color;
  final double radius;
  final double width;
  final Color? fill;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shape = BeveledRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: color, width: width),
    );
    final fill = this.fill;
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: DecoratedBox(
        // The border is drawn over the child, so a fill does not cover half
        // of it.
        position: DecorationPosition.foreground,
        decoration: ShapeDecoration(shape: shape),
        child: fill == null ? child : ColoredBox(color: fill, child: child),
      ),
    );
  }
}
