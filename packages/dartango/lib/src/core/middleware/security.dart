import 'dart:async';

import '../http/request.dart';
import '../http/response.dart';
import 'base.dart';

class SecurityMiddleware extends BaseMiddleware {
  static const String hstsHeader = 'Strict-Transport-Security';
  static const String contentTypeOptionsHeader = 'X-Content-Type-Options';
  static const String xssProtectionHeader = 'X-XSS-Protection';
  static const String frameOptionsHeader = 'X-Frame-Options';
  static const String contentSecurityPolicyHeader = 'Content-Security-Policy';
  static const String referrerPolicyHeader = 'Referrer-Policy';
  static const String featurePolicyHeader = 'Feature-Policy';
  static const String permissionsPolicyHeader = 'Permissions-Policy';

  final bool secureRedirect;
  final List<String> secureRedirectExempt;
  final String? secureRedirectHost;
  final bool secureSslRedirect;
  final Duration? hstsMaxAge;
  final bool hstsIncludeSubdomains;
  final bool hstsPreload;
  final bool contentTypeNosniff;
  final bool xssFilter;
  final String? frameOptions;
  final Map<String, String>? contentSecurityPolicy;
  final String? referrerPolicy;
  final Map<String, String>? featurePolicy;
  final Map<String, String>? permissionsPolicy;
  final List<String> secureProxyHeaders;

  SecurityMiddleware({
    bool? secureRedirect,
    List<String>? secureRedirectExempt,
    this.secureRedirectHost,
    bool? secureSslRedirect,
    Duration? hstsMaxAge,
    bool? hstsIncludeSubdomains,
    bool? hstsPreload,
    bool? contentTypeNosniff,
    bool? xssFilter,
    String? frameOptions,
    this.contentSecurityPolicy,
    this.referrerPolicy,
    this.featurePolicy,
    this.permissionsPolicy,
    List<String>? secureProxyHeaders,
  })  : secureRedirect = secureRedirect ?? false,
        secureRedirectExempt = secureRedirectExempt ?? [],
        secureSslRedirect = secureSslRedirect ?? false,
        hstsMaxAge = hstsMaxAge,
        hstsIncludeSubdomains = hstsIncludeSubdomains ?? false,
        hstsPreload = hstsPreload ?? false,
        contentTypeNosniff = contentTypeNosniff ?? true,
        xssFilter = xssFilter ?? true,
        frameOptions = frameOptions ?? 'DENY',
        secureProxyHeaders = secureProxyHeaders ?? [];


  @override
  FutureOr<HttpResponse?> processRequest(HttpRequest request) {
    if (secureSslRedirect && !_isSecure(request)) {
      if (!_isExempt(request.path)) {
        return _redirectToHttps(request);
      }
    }
    return null;
  }

  @override
  FutureOr<HttpResponse> processResponse(
    HttpRequest request,
    HttpResponse response,
  ) {
    if (_isSecure(request)) {
      if (hstsMaxAge != null) {
        final hstsValue = _buildHstsHeader();
        response = response.setHeader(hstsHeader, hstsValue);
      }
    }

    if (contentTypeNosniff) {
      response = response.setHeader(contentTypeOptionsHeader, 'nosniff');
    }

    if (xssFilter) {
      response = response.setHeader(xssProtectionHeader, '1; mode=block');
    }

    if (frameOptions != null) {
      response = response.setHeader(frameOptionsHeader, frameOptions!);
    }

    if (contentSecurityPolicy != null) {
      final cspValue = _buildCspHeader();
      response = response.setHeader(contentSecurityPolicyHeader, cspValue);
    }

    if (referrerPolicy != null) {
      response = response.setHeader(referrerPolicyHeader, referrerPolicy!);
    }

    if (featurePolicy != null) {
      final fpValue = _buildFeaturePolicyHeader();
      response = response.setHeader(featurePolicyHeader, fpValue);
    }

    if (permissionsPolicy != null) {
      final ppValue = _buildPermissionsPolicyHeader();
      response = response.setHeader(permissionsPolicyHeader, ppValue);
    }

    return response;
  }

