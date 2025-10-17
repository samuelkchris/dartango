import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'core/database/connection.dart';
import 'core/admin/admin.dart';
import 'core/admin/autodiscover.dart';
import 'core/admin/integration.dart';
import 'core/auth/models.dart' as auth;
import 'core/http/request.dart';
import 'core/http/response.dart';
import 'core/views/base.dart';
import 'core/templates/flutter_template_engine.dart';
import 'core/templates/flutter_renderer.dart';
import 'core/utils/crypto.dart';
import 'core/auth/jwt.dart';
import 'core/websocket/server.dart';

abstract class DartangoApp {
  late HttpServer _server;
  late Router _router;
  late AdminSite _adminSite;
  late WebSocketServer _webSocketServer;
  FlutterTemplateEngine? _flutterTemplateEngine;

  String get name => runtimeType.toString().replaceAll('App', '').toLowerCase();

  String get version => '1.0.0';

  List<String> get installedApps => [];

  Map<String, dynamic> get settings => {};

  List<String> get urlPatterns => [];

  List<Middleware> get middleware => [];

  String get host => settings['HOST'] ?? 'localhost';

  int get port => settings['PORT'] ?? 8000;

  bool get debug => settings['DEBUG'] ?? false;

  String get secretKey =>
      settings['SECRET_KEY'] ?? SecureKeyGenerator.generateDjangoSecretKey();

