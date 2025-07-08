import 'dart:convert';
import 'package:crypto/crypto.dart';

class HttpUtils {
  static const Map<int, String> statusMessages = {
    100: 'Continue',
    101: 'Switching Protocols',
    102: 'Processing',
    103: 'Early Hints',
    200: 'OK',
    201: 'Created',
    202: 'Accepted',
    203: 'Non-Authoritative Information',
    204: 'No Content',
    205: 'Reset Content',
    206: 'Partial Content',
    207: 'Multi-Status',
    208: 'Already Reported',
    226: 'IM Used',
    300: 'Multiple Choices',
    301: 'Moved Permanently',
    302: 'Found',
    303: 'See Other',
    304: 'Not Modified',
    305: 'Use Proxy',
    307: 'Temporary Redirect',
    308: 'Permanent Redirect',
    400: 'Bad Request',
    401: 'Unauthorized',
    402: 'Payment Required',
    403: 'Forbidden',
    404: 'Not Found',
    405: 'Method Not Allowed',
    406: 'Not Acceptable',
    407: 'Proxy Authentication Required',
    408: 'Request Timeout',
    409: 'Conflict',
    410: 'Gone',
    411: 'Length Required',
    412: 'Precondition Failed',
    413: 'Payload Too Large',
    414: 'URI Too Long',
    415: 'Unsupported Media Type',
    416: 'Range Not Satisfiable',
    417: 'Expectation Failed',
    418: "I'm a teapot",
    421: 'Misdirected Request',
    422: 'Unprocessable Entity',
    423: 'Locked',
    424: 'Failed Dependency',
    425: 'Too Early',
    426: 'Upgrade Required',
    428: 'Precondition Required',
    429: 'Too Many Requests',
    431: 'Request Header Fields Too Large',
    451: 'Unavailable For Legal Reasons',
    500: 'Internal Server Error',
    501: 'Not Implemented',
    502: 'Bad Gateway',
    503: 'Service Unavailable',
    504: 'Gateway Timeout',
    505: 'HTTP Version Not Supported',
    506: 'Variant Also Negotiates',
    507: 'Insufficient Storage',
    508: 'Loop Detected',
    510: 'Not Extended',
    511: 'Network Authentication Required',
  };

  static String getStatusMessage(int statusCode) {
    return statusMessages[statusCode] ?? 'Unknown Status';
  }

  static bool isInformational(int statusCode) =>
      statusCode >= 100 && statusCode < 200;
  static bool isSuccessful(int statusCode) =>
      statusCode >= 200 && statusCode < 300;
  static bool isRedirection(int statusCode) =>
      statusCode >= 300 && statusCode < 400;
  static bool isClientError(int statusCode) =>
      statusCode >= 400 && statusCode < 500;
  static bool isServerError(int statusCode) =>
      statusCode >= 500 && statusCode < 600;

  static String formatHttpDate(DateTime dateTime) {
    return dateTime.toUtc().toString().replaceAll(RegExp(r'\.\d{3}Z$'), ' GMT');
  }

