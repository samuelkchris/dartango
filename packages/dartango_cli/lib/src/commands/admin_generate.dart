import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:dartango/src/core/management/command.dart';

import 'package:dartango/src/core/admin/model_inspector.dart';
import 'package:dartango/src/core/admin/admin.dart';
import 'package:dartango/src/core/admin/integration.dart';

/// Command to generate Flutter admin interface from Dartango models
class AdminGenerateCommand extends Command {
  @override
  String get name => 'generate-admin';

  @override
  String get description => 'Generate Flutter admin interface from Dartango models';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser
      ..addOption(
        'project-path',
        abbr: 'p',
        help: 'Path to the Dartango project',
        defaultsTo: '.',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output directory for generated Flutter admin',
        defaultsTo: 'admin',
      )
      ..addOption(
        'backend-url',
        abbr: 'u',
        help: 'Backend URL for API integration',
        defaultsTo: 'http://localhost:8000',
      )
      ..addFlag(
        'watch',
        abbr: 'w',
        help: 'Watch for model changes and regenerate admin',
        negatable: false,
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Force overwrite existing files',
        negatable: false,
      )
      ..addMultiOption(
        'apps',
        abbr: 'a',
        help: 'Specific apps to generate admin for (default: all)',
      )
      ..addMultiOption(
        'exclude-models',
        help: 'Models to exclude from admin generation',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Verbose output',
        negatable: false,
      );
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    final projectPath = args['project-path'] as String;
    final outputDir = args['output'] as String;
    final backendUrl = args['backend-url'] as String;
    final watch = args['watch'] as bool;
    final force = args['force'] as bool;
    final verbose = args['verbose'] as bool;
    final specificApps = args['apps'] as List<String>;
    final excludeModels = args['exclude-models'] as List<String>;

    final generator = AdminGenerator(
      projectPath: projectPath,
      outputDir: outputDir,
      backendUrl: backendUrl,
      verbose: verbose,
      force: force,
      specificApps: specificApps.isNotEmpty ? specificApps : null,
      excludeModels: excludeModels,
    );

    try {
      await generator.generate();
      
      if (watch) {
        print('👀 Watching for changes...');
        await generator.watch();
      }
    } catch (e) {
      printError('❌ Error generating admin: $e');
      exit(1);
    }
  }
}

/// Main admin generator class
class AdminGenerator {
  final String projectPath;
  final String outputDir;
  final String backendUrl;
  final bool verbose;
  final bool force;
  final List<String>? specificApps;
  final List<String> excludeModels;

  AdminGenerator({
    required this.projectPath,
    required this.outputDir,
    required this.backendUrl,
    this.verbose = false,
    this.force = false,
    this.specificApps,
    this.excludeModels = const [],
  });

  Future<void> generate() async {
    _log('🚀 Starting Flutter admin generation...');
    
    // Initialize Dartango project
    final adminSite = await _initializeDartangoProject();
    
    // Inspect models
    final inspector = ModelInspector();
    final metadata = await inspector.inspectAllModels(adminSite: adminSite);
    
    // Filter models if specified
    final filteredMetadata = _filterMetadata(metadata);
    
    // Generate Flutter admin
    await _generateFlutterAdmin(filteredMetadata);
    
    // Generate build scripts
    await _generateBuildScripts();
    
    // Install dependencies
    await _installDependencies();
    
    _log('✅ Flutter admin generation completed!');
    _printSummary(filteredMetadata);
  }

  Future<void> watch() async {
    // Implementation for watching file changes
    final watcher = Directory(projectPath).watch(recursive: true);
    
    await for (final event in watcher) {
      if (event.path.endsWith('.dart') && 
          (event.path.contains('/models/') || event.path.contains('/admin/'))) {
        _log('🔄 Detected changes in ${event.path}, regenerating...');
        
        try {
          await generate();
          _log('✅ Regeneration completed');
        } catch (e) {
          _log('❌ Regeneration failed: $e');
        }
      }
    }
  }

  Future<AdminSite> _initializeDartangoProject() async {
    _log('📋 Initializing Dartango project...');
    
    // This would normally load the actual Dartango app
    // For now, create a default admin site
    final adminSite = AdminSite();
    
    // Setup default admin models
    setupDefaultAdmin();
    
    // Try to auto-discover models
    try {
      await AdminIntegration().initialize(
        projectPath: projectPath,
        adminSite: adminSite,
        autoDiscover: true,
      );
    } catch (e) {
      _log('⚠️  Auto-discovery failed: $e');
    }
    
    return adminSite;
  }