  bool _isSecure(HttpRequest request) {
    if (request.scheme == 'https') {
      return true;
    }

    if (secureProxyHeaders.isNotEmpty) {
      for (final headerSpec in secureProxyHeaders) {
        final parts = headerSpec.split(':');
        if (parts.length == 2) {
          final headerName = parts[0];
          final headerValue = parts[1];
          if (request.headers[headerName.toLowerCase()] == headerValue) {
            return true;
          }
        }
      }
    }

    return false;
  }

  bool _isExempt(String path) {
    for (final pattern in secureRedirectExempt) {
      if (RegExp(pattern).hasMatch(path)) {
        return true;
      }
    }
    return false;
  }

  HttpResponse _redirectToHttps(HttpRequest request) {
    String host = secureRedirectHost ?? request.host;
    final path = request.uri.path;
    final query = request.uri.query.isNotEmpty ? '?${request.uri.query}' : '';
    final url = 'https://$host$path$query';
    return HttpResponse.permanentRedirect(url);
  }

  String _buildHstsHeader() {
    final parts = ['max-age=${hstsMaxAge!.inSeconds}'];
    
    if (hstsIncludeSubdomains) {
      parts.add('includeSubDomains');
    }
    
    if (hstsPreload) {
      parts.add('preload');
    }
    
    return parts.join('; ');
  }

  String _buildCspHeader() {
    final parts = <String>[];
    for (final entry in contentSecurityPolicy!.entries) {
      parts.add('${entry.key} ${entry.value}');
    }
    return parts.join('; ');
  }

  String _buildFeaturePolicyHeader() {
    final parts = <String>[];
    for (final entry in featurePolicy!.entries) {
      parts.add('${entry.key} ${entry.value}');
    }
    return parts.join('; ');
  }

  String _buildPermissionsPolicyHeader() {
    final parts = <String>[];
    for (final entry in permissionsPolicy!.entries) {
      parts.add('${entry.key}=(${entry.value})');
    }
    return parts.join(', ');
  }
}

class CorsMiddleware extends BaseMiddleware {
  final List<String> allowedOrigins;
  final List<String> allowedMethods;
  final List<String> allowedHeaders;
  final List<String> exposedHeaders;
  final bool allowCredentials;
  final Duration? maxAge;
  final bool allowAllOrigins;
  final bool allowAllMethods;
  final bool allowAllHeaders;

  CorsMiddleware({
    List<String>? allowedOrigins,
    List<String>? allowedMethods,
    List<String>? allowedHeaders,
    List<String>? exposedHeaders,
    bool? allowCredentials,
    this.maxAge,
    bool? allowAllOrigins,
    bool? allowAllMethods,
    bool? allowAllHeaders,
  })  : allowedOrigins = allowedOrigins ?? [],
        allowedMethods = allowedMethods ?? ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'],
        allowedHeaders = allowedHeaders ?? [],
        exposedHeaders = exposedHeaders ?? [],
        allowCredentials = allowCredentials ?? false,
        allowAllOrigins = allowAllOrigins ?? false,
        allowAllMethods = allowAllMethods ?? false,
        allowAllHeaders = allowAllHeaders ?? false;

  @override
  FutureOr<HttpResponse?> processRequest(HttpRequest request) {
    if (request.method == 'OPTIONS') {
      return _handlePreflightRequest(request);
    }
    return null;
  }

  @override
  FutureOr<HttpResponse> processResponse(
    HttpRequest request,
    HttpResponse response,
  ) {
    final origin = request.headers['origin'];
    if (origin == null) {
      return response;
    }

    if (_isAllowedOrigin(origin)) {
      response = response.setHeader('Access-Control-Allow-Origin', allowAllOrigins ? '*' : origin);
      
      if (allowCredentials && !allowAllOrigins) {
        response = response.setHeader('Access-Control-Allow-Credentials', 'true');
      }
      
      if (exposedHeaders.isNotEmpty) {
        response = response.setHeader('Access-Control-Expose-Headers', exposedHeaders.join(', '));
      }
    }

    return response;
  }

