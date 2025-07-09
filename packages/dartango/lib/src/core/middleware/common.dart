import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

import '../http/request.dart';
import '../http/response.dart';
import 'base.dart';

class CommonMiddleware extends BaseMiddleware {
  final bool appendSlash;
  final bool prependWww;
  final bool removeWww;
  final List<String> ignoredPaths;
  final bool useEtags;
  final bool useConditionalGet;
  final Map<String, String> responseHeaders;
  final int? contentLengthWarning;
  final List<String> disallowedUserAgents;
  final bool allowedHostsRequired;
  final List<String> allowedHosts;

  CommonMiddleware({
    bool? appendSlash,
    bool? prependWww,
    bool? removeWww,
    List<String>? ignoredPaths,
    bool? useEtags,
    bool? useConditionalGet,
    Map<String, String>? responseHeaders,
    this.contentLengthWarning,
    List<String>? disallowedUserAgents,
    bool? allowedHostsRequired,
    List<String>? allowedHosts,
  })  : appendSlash = appendSlash ?? true,
        prependWww = prependWww ?? false,
        removeWww = removeWww ?? false,
        ignoredPaths = ignoredPaths ?? [],
        useEtags = useEtags ?? true,
        useConditionalGet = useConditionalGet ?? true,
        responseHeaders = responseHeaders ?? {},
        disallowedUserAgents = disallowedUserAgents ?? [],
        allowedHostsRequired = allowedHostsRequired ?? true,
        allowedHosts = allowedHosts ?? [];

  @override
  FutureOr<HttpResponse?> processRequest(HttpRequest request) {
    final host = request.host;
    
    if (allowedHostsRequired && !_isAllowedHost(host)) {
      return HttpResponse.badRequest('Invalid host header');
    }

    final userAgent = request.headers['user-agent'] ?? '';
    if (_isDisallowedUserAgent(userAgent)) {
      return HttpResponse.forbidden('Forbidden user agent');
    }

    String path = request.path;
    String? newPath;

    if (prependWww && !host.startsWith('www.')) {
      return _redirectToWww(request);
    }

    if (removeWww && host.startsWith('www.')) {
      return _redirectFromWww(request);
    }

    if (appendSlash && !path.endsWith('/') && !_hasExtension(path)) {
      newPath = '$path/';
    }

    if (newPath != null && _shouldRedirect(request, newPath)) {
      return _redirect(request, newPath);
    }

    return null;
  }

  @override
  FutureOr<HttpResponse> processResponse(
    HttpRequest request,
    HttpResponse response,
  ) {
    for (final entry in responseHeaders.entries) {
      response = response.setHeader(entry.key, entry.value);
    }

    if (contentLengthWarning != null) {
      final contentLength = response.headers['content-length'];
      if (contentLength != null) {
        final length = int.tryParse(contentLength);
        if (length != null && length > contentLengthWarning!) {
          _logLargeResponse(request, length);
        }
      }
    }

    if (!_shouldProcessConditional(request, response)) {
      return response;
    }

    if (useEtags && !response.headers.containsKey('etag')) {
      response = _addEtag(response);
    }

    if (useConditionalGet) {
      response = _handleConditionalGet(request, response);
    }

    return response;
  }

  bool _isAllowedHost(String host) {
    if (allowedHosts.isEmpty) {
      return true;
    }

    final hostWithoutPort = host.split(':').first;

    for (final allowed in allowedHosts) {
      if (allowed == '*') {
        return true;
      }

      if (allowed.startsWith('.')) {
        if (hostWithoutPort.endsWith(allowed) || hostWithoutPort == allowed.substring(1)) {
          return true;
        }
      } else if (hostWithoutPort == allowed) {
        return true;
      }
    }

    return false;
  }

