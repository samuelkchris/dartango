import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

import 'admin.dart';
import 'autodiscover.dart';

/// Django-style admin integration for Flutter admin package
class AdminIntegration {
  static final AdminIntegration _instance = AdminIntegration._internal();
  factory AdminIntegration() => _instance;
  AdminIntegration._internal();
  
  AdminSite? _adminSite;
  String? _projectPath;
  bool _isInitialized = false;
  
  /// Initialize admin integration
  Future<void> initialize({
    required String projectPath,
    AdminSite? adminSite,
    bool autoDiscover = true,
  }) async {
    if (_isInitialized) return;
    
    _projectPath = projectPath;
    _adminSite = adminSite ?? AdminSite();
    
    print('🚀 Initializing Django-style admin integration...');
    
    // Setup default admin models
    setupDefaultAdmin();
    
    // Auto-discover models if enabled
    if (autoDiscover) {
      await AdminAutoDiscovery().autodiscover(
        projectPath: projectPath,
        adminSite: _adminSite,
      );
    }
    
    // Generate admin configuration files
    await _generateAdminFiles();
    
    _isInitialized = true;
    print('✅ Admin integration initialized successfully');
  }
  
  /// Generate admin configuration files for Flutter admin
  Future<void> _generateAdminFiles() async {
    if (_projectPath == null) return;
    
    final adminDir = Directory(path.join(_projectPath!, 'admin'));
    if (!adminDir.existsSync()) {
      adminDir.createSync(recursive: true);
    }
    
    // Generate model configuration
    await _generateModelConfig();
    
    // Generate routes configuration
    await _generateRoutesConfig();
    
    // Generate theme configuration
    await _generateThemeConfig();
    
    // Generate Flutter admin main.dart
    await _generateFlutterAdminMain();
    
    print('📄 Generated admin configuration files');
  }
  
  /// Generate model configuration for Flutter admin
  Future<void> _generateModelConfig() async {
    final models = AdminAutoDiscovery().discoveredModels;
    final config = {
      'models': _buildModelConfig(models),
      'site': _buildSiteConfig(),
    };
    
    final configFile = File(path.join(_projectPath!, 'admin', 'models.json'));
    await configFile.writeAsString(jsonEncode(config));
  }
  
  /// Build model configuration
  Map<String, dynamic> _buildModelConfig(Map<String, List<Type>> models) {
    final modelConfig = <String, dynamic>{};
    
    for (final entry in models.entries) {
      final appName = entry.key;
      final appModels = <String, dynamic>{};
      
      for (final modelType in entry.value) {
        final admin = _adminSite?.getModelAdmin(modelType);
        if (admin != null) {
          appModels[modelType.toString()] = _buildModelAdminConfig(admin);
        }
      }
      
      if (appModels.isNotEmpty) {
        modelConfig[appName] = appModels;
      }
    }
    
    return modelConfig;
  }
  
  /// Build model admin configuration
  Map<String, dynamic> _buildModelAdminConfig(ModelAdmin admin) {
    return {
      'app_label': admin.getAppLabel(),
      'model_name': admin.modelType.toString(),
      'verbose_name': admin.getVerboseName(),
      'verbose_name_plural': admin.getVerboseNamePlural(),
      'list_display': admin.listDisplay,
      'list_filter': admin.listFilter,
      'search_fields': admin.searchFields,
      'ordering_fields': admin.orderingFields,
      'readonly_fields': admin.readonlyFields,
      'exclude_fields': admin.excludeFields,
      'fieldsets': admin.fieldsets,
      'list_per_page': admin.listPerPage,
      'permissions': {
        'add': admin.hasAddPermission,
        'change': admin.hasChangePermission,
        'delete': admin.hasDeletePermission,
        'view': admin.hasViewPermission,
      },
      'actions': admin.actions.map((action) => {
        'name': action.name,
        'description': action.description,
        'requires_confirmation': action.requiresConfirmation,
      }).toList(),
      'urls': {
        'changelist': admin.getChangelistUrl(),
        'add': '${admin.getChangelistUrl()}add/',
        'api': {
          'list': '/admin/api/${admin.getAppLabel()}/${admin.modelType.toString().toLowerCase()}/',
          'detail': '/admin/api/${admin.getAppLabel()}/${admin.modelType.toString().toLowerCase()}/<id>/',
        },
      },
    };
  }
  
