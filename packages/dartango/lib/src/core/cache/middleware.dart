import 'dart:async';

import '../http/request.dart';
import '../http/response.dart';
import '../middleware/base.dart';
import 'cache.dart';

class CacheMiddleware extends BaseMiddleware {
  final Cache cache;
  final Duration defaultTimeout;
  final List<String> cacheableHeaders;
  final List<String> varyHeaders;
  final bool cacheAnonymousOnly;

  CacheMiddleware({
    required this.cache,
    this.defaultTimeout = const Duration(minutes: 5),
    this.cacheableHeaders = const [
      'cache-control',
      'expires',
      'etag',
      'last-modified',
      'vary',
    ],
    this.varyHeaders = const ['Accept-Language', 'User-Agent'],
    this.cacheAnonymousOnly = true,
  });

  @override
  Future<HttpResponse?> processRequest(HttpRequest request) async {
    if (!_shouldCacheRequest(request)) {
      return null;
    }

    final cacheKey = _generateCacheKey(request);
    final cachedResponse = await cache.get<Map<String, dynamic>>(cacheKey);

    if (cachedResponse != null) {
      return _deserializeResponse(cachedResponse);
    }

    return null;
  }

  @override
  Future<HttpResponse> processResponse(HttpRequest request, HttpResponse response) async {
    if (!_shouldCacheResponse(request, response)) {
      return response;
    }

    final cacheKey = _generateCacheKey(request);
    final timeout = _getCacheTimeout(response);
    
    if (timeout != null) {
      final serializedResponse = _serializeResponse(response);
      await cache.set(cacheKey, serializedResponse, timeout: timeout);
    }

    return response;
  }

  bool _shouldCacheRequest(HttpRequest request) {
    if (request.method != 'GET' && request.method != 'HEAD') {
      return false;
    }

    if (cacheAnonymousOnly && request.hasUser) {
      return false;
    }

    final cacheControl = request.headers['cache-control'];
    if (cacheControl != null && 
        (cacheControl.contains('no-cache') || cacheControl.contains('no-store'))) {
      return false;
    }

    return true;
  }

  bool _shouldCacheResponse(HttpRequest request, HttpResponse response) {
    if (response.statusCode != 200) {
      return false;
    }

    final cacheControl = response.headers['cache-control'];
    if (cacheControl != null && 
        (cacheControl.contains('no-cache') || 
         cacheControl.contains('no-store') ||
         cacheControl.contains('private'))) {
      return false;
    }

    if (response.headers.containsKey('set-cookie')) {
      return false;
    }

    return true;
  }

  String _generateCacheKey(HttpRequest request) {
    final baseKey = '${request.method}:${request.path}';
    
    if (request.queryParameters.isNotEmpty) {
      final sortedParams = request.queryParameters.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final queryString = sortedParams
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      return '$baseKey?$queryString';
    }

    final varyValues = varyHeaders
        .where((header) => request.headers.containsKey(header))
        .map((header) => '$header:${request.headers[header]}')
        .join('|');

    return varyValues.isNotEmpty ? '$baseKey|$varyValues' : baseKey;
  }

  Duration? _getCacheTimeout(HttpResponse response) {
    final cacheControl = response.headers['cache-control'];
    if (cacheControl != null) {
      final maxAgeMatch = RegExp(r'max-age=(\d+)').firstMatch(cacheControl);
      if (maxAgeMatch != null) {
        final seconds = int.parse(maxAgeMatch.group(1)!);
        return Duration(seconds: seconds);
      }
    }

    final expires = response.headers['expires'];
    if (expires != null) {
      try {
        final expiryDate = DateTime.parse(expires);
        final now = DateTime.now();
        if (expiryDate.isAfter(now)) {
          return expiryDate.difference(now);
        }
      } catch (e) {
        // Invalid expires header
      }
    }

    return defaultTimeout;
  }

  Map<String, dynamic> _serializeResponse(HttpResponse response) {
    return {
      'status_code': response.statusCode,
      'headers': response.headers,
      'body': response.body,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  HttpResponse _deserializeResponse(Map<String, dynamic> data) {
    final statusCode = data['status_code'] as int;
    final headers = Map<String, String>.from(data['headers'] as Map);
    final body = data['body'] as String;

    headers['x-cache'] = 'HIT';
    headers['x-cache-date'] = DateTime.fromMillisecondsSinceEpoch(
      data['cached_at'] as int,
    ).toIso8601String();

    return HttpResponse(
      body: body,
      statusCode: statusCode,
      headers: headers,
    );
  }
}

class VaryHeaderMiddleware extends BaseMiddleware {
  final List<String> varyHeaders;

  VaryHeaderMiddleware({
    this.varyHeaders = const ['Accept-Language', 'User-Agent'],
  });

  @override
  Future<HttpResponse> processResponse(HttpRequest request, HttpResponse response) async {
    final existingVary = response.headers['vary'];
    final varyValues = <String>[];

    if (existingVary != null) {
      varyValues.addAll(existingVary.split(',').map((s) => s.trim()));
    }

    for (final header in varyHeaders) {
      if (!varyValues.contains(header)) {
        varyValues.add(header);
      }
    }

    if (varyValues.isNotEmpty) {
      response.headers['vary'] = varyValues.join(', ');
    }

    return response;
  }
}

class ETagMiddleware extends BaseMiddleware {
  @override
  Future<HttpResponse> processResponse(HttpRequest request, HttpResponse response) async {
    if (response.statusCode == 200 && !response.headers.containsKey('etag')) {
      final etag = _generateETag(response.body);
      response.headers['etag'] = etag;

      final ifNoneMatch = request.headers['if-none-match'];
      if (ifNoneMatch == etag) {
        return HttpResponse(
          statusCode: 304,
          headers: {
            'etag': etag,
            'cache-control': response.headers['cache-control'] ?? 'max-age=0',
          },
        );
      }
    }

    return response;
  }

  String _generateETag(String content) {
    return '"${content.hashCode.abs().toRadixString(16)}"';
  }
}

class ConditionalGetMiddleware extends BaseMiddleware {
  @override
  Future<HttpResponse> processResponse(HttpRequest request, HttpResponse response) async {
    if (response.statusCode != 200) {
      return response;
    }

    final ifModifiedSince = request.headers['if-modified-since'];
    final lastModified = response.headers['last-modified'];

    if (ifModifiedSince != null && lastModified != null) {
      try {
        final clientDate = DateTime.parse(ifModifiedSince);
        final resourceDate = DateTime.parse(lastModified);

        if (!resourceDate.isAfter(clientDate)) {
          return HttpResponse(
            statusCode: 304,
            headers: {
              'last-modified': lastModified,
              'cache-control': response.headers['cache-control'] ?? 'max-age=0',
            },
          );
        }
      } catch (e) {
        // Invalid date headers
      }
    }

    return response;
  }
}

class CacheControlMiddleware extends BaseMiddleware {
  final String defaultCacheControl;

  CacheControlMiddleware({
    this.defaultCacheControl = 'max-age=300, public',
  });

  @override
  Future<HttpResponse> processResponse(HttpRequest request, HttpResponse response) async {
    if (!response.headers.containsKey('cache-control')) {
      response.headers['cache-control'] = defaultCacheControl;
    }

    return response;
  }
}