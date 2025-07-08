import 'dart:convert';

class EncodingUtils {
  static const utf8 = Utf8Codec();
  static const latin1 = Latin1Codec();
  static const ascii = AsciiCodec();

  static String detectEncoding(List<int> bytes) {
    if (bytes.isEmpty) return 'utf-8';

    if (bytes.length >= 3) {
      if (bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
        return 'utf-8';
      }
    }

    if (bytes.length >= 2) {
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
        return 'utf-16be';
      }
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
        return 'utf-16le';
      }
    }

    if (bytes.length >= 4) {
      if (bytes[0] == 0x00 &&
          bytes[1] == 0x00 &&
          bytes[2] == 0xFE &&
          bytes[3] == 0xFF) {
        return 'utf-32be';
      }
      if (bytes[0] == 0xFF &&
          bytes[1] == 0xFE &&
          bytes[2] == 0x00 &&
          bytes[3] == 0x00) {
        return 'utf-32le';
      }
    }

    try {
      utf8.decode(bytes);
      return 'utf-8';
    } catch (_) {
      return 'latin1';
    }
  }

  static String safeDecodeString(List<int> bytes, {String? encoding}) {
    encoding ??= detectEncoding(bytes);

    try {
      switch (encoding.toLowerCase()) {
        case 'utf-8':
          return utf8.decode(bytes);
        case 'latin1':
        case 'iso-8859-1':
          return latin1.decode(bytes);
        case 'ascii':
          return ascii.decode(bytes);
        default:
          return utf8.decode(bytes);
      }
    } catch (_) {
      return String.fromCharCodes(bytes.where((b) => b >= 32 && b <= 126));
    }
  }

  static List<int> safeEncodeString(String text, {String encoding = 'utf-8'}) {
    try {
      switch (encoding.toLowerCase()) {
        case 'utf-8':
          return utf8.encode(text);
        case 'latin1':
        case 'iso-8859-1':
          return latin1.encode(text);
        case 'ascii':
          return ascii.encode(text);
        default:
          return utf8.encode(text);
      }
    } catch (_) {
      return utf8.encode(text);
    }
  }

  static String escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  static String unescapeHtml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#x27;', "'");
  }

  static String escapeUrl(String text) {
    return Uri.encodeComponent(text);
  }

  static String unescapeUrl(String text) {
    return Uri.decodeComponent(text);
  }

  static String escapeJs(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t')
        .replaceAll('\b', '\\b')
        .replaceAll('\f', '\\f');
  }

  static String slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  static String base64Encode(List<int> bytes) {
    return base64.encode(bytes);
  }

  static List<int> base64Decode(String encoded) {
    return base64.decode(encoded);
  }

  static String base64UrlEncode(List<int> bytes) {
    return base64Url.encode(bytes);
  }

  static List<int> base64UrlDecode(String encoded) {
    return base64Url.decode(encoded);
  }

  static bool isValidUtf8(List<int> bytes) {
    try {
      utf8.decode(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool isValidAscii(List<int> bytes) {
    try {
      ascii.decode(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String normalizeLineEndings(String text) {
    return text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  static String truncateString(String text, int maxLength,
      {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - suffix.length) + suffix;
  }

  static String truncateWords(String text, int maxWords,
      {String suffix = '...'}) {
    final words = text.split(' ');
    if (words.length <= maxWords) return text;
    return '${words.take(maxWords).join(' ')}$suffix';
  }

  static String stripTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  static List<String> splitLines(String text) {
    return text.split(RegExp(r'\r?\n'));
  }

  static String joinLines(List<String> lines, {String separator = '\n'}) {
    return lines.join(separator);
  }

  static String padLeft(String text, int width, {String padding = ' '}) {
    return text.padLeft(width, padding);
  }

  static String padRight(String text, int width, {String padding = ' '}) {
    return text.padRight(width, padding);
  }

  static String center(String text, int width, {String padding = ' '}) {
    if (text.length >= width) return text;
    final totalPadding = width - text.length;
    final leftPadding = totalPadding ~/ 2;
    final rightPadding = totalPadding - leftPadding;
    return (padding * leftPadding) + text + (padding * rightPadding);
  }

  static String repeat(String text, int count) {
    return text * count;
  }

  static String reverse(String text) {
    return text.split('').reversed.join('');
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String titleCase(String text) {
    return text.split(' ').map(capitalize).join(' ');
  }

  static String camelCase(String text) {
    final words = text.split(RegExp(r'[_\s-]+'));
    if (words.isEmpty) return text;
    return words.first.toLowerCase() + words.skip(1).map(capitalize).join('');
  }

  static String snakeCase(String text) {
    return text
        .replaceAllMapped(
            RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceAll(RegExp(r'[_\s-]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .toLowerCase();
  }

  static String kebabCase(String text) {
    return text
        .replaceAllMapped(
            RegExp(r'[A-Z]'), (match) => '-${match.group(0)!.toLowerCase()}')
        .replaceAll(RegExp(r'[_\s-]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '')
        .toLowerCase();
  }
}