  bool _isDisallowedUserAgent(String userAgent) {
    if (disallowedUserAgents.isEmpty) {
      return false;
    }

    final lowerUserAgent = userAgent.toLowerCase();
    for (final pattern in disallowedUserAgents) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lowerUserAgent)) {
        return true;
      }
    }

    return false;
  }

  bool _hasExtension(String path) {
    final lastSegment = path.split('/').last;
    return lastSegment.contains('.') && !lastSegment.endsWith('.');
  }

  bool _shouldRedirect(HttpRequest request, String newPath) {
    if (request.method != 'GET' && request.method != 'HEAD') {
      return false;
    }

    for (final pattern in ignoredPaths) {
      if (RegExp(pattern).hasMatch(request.path)) {
        return false;
      }
    }

    return true;
  }

  HttpResponse _redirect(HttpRequest request, String newPath) {
    final query = request.uri.query.isNotEmpty ? '?${request.uri.query}' : '';
    final newUrl = '${request.scheme}://${request.host}$newPath$query';
    return HttpResponse.permanentRedirect(newUrl);
  }

  HttpResponse _redirectToWww(HttpRequest request) {
    final newHost = 'www.${request.host}';
    final path = request.uri.path;
    final query = request.uri.query.isNotEmpty ? '?${request.uri.query}' : '';
    final newUrl = '${request.scheme}://$newHost$path$query';
    return HttpResponse.permanentRedirect(newUrl);
  }

  HttpResponse _redirectFromWww(HttpRequest request) {
    final newHost = request.host.substring(4);
    final path = request.uri.path;
    final query = request.uri.query.isNotEmpty ? '?${request.uri.query}' : '';
    final newUrl = '${request.scheme}://$newHost$path$query';
    return HttpResponse.permanentRedirect(newUrl);
  }

  bool _shouldProcessConditional(HttpRequest request, HttpResponse response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return false;
    }

    if (request.method != 'GET' && request.method != 'HEAD') {
      return false;
    }

    return true;
  }

  HttpResponse _addEtag(HttpResponse response) {
    final content = response.body;
    if (content is String) {
      final etag = _generateEtag(content);
      return response.setHeader('etag', etag);
    } else if (content is List<int>) {
      final etag = _generateEtagFromBytes(content);
      return response.setHeader('etag', etag);
    }
    return response;
  }

  String _generateEtag(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return '"${digest.toString().substring(0, 16)}"';
  }

  String _generateEtagFromBytes(List<int> content) {
    final digest = sha256.convert(content);
    return '"${digest.toString().substring(0, 16)}"';
  }

  HttpResponse _handleConditionalGet(HttpRequest request, HttpResponse response) {
    final etag = response.headers['etag'];
    final lastModified = response.headers['last-modified'];

    if (etag != null) {
      final ifNoneMatch = request.headers['if-none-match'];
      if (ifNoneMatch != null && _etagMatches(etag, ifNoneMatch)) {
        return _notModifiedResponse(response);
      }

      final ifMatch = request.headers['if-match'];
      if (ifMatch != null && !_etagMatches(etag, ifMatch)) {
        return HttpResponse(
          'Precondition Failed',
          statusCode: HttpStatus.preconditionFailed,
        );
      }
    }

    if (lastModified != null) {
      final ifModifiedSince = request.headers['if-modified-since'];
      if (ifModifiedSince != null) {
        try {
          final ifModifiedDate = HttpDate.parse(ifModifiedSince);
          final lastModifiedDate = HttpDate.parse(lastModified);
          if (lastModifiedDate.isBefore(ifModifiedDate) || 
              lastModifiedDate.isAtSameMomentAs(ifModifiedDate)) {
            return _notModifiedResponse(response);
          }
        } catch (e) {
          // Invalid date format, ignore
        }
      }

      final ifUnmodifiedSince = request.headers['if-unmodified-since'];
      if (ifUnmodifiedSince != null) {
        try {
          final ifUnmodifiedDate = HttpDate.parse(ifUnmodifiedSince);
          final lastModifiedDate = HttpDate.parse(lastModified);
          if (lastModifiedDate.isAfter(ifUnmodifiedDate)) {
            return HttpResponse(
              'Precondition Failed',
              statusCode: HttpStatus.preconditionFailed,
            );
          }
        } catch (e) {
          // Invalid date format, ignore
        }
      }
    }

    return response;
  }

  bool _etagMatches(String etag, String matchHeader) {
    if (matchHeader == '*') {
      return true;
    }

    final tags = matchHeader.split(',').map((tag) => tag.trim()).toList();
    return tags.contains(etag);
  }

  HttpResponse _notModifiedResponse(HttpResponse originalResponse) {
    var response = HttpResponse(
      '',
      statusCode: HttpStatus.notModified,
    );

    final headersToKeep = [
      'cache-control',
      'content-location',
      'date',
      'etag',
      'expires',
      'last-modified',
      'vary',
    ];

    for (final header in headersToKeep) {
      final value = originalResponse.headers[header];
      if (value != null) {
        response = response.setHeader(header, value);
      }
    }

    return response;
  }

  void _logLargeResponse(HttpRequest request, int contentLength) {
    final path = request.uri.path;
    final method = request.method;
    final mb = (contentLength / 1048576).toStringAsFixed(2);
    print('Large response: $method $path returned ${mb}MB');
  }
}

