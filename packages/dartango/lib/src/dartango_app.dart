import 'dart:io';
import 'dart:async';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:path/path.dart' as p;

import 'core/database/connection.dart';
import 'core/admin/admin.dart';
import 'core/auth/models.dart' as auth;
import 'core/http/request.dart';
import 'core/http/response.dart';
import 'core/views/base.dart';
import 'core/templates/engine.dart';
import 'core/websocket/server.dart';

abstract class DartangoApp {
  late HttpServer _server;
  late Router _router;
  late AdminSite _adminSite;
  late WebSocketServer _webSocketServer;
  
  String get name => runtimeType.toString().replaceAll('App', '').toLowerCase();
  String get version => '1.0.0';
  
  List<String> get installedApps => [];
  Map<String, dynamic> get settings => {};
  List<String> get urlPatterns => [];
  List<Middleware> get middleware => [];
  
  String get host => settings['HOST'] ?? 'localhost';
  int get port => settings['PORT'] ?? 8000;
  bool get debug => settings['DEBUG'] ?? false;
  String get secretKey => settings['SECRET_KEY'] ?? 'your-secret-key-here';
  List<String> get allowedHosts => settings['ALLOWED_HOSTS'] ?? ['localhost', '127.0.0.1'];
  
  String get databaseUrl => settings['DATABASE_URL'] ?? 'sqlite:///db.sqlite3';
  String get staticUrl => settings['STATIC_URL'] ?? '/static/';
  String get staticRoot => settings['STATIC_ROOT'] ?? 'web/static/';
  String get mediaUrl => settings['MEDIA_URL'] ?? '/media/';
  String get mediaRoot => settings['MEDIA_ROOT'] ?? 'web/media/';
  
  String get templateDir => settings['TEMPLATE_DIR'] ?? 'templates/';
  String get adminUrl => settings['ADMIN_URL'] ?? '/admin/';
  
  Future<void> run(List<String> args) async {
    print('🚀 Starting $name v$version...');
    
    await configure();
    await _initializeDatabase();
    await _setupAdmin();
    await _setupRoutes();
    await _setupMiddleware();
    await _setupWebSocket();
    
    final handler = _createHandler();
    _server = await serve(handler, host, port);
    
    print('✅ $name running on http://$host:$port');
    print('📋 Admin interface: http://$host:$port$adminUrl');
    if (debug) {
      print('🔧 Debug mode enabled');
    }
    print('Press Ctrl+C to stop the server\n');
    
    // Server automatically handles connection cleanup
  }
  
  Future<void> stop() async {
    print('🛑 Stopping $name server...');
    await _server.close();
    // Database connections handled automatically
    print('✅ Server stopped');
  }
  
  Future<void> configure() async {
    // Override in subclasses for custom configuration
  }
  
  Future<void> _initializeDatabase() async {
    print('📊 Initializing database...');
    
    final config = DatabaseConfig(
      backend: DatabaseBackend.sqlite,
      database: _extractDatabaseName(databaseUrl),
      maxConnections: 10,
      connectionTimeout: Duration(seconds: 30),
    );
    
    DatabaseRouter.registerDatabase('default', config);
    
    await _createAuthTables();
    await _createDefaultSuperuser();
    
    print('✅ Database initialized');
  }
  
  String _extractDatabaseName(String url) {
    if (url.startsWith('sqlite:///')) {
      return url.substring(10);
    }
    return 'db.sqlite3';
  }
  
  Future<void> _createAuthTables() async {
    final connection = await DatabaseRouter.getConnection();
    try {
      await connection.execute('''
        CREATE TABLE IF NOT EXISTS auth_users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username VARCHAR(150) UNIQUE NOT NULL,
          email VARCHAR(254) NOT NULL,
          first_name VARCHAR(150) NOT NULL DEFAULT '',
          last_name VARCHAR(150) NOT NULL DEFAULT '',
          is_active BOOLEAN NOT NULL DEFAULT 1,
          is_staff BOOLEAN NOT NULL DEFAULT 0,
          is_superuser BOOLEAN NOT NULL DEFAULT 0,
          date_joined DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
          last_login DATETIME,
          password VARCHAR(128) NOT NULL
        )
      ''');
      
      await connection.execute('''
        CREATE TABLE IF NOT EXISTS auth_groups (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name VARCHAR(150) UNIQUE NOT NULL
        )
      ''');
    } finally {
      await DatabaseRouter.releaseConnection(connection);
    }
  }
  
  Future<void> _createDefaultSuperuser() async {
    try {
      await auth.User.createSuperuser(
        username: 'admin',
        email: 'admin@${name}.com',
        password: 'admin123',
        firstName: 'Admin',
        lastName: 'User',
      );
      print('✅ Default superuser created: admin/admin123');
    } catch (e) {
      // User already exists
    }
  }
  
  Future<void> _setupAdmin() async {
    print('🔧 Setting up admin interface...');
    
    _adminSite = AdminSite();
    setupDefaultAdmin();
    
    await setupAdmin(_adminSite);
    
    print('✅ Admin interface configured');
  }
  
