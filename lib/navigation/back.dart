import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void popOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/');
  }
}