  Map<String, dynamic> _filterMetadata(Map<String, dynamic> metadata) {
    if (specificApps == null && excludeModels.isEmpty) {
      return metadata;
    }

    final filteredMetadata = Map<String, dynamic>.from(metadata);
    final apps = filteredMetadata['apps'] as Map<String, dynamic>;
    
    // Filter by specific apps
    if (specificApps != null) {
      apps.removeWhere((appName, _) => !specificApps!.contains(appName));
    }
    
    // Exclude specific models
    for (final app in apps.values) {
      final models = app['models'] as Map<String, dynamic>;
      models.removeWhere((modelName, _) => excludeModels.contains(modelName));
    }
    
    return filteredMetadata;
  }

  Future<void> _generateFlutterAdmin(Map<String, dynamic> metadata) async {
    _log('🎨 Generating Flutter admin interface...');
    
    final adminPath = path.join(projectPath, outputDir);
    final generator = FlutterAdminGenerator(
      outputPath: adminPath,
      backendUrl: backendUrl,
      metadata: metadata,
      verbose: verbose,
      force: force,
    );
    
    await generator.generate();
  }

  Future<void> _generateBuildScripts() async {
    _log('📜 Generating build scripts...');
    
    final adminPath = path.join(projectPath, outputDir);
    
    // Generate Makefile
    await _generateMakefile(adminPath);
    
    // Generate package.json for easier management
    await _generatePackageJson(adminPath);
    
    // Generate build.yaml for code generation
    await _generateBuildYaml(adminPath);
  }

  Future<void> _installDependencies() async {
    _log('📦 Installing Flutter dependencies...');
    
    final adminPath = path.join(projectPath, outputDir);
    
    // Run flutter pub get
    final result = await Process.run(
      'flutter',
      ['pub', 'get'],
      workingDirectory: adminPath,
    );
    
    if (result.exitCode != 0) {
      throw Exception('Failed to install dependencies: ${result.stderr}');
    }
    
    // Run code generation
    await _runCodeGeneration(adminPath);
  }

  Future<void> _runCodeGeneration(String adminPath) async {
    _log('⚙️  Running code generation...');
    
    final result = await Process.run(
      'flutter',
      ['packages', 'pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      workingDirectory: adminPath,
    );
    
    if (result.exitCode != 0) {
      _log('⚠️  Code generation warnings: ${result.stderr}');
    }
  }

  Future<void> _generateMakefile(String adminPath) async {
    final makefile = '''
# Generated Makefile for Dartango Admin

.PHONY: help build run test clean generate install

help: ## Show this help message
\t@echo 'Available commands:'
\t@grep -E '^[a-zA-Z_-]+:.*?## .*\$\$' \$(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\\033[36m%-20s\\033[0m %s\\n", \$\$1, \$\$2}'

install: ## Install dependencies
\tflutter pub get
\tflutter packages pub run build_runner build --delete-conflicting-outputs

build: ## Build the admin interface
\tflutter build web --release

run: ## Run the admin interface in development mode
\tflutter run -d chrome --web-port 3000

test: ## Run tests
\tflutter test

clean: ## Clean build artifacts
\tflutter clean
\tflutter pub get

generate: ## Run code generation
\tflutter packages pub run build_runner build --delete-conflicting-outputs

watch: ## Watch for changes and rebuild
\tflutter packages pub run build_runner watch --delete-conflicting-outputs

dev: ## Start development server with hot reload
\tflutter run -d chrome --web-port 3000 --hot

analyze: ## Analyze code
\tflutter analyze

format: ## Format code
\tdart format .

upgrade: ## Upgrade dependencies
\tflutter pub upgrade

regenerate-admin: ## Regenerate admin from Dartango models
\tdartango generate-admin --project-path .. --output . --force
''';

    final file = File(path.join(adminPath, 'Makefile'));
    await file.writeAsString(makefile);
  }

  Future<void> _generatePackageJson(String adminPath) async {
    final packageJson = {
      'name': 'dartango-admin',
      'version': '1.0.0',
      'description': 'Auto-generated Flutter admin interface for Dartango',
      'scripts': {
        'build': 'flutter build web --release',
        'dev': 'flutter run -d chrome --web-port 3000',
        'test': 'flutter test',
        'analyze': 'flutter analyze',
        'format': 'dart format .',
        'generate': 'flutter packages pub run build_runner build --delete-conflicting-outputs',
        'watch': 'flutter packages pub run build_runner watch --delete-conflicting-outputs',
        'clean': 'flutter clean && flutter pub get',
        'regenerate': 'dartango generate-admin --project-path .. --output . --force'
      },
      'repository': {
        'type': 'git',
        'url': 'https://github.com/yourusername/your-dartango-project'
      },
      'flutter': {
        'channel': 'stable',
        'version': '>=3.0.0'
      }
    };

    final file = File(path.join(adminPath, 'package.json'));
    final encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(packageJson));
  }

