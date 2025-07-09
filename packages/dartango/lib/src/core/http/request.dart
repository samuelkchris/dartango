import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart' as shelf;

import '../exceptions/http.dart';

class HttpRequest {
  final shelf.Request _shelfRequest;
  final Map<String, dynamic> _middlewareState = {};
  final Map<String, dynamic> _meta = {};

  String? _bodyString;
  Map<String, dynamic>? _parsedBody;
  Map<String, List<String>>? _parsedQueryParams;
  Map<String, Cookie>? _parsedCookies;
  bool _bodyParsed = false;
  bool _queryParamsParsed = false;
  bool _cookiesParsed = false;

  HttpRequest(this._shelfRequest);

  String get method => _shelfRequest.method;
  Uri get uri => _shelfRequest.requestedUri;
  String get path => uri.path;
  String get pathInfo => path;
  String get queryString => uri.query;
  String get scheme => uri.scheme;
  bool get isSecure => scheme == 'https';
  String get host => uri.host;
  int get port => uri.port;
  String get hostWithPort => uri.hasPort ? '$host:$port' : host;

  Map<String, String> get headers => _shelfRequest.headers;
  Map<String, dynamic> get meta => _meta;
  Map<String, dynamic> get middlewareState => _middlewareState;
  Map<String, dynamic> get context => _middlewareState;

  String? getHeader(String name) => headers[name.toLowerCase()];
  List<String> getHeaders(String name) {
    final value = getHeader(name);
    if (value == null) return [];
    return value.split(',').map((s) => s.trim()).toList();
  }

  bool hasHeader(String name) => headers.containsKey(name.toLowerCase());

  String? get contentType => getHeader('content-type');
  String? get contentLength => getHeader('content-length');
  String? get userAgent => getHeader('user-agent');
  String? get referer => getHeader('referer');
  String? get authorization => getHeader('authorization');
  String? get acceptLanguage => getHeader('accept-language');
  String? get acceptEncoding => getHeader('accept-encoding');
  String? get accept => getHeader('accept');
  String? get xForwardedFor => getHeader('x-forwarded-for');
  String? get xForwardedHost => getHeader('x-forwarded-host');
  String? get xForwardedProto => getHeader('x-forwarded-proto');
  String? get xRealIp => getHeader('x-real-ip');

  String get remoteAddr {
    if (xRealIp != null) return xRealIp!;
    if (xForwardedFor != null) {
      final ips = xForwardedFor!.split(',').map((s) => s.trim()).toList();
      if (ips.isNotEmpty) return ips.first;
    }
    final connectionInfo = _shelfRequest.context['shelf.io.connection_info'];
    if (connectionInfo != null) {
      return connectionInfo.toString();
    }
    return 'unknown';
  }

  String get serverName => xForwardedHost ?? host;
  int get serverPort => port;

  bool get isAjax =>
      getHeader('x-requested-with')?.toLowerCase() == 'xmlhttprequest';
  bool get isPost => method == 'POST';
  bool get isGet => method == 'GET';
  bool get isPut => method == 'PUT';
  bool get isDelete => method == 'DELETE';
  bool get isPatch => method == 'PATCH';
  bool get isHead => method == 'HEAD';
  bool get isOptions => method == 'OPTIONS';
  bool get isTrace => method == 'TRACE';

  Map<String, List<String>> get queryParams {
    if (!_queryParamsParsed) {
      _parsedQueryParams = <String, List<String>>{};
      if (uri.query.isNotEmpty) {
        final pairs = uri.query.split('&');
        for (final pair in pairs) {
          final equalIndex = pair.indexOf('=');
          if (equalIndex != -1) {
            final key = Uri.decodeQueryComponent(pair.substring(0, equalIndex));
            final value =
                Uri.decodeQueryComponent(pair.substring(equalIndex + 1));
            if (_parsedQueryParams!.containsKey(key)) {
              _parsedQueryParams![key]!.add(value);
            } else {
              _parsedQueryParams![key] = [value];
            }
          } else {
            final key = Uri.decodeQueryComponent(pair);
            if (_parsedQueryParams!.containsKey(key)) {
              _parsedQueryParams![key]!.add('');
            } else {
              _parsedQueryParams![key] = [''];
            }
          }
        }
      }
      _queryParamsParsed = true;
    }
    return _parsedQueryParams!;
  }

  String? getQueryParam(String key) => queryParams[key]?.first;
  List<String> getQueryParams(String key) => queryParams[key] ?? [];

  Map<String, Cookie> get cookies {
    if (!_cookiesParsed) {
      _parsedCookies = <String, Cookie>{};
      final cookieHeader = getHeader('cookie');
      if (cookieHeader != null) {
        final cookiePairs = cookieHeader.split(';');
        for (final pair in cookiePairs) {
          final equalIndex = pair.indexOf('=');
          if (equalIndex != -1) {
            final name = pair.substring(0, equalIndex).trim();
            final value = pair.substring(equalIndex + 1).trim();
            _parsedCookies![name] = Cookie(name, value);
          }
        }
      }
      _cookiesParsed = true;
    }
    return _parsedCookies!;
  }

  String? getCookie(String name) => cookies[name]?.value;

