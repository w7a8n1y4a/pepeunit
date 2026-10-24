import 'package:url_launcher/url_launcher.dart';

Future<void> launchExternal(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