  static DateTime? parseHttpDate(String? dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString.replaceAll(' GMT', 'Z'));
    } catch (_) {
      return null;
    }
  }

  static String generateETag(String content) {
    final bytes = utf8.encode(content);
    final hash = sha1.convert(bytes);
    return hash.toString();
  }

  static String generateETagFromBytes(List<int> bytes) {
    final hash = sha1.convert(bytes);
    return hash.toString();
  }

  static bool isValidHttpMethod(String method) {
    const validMethods = {
      'GET',
      'POST',
      'PUT',
      'DELETE',
      'PATCH',
      'HEAD',
      'OPTIONS',
      'TRACE',
      'CONNECT'
    };
    return validMethods.contains(method.toUpperCase());
  }

  static bool isValidHttpVersion(String version) {
    return version == '1.0' ||
        version == '1.1' ||
        version == '2.0' ||
        version == '3.0';
  }

  static String normalizeHeaderName(String name) {
    return name.toLowerCase().replaceAll('_', '-');
  }

  static String formatHeaderValue(String value) {
    return value.trim();
  }

  static Map<String, String> parseAcceptHeader(String? acceptHeader) {
    if (acceptHeader == null) return {};

    final result = <String, String>{};
    final parts = acceptHeader.split(',');

    for (final part in parts) {
      final trimmed = part.trim();
      final semicolonIndex = trimmed.indexOf(';');

      if (semicolonIndex == -1) {
        result[trimmed] = '1.0';
      } else {
        final mediaType = trimmed.substring(0, semicolonIndex);
        final params = trimmed.substring(semicolonIndex + 1);

        final qMatch = RegExp(r'q=([0-9.]+)').firstMatch(params);
        final quality = qMatch?.group(1) ?? '1.0';

        result[mediaType] = quality;
      }
    }

    return result;
  }

  static List<String> parseAcceptLanguageHeader(String? acceptLanguageHeader) {
    if (acceptLanguageHeader == null) return [];

    final languages = <String>[];
    final parts = acceptLanguageHeader.split(',');

    for (final part in parts) {
      final trimmed = part.trim();
      final semicolonIndex = trimmed.indexOf(';');

      if (semicolonIndex == -1) {
        languages.add(trimmed);
      } else {
        languages.add(trimmed.substring(0, semicolonIndex));
      }
    }

    return languages;
  }

  static Map<String, String> parseContentTypeHeader(String? contentTypeHeader) {
    if (contentTypeHeader == null) return {};

    final result = <String, String>{};
    final parts = contentTypeHeader.split(';');

    if (parts.isNotEmpty) {
      result['type'] = parts.first.trim();

      for (int i = 1; i < parts.length; i++) {
        final param = parts[i].trim();
        final equalIndex = param.indexOf('=');

        if (equalIndex != -1) {
          final key = param.substring(0, equalIndex).trim();
          final value =
              param.substring(equalIndex + 1).trim().replaceAll('"', '');
          result[key] = value;
        }
      }
    }

    return result;
  }

  static String buildContentTypeHeader(String type,
      {String? charset, Map<String, String>? parameters}) {
    final parts = [type];

    if (charset != null) {
      parts.add('charset=$charset');
    }

    if (parameters != null) {
      for (final entry in parameters.entries) {
        parts.add('${entry.key}=${entry.value}');
      }
    }

    return parts.join('; ');
  }

  static bool isJsonContentType(String? contentType) {
    if (contentType == null) return false;
    return contentType.toLowerCase().contains('application/json');
  }

  static bool isFormContentType(String? contentType) {
    if (contentType == null) return false;
    return contentType
        .toLowerCase()
        .contains('application/x-www-form-urlencoded');
  }

  static bool isMultipartContentType(String? contentType) {
    if (contentType == null) return false;
    return contentType.toLowerCase().contains('multipart/form-data');
  }

  static bool isXmlContentType(String? contentType) {
    if (contentType == null) return false;
    final lower = contentType.toLowerCase();
    return lower.contains('application/xml') || lower.contains('text/xml');
  }

  static bool isHtmlContentType(String? contentType) {
    if (contentType == null) return false;
    return contentType.toLowerCase().contains('text/html');
  }

  static bool isTextContentType(String? contentType) {
    if (contentType == null) return false;
    return contentType.toLowerCase().startsWith('text/');
  }

  static String quote(String value) {
    return '"${value.replaceAll('"', '\\"')}"';
  }

  static String unquote(String value) {
    if (value.startsWith('"') && value.endsWith('"')) {
      return value.substring(1, value.length - 1).replaceAll('\\"', '"');
    }
    return value;
  }

  static String formatByteSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (_) {
      return false;
    }
  }

  static bool isAbsoluteUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme;
    } catch (_) {
      return false;
    }
  }

  static String joinUrls(String base, String path) {
    if (path.startsWith('/')) {
      final baseUri = Uri.parse(base);
      return '${baseUri.scheme}://${baseUri.authority}$path';
    }

    if (base.endsWith('/')) {
      return base + path;
    }

    return '$base/$path';
  }

  static Map<String, String> parseQueryString(String queryString) {
    final result = <String, String>{};
    if (queryString.isEmpty) return result;

    final pairs = queryString.split('&');
    for (final pair in pairs) {
      final equalIndex = pair.indexOf('=');
      if (equalIndex == -1) {
        result[Uri.decodeQueryComponent(pair)] = '';
      } else {
        final key = Uri.decodeQueryComponent(pair.substring(0, equalIndex));
        final value = Uri.decodeQueryComponent(pair.substring(equalIndex + 1));
        result[key] = value;
      }
    }

    return result;
  }

  static String buildQueryString(Map<String, dynamic> params) {
    final pairs = <String>[];

    for (final entry in params.entries) {
      final key = Uri.encodeQueryComponent(entry.key);
      final value = Uri.encodeQueryComponent(entry.value.toString());
      pairs.add('$key=$value');
    }

    return pairs.join('&');
  }

  static String combineHeaders(String? existing, String newValue) {
    if (existing == null) return newValue;
    return '$existing, $newValue';
  }

  static List<String> parseHeaderList(String? headerValue) {
    if (headerValue == null) return [];
    return headerValue
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static String generateBoundary() {
    final random = List.generate(16, (i) => (97 + (i % 26)));
    return String.fromCharCodes(random);
  }

  static bool isValidHttpHeaderName(String name) {
    return RegExp(r'^[a-zA-Z0-9!#$%&*+\-.^_`|~]+$').hasMatch(name);
  }

  static bool isValidHttpHeaderValue(String value) {
    return !value.contains(RegExp(r'[\r\n]'));
  }

  static String sanitizeHeaderValue(String value) {
    return value.replaceAll(RegExp(r'[\r\n\t]'), ' ').trim();
  }

  static bool matchesMediaType(String mediaType, String pattern) {
    if (pattern == '*/*') return true;
    if (pattern.endsWith('/*')) {
      final prefix = pattern.substring(0, pattern.length - 2);
      return mediaType.startsWith(prefix);
    }
    return mediaType == pattern;
  }

  static double parseQuality(String? qValue) {
    if (qValue == null) return 1.0;
    try {
      final quality = double.parse(qValue);
      return quality.clamp(0.0, 1.0);
    } catch (_) {
      return 1.0;
    }
  }

  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h ${duration.inMinutes % 60}m';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  static String escapeHeaderValue(String value) {
    return value.replaceAll('"', '\\"');
  }

  static String unescapeHeaderValue(String value) {
    return value.replaceAll('\\"', '"');
  }

  static bool isSecureScheme(String scheme) {
    return scheme.toLowerCase() == 'https';
  }

  static int getDefaultPort(String scheme) {
    switch (scheme.toLowerCase()) {
      case 'http':
        return 80;
      case 'https':
        return 443;
      case 'ftp':
        return 21;
      case 'ftps':
        return 990;
      default:
        return 80;
    }
  }

  static String normalizeHost(String host) {
    return host.toLowerCase();
  }

  static bool isValidHost(String host) {
    return RegExp(r'^[a-zA-Z0-9.-]+$').hasMatch(host);
  }

  static bool isValidPort(int port) {
    return port >= 1 && port <= 65535;
  }

  static String buildFullUrl(String scheme, String host, int port, String path,
      {String? query, String? fragment}) {
    final buffer = StringBuffer();
    buffer.write(scheme);
    buffer.write('://');
    buffer.write(host);

    if (port != getDefaultPort(scheme)) {
      buffer.write(':');
      buffer.write(port);
    }

    buffer.write(path);

    if (query != null && query.isNotEmpty) {
      buffer.write('?');
      buffer.write(query);
    }

    if (fragment != null && fragment.isNotEmpty) {
      buffer.write('#');
      buffer.write(fragment);
    }

    return buffer.toString();
  }
}