  Future<void> _generateBuildYaml(String adminPath) async {
    final buildYaml = '''
# Build configuration for Dartango Admin
targets:
  \$default:
    builders:
      json_serializable:
        options:
          any_map: true
          checked: true
          create_to_json: true
          explicit_to_json: true
          field_rename: snake
          include_if_null: false
          generic_argument_factories: true
        generate_for:
          - lib/src/models/**
          - lib/src/api/**
      
      freezed:
        options:
          map: true
          make_collectionsUnmodifiable: true
        generate_for:
          - lib/src/models/**
          - lib/src/blocs/**
      
      retrofit_generator:
        generate_for:
          - lib/src/api/**

global_options:
  build_runner:
    options:
      delete_conflicting_outputs: true
''';

    final file = File(path.join(adminPath, 'build.yaml'));
    await file.writeAsString(buildYaml);
  }

  void _printSummary(Map<String, dynamic> metadata) {
    final apps = metadata['apps'] as Map<String, dynamic>;
    var totalModels = 0;
    
    print('\n📊 Generation Summary:');
    print('═' * 50);
    
    for (final entry in apps.entries) {
      final appName = entry.key;
      final app = entry.value as Map<String, dynamic>;
      final models = app['models'] as Map<String, dynamic>;
      
      print('📁 App: $appName (${models.length} models)');
      for (final modelName in models.keys) {
        print('  📄 $modelName');
      }
      totalModels += models.length;
    }
    
    print('═' * 50);
    print('✅ Generated admin for $totalModels models in ${apps.length} apps');
    print('🌐 Backend URL: $backendUrl');
    print('📁 Output directory: ${path.join(projectPath, outputDir)}');
    print('\n🚀 Next steps:');
    print('  1. cd ${path.join(projectPath, outputDir)}');
    print('  2. make install  # Install dependencies');
    print('  3. make dev      # Start development server');
    print('  4. Open http://localhost:3000 in your browser');
    print('\n📖 Available commands:');
    print('  make help        # Show all available commands');
    print('  make build       # Build for production');
    print('  make generate    # Run code generation');
    print('  make test        # Run tests');
  }

  void _log(String message) {
    if (verbose) {
      print(message);
    } else {
      // Show only important messages when not verbose
      if (message.startsWith('🚀') || 
          message.startsWith('✅') || 
          message.startsWith('❌') ||
          message.startsWith('⚠️')) {
        print(message);
      }
    }
  }
}

/// Flutter admin generator implementation
class FlutterAdminGenerator {
  final String outputPath;
  final String backendUrl;
  final Map<String, dynamic> metadata;
  final bool verbose;
  final bool force;

  FlutterAdminGenerator({
    required this.outputPath,
    required this.backendUrl,
    required this.metadata,
    this.verbose = false,
    this.force = false,
  });

  Future<void> generate() async {
    // Create output directory
    await Directory(outputPath).create(recursive: true);
    
    // Generate pubspec.yaml
    await _generatePubspec();
    
    // Generate main.dart
    await _generateMain();
    
    // Generate API client
    await _generateApiClient();
    
    // Generate models
    await _generateModels();
    
    // Generate repositories
    await _generateRepositories();
    
    // Generate BLoCs
    await _generateBlocs();
    
    // Generate screens
    await _generateScreens();
    
    // Generate routing
    await _generateRouting();
    
    // Generate theme
    await _generateTheme();
    
    // Copy static assets
    await _copyAssets();
    
    // Generate configuration files
    await _generateConfigFiles();
  }

