import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../app_model.dart';
import '../app_scope.dart';
import 'back.dart';

/// Opens a screen that picks a value and waits for the answer.
///
/// The answer travels through [AppModel.finishPick], not through the route
/// result: a picker may change its scale, which replaces its route, and a
/// replaced route never delivers its result. Null means the person left
/// without choosing. [items] are rows the opener already holds, so a name
/// picker does not ask for them again.
Future<T?> openPick<T extends Object>(
  BuildContext context,
  String path, {
  List<PickItem>? items,
}) {
  final answer = AppScope.of(context).beginPick<T>(items: items);
  context.push<void>(path);
  return answer;
}

/// Answers the opener of [openPick] and closes the picker. A null [value] is
/// Back: it also clears the open pick.
void givePick(BuildContext context, Object? value) {
  AppScope.of(context).finishPick(value);
  popOrHome(context);
}
