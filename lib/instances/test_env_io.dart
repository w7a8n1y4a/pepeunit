import 'dart:io';

/// `flutter test` sets FLUTTER_TEST in the process environment. A real
/// isolate there cannot finish inside the fake async of a widget test, so
/// those runs sign inline instead.
bool get inFlutterTestRunner => Platform.environment.containsKey('FLUTTER_TEST');
