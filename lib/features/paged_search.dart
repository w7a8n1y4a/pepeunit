import 'package:flutter/material.dart';

import '../app_model.dart';
import '../app_scope.dart';
import '../instances/network_view.dart';
import 'line_input.dart';

/// What every search screen with a page window does the same way: the offset,
/// the busy flag, the error cell, the pause after typing, and one guarded
/// load. The screen gives [scopeOf] and [fetch]; the rest is here.
///
/// A load that is overtaken by a newer one is dropped, so a slow answer never
/// replaces a fresh one.
mixin PagedSearch<W extends StatefulWidget> on State<W> {
  var offset = 0;
  var loading = false;
  var failureOpen = false;
  String? failure;
  var _ticket = 0;
  final typing = SearchDelay();

  /// The scale tick the widget shows. A new tick starts the window over.
  int scopeOf(W widget);

  /// Whether the screen may ask at all. Otherwise it shows "not signed in".
  bool canLoad(AppModel model) => model.signedIn;

  /// Asks for the page at [offset]. The answer is a callback that stores it
  /// in the screen's fields, run inside `setState` once the load is still the
  /// newest; `null` says the answer was already dropped.
  Future<VoidCallback?> fetch(AppModel model);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) load();
    });
  }

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (scopeOf(oldWidget) == scopeOf(widget)) return;
    offset = 0;
    load();
  }

  @override
  void dispose() {
    typing.dispose();
    super.dispose();
  }

  /// Starts over from the first page after the pause that typing leaves.
  void searchLater() {
    typing.later(() {
      if (!mounted) return;
      setState(() => offset = 0);
      load();
    });
  }

  /// Starts over from the first page now: a filter or an order changed.
  void retune() {
    typing.cancel();
    setState(() => offset = 0);
    load();
  }

  /// One page forward or back, when the window allows it.
  void step(
    int direction, {
    required int limit,
    required int count,
    required int capacity,
  }) {
    if (loading) return;
    final next = pageShift(
      direction: direction,
      offset: offset,
      limit: limit,
      count: count,
      capacity: capacity,
    );
    if (next == null) return;
    setState(() => offset = next);
    load();
  }

  Future<void> load() async {
    final ticket = ++_ticket;
    final model = AppScope.of(context);
    if (!canLoad(model)) {
      setState(() {
        loading = false;
        failure = model.notSignedIn;
      });
      return;
    }
    setState(() {
      loading = true;
      failure = null;
      failureOpen = false;
    });
    try {
      final store = await fetch(model);
      if (!mounted || ticket != _ticket || store == null) return;
      setState(() {
        store();
        loading = false;
      });
    } catch (error) {
      if (!mounted || ticket != _ticket) return;
      setState(() {
        loading = false;
        failure = '$error';
      });
    }
  }
}