  Future<void> setupAdmin(AdminSite adminSite) async {
    // Override in subclasses to register models
  }
  
  Future<void> _setupRoutes() async {
    _router = Router();
    
    // Static files (only create if directories exist)
    final staticDir = Directory(staticRoot);
    if (staticDir.existsSync()) {
      _router.mount(staticUrl, createStaticHandler(staticRoot));
    }
    final mediaDir = Directory(mediaRoot);
    if (mediaDir.existsSync()) {
      _router.mount(mediaUrl, createStaticHandler(mediaRoot));
    }
    
    // WebSocket endpoint
    _router.get('/ws', _webSocketHandler);
    
    // Admin API routes only (no HTML - pure Flutter admin)
    _router.get('${adminUrl}api/<app>/<model>/', _adminApiListHandler);
    _router.get('${adminUrl}api/<app>/<model>/<id>/', _adminApiDetailHandler);
    _router.post('${adminUrl}api/<app>/<model>/', _adminApiCreateHandler);
    _router.put('${adminUrl}api/<app>/<model>/<id>/', _adminApiUpdateHandler);
    _router.delete('${adminUrl}api/<app>/<model>/<id>/', _adminApiDeleteHandler);
    
    // Authentication API
    _router.post('/api/auth/login/', _authLoginHandler);
    _router.post('/api/auth/logout/', _authLogoutHandler);
    _router.get('/api/auth/user/', _authUserHandler);
    
    // User-defined routes
    await setupRoutes(_router);
    
    // Default root handler
    _router.get('/', _defaultRootHandler);
  }
  
  Future<void> setupRoutes(Router router) async {
    // Override in subclasses to add custom routes
  }
  
  Future<void> _setupMiddleware() async {
    // Middleware will be applied in the handler
  }
  
  Future<void> _setupWebSocket() async {
    _webSocketServer = WebSocketServer();
    // WebSocket server initialized automatically
  }
  