  List<String> get allowedHosts =>
      settings['ALLOWED_HOSTS'] ?? ['localhost', '127.0.0.1'];

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
    await _setupTemplates();
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
    // Only create default superuser in development mode
    if (debug) {
      final defaultUsername = settings['DEFAULT_SUPERUSER_USERNAME'] ?? 'admin';
      final defaultPassword = settings['DEFAULT_SUPERUSER_PASSWORD'] ??
          SecureKeyGenerator.generateUrlSafeToken(length: 12);

      try {
        await auth.User.createSuperuser(
          username: defaultUsername,
          email: 'admin@${name}.com',
          password: defaultPassword,
          firstName: 'Admin',
          lastName: 'User',
        );
        print(
            '✅ Development superuser created: $defaultUsername/$defaultPassword');
        print('⚠️  WARNING: Change default credentials in production!');
      } catch (e) {
        // User already exists
      }
    }
  }

  Future<void> _setupAdmin() async {
    print('🔧 Setting up Django-style admin interface...');

    _adminSite = AdminSite();
    
    // Setup built-in admin models
    setupDefaultAdmin();

    // Initialize admin integration
    await AdminIntegration().initialize(
      projectPath: Directory.current.path,
      adminSite: _adminSite,
      autoDiscover: true,
    );

    // Setup custom admin configurations
    await setupAdmin(_adminSite);

    print('✅ Django-style admin interface configured');
  }

  Future<void> _setupTemplates() async {
    print('🎨 Setting up Flutter templates...');

    _flutterTemplateEngine = FlutterTemplateEngine(
      templateDir: 'templates',
      debug: debug,
    );

    // Register default templates
    TemplateRegistry.registerDefaults();

    // Register custom templates
    if (_flutterTemplateEngine != null) {
      await setupFlutterTemplates(_flutterTemplateEngine!);
    }

    print('✅ Flutter templates configured');
  }

  Future<void> setupAdmin(AdminSite adminSite) async {
    // Override in subclasses to register models
  }

  Future<void> setupFlutterTemplates(
      FlutterTemplateEngine templateEngine) async {
    // Override in subclasses to register custom templates
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

    // Django-style admin routes
    _router.get('${adminUrl}', _adminIndexHandler);
    _router.get('${adminUrl}login/', _adminLoginHandler);
    _router.post('${adminUrl}login/', _adminLoginHandler);
    _router.get('${adminUrl}logout/', _adminLogoutHandler);
    
    // Model admin routes (Django-style)
    _router.get('${adminUrl}<app>/<model>/', _adminModelListHandler);
    _router.get('${adminUrl}<app>/<model>/add/', _adminModelAddHandler);
    _router.post('${adminUrl}<app>/<model>/add/', _adminModelAddHandler);
    _router.get('${adminUrl}<app>/<model>/<id>/change/', _adminModelChangeHandler);
    _router.post('${adminUrl}<app>/<model>/<id>/change/', _adminModelChangeHandler);
    _router.get('${adminUrl}<app>/<model>/<id>/delete/', _adminModelDeleteHandler);
    _router.post('${adminUrl}<app>/<model>/<id>/delete/', _adminModelDeleteHandler);
    
    // Admin API routes for Flutter admin
    _router.get('${adminUrl}api/', _adminApiIndexHandler);
    _router.get('${adminUrl}api/apps/', _adminApiAppsHandler);
    _router.get('${adminUrl}api/<app>/<model>/', _adminApiListHandler);
    _router.get('${adminUrl}api/<app>/<model>/<id>/', _adminApiDetailHandler);
    _router.post('${adminUrl}api/<app>/<model>/', _adminApiCreateHandler);
    _router.put('${adminUrl}api/<app>/<model>/<id>/', _adminApiUpdateHandler);
    _router.delete(
        '${adminUrl}api/<app>/<model>/<id>/', _adminApiDeleteHandler);

    // Authentication API
    _router.post('/api/auth/login/', _authLoginHandler);
    _router.post('/api/auth/logout/', _authLogoutHandler);
    _router.post('/api/auth/refresh/', _authRefreshHandler);
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
    final httpRequest = HttpRequest(request);
    final httpResponse = await _webSocketServer.handleUpgrade(httpRequest);
    return _convertHttpResponse(httpResponse);
  }

  // HTML admin handlers removed - pure Flutter admin only

  // Flutter admin handler removed - admin is standalone Flutter app

  // Django-style admin handlers
  Future<Response> _adminIndexHandler(Request request) async {
    final httpRequest = HttpRequest(request);
    final response = await _adminSite.indexView(httpRequest);
    return _convertHttpResponse(response);
  }
  
  Future<Response> _adminLoginHandler(Request request) async {
    final httpRequest = HttpRequest(request);
    final response = await _adminSite.loginView(httpRequest);
    return _convertHttpResponse(response);
  }
  
  Future<Response> _adminLogoutHandler(Request request) async {
    final httpRequest = HttpRequest(request);
    final response = await _adminSite.logoutView(httpRequest);
    return _convertHttpResponse(response);
  }
  
  Future<Response> _adminModelListHandler(Request request) async {
    final app = request.params['app']!;
    final model = request.params['model']!;
    final httpRequest = HttpRequest(request);
    
    final modelAdmin = _adminSite.getModelAdminByName(app, model);
    if (modelAdmin == null) {
      return Response.notFound('{"error": "Model not found"}');
    }
    
    final response = await modelAdmin.changelistView(httpRequest);
    return _convertHttpResponse(response);
  }
  
  Future<Response> _adminModelAddHandler(Request request) async {
    final app = request.params['app']!;
    final model = request.params['model']!;
    final httpRequest = HttpRequest(request);
    
    final modelAdmin = _adminSite.getModelAdminByName(app, model);
    if (modelAdmin == null) {
      return Response.notFound('{"error": "Model not found"}');
    }
    
    final response = await modelAdmin.addView(httpRequest);
    return _convertHttpResponse(response);
  }
  
  Future<Response> _adminModelChangeHandler(Request request) async {
    final app = request.params['app']!;
    final model = request.params['model']!;
    final id = request.params['id']!;
    final httpRequest = HttpRequest(request);
    
    final modelAdmin = _adminSite.getModelAdminByName(app, model);
    if (modelAdmin == null) {
      return Response.notFound('{"error": "Model not found"}');
    }
    
    final response = await modelAdmin.changeView(httpRequest, id);
    return _convertHttpResponse(response);
  }
  
  Future<Response> _adminModelDeleteHandler(Request request) async {
    final app = request.params['app']!;
    final model = request.params['model']!;
    final id = request.params['id']!;
    final httpRequest = HttpRequest(request);
    
    final modelAdmin = _adminSite.getModelAdminByName(app, model);
    if (modelAdmin == null) {
      return Response.notFound('{"error": "Model not found"}');
    }
    
    final response = await modelAdmin.deleteView(httpRequest, id);
    return _convertHttpResponse(response);
  }
  
  // Flutter admin API handlers
  Future<Response> _adminApiIndexHandler(Request request) async {
    final adminIntegration = AdminIntegration();
    final config = {
      'site_title': _adminSite.siteTitle,
      'site_header': _adminSite.siteHeader,
      'index_title': _adminSite.indexTitle,
      'models': AdminAutoDiscovery().discoveredModels.map((app, models) {
        return MapEntry(app, models.map((model) => model.toString()).toList());
      }),
      'admin_url': adminUrl,
    };
    
    return Response.ok(
      jsonEncode(config),
      headers: {'Content-Type': 'application/json'},
    );
  }
  
  Future<Response> _adminApiAppsHandler(Request request) async {
    final httpRequest = HttpRequest(request);
    final appList = await _adminSite.getAppList(httpRequest);
    
    return Response.ok(
      jsonEncode({'apps': appList}),
      headers: {'Content-Type': 'application/json'},
    );
  }
  
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
  
  /// Convert HttpResponse to Shelf Response
  Response _convertHttpResponse(HttpResponse httpResponse) {
    return Response(
      httpResponse.statusCode,
      body: httpResponse.body,
      headers: httpResponse.headers,
    );
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
    final app = request.params['app']!;
    final model = request.params['model']!;
    final httpRequest = HttpRequest(request);
    
    final modelAdmin = _adminSite.getModelAdminByName(app, model);
    if (modelAdmin == null) {
      return Response.notFound('{"error": "Model not found"}');
    }
    
    final response = await modelAdmin.addView(httpRequest);
    return _convertHttpResponse(response);
  }

  Future<Response> _adminApiUpdateHandler(Request request) async {
    final app = request.params['app']!;
    final model = request.params['model']!;
    final id = request.params['id']!;
    final httpRequest = HttpRequest(request);
    
    final modelAdmin = _adminSite.getModelAdminByName(app, model);
    if (modelAdmin == null) {
      return Response.notFound('{"error": "Model not found"}');
    }
    
    final response = await modelAdmin.changeView(httpRequest, id);
    return _convertHttpResponse(response);
  }

  Future<Response> _adminApiDeleteHandler(Request request) async {
    final app = request.params['app']!;
    final model = request.params['model']!;
    final id = request.params['id']!;
    final httpRequest = HttpRequest(request);
    
    final modelAdmin = _adminSite.getModelAdminByName(app, model);
    if (modelAdmin == null) {
      return Response.notFound('{"error": "Model not found"}');
    }
    
    final response = await modelAdmin.deleteView(httpRequest, id);
    return _convertHttpResponse(response);
  }

  Future<Response> _authLoginHandler(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      final username = data['username'] as String?;
      final password = data['password'] as String?;

      if (username == null || password == null) {
        return Response(400,
            body: jsonEncode({
              'error': 'Username and password are required',
            }),
            headers: {'Content-Type': 'application/json'});
      }

      // Authenticate user
      final user = await auth.User.getUserByUsername(username);
      if (user == null || !user.isActive) {
        return Response(401,
            body: jsonEncode({
              'error': 'Invalid credentials',
            }),
            headers: {'Content-Type': 'application/json'});
      }

      if (!user.checkPassword(password)) {
        return Response(401,
            body: jsonEncode({
              'error': 'Invalid credentials',
            }),
            headers: {'Content-Type': 'application/json'});
      }

      // Generate JWT token
      final jwtService = JwtService(secretKey);
      final jwtToken = jwtService.generateToken(user.id, user.username);

      return Response.ok(
          jsonEncode({
            'token': jwtToken.accessToken,
            'refresh_token': jwtToken.refreshToken,
            'expires_in':
                jwtToken.expiresAt.difference(DateTime.now()).inSeconds,
            'user': {
              'id': user.id,
              'username': user.username,
              'email': user.email,
              'first_name': user.firstName,
              'last_name': user.lastName,
              'is_staff': user.isStaff,
              'is_superuser': user.isSuperuser,
            },
          }),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response(500,
          body: jsonEncode({
            'error': 'Authentication failed',
          }),
          headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _authLogoutHandler(Request request) async {
    // For JWT, logout is handled client-side by discarding the token
    // In production, you might want to maintain a token blacklist
    return Response.ok(
        jsonEncode({
          'message': 'Logged out successfully',
        }),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _authRefreshHandler(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      final refreshToken = data['refresh_token'] as String?;
      if (refreshToken == null) {
        return Response(400,
            body: jsonEncode({
              'error': 'Refresh token is required',
            }),
            headers: {'Content-Type': 'application/json'});
      }

      final jwtService = JwtService(secretKey);
      final newTokens = jwtService.refreshAccessToken(refreshToken);

      if (newTokens == null) {
        return Response(401,
            body: jsonEncode({
              'error': 'Invalid or expired refresh token',
            }),
            headers: {'Content-Type': 'application/json'});
      }

      return Response.ok(
          jsonEncode({
            'token': newTokens.accessToken,
            'refresh_token': newTokens.refreshToken,
            'expires_in':
                newTokens.expiresAt.difference(DateTime.now()).inSeconds,
          }),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response(500,
          body: jsonEncode({
            'error': 'Token refresh failed',
          }),
          headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _authUserHandler(Request request) async {
    try {
      final authHeader = request.headers['Authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(401,
            body: jsonEncode({
              'error': 'Authentication required',
            }),
            headers: {'Content-Type': 'application/json'});
      }

      final token = authHeader.substring(7);
      final jwtService = JwtService(secretKey);
      final payload = jwtService.verifyToken(token);

      if (payload == null) {
        return Response(401,
            body: jsonEncode({
              'error': 'Invalid token',
            }),
            headers: {'Content-Type': 'application/json'});
      }

      final userId = payload['user_id'] as int;
      final user = await auth.User.getUserById(userId);

      if (user == null || !user.isActive) {
        return Response(401,
            body: jsonEncode({
              'error': 'User not found or inactive',
            }),
            headers: {'Content-Type': 'application/json'});
      }

      return Response.ok(
          jsonEncode({
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'first_name': user.firstName,
            'last_name': user.lastName,
            'is_staff': user.isStaff,
            'is_superuser': user.isSuperuser,
            'is_active': user.isActive,
          }),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response(500,
          body: jsonEncode({
            'error': 'Failed to get user information',
          }),
          headers: {'Content-Type': 'application/json'});
    }
  }

  Response _defaultRootHandler(Request request) {
    // Use Flutter template for the homepage
    final context = {
      'title': name,
      'version': version,
      'admin_url': adminUrl,
      'debug': debug,
    };

    final widget = Scaffold(
      body: Container(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🚀 $name',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: const Text(
                'Your Dartango application is running successfully!',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            Text(
              'Version: $version',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
              ),
            ),
            Container(
              padding: EdgeInsets.only(top: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: null,
                    child: const Text('🛠️ Admin Interface'),
                  ),
                  ElevatedButton(
                    onPressed: null,
                    child: const Text('🔗 API Documentation'),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(top: 32),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CardComponent({
                    'title': '🎯 Django-Compatible',
                    'content': 'Familiar patterns and conventions'
                  }),
                  CardComponent({
                    'title': '⚡ Fast & Modern',
                    'content': 'Built with Dart for performance'
                  }),
                  CardComponent({
                    'title': '🔒 Secure by Default',
                    'content': 'Built-in security features'
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
    );

    final html = widget.render(context);
    return Response.ok(html, headers: {'Content-Type': 'text/html'});
  }

  String _jsonEncode(dynamic object) {
    // Simple JSON encoding - in production, use dart:convert
    if (object is Map) {
      final entries =
          object.entries.map((e) => '"${e.key}": ${_jsonEncode(e.value)}');
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
  Future<HttpResponse> get(
      HttpRequest request, Map<String, dynamic> params) async {
    final context = getContextData();
    final content = await renderTemplate(templateName, context);
    return HttpResponse.ok(content, headers: {'Content-Type': 'text/html'});
  }

  Map<String, dynamic> getContextData() {
    return {};
  }

  Future<String> renderTemplate(
      String template, Map<String, dynamic> context) async {
    // Simple template rendering - replace with actual template engine
    var content = await File('templates/$template').readAsString();
    for (final entry in context.entries) {
      content =
          content.replaceAll('{{ ${entry.key} }}', entry.value.toString());
    }
    return content;
  }

  /// Render a Flutter template
  String renderFlutterTemplate(
      String templateName, Map<String, dynamic> context) {
    // Access the global flutter template engine
    final engine = FlutterTemplateEngine(
      templateDir: 'templates',
      debug: true,
    );
    return engine.render(templateName, context);
  }

  /// Render a Flutter widget directly
  String renderFlutterWidget(
      FlutterWidget widget, Map<String, dynamic> context) {
    return widget.render(context);
  }
}

// JSON response view
class JsonResponse extends HttpResponse {
  JsonResponse(Map<String, dynamic> data,
      {int statusCode = 200, Map<String, String>? headers})
      : super(
          _jsonEncode(data),
          statusCode: statusCode,
          headers: {
            'Content-Type': 'application/json',
            ...?headers,
          },
        );

  static String _jsonEncode(dynamic object) {
    // Simple JSON encoding - in production, use dart:convert
    if (object is Map) {
      final entries =
          object.entries.map((e) => '"${e.key}": ${_jsonEncode(e.value)}');
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
