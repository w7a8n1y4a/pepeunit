import 'package:flutter/widgets.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../locale/failure.dart';
import 'code_modal.dart';

/// What every panel over a [CodeModal] does the same way: read once, run a
/// command with a spinner, and put a failure into the note under the body.
mixin CodePanelState<T extends StatefulWidget> on State<T> {
  /// The note under the body. Null when there is nothing to say.
  String? failure;

  /// The first read has not answered yet.
  var loading = true;

  /// The command a word on the bar is running, or null.
  String? pending;

  /// Runs [request] for a signed-in person. Null comes back when nobody is
  /// signed in, the request failed (the note says why), or the panel closed
  /// while it ran.
  Future<R?> ask<R extends Object>(
    Future<R> Function(AppModel model) request,
  ) async {
    final model = AppScope.of(context);
    if (!model.signedIn) {
      setState(() {
        loading = false;
        failure = model.notSignedIn;
      });
      return null;
    }
    try {
      final result = await request(model);
      return mounted ? result : null;
    } catch (error) {
      if (mounted) {
        setState(() {
          loading = false;
          failure = describeFailure('$error', model.vault.language);
        });
      }
      return null;
    }
  }

  /// Runs [action] as the command [name]: its word shows a spinner, and a
  /// second command waits. A fast answer still shows the spinner for a
  /// moment unless [hold] is off. False when it failed or the panel closed.
  Future<bool> work(
    String name,
    Future<void> Function() action, {
    bool hold = true,
  }) async {
    if (pending != null) return false;
    setState(() {
      pending = name;
      failure = null;
    });
    final watch = Stopwatch()..start();
    try {
      await action();
      if (hold) await holdSpinner(watch);
      if (!mounted) return false;
      setState(() => pending = null);
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() {
        pending = null;
        failure = describeFailure(
          '$error',
          AppScope.of(context).vault.language,
        );
      });
      return false;
    }
  }
}