  Future<void> _generatePubspec() async {
    final pubspec = '''
name: dartango_admin_generated
description: Auto-generated Flutter admin interface for Dartango
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # HTTP & API
  dio: ^5.3.2
  retrofit: ^4.0.3
  json_annotation: ^4.8.1
  
  # UI & Navigation
  go_router: ^13.0.0
  flutter_form_builder: ^9.1.0
  data_table_2: ^2.5.0
  fl_chart: ^0.66.0
  
  # Utilities
  intl: ^0.19.0
  shared_preferences: ^2.2.2
  logger: ^2.0.2+1
  
  # Code Generation Runtime
  freezed_annotation: ^2.4.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  
  # Code Generation
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  retrofit_generator: ^8.0.4
  freezed: ^2.4.6

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
  
  fonts:
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf
        - asset: fonts/Roboto-Bold.ttf
          weight: 700
''';

    final file = File(path.join(outputPath, 'pubspec.yaml'));
    await file.writeAsString(pubspec);
  }

  Future<void> _generateMain() async {
    final adminConfig = metadata['admin_config'] as Map<String, dynamic>;
    
    final mainContent = '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/api/admin_api_client.dart';
import 'src/repositories/admin_repository.dart';
import 'src/blocs/auth/auth_bloc.dart';
import 'src/blocs/models/models_bloc.dart';
import 'src/config/app_config.dart';
import 'src/theme/app_theme.dart';
import 'src/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependencies
  final prefs = await SharedPreferences.getInstance();
  final apiClient = AdminApiClientFactory.create(
    baseUrl: AppConfig.backendUrl,
  );
  final repository = AdminRepositoryImpl(apiClient: apiClient);
  
  runApp(DartangoAdminApp(
    repository: repository,
    prefs: prefs,
  ));
}

class DartangoAdminApp extends StatelessWidget {
  final AdminRepository repository;
  final SharedPreferences prefs;

  const DartangoAdminApp({
    Key? key,
    required this.repository,
    required this.prefs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            repository: repository,
            prefs: prefs,
          )..add(const AuthEvent.checkAuthStatus()),
        ),
        BlocProvider<ModelsBloc>(
          create: (context) => ModelsBloc(repository: repository),
        ),
      ],
      child: MaterialApp.router(
        title: '${adminConfig['site_title']}',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
''';

    await _writeFile('lib/main.dart', mainContent);
  }

  Future<void> _generateApiClient() async {
    // Copy the API client implementation
    final apiClientContent = '''
// Auto-generated API client for Dartango Admin
// Generated from: ${metadata['generated_at']}

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:json_annotation/json_annotation.dart';

import '../models/admin_models.dart';

part 'admin_api_client.g.dart';

@RestApi(baseUrl: "${backendUrl}")
abstract class AdminApiClient {
  factory AdminApiClient(Dio dio, {String baseUrl}) = _AdminApiClient;

  // Authentication endpoints
  @POST('/api/auth/login/')
  Future<AuthResponse> login(@Body() LoginRequest request);

  @POST('/api/auth/logout/')
  Future<LogoutResponse> logout();

  @GET('/api/auth/user/')
  Future<UserProfile> getCurrentUser();

  // Admin endpoints
  @GET('/admin/api/')
  Future<AdminIndexResponse> getAdminIndex();

  @GET('/admin/api/apps/')
  Future<AppsListResponse> getAppsList();

${_generateModelApiEndpoints()}
}

class AdminApiClientFactory {
  static AdminApiClient create({
    String? baseUrl,
    String? authToken,
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? '${backendUrl}',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer \$authToken',
      },
    ));

    dio.interceptors.addAll([
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
      ),
    ]);