  Future<String> get body async {
    if (_bodyString == null) {
      final bytes =
          await _shelfRequest.read().expand((chunk) => chunk).toList();
      _bodyString = utf8.decode(bytes);
    }
    return _bodyString!;
  }

  Future<Uint8List> get bodyBytes async {
    final bytes = await _shelfRequest.read().expand((chunk) => chunk).toList();
    return Uint8List.fromList(bytes);
  }

  Future<Map<String, dynamic>> get parsedBody async {
    if (!_bodyParsed) {
      _parsedBody = {};
      final bodyStr = await body;

      if (bodyStr.isEmpty) {
        _parsedBody = {};
      } else if (contentType?.startsWith('application/json') == true) {
        try {
          _parsedBody = json.decode(bodyStr) as Map<String, dynamic>;
        } catch (e) {
          throw BadRequestException('Invalid JSON in request body');
        }
      } else if (contentType?.startsWith('application/x-www-form-urlencoded') ==
          true) {
        _parsedBody = <String, dynamic>{};
        final params = Uri.splitQueryString(bodyStr);
        params.forEach((key, value) {
          _parsedBody![key] = value;
        });
      } else if (contentType?.startsWith('multipart/form-data') == true) {
        _parsedBody = await _parseMultipartFormData(bodyStr);
      } else {
        _parsedBody = {'_raw': bodyStr};
      }
      _bodyParsed = true;
    }
    return _parsedBody!;
  }

  Future<Map<String, dynamic>> _parseMultipartFormData(String body) async {
    final contentTypeHeader = contentType!;
    final boundary = _extractBoundary(contentTypeHeader);
    if (boundary == null) {
      throw BadRequestException(
          'Invalid multipart form data: missing boundary');
    }

    final parts = body.split('--$boundary');
    final result = <String, dynamic>{};
    final files = <String, HttpFile>{};

    for (final part in parts) {
      if (part.trim().isEmpty || part.trim() == '--') continue;

      final lines = part.split('\r\n');
      if (lines.length < 3) continue;

      final dispositionLine = lines.firstWhere(
        (line) => line.toLowerCase().startsWith('content-disposition:'),
        orElse: () => '',
      );

      if (dispositionLine.isEmpty) continue;

      final nameMatch = RegExp(r'name="([^"]*)"').firstMatch(dispositionLine);
      if (nameMatch == null) continue;

      final name = nameMatch.group(1)!;
      final filenameMatch =
          RegExp(r'filename="([^"]*)"').firstMatch(dispositionLine);

      final contentStart = lines.indexWhere((line) => line.isEmpty) + 1;
      if (contentStart >= lines.length) continue;

      final content = lines.sublist(contentStart).join('\r\n');

      if (filenameMatch != null) {
        final filename = filenameMatch.group(1)!;
        final contentTypeLine = lines.firstWhere(
          (line) => line.toLowerCase().startsWith('content-type:'),
          orElse: () => 'content-type: application/octet-stream',
        );
        final fileContentType = contentTypeLine.split(':')[1].trim();

        files[name] = HttpFile(
          name: filename,
          contentType: fileContentType,
          content: utf8.encode(content),
        );
      } else {
        result[name] = content;
      }
    }

    result['_files'] = files;
    return result;
  }

  String? _extractBoundary(String contentType) {
    final match = RegExp(r'boundary=([^;]+)').firstMatch(contentType);
    return match?.group(1)?.replaceAll('"', '');
  }

  dynamic operator [](String key) {
    if (queryParams.containsKey(key)) {
      return getQueryParam(key);
    }
    return null;
  }

  bool containsKey(String key) => queryParams.containsKey(key);

  String get fullPath => uri.toString();
  String get absoluteUri => uri.toString();

  HttpRequest copyWith({
    String? method,
    Uri? uri,
    Map<String, String>? headers,
    Map<String, dynamic>? meta,
  }) {
    final newRequest = shelf.Request(
      method ?? this.method,
      uri ?? this.uri,
      headers: headers ?? this.headers,
      context: _shelfRequest.context,
    );
    final copy = HttpRequest(newRequest);
    copy._meta.addAll(meta ?? this.meta);
    return copy;
  }

  Map<String, dynamic> toMap() {
    return {
      'method': method,
      'uri': uri.toString(),
      'path': path,
      'query_string': queryString,
      'headers': headers,
      'remote_addr': remoteAddr,
      'server_name': serverName,
      'server_port': serverPort,
      'is_secure': isSecure,
      'is_ajax': isAjax,
      'content_type': contentType,
      'content_length': contentLength,
      'user_agent': userAgent,
    };
  }

  @override
  String toString() => '$method $path';
}

class HttpFile {
  final String name;
  final String contentType;
  final Uint8List content;

  HttpFile({
    required this.name,
    required this.contentType,
    required this.content,
  });

  int get size => content.length;
  String get extension => name.split('.').last;

  Future<void> saveTo(String path) async {
    final file = File(path);
    await file.writeAsBytes(content);
  }

  String get contentAsString => utf8.decode(content);

  @override
  String toString() => 'HttpFile($name, $contentType, ${size}bytes)';
}