  /// Build site configuration
  Map<String, dynamic> _buildSiteConfig() {
    return {
      'site_header': _adminSite?.siteHeader ?? 'Dartango Administration',
      'site_title': _adminSite?.siteTitle ?? 'Dartango Admin',
      'index_title': _adminSite?.indexTitle ?? 'Site Administration',
      'admin_url': _adminSite?.adminUrl ?? '/admin/',
      'enable_nav_sidebar': _adminSite?.enableNavSidebar ?? true,
    };
  }
  
  /// Generate routes configuration
  Future<void> _generateRoutesConfig() async {
    final routes = _buildRoutesConfig();
    final routesFile = File(path.join(_projectPath!, 'admin', 'routes.json'));
    await routesFile.writeAsString(jsonEncode(routes));
  }
  
  /// Build routes configuration
  Map<String, dynamic> _buildRoutesConfig() {
    final routes = <String, dynamic>{
      'base_url': _adminSite?.adminUrl ?? '/admin/',
      'api_endpoints': <String, dynamic>{},
      'model_urls': <String, dynamic>{},
    };
    
    // Add API endpoints
    routes['api_endpoints'] = {
      'auth': {
        'login': '/api/auth/login/',
        'logout': '/api/auth/logout/',
        'refresh': '/api/auth/refresh/',
        'user': '/api/auth/user/',
      },
      'admin': {
        'index': '/admin/api/',
        'apps': '/admin/api/apps/',
      },
    };
    
    // Add model-specific URLs
    final models = AdminAutoDiscovery().discoveredModels;
    for (final entry in models.entries) {
      final appName = entry.key;
      final appUrls = <String, dynamic>{};
      
      for (final modelType in entry.value) {
        final admin = _adminSite?.getModelAdmin(modelType);
        if (admin != null) {
          final modelName = modelType.toString().toLowerCase();
          appUrls[modelName] = {
            'list': '/admin/api/$appName/$modelName/',
            'detail': '/admin/api/$appName/$modelName/<id>/',
            'add': '/admin/api/$appName/$modelName/add/',
            'edit': '/admin/api/$appName/$modelName/<id>/edit/',
            'delete': '/admin/api/$appName/$modelName/<id>/delete/',
          };
        }
      }
      
      if (appUrls.isNotEmpty) {
        routes['model_urls'][appName] = appUrls;
      }
    }
    
    return routes;
  }
  
  /// Generate theme configuration
  Future<void> _generateThemeConfig() async {
    final theme = {
      'primary_color': '#2196F3',
      'accent_color': '#FFC107',
      'background_color': '#F5F5F5',
      'surface_color': '#FFFFFF',
      'error_color': '#F44336',
      'text_color': '#212121',
      'secondary_text_color': '#757575',
      'divider_color': '#E0E0E0',
      'app_bar_color': '#1976D2',
      'card_color': '#FFFFFF',
      'scaffold_background_color': '#FAFAFA',
      'brightness': 'light',
      'typography': {
        'font_family': 'Roboto',
        'headline1': {'size': 96, 'weight': 'w300'},
        'headline2': {'size': 60, 'weight': 'w300'},
        'headline3': {'size': 48, 'weight': 'w400'},
        'headline4': {'size': 34, 'weight': 'w400'},
        'headline5': {'size': 24, 'weight': 'w400'},
        'headline6': {'size': 20, 'weight': 'w500'},
        'subtitle1': {'size': 16, 'weight': 'w400'},
        'subtitle2': {'size': 14, 'weight': 'w500'},
        'body1': {'size': 16, 'weight': 'w400'},
        'body2': {'size': 14, 'weight': 'w400'},
        'button': {'size': 14, 'weight': 'w500'},
        'caption': {'size': 12, 'weight': 'w400'},
        'overline': {'size': 10, 'weight': 'w400'},
      },
    };
    
    final themeFile = File(path.join(_projectPath!, 'admin', 'theme.json'));
    await themeFile.writeAsString(jsonEncode(theme));
  }
  
