import 'dart:io';
import 'package:path/path.dart' as path;

class MiddlewareGenerator {
  final String name;
  final String outputPath;
  final bool force;

  MiddlewareGenerator({
    required this.name,
    required this.outputPath,
    this.force = false,
  });

  Future<void> generate() async {
    final middlewareDir = Directory(outputPath);
    await middlewareDir.create(recursive: true);

    final middlewareFileName = '${_toSnakeCase(name)}.dart';
    final middlewareFile = File(path.join(middlewareDir.path, middlewareFileName));

    if (await middlewareFile.exists() && !force) {
      throw Exception('Middleware file already exists: ${middlewareFile.path}');
    }

    final middlewareContent = _generateMiddlewareContent();
    await middlewareFile.writeAsString(middlewareContent);
  }

  String _generateMiddlewareContent() {
    final className = _toPascalCase(name);

    return '''
import 'dart:async';
import 'package:dartango/dartango.dart';

/// ${_toTitleCase(name)} middleware
/// 
/// This middleware handles ${_toTitleCase(name).toLowerCase()} functionality.
/// Customize the process_request and process_response methods as needed.
class $className extends Middleware {
  @override
  Future<HttpResponse?> processRequest(HttpRequest request) async {
    // Process the incoming request
    // Return null to continue processing, or an HttpResponse to short-circuit
    
    // Example: Log the request
    print('[$className] Processing request: \${request.method} \${request.path}');
    
    // Example: Add custom headers
    request.meta['${_toSnakeCase(name)}_processed'] = true;
    
    // Example: Authentication check
    if (_requiresAuthentication(request)) {
      final isAuthenticated = await _checkAuthentication(request);
      if (!isAuthenticated) {
        return HttpResponse.unauthorized('Authentication required');
      }
    }
    
    // Example: Rate limiting
    if (_shouldApplyRateLimit(request)) {
      final isAllowed = await _checkRateLimit(request);
      if (!isAllowed) {
        return HttpResponse.tooManyRequests('Rate limit exceeded');
      }
    }
    
    // Continue processing
    return null;
  }

  @override
  Future<HttpResponse> processResponse(HttpRequest request, HttpResponse response) async {
    // Process the response before it's sent to the client
    
    // Example: Add custom headers
    response.headers['X-${_toPascalCase(name)}-Processed'] = 'true';
    response.headers['X-Processing-Time'] = DateTime.now().toIso8601String();
    
    // Example: Log the response
    print('[$className] Response: \${response.statusCode} for \${request.path}');
    
    // Example: Modify response content
    if (_shouldModifyResponse(request, response)) {
      return await _modifyResponse(request, response);
    }
    
    return response;
  }

  @override
  Future<HttpResponse?> processException(HttpRequest request, Exception exception) async {
    // Handle exceptions that occur during request processing
    
    // Log the exception
    print('[$className] Exception: \$exception for \${request.path}');
    
    // Example: Custom error handling
    if (exception is ValidationException) {
      return JsonResponse({
        'error': 'Validation failed',
        'details': exception.errors,
      }, statusCode: 400);
    }
    
    if (exception is AuthenticationException) {
      return JsonResponse({
        'error': 'Authentication failed',
        'message': exception.message,
      }, statusCode: 401);
    }
    
    // Return null to use default exception handling
    return null;
  }

  // Helper methods
  
  bool _requiresAuthentication(HttpRequest request) {
    // Define which paths require authentication
    final protectedPaths = ['/admin/', '/api/private/'];
    return protectedPaths.any((path) => request.path.startsWith(path));
  }
  
  Future<bool> _checkAuthentication(HttpRequest request) async {
    // Implement your authentication logic here
    final authHeader = request.headers['authorization'];
    if (authHeader == null) return false;
    
    // Example: Bearer token validation
    if (authHeader.startsWith('Bearer ')) {
      final token = authHeader.substring(7);
      return await _validateToken(token);
    }
    
    return false;
  }
  
  Future<bool> _validateToken(String token) async {
    // Implement token validation logic
    // This is a placeholder implementation
    return token.isNotEmpty && token.length > 10;
  }
  
  bool _shouldApplyRateLimit(HttpRequest request) {
    // Define which paths should have rate limiting
    final rateLimitedPaths = ['/api/'];
    return rateLimitedPaths.any((path) => request.path.startsWith(path));
  }
  
  Future<bool> _checkRateLimit(HttpRequest request) async {
    // Implement rate limiting logic
    // This is a placeholder implementation
    final clientIp = request.remoteAddr;
    
    // Example: Simple in-memory rate limiting
    final key = '${_toSnakeCase(name)}_rate_limit_\$clientIp';
    final now = DateTime.now();
    
    // In a real implementation, you'd use a proper cache/database
    // For now, we'll just return true (allow request)
    return true;
  }
  
  bool _shouldModifyResponse(HttpRequest request, HttpResponse response) {
    // Define conditions for response modification
    return response.statusCode == 200 && 
           request.path.startsWith('/api/') &&
           response.headers['content-type']?.startsWith('application/json') == true;
  }
  
  Future<HttpResponse> _modifyResponse(HttpRequest request, HttpResponse response) async {
    // Modify the response as needed
    if (response is JsonResponse) {
      // Add metadata to JSON responses
      final originalData = response.data;
      final modifiedData = {
        'data': originalData,
        'meta': {
          'processed_by': '$className',
          'timestamp': DateTime.now().toIso8601String(),
          'version': '1.0',
        },
      };
      
      return JsonResponse(modifiedData, statusCode: response.statusCode);
    }
    
    return response;
  }
}

// Configuration class for the middleware
class ${className}Config {
  final bool enableLogging;
  final bool enableAuthentication;
  final bool enableRateLimit;
  final Duration rateLimitWindow;
  final int maxRequestsPerWindow;
  final List<String> exemptPaths;
  
  const ${className}Config({
    this.enableLogging = true,
    this.enableAuthentication = true,
    this.enableRateLimit = false,
    this.rateLimitWindow = const Duration(minutes: 1),
    this.maxRequestsPerWindow = 60,
    this.exemptPaths = const ['/health', '/status'],
  });
}

// Configurable middleware version
class Configurable$className extends $className {
  final ${className}Config config;
  
  Configurable$className({${className}Config? config})
      : config = config ?? const ${className}Config();
  
  @override
  Future<HttpResponse?> processRequest(HttpRequest request) async {
    // Skip processing for exempt paths
    if (config.exemptPaths.any((path) => request.path.startsWith(path))) {
      return null;
    }
    
    if (config.enableLogging) {
      print('[$className] Processing request: \${request.method} \${request.path}');
    }
    
    // Apply authentication if enabled
    if (config.enableAuthentication && _requiresAuthentication(request)) {
      final isAuthenticated = await _checkAuthentication(request);
      if (!isAuthenticated) {
        return HttpResponse.unauthorized('Authentication required');
      }
    }
    
    // Apply rate limiting if enabled
    if (config.enableRateLimit && _shouldApplyRateLimit(request)) {
      final isAllowed = await _checkRateLimit(request);
      if (!isAllowed) {
        return HttpResponse.tooManyRequests('Rate limit exceeded');
      }
    }
    
    return null;
  }
  
  @override
  Future<HttpResponse> processResponse(HttpRequest request, HttpResponse response) async {
    if (config.enableLogging) {
      print('[$className] Response: \${response.statusCode} for \${request.path}');
    }
    
    return super.processResponse(request, response);
  }
}

// Extension for easy registration
extension ${className}Extension on List<Middleware> {
  void add$className({${className}Config? config}) {
    add(Configurable$className(config: config));
  }
}

// Custom exceptions
class ${className}Exception implements Exception {
  final String message;
  final int statusCode;
  
  const ${className}Exception(this.message, [this.statusCode = 500]);
  
  @override
  String toString() => message;
}

class ValidationException extends ${className}Exception {
  final Map<String, List<String>> errors;
  
  const ValidationException(this.errors) : super('Validation failed', 400);
}

class AuthenticationException extends ${className}Exception {
  const AuthenticationException(String message) : super(message, 401);
}

// Usage example in comments:
/*
// In your main application file:
final app = DartangoApp();
app.middleware.add$className(
  config: ${className}Config(
    enableLogging: true,
    enableAuthentication: true,
    enableRateLimit: true,
    maxRequestsPerWindow: 100,
    exemptPaths: ['/health', '/status', '/metrics'],
  ),
);

// Or use the basic version:
app.middleware.add($className());
*/
''';
  }

  String _toPascalCase(String input) {
    return input
        .split('_')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join('');
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => '_${match.group(1)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '')
        .toLowerCase();
  }

  String _toTitleCase(String input) {
    return input
        .split('_')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }
}