  HttpResponse _handlePreflightRequest(HttpRequest request) {
    final origin = request.headers['origin'];
    if (origin == null || !_isAllowedOrigin(origin)) {
      return HttpResponse.forbidden('CORS policy violation');
    }

    var response = HttpResponse.noContent();
    
    response = response.setHeader('Access-Control-Allow-Origin', allowAllOrigins ? '*' : origin);
    
    if (allowCredentials && !allowAllOrigins) {
      response = response.setHeader('Access-Control-Allow-Credentials', 'true');
    }
    
    final requestedMethod = request.headers['access-control-request-method'];
    if (requestedMethod != null) {
      if (allowAllMethods || allowedMethods.contains(requestedMethod)) {
        response = response.setHeader('Access-Control-Allow-Methods', allowAllMethods ? '*' : allowedMethods.join(', '));
      } else {
        return HttpResponse.forbidden('Method not allowed by CORS policy');
      }
    }
    
    final requestedHeaders = request.headers['access-control-request-headers'];
    if (requestedHeaders != null) {
      if (allowAllHeaders) {
        response = response.setHeader('Access-Control-Allow-Headers', requestedHeaders);
      } else {
        final headersList = requestedHeaders.split(',').map((h) => h.trim()).toList();
        final allowedHeadersList = headersList.where((h) => allowedHeaders.contains(h)).toList();
        if (allowedHeadersList.isNotEmpty) {
          response = response.setHeader('Access-Control-Allow-Headers', allowedHeadersList.join(', '));
        }
      }
    }
    
    if (maxAge != null) {
      response = response.setHeader('Access-Control-Max-Age', maxAge!.inSeconds.toString());
    }
    
    return response;
  }

  bool _isAllowedOrigin(String origin) {
    if (allowAllOrigins) {
      return true;
    }
    
    for (final allowed in allowedOrigins) {
      if (allowed == origin) {
        return true;
      }
      if (allowed.contains('*')) {
        final pattern = allowed.replaceAll('*', '.*');
        if (RegExp('^$pattern\$').hasMatch(origin)) {
          return true;
        }
      }
    }
    
    return false;
  }
}

class ContentSecurityPolicyMiddleware extends BaseMiddleware {
  final Map<String, String> directives;
  final bool reportOnly;
  final String? reportUri;
  final bool upgradeInsecureRequests;
  final bool blockAllMixedContent;

  ContentSecurityPolicyMiddleware({
    Map<String, String>? directives,
    this.reportOnly = false,
    this.reportUri,
    this.upgradeInsecureRequests = true,
    this.blockAllMixedContent = true,
  }) : directives = directives ?? _getDefaultDirectives();

  static Map<String, String> _getDefaultDirectives() {
    return {
      'default-src': "'self'",
      'script-src': "'self' 'unsafe-inline' 'unsafe-eval'",
      'style-src': "'self' 'unsafe-inline'",
      'img-src': "'self' data: https:",
      'font-src': "'self'",
      'connect-src': "'self'",
      'media-src': "'self'",
      'object-src': "'none'",
      'frame-ancestors': "'none'",
      'base-uri': "'self'",
      'form-action': "'self'",
    };
  }

  @override
  FutureOr<HttpResponse> processResponse(
    HttpRequest request,
    HttpResponse response,
  ) {
    final cspValue = _buildCspValue();
    final headerName = reportOnly 
        ? 'Content-Security-Policy-Report-Only' 
        : 'Content-Security-Policy';
    
    return response.setHeader(headerName, cspValue);
  }

  String _buildCspValue() {
    final parts = <String>[];
    
    for (final entry in directives.entries) {
      parts.add('${entry.key} ${entry.value}');
    }
    
    if (upgradeInsecureRequests) {
      parts.add('upgrade-insecure-requests');
    }
    
    if (blockAllMixedContent) {
      parts.add('block-all-mixed-content');
    }
    
    if (reportUri != null) {
      parts.add('report-uri $reportUri');
    }
    
    return parts.join('; ');
  }
}