import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void popOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/');
  }
}

String accountText(String language, String ru, String en) =>
    language == 'en' ? en : ru;