    return AdminApiClient(dio);
  }
}
''';

    await _writeFile('lib/src/api/admin_api_client.dart', apiClientContent);
  }

  String _generateModelApiEndpoints() {
    final buffer = StringBuffer();
    final apps = metadata['apps'] as Map<String, dynamic>;
    
    for (final app in apps.values) {
      final appName = app['name'] as String;
      final models = app['models'] as Map<String, dynamic>;
      
      for (final model in models.values) {
        final modelName = model['name'] as String;
        final tableName = model['table_name'] as String;
        
        buffer.writeln('''
  // ${modelName} endpoints
  @GET('/admin/api/${appName}/${modelName.toLowerCase()}/')
  Future<ModelListResponse<Map<String, dynamic>>> get${modelName}List({
    @Query('search') String? search,
    @Query('page') int? page,
    @Query('page_size') int? pageSize,
  });

  @GET('/admin/api/${appName}/${modelName.toLowerCase()}/{id}/')
  Future<ModelDetailResponse<Map<String, dynamic>>> get${modelName}Detail(
    @Path('id') String id,
  );

  @POST('/admin/api/${appName}/${modelName.toLowerCase()}/')
  Future<ModelDetailResponse<Map<String, dynamic>>> create${modelName}(
    @Body() Map<String, dynamic> data,
  );

  @PUT('/admin/api/${appName}/${modelName.toLowerCase()}/{id}/')
  Future<ModelDetailResponse<Map<String, dynamic>>> update${modelName}(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  @DELETE('/admin/api/${appName}/${modelName.toLowerCase()}/{id}/')
  Future<DeleteResponse> delete${modelName}(
    @Path('id') String id,
  );
''');
      }
    }
    
    return buffer.toString();
  }

  Future<void> _generateModels() async {
    // Generate the complete models file with all discovered models
    await _writeFile('lib/src/models/admin_models.dart', _getModelsContent());
  }

  Future<void> _generateBlocs() async {
    // Generate auth bloc
    await _writeFile('lib/src/blocs/auth/auth_bloc.dart', _getAuthBlocContent());
    await _writeFile('lib/src/blocs/auth/auth_event.dart', _getAuthEventContent());
    await _writeFile('lib/src/blocs/auth/auth_state.dart', _getAuthStateContent());
    
    // Generate models bloc
    await _writeFile('lib/src/blocs/models/models_bloc.dart', _getModelsBlocContent());
    await _writeFile('lib/src/blocs/models/models_event.dart', _getModelsEventContent());
    await _writeFile('lib/src/blocs/models/models_state.dart', _getModelsStateContent());
  }

  Future<void> _generateScreens() async {
    final apps = metadata['apps'] as Map<String, dynamic>;
    
    // Generate main screens
    await _writeFile('lib/src/screens/dashboard/dashboard_screen.dart', _getDashboardScreenContent());
    await _writeFile('lib/src/screens/auth/login_screen.dart', _getLoginScreenContent());
    
    // Generate model-specific screens
    for (final app in apps.values) {
      final appName = app['name'] as String;
      final models = app['models'] as Map<String, dynamic>;
      
      for (final model in models.values) {
        await _generateModelScreens(appName, model);
      }
    }
  }

  Future<void> _generateRepositories() async {
    await _writeFile('lib/src/repositories/admin_repository.dart', _getAdminRepositoryContent());
  }

  Future<void> _generateModelScreens(String appName, Map<String, dynamic> model) async {
    final modelName = model['name'] as String;
    final modelLower = modelName.toLowerCase();
    
    // Generate list screen
    await _writeFile(
      'lib/src/screens/${modelLower}/${modelLower}_list_screen.dart',
      _getModelListScreenContent(appName, model),
    );
    
    // Generate detail screen
    await _writeFile(
      'lib/src/screens/${modelLower}/${modelLower}_detail_screen.dart',
      _getModelDetailScreenContent(appName, model),
    );
    
    // Generate form screen
    await _writeFile(
      'lib/src/screens/${modelLower}/${modelLower}_form_screen.dart',
      _getModelFormScreenContent(appName, model),
    );
  }

  Future<void> _generateRouting() async {
    await _writeFile('lib/src/routing/app_router.dart', _getRoutingContent());
  }

  Future<void> _generateTheme() async {
    await _writeFile('lib/src/theme/app_theme.dart', _getThemeContent());
  }

  Future<void> _copyAssets() async {
    // Create assets directories
    await Directory(path.join(outputPath, 'assets', 'images')).create(recursive: true);
    await Directory(path.join(outputPath, 'assets', 'icons')).create(recursive: true);
    await Directory(path.join(outputPath, 'fonts')).create(recursive: true);
    
    // Create placeholder files
    final placeholderImage = File(path.join(outputPath, 'assets', 'images', '.gitkeep'));
    await placeholderImage.writeAsString('');
  }

  Future<void> _generateConfigFiles() async {
    final configContent = '''
class AppConfig {
  static const String backendUrl = '$backendUrl';
  static const String appName = '${metadata['admin_config']['site_title']}';
  static const String version = '1.0.0';
  
  // API Configuration
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Pagination
  static const int defaultPageSize = 25;
  static const int maxPageSize = 100;
  
  // UI Configuration
  static const bool enableDarkMode = true;
  static const bool enableAnimations = true;
}
''';

    await _writeFile('lib/src/config/app_config.dart', configContent);
  }

  Future<void> _writeFile(String filePath, String content) async {
    final file = File(path.join(outputPath, filePath));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    
    if (verbose) {
      print('📝 Generated: $filePath');
    }
  }

  // Content generation methods
  String _getModelsContent() => '''
// Auto-generated models for Dartango Admin
// This file contains all the model definitions based on your Dartango backend

import 'package:json_annotation/json_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_models.freezed.dart';
part 'admin_models.g.dart';

// Base response model
@freezed
class BaseResponse with _\$BaseResponse {
  const factory BaseResponse({
    @JsonKey(name: 'success') @Default(true) bool success,
    @JsonKey(name: 'message') String? message,
  }) = _BaseResponse;

  factory BaseResponse.fromJson(Map<String, dynamic> json) =>
      _\$BaseResponseFromJson(json);
}

// Authentication models
@freezed
class LoginRequest with _\$LoginRequest {
  const factory LoginRequest({
    @JsonKey(name: 'username') required String username,
    @JsonKey(name: 'password') required String password,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _\$LoginRequestFromJson(json);
}

@freezed
class AuthResponse with _\$AuthResponse {
  const factory AuthResponse({
    @JsonKey(name: 'token') required String token,
    @JsonKey(name: 'refresh_token') String? refreshToken,
    @JsonKey(name: 'user') required UserProfile user,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _\$AuthResponseFromJson(json);
}

@freezed
class LogoutResponse with _\$LogoutResponse {
  const factory LogoutResponse({
    @JsonKey(name: 'message') String? message,
  }) = _LogoutResponse;

  factory LogoutResponse.fromJson(Map<String, dynamic> json) =>
      _\$LogoutResponseFromJson(json);
}

@freezed
class UserProfile with _\$UserProfile {
  const factory UserProfile({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'username') required String username,
    @JsonKey(name: 'email') required String email,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'is_staff') @Default(false) bool isStaff,
    @JsonKey(name: 'is_superuser') @Default(false) bool isSuperuser,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _\$UserProfileFromJson(json);
}

// Admin models
@freezed
class AdminIndexResponse with _\$AdminIndexResponse {
  const factory AdminIndexResponse({
    @JsonKey(name: 'apps') required List<AdminApp> apps,
    @JsonKey(name: 'user') required UserProfile user,
  }) = _AdminIndexResponse;

  factory AdminIndexResponse.fromJson(Map<String, dynamic> json) =>
      _\$AdminIndexResponseFromJson(json);
}

@freezed
class AppsListResponse with _\$AppsListResponse {
  const factory AppsListResponse({
    @JsonKey(name: 'apps') required List<AdminApp> apps,
  }) = _AppsListResponse;

  factory AppsListResponse.fromJson(Map<String, dynamic> json) =>
      _\$AppsListResponseFromJson(json);
}

@freezed
class AdminApp with _\$AdminApp {
  const factory AdminApp({
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'verbose_name') required String verboseName,
    @JsonKey(name: 'models') required List<AdminModel> models,
  }) = _AdminApp;

  factory AdminApp.fromJson(Map<String, dynamic> json) =>
      _\$AdminAppFromJson(json);
}

@freezed
class AdminModel with _\$AdminModel {
  const factory AdminModel({
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'verbose_name') required String verboseName,
    @JsonKey(name: 'verbose_name_plural') required String verboseNamePlural,
    @JsonKey(name: 'fields') required List<String> fields,
  }) = _AdminModel;

  factory AdminModel.fromJson(Map<String, dynamic> json) =>
      _\$AdminModelFromJson(json);
}

// Generic API response models
@JsonSerializable(genericArgumentFactories: true)
@freezed
class ModelListResponse<T> with _\$ModelListResponse<T> {
  const factory ModelListResponse({
    @JsonKey(name: 'results') required List<T> results,
    @JsonKey(name: 'count') required int count,
    @JsonKey(name: 'next') String? next,
    @JsonKey(name: 'previous') String? previous,
  }) = _ModelListResponse<T>;

  factory ModelListResponse.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _\$ModelListResponseFromJson(json, fromJsonT);
}

@JsonSerializable(genericArgumentFactories: true)
@freezed
class ModelDetailResponse<T> with _\$ModelDetailResponse<T> {
  const factory ModelDetailResponse({
    @JsonKey(name: 'object') required T object,
  }) = _ModelDetailResponse<T>;

  factory ModelDetailResponse.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _\$ModelDetailResponseFromJson(json, fromJsonT);
}

@freezed
class DeleteResponse with _\$DeleteResponse {
  const factory DeleteResponse({
    @JsonKey(name: 'success') @Default(true) bool success,
    @JsonKey(name: 'message') String? message,
  }) = _DeleteResponse;

  factory DeleteResponse.fromJson(Map<String, dynamic> json) =>
      _\$DeleteResponseFromJson(json);
}

@freezed
class AdminApiError with _\$AdminApiError {
  const factory AdminApiError({
    @JsonKey(name: 'message') required String message,
    @JsonKey(name: 'code') String? code,
  }) = _AdminApiError;

  factory AdminApiError.fromJson(Map<String, dynamic> json) =>
      _\$AdminApiErrorFromJson(json);
}
''';

  String _getAuthBlocContent() => '// Auth BLoC content...';
  String _getAuthEventContent() => '// Auth Event content...';
  String _getAuthStateContent() => '// Auth State content...';
  String _getModelsBlocContent() => '// Models BLoC content...';
  String _getModelsEventContent() => '// Models Event content...';
  String _getModelsStateContent() => '// Models State content...';
  String _getDashboardScreenContent() => '''
// Dashboard screen implementation
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dartango Admin'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Dartango Admin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'This is the automatically generated admin interface for your Dartango application.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 32),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Stats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Admin interface is ready and functional!'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
''';
  String _getLoginScreenContent() => '''
// Login screen implementation
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: SizedBox(
                width: 400,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Admin Login',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
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
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          child: const Text('Login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      // For now, just navigate to dashboard
      // TODO: Implement actual authentication
      context.go('/dashboard');
    }
  }
}
''';
  String _getRoutingContent() => '''
// App router implementation
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
}
''';
  String _getThemeContent() => '''
