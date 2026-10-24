import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../locale/languages.dart';

void popOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/');
  }
}

String accountText(String language, String ru, String en) =>
    phrase(language, {'ru': ru, 'en': en});