  /// Generate Flutter admin main.dart
  Future<void> _generateFlutterAdminMain() async {
    final mainContent = _buildFlutterAdminMain();
    final mainFile = File(path.join(_projectPath!, 'admin', 'main.dart'));
    await mainFile.writeAsString(mainContent);
  }
  
  /// Build Flutter admin main.dart content
  String _buildFlutterAdminMain() {
    return '''
import 'package:flutter/material.dart';
import 'package:dartango_admin/dartango_admin.dart';

void main() {
  runApp(DartangoAdminApp());
}

class DartangoAdminApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dartango Admin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AdminDashboard(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/dashboard': (context) => AdminDashboard(),
        '/models': (context) => ModelsListScreen(),
      },
    );
  }
}

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_adminSite?.siteHeader ?? 'Dartango Administration'}'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: AdminDrawer(),
      body: AdminDashboardBody(),
    );
  }
  
  void _logout(BuildContext context) {
    // Handle logout
    Navigator.pushReplacementNamed(context, '/login');
  }
}

class AdminDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Admin Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () => Navigator.pushNamed(context, '/dashboard'),
          ),
          ListTile(
            leading: Icon(Icons.list),
            title: Text('Models'),
            onTap: () => Navigator.pushNamed(context, '/models'),
          ),
          Divider(),
          ...${_buildModelMenuItems()},
        ],
      ),
    );
  }
}

class AdminDashboardBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_adminSite?.indexTitle ?? 'Site Administration'}',
            style: Theme.of(context).textTheme.headline4,
          ),
          SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                ${_buildDashboardCards()},
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Login'),
      ),
      body: Center(
        child: Card(
          margin: EdgeInsets.all(32),
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Login to Admin',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  SizedBox(height: 32),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _login,
                    child: Text('Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _login() {
    if (_formKey.currentState!.validate()) {
      // Handle login
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }
}

class ModelsListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Models'),
      ),
      body: ListView(
        children: [
          ${_buildModelsList()},
        ],
      ),
    );
  }
}
''';
  }
  
  /// Build model menu items
  String _buildModelMenuItems() {
    final items = <String>[];
    final models = AdminAutoDiscovery().discoveredModels;
    
    for (final entry in models.entries) {
      final appName = entry.key;
      items.add('''
          ExpansionTile(
            leading: Icon(Icons.folder),
            title: Text('${_humanize(appName)}'),
            children: [''');
      
      for (final modelType in entry.value) {
        final admin = _adminSite?.getModelAdmin(modelType);
        if (admin != null) {
          items.add('''
              ListTile(
                leading: Icon(Icons.description),
                title: Text('${admin.getVerboseNamePlural()}'),
                onTap: () => _navigateToModel(context, '${admin.getAppLabel()}', '${modelType.toString().toLowerCase()}'),
              ),''');
        }
      }
      
      items.add('''
            ],
          ),''');
    }
    
    return items.join('\n');
  }
  
  /// Build dashboard cards
  String _buildDashboardCards() {
    final cards = <String>[];
    final models = AdminAutoDiscovery().discoveredModels;
    
    for (final entry in models.entries) {
      final appName = entry.key;
      
      for (final modelType in entry.value) {
        final admin = _adminSite?.getModelAdmin(modelType);
        if (admin != null) {
          cards.add('''
                DashboardCard(
                  title: '${admin.getVerboseNamePlural()}',
                  subtitle: '${admin.getAppLabel()}',
                  icon: Icons.description,
                  onTap: () => _navigateToModel(context, '${admin.getAppLabel()}', '${modelType.toString().toLowerCase()}'),
                ),''');
        }
      }
    }
    
    return cards.join('\n');
  }
  