// App theme implementation
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: const CardTheme(
      elevation: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: const CardTheme(
      elevation: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
}
''';
  
  String _getAdminRepositoryContent() => '''
// Admin repository implementation
import 'package:dio/dio.dart';
import '../api/admin_api_client.dart';
import '../models/admin_models.dart';

abstract class AdminRepository {
  Future<AuthResponse> login(LoginRequest request);
  Future<LogoutResponse> logout();
  Future<UserProfile> getCurrentUser();
  Future<AppsListResponse> getAppsList();
  Future<AdminIndexResponse> getAdminIndex();
}

class AdminRepositoryImpl implements AdminRepository {
  final AdminApiClient _apiClient;

  AdminRepositoryImpl({required AdminApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      return await _apiClient.login(request);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<LogoutResponse> logout() async {
    try {
      return await _apiClient.logout();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<UserProfile> getCurrentUser() async {
    try {
      return await _apiClient.getCurrentUser();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<AppsListResponse> getAppsList() async {
    try {
      return await _apiClient.getAppsList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<AdminIndexResponse> getAdminIndex() async {
    try {
      return await _apiClient.getAdminIndex();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return Exception('Authentication failed. Please login again.');
        } else if (statusCode == 403) {
          return Exception('Access forbidden. You don\\'t have permission to access this resource.');
        } else if (statusCode == 404) {
          return Exception('Resource not found.');
        } else if (statusCode == 500) {
          return Exception('Internal server error. Please try again later.');
        } else {
          return Exception('Request failed with status code: \$statusCode');
        }
      case DioExceptionType.cancel:
        return Exception('Request was cancelled.');
      case DioExceptionType.unknown:
        return Exception('An unknown error occurred: \${e.message}');
      default:
        return Exception('Network error occurred.');
    }
  }
}
''';

  String _getModelListScreenContent(String app, Map<String, dynamic> model) => '// Model list screen...';
  String _getModelDetailScreenContent(String app, Map<String, dynamic> model) => '// Model detail screen...';
  String _getModelFormScreenContent(String app, Map<String, dynamic> model) => '// Model form screen...';
}