class ConditionalGetMiddleware extends BaseMiddleware {
  @override
  FutureOr<HttpResponse> processResponse(
    HttpRequest request,
    HttpResponse response,
  ) {
    if (!_shouldProcess(request, response)) {
      return response;
    }

    final etag = response.headers['etag'];
    final lastModified = response.headers['last-modified'];

    if (etag == null && lastModified == null) {
      return response;
    }

    if (etag != null) {
      final ifNoneMatch = request.headers['if-none-match'];
      if (ifNoneMatch != null && _etagMatches(etag, ifNoneMatch)) {
        return _notModifiedResponse(response);
      }
    }

    if (lastModified != null) {
      final ifModifiedSince = request.headers['if-modified-since'];
      if (ifModifiedSince != null) {
        try {
          final ifModifiedDate = HttpDate.parse(ifModifiedSince);
          final lastModifiedDate = HttpDate.parse(lastModified);
          if (!lastModifiedDate.isAfter(ifModifiedDate)) {
            return _notModifiedResponse(response);
          }
        } catch (e) {
          // Invalid date format, ignore
        }
      }
    }

    return response;
  }

  bool _shouldProcess(HttpRequest request, HttpResponse response) {
    if (response.statusCode != HttpStatus.ok) {
      return false;
    }

    if (request.method != 'GET' && request.method != 'HEAD') {
      return false;
    }

    return true;
  }

  bool _etagMatches(String etag, String matchHeader) {
    if (matchHeader == '*') {
      return true;
    }

    final tags = matchHeader.split(',').map((tag) => tag.trim()).toList();
    return tags.contains(etag);
  }

  HttpResponse _notModifiedResponse(HttpResponse originalResponse) {
    var response = HttpResponse(
      '',
      statusCode: HttpStatus.notModified,
    );

    final headersToKeep = [
      'cache-control',
      'content-location',
      'date',
      'etag',
      'expires',
      'last-modified',
      'vary',
    ];

    for (final header in headersToKeep) {
      final value = originalResponse.headers[header];
      if (value != null) {
        response = response.setHeader(header, value);
      }
    }

    return response;
  }
}

class BrokenLinkEmailsMiddleware extends BaseMiddleware {
  final List<String> ignorable404Urls;
  final List<String> ignorable404UserAgents;
  final String? reportTo;
  final bool reportOnly404s;

  BrokenLinkEmailsMiddleware({
    List<String>? ignorable404Urls,
    List<String>? ignorable404UserAgents,
    this.reportTo,
    this.reportOnly404s = true,
  })  : ignorable404Urls = ignorable404Urls ?? [],
        ignorable404UserAgents = ignorable404UserAgents ?? [
          'bot',
          'spider',
          'crawler',
          'slurp',
          'twiceler',
        ];

  @override
  FutureOr<HttpResponse> processResponse(
    HttpRequest request,
    HttpResponse response,
  ) {
    if (reportTo == null) {
      return response;
    }

    if (reportOnly404s && response.statusCode != HttpStatus.notFound) {
      return response;
    }

    if (!reportOnly404s && response.statusCode < 400) {
      return response;
    }

    if (_shouldIgnore(request)) {
      return response;
    }

    _reportBrokenLink(request, response);
    return response;
  }

  bool _shouldIgnore(HttpRequest request) {
    final path = request.uri.path;
    for (final pattern in ignorable404Urls) {
      if (RegExp(pattern).hasMatch(path)) {
        return true;
      }
    }

    final userAgent = request.headers['user-agent']?.toLowerCase() ?? '';
    for (final pattern in ignorable404UserAgents) {
      if (userAgent.contains(pattern)) {
        return true;
      }
    }

    final referer = request.headers['referer'];
    if (referer == null || referer.isEmpty) {
      return true;
    }

    return false;
  }

  void _reportBrokenLink(HttpRequest request, HttpResponse response) {
    final path = request.uri.toString();
    final referer = request.headers['referer'] ?? 'unknown';
    final userAgent = request.headers['user-agent'] ?? 'unknown';
    final statusCode = response.statusCode;

    print('Broken link: $statusCode for $path (referred by: $referer, user-agent: $userAgent)');
  }
}