  /// Build models list
  String _buildModelsList() {
    final items = <String>[];
    final models = AdminAutoDiscovery().discoveredModels;
    
    for (final entry in models.entries) {
      final appName = entry.key;
      
      items.add('''
          ExpansionTile(
            title: Text('${_humanize(appName)}'),
            children: [''');
      
      for (final modelType in entry.value) {
        final admin = _adminSite?.getModelAdmin(modelType);
        if (admin != null) {
          items.add('''
              ListTile(
                title: Text('${admin.getVerboseNamePlural()}'),
                subtitle: Text('${admin.getVerboseName()}'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateToModel(context, '${admin.getAppLabel()}', '${modelType.toString().toLowerCase()}'),
              ),''');
        }
      }
      
      items.add('''
            ],
          ),''');
    }
    
    return items.join('\n');
  }
  
  /// Humanize string
  String _humanize(String input) {
    return input
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match.group(1)} ${match.group(2)}')
        .toLowerCase()
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word)
        .join(' ');
  }
  
  /// Create Django-style admin URLs
  Future<void> setupAdminUrls(Function(String, Function) addRoute) async {
    final adminSite = _adminSite;
    if (adminSite == null) return;
    
    // Main admin routes
    addRoute('/admin/', adminSite.indexView);
    addRoute('/admin/login/', adminSite.loginView);
    addRoute('/admin/logout/', adminSite.logoutView);
    
    // Model admin routes
    final models = AdminAutoDiscovery().discoveredModels;
    for (final entry in models.entries) {
      final appName = entry.key;
      
      for (final modelType in entry.value) {
        final admin = adminSite.getModelAdmin(modelType);
        if (admin != null) {
          final modelName = modelType.toString().toLowerCase();
          
          // List view
          addRoute('/admin/$appName/$modelName/', admin.changelistView);
          
          // Add view
          addRoute('/admin/$appName/$modelName/add/', admin.addView);
          
          // Change view
          addRoute('/admin/$appName/$modelName/<id>/change/', (request) async {
            final id = request.pathParameters['id'];
            return await admin.changeView(request, id);
          });
          
          // Delete view
          addRoute('/admin/$appName/$modelName/<id>/delete/', (request) async {
            final id = request.pathParameters['id'];
            return await admin.deleteView(request, id);
          });
        }
      }
    }
  }
  
  /// Get admin site
  AdminSite? get adminSite => _adminSite;
  
  /// Check if initialized
  bool get isInitialized => _isInitialized;
}

/// Flutter admin integration utilities
class FlutterAdminUtils {
  /// Generate pubspec.yaml for admin package
  static String generatePubspec(String projectName) {
    return '''
name: ${projectName}_admin
description: Auto-generated Flutter admin interface for $projectName
version: 1.0.0+1

environment:
  sdk: ">=2.12.0 <4.0.0"
  flutter: ">=1.17.0"

dependencies:
  flutter:
    sdk: flutter
  dartango_admin: ^1.0.0
  http: ^0.13.3
  provider: ^6.0.0
  shared_preferences: ^2.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true
''';
  }
  
  /// Generate gitignore for admin package
  static String generateGitignore() {
    return '''
# Flutter/Dart/Pub related
**/doc/api/
**/ios/Flutter/.last_build_id
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
/build/

# Web related
lib/generated_plugin_registrant.dart

# Symbolication related
app.*.symbols

# Obfuscation related
app.*.map.json

# Android Studio will place build artifacts here
/android/app/debug
/android/app/profile
/android/app/release
''';
  }
}