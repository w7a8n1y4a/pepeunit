import 'package:flutter/material.dart';

/// Screens change at once: no fade, no zoom, no wait. The pages are
/// transparent, so a delay would show the old screen under the new one.
class InstantPageTransitions extends PageTransitionsBuilder {
  const InstantPageTransitions();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
