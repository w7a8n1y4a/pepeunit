import 'dart:convert';
import 'dart:typed_data';

import '../locale/languages.dart';

const iconSide = 192;
const iconMaxBytes = 128 * 1024;

const _png = <int>[137, 80, 78, 71, 13, 10, 26, 10];

/// `empty`, `large`, `png`, or `size`. Null when the bytes can be an icon.
String? iconProblem(Uint8List bytes) {
  if (bytes.isEmpty) return 'empty';
  if (bytes.length > iconMaxBytes) return 'large';
  final size = pngSize(bytes);
  if (size == null) return 'png';
  if (size.$1 != iconSide || size.$2 != iconSide) return 'size';
  return null;
}

/// Phrase for an [iconProblem] code, plus `read` when the file cannot be opened.
String? iconProblemText(String? code, String language) {
  switch (code) {
    case 'empty':
      return phrase(language, {'ru': 'Файл пустой', 'en': 'The file is empty'});
    case 'large':
      return phrase(language, {
        'ru': 'Картинка больше 128 КБ',
        'en': 'The picture is larger than 128 KB',
      });
    case 'png':
      return phrase(language, {
        'ru': 'Нужен файл PNG',
        'en': 'A PNG file is required',
      });
    case 'size':
      return phrase(language, {
        'ru': 'Нужен размер 192x192',
        'en': 'The picture must be 192x192',
      });
    case 'read':
      return phrase(language, {
        'ru': 'Не удалось прочитать файл',
        'en': 'The file could not be read',
      });
    default:
      return null;
  }
}

Uint8List? iconBytes(String? encoded) {
  if (encoded == null || encoded.isEmpty) return null;
  try {
    final bytes = base64.decode(encoded);
    return bytes.isEmpty ? null : bytes;
  } catch (_) {
    return null;
  }
}

/// Width and height from a PNG header, or null when the bytes are not a PNG.
(int, int)? pngSize(Uint8List bytes) {
  if (bytes.length < 24) return null;
  for (var i = 0; i < _png.length; i++) {
    if (bytes[i] != _png[i]) return null;
  }
  if (bytes[12] != 0x49 ||
      bytes[13] != 0x48 ||
      bytes[14] != 0x44 ||
      bytes[15] != 0x52) {
    return null;
  }
  final data = ByteData.sublistView(bytes);
  final width = data.getUint32(16);
  final height = data.getUint32(20);
  if (width == 0 || height == 0) return null;
  return (width, height);
}
