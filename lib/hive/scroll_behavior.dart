import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// One way to scroll on every platform. The stock behavior follows the
/// system: iOS and macOS bounce past the edge, Android stretches it, the
/// desktop shows a scrollbar and the phone does not. Here every platform
/// stops at the edge, draws no overscroll effect, and shows the same
/// scrollbar on a vertical list.
class UniformScrollBehavior extends MaterialScrollBehavior {
  const UniformScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();

  @override
  GestureVelocityTrackerBuilder velocityTrackerBuilder(BuildContext context) =>
      (event) => VelocityTracker.withKind(event.kind);

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (axisDirectionToAxis(details.direction) == Axis.horizontal) return child;
    return Scrollbar(controller: details.controller, child: child);
  }
}