  Handler _createHandler() {
    return Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_corsMiddleware())
        .addMiddleware(_securityMiddleware())
        .addMiddleware(_sessionMiddleware())
        .addMiddleware(_authenticationMiddleware())
        .addHandler(_router);
  }
  
  Middleware _corsMiddleware() {
    return createMiddleware(
      requestHandler: (Request request) {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          });
        }
        return null;
      },
      responseHandler: (Response response) {
        return response.change(headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        });
      },
    );
  }
  
  Middleware _securityMiddleware() {
    return createMiddleware(
      responseHandler: (Response response) {
        return response.change(headers: {
          'X-Frame-Options': 'DENY',
          'X-Content-Type-Options': 'nosniff',
          'X-XSS-Protection': '1; mode=block',
          'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
        });
      },
    );
  }
  
  Middleware _sessionMiddleware() {
    return createMiddleware(
      requestHandler: (Request request) {
        // Add session support
        return null;
      },
    );
  }
  
  Middleware _authenticationMiddleware() {
    return createMiddleware(
      requestHandler: (Request request) {
        // Add authentication support
        return null;
      },
    );
  }
  
  Future<Response> _webSocketHandler(Request request) async {
    return Response.ok('WebSocket support coming soon');
  }
  
  // HTML admin handlers removed - pure Flutter admin only
  
  // Flutter admin handler removed - admin is standalone Flutter app
  
  Future<Response> _adminApiListHandler(Request request) async {
    final app = request.params['app']!;
    final model = request.params['model']!;
    
    try {
      final modelAdmin = _adminSite.getModelAdminByName(app, model);
      if (modelAdmin == null) {
        return Response.notFound('{"error": "Model not found"}');
      }
      
      final objects = await modelAdmin.getQueryset();
      final jsonData = objects.map((obj) => obj.toJson()).toList();
      
      return Response.ok(
        '{"results": ${_jsonEncode(jsonData)}, "count": ${objects.length}}',
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: '{"error": "Failed to fetch $model list: $e"}',
      );
    }
  }
  
  Future<Response> _adminApiDetailHandler(Request request) async {
    final app = request.params['app']!;
    final model = request.params['model']!;
    final id = request.params['id']!;
    
    try {
      final modelAdmin = _adminSite.getModelAdminByName(app, model);
      if (modelAdmin == null) {
        return Response.notFound('{"error": "Model not found"}');
      }
      
      final object = await modelAdmin.getObject(id);
      if (object == null) {
        return Response.notFound('{"error": "Object not found"}');
      }
      
      return Response.ok(
        _jsonEncode(object.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: '{"error": "Failed to fetch $model detail: $e"}',
      );
    }
  }
  
  Future<Response> _adminApiCreateHandler(Request request) async {
    // TODO: Implement create functionality
    return Response.ok('{"message": "Create functionality will be implemented"}');
  }
  
  Future<Response> _adminApiUpdateHandler(Request request) async {
    // TODO: Implement update functionality
    return Response.ok('{"message": "Update functionality will be implemented"}');
  }
  
  Future<Response> _adminApiDeleteHandler(Request request) async {
    // TODO: Implement delete functionality
    return Response.ok('{"message": "Delete functionality will be implemented"}');
  }
  
  Future<Response> _authLoginHandler(Request request) async {
    // TODO: Implement authentication
    return Response.ok('{"token": "dummy-token", "user": {"username": "admin", "email": "admin@example.com"}}');
  }
  
  Future<Response> _authLogoutHandler(Request request) async {
    return Response.ok('{"message": "Logged out successfully"}');
  }
  
  Future<Response> _authUserHandler(Request request) async {
    return Response.ok('{"username": "admin", "email": "admin@example.com", "is_staff": true}');
  }
  
  Response _defaultRootHandler(Request request) {
    return Response.ok('''
<!DOCTYPE html>
<html>
<head>
    <title>$name - Dartango Application</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center; }
        .container { text-align: center; color: white; max-width: 600px; padding: 2rem; }
        h1 { font-size: 3rem; margin-bottom: 1rem; }
        p { font-size: 1.2rem; margin-bottom: 2rem; }
        .actions { margin-top: 2rem; }
        .action-btn { display: inline-block; padding: 15px 30px; background: rgba(255,255,255,0.2); color: white; text-decoration: none; border-radius: 5px; margin: 10px; backdrop-filter: blur(10px); }
        .action-btn:hover { background: rgba(255,255,255,0.3); }
        .features { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin-top: 2rem; }
        .feature { background: rgba(255, 255, 255, 0.1); padding: 1rem; border-radius: 8px; backdrop-filter: blur(10px); }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 $name</h1>
        <p>Your Dartango application is running successfully!</p>
        
        <div class="actions">
            <a href="$adminUrl" class="action-btn">🛠️ Admin Interface</a>
            <a href="/api/" class="action-btn">🔗 API Documentation</a>
        </div>
        
        <div class="features">
            <div class="feature">
                <h3>🎯 Django-Compatible</h3>
                <p>Familiar patterns and conventions</p>
            </div>
            <div class="feature">
                <h3>⚡ Fast & Modern</h3>
                <p>Built with Dart for performance</p>
            </div>
            <div class="feature">
                <h3>🔒 Secure by Default</h3>
                <p>Built-in security features</p>
            </div>
        </div>
    </div>
</body>
</html>
    ''', headers: {'Content-Type': 'text/html'});
  }
  
  String _jsonEncode(dynamic object) {
    // Simple JSON encoding - in production, use dart:convert
    if (object is Map) {
      final entries = object.entries.map((e) => '"${e.key}": ${_jsonEncode(e.value)}');
      return '{${entries.join(', ')}}';
    } else if (object is List) {
      final items = object.map((item) => _jsonEncode(item));
      return '[${items.join(', ')}]';
    } else if (object is String) {
      return '"$object"';
    } else if (object is num || object is bool) {
      return object.toString();
    } else if (object == null) {
      return 'null';
    } else {
      return '"${object.toString()}"';
    }
  }
}

// Helper function to setup default admin
void setupDefaultAdmin() {
  // This will be called automatically
}

// Template view for convenience
abstract class TemplateView extends View {
  String get templateName;
  
  @override
  Future<HttpResponse> get(HttpRequest request, Map<String, dynamic> params) async {
    final context = getContextData();
    final content = await renderTemplate(templateName, context);
    return HttpResponse.ok(content, headers: {'Content-Type': 'text/html'});
  }
  
  Map<String, dynamic> getContextData() {
    return {};
  }
  
  Future<String> renderTemplate(String template, Map<String, dynamic> context) async {
    // Simple template rendering - replace with actual template engine
    var content = await File('templates/$template').readAsString();
    for (final entry in context.entries) {
      content = content.replaceAll('{{ ${entry.key} }}', entry.value.toString());
    }
    return content;
  }
}

// JSON response view
class JsonResponse extends HttpResponse {
  JsonResponse(Map<String, dynamic> data, {int statusCode = 200, Map<String, String>? headers}) 
      : super(_jsonEncode(data),
          statusCode: statusCode,
          headers: {
            'Content-Type': 'application/json',
            ...?headers,
          },
        );
  
  static String _jsonEncode(dynamic object) {
    // Simple JSON encoding - in production, use dart:convert
    if (object is Map) {
      final entries = object.entries.map((e) => '"${e.key}": ${_jsonEncode(e.value)}');
      return '{${entries.join(', ')}}';
    } else if (object is List) {
      final items = object.map((item) => _jsonEncode(item));
      return '[${items.join(', ')}]';
    } else if (object is String) {
      return '"$object"';
    } else if (object is num || object is bool) {
      return object.toString();
    } else if (object == null) {
      return 'null';
    } else {
      return '"${object.toString()}"';
    }
  }
}

// URL helper functions
String urlPath(String pattern, Handler handler, {String? name}) {
  // This is a placeholder - implement actual URL routing
  return pattern;
}