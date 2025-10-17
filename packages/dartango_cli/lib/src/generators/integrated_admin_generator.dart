import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

import 'package:dartango/src/core/admin/model_inspector.dart';
import 'package:dartango/src/core/admin/admin.dart';
import 'package:dartango/src/core/admin/integration.dart';

/// Generator that creates fully integrated Flutter admin interfaces
/// as part of the Dartango app creation process
class IntegratedAdminGenerator {
  final String projectPath;
  final String projectName;
  final String backendUrl;
  final bool verbose;

  IntegratedAdminGenerator({
    required this.projectPath,
    required this.projectName,
    this.backendUrl = 'http://localhost:8000',
    this.verbose = false,
  });

  /// Generate the complete integrated admin interface
  Future<void> generate() async {
    _log('🎨 Generating integrated Flutter admin interface...');
    
    final adminPath = path.join(projectPath, 'admin');
    await Directory(adminPath).create(recursive: true);

    // Initialize admin site and inspect models
    final adminSite = await _initializeAdminSite();
    final metadata = await _inspectModels(adminSite);
    
    // Generate Flutter admin package
    await _generateFlutterAdminPackage(adminPath, metadata);
    
    // Generate build and configuration files
    await _generateBuildConfiguration(adminPath);
    
    // Install dependencies and run code generation
    await _installDependenciesAndGenerate(adminPath);
    
    _log('✅ Integrated Flutter admin generated successfully!');
    _printCompletionSummary(adminPath, metadata);
  }

  /// Initialize admin site with auto-discovery
  Future<AdminSite> _initializeAdminSite() async {
    _log('📋 Initializing admin site with model discovery...');
    
    final adminSite = AdminSite();
    setupDefaultAdmin();
    
    try {
      await AdminIntegration().initialize(
        projectPath: projectPath,
        adminSite: adminSite,
        autoDiscover: true,
      );
    } catch (e) {
      _log('⚠️  Model auto-discovery failed: $e');
      // Continue with default admin setup
    }
    
    return adminSite;
  }

  /// Inspect models and generate metadata
  Future<Map<String, dynamic>> _inspectModels(AdminSite adminSite) async {
    _log('🔍 Inspecting models for admin generation...');
    
    final inspector = ModelInspector();
    final metadata = await inspector.inspectAllModels(adminSite: adminSite);
    
    // Enhance metadata with project-specific info
    metadata['project_name'] = projectName;
    metadata['backend_url'] = backendUrl;
    metadata['admin_config']['site_title'] = '$projectName Admin';
    
    return metadata;
  }

  /// Generate the complete Flutter admin package
  Future<void> _generateFlutterAdminPackage(String adminPath, Map<String, dynamic> metadata) async {
    _log('📦 Generating Flutter admin package...');
    
    // Generate pubspec.yaml
    await _generatePubspec(adminPath);
    
    // Generate main.dart
    await _generateMain(adminPath, metadata);
    
    // Generate API client
    await _generateApiClient(adminPath, metadata);
    
    // Generate models
    await _generateModels(adminPath, metadata);
    
    // Generate BLoCs
    await _generateBlocs(adminPath, metadata);
    
    // Generate screens
    await _generateScreens(adminPath, metadata);
    
    // Generate routing
    await _generateRouting(adminPath, metadata);
    
    // Generate theme and configuration
    await _generateThemeAndConfig(adminPath, metadata);
    
    // Generate widgets
    await _generateCommonWidgets(adminPath);
    
    // Generate repositories
    await _generateRepositories(adminPath);
    
    // Copy assets
    await _copyAssets(adminPath);
  }

  /// Generate pubspec.yaml for the admin package
  Future<void> _generatePubspec(String adminPath) async {
    final pubspec = '''
name: ${projectName}_admin
description: Auto-generated Flutter admin interface for $projectName
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
  data_table_2: ^2.5.0
  fl_chart: ^0.66.0
  
  # Utilities
  intl: any
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

    await _writeFile(adminPath, 'pubspec.yaml', pubspec);
  }

  /// Generate main.dart entry point
  Future<void> _generateMain(String adminPath, Map<String, dynamic> metadata) async {
    final adminConfig = metadata['admin_config'] as Map<String, dynamic>;
    final siteTitle = adminConfig['site_title'] ?? '$projectName Admin';
    
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
  
  runApp(${_toPascalCase(projectName)}AdminApp(
    repository: repository,
    prefs: prefs,
  ));
}

class ${_toPascalCase(projectName)}AdminApp extends StatelessWidget {
  final AdminRepository repository;
  final SharedPreferences prefs;

  const ${_toPascalCase(projectName)}AdminApp({
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
        title: '$siteTitle',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
''';

    await _writeFile(adminPath, 'lib/main.dart', mainContent);
  }

  /// Generate API client with all endpoints
  Future<void> _generateApiClient(String adminPath, Map<String, dynamic> metadata) async {
    final apiClientContent = '''
// Auto-generated API client for $projectName Admin
// Generated at: ${metadata['generated_at']}

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:json_annotation/json_annotation.dart';

import '../models/admin_models.dart';

part 'admin_api_client.g.dart';

@RestApi(baseUrl: "$backendUrl")
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

${_generateModelApiEndpoints(metadata)}
}

class AdminApiClientFactory {
  static AdminApiClient create({
    String? baseUrl,
    String? authToken,
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? '$backendUrl',
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

    await _writeFile(adminPath, 'lib/src/api/admin_api_client.dart', apiClientContent);
  }

  /// Generate model API endpoints
  String _generateModelApiEndpoints(Map<String, dynamic> metadata) {
    final buffer = StringBuffer();
    final apps = metadata['apps'] as Map<String, dynamic>;
    
    for (final app in apps.values) {
      final appName = app['name'] as String;
      final models = app['models'] as Map<String, dynamic>;
      
      for (final model in models.values) {
        final modelName = model['name'] as String;
        
        buffer.writeln('''
  // $modelName endpoints
  @GET('/admin/api/$appName/${modelName.toLowerCase()}/')
  Future<ModelListResponse<Map<String, dynamic>>> get${modelName}List({
    @Query('search') String? search,
    @Query('page') int? page,
    @Query('page_size') int? pageSize,
  });

  @GET('/admin/api/$appName/${modelName.toLowerCase()}/{id}/')
  Future<ModelDetailResponse<Map<String, dynamic>>> get${modelName}Detail(
    @Path('id') String id,
  );

  @POST('/admin/api/$appName/${modelName.toLowerCase()}/')
  Future<ModelDetailResponse<Map<String, dynamic>>> create$modelName(
    @Body() Map<String, dynamic> data,
  );

  @PUT('/admin/api/$appName/${modelName.toLowerCase()}/{id}/')
  Future<ModelDetailResponse<Map<String, dynamic>>> update$modelName(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  @DELETE('/admin/api/$appName/${modelName.toLowerCase()}/{id}/')
  Future<DeleteResponse> delete$modelName(
    @Path('id') String id,
  );
''');
      }
    }
    
    return buffer.toString();
  }

  /// Generate admin models
  Future<void> _generateModels(String adminPath, Map<String, dynamic> metadata) async {
    // Read the existing admin models from dartango_admin package
    final adminModelsPath = '/Users/samuel/IdeaProjects/dartango/packages/dartango_admin/lib/src/models/admin_models.dart';
    final adminModelsContent = await File(adminModelsPath).readAsString();
    
    final modelsContent = '''
// Auto-generated models for $projectName Admin
// This file contains all the model definitions based on your Dartango backend

import 'package:json_annotation/json_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:equatable/equatable.dart';

part 'admin_models.freezed.dart';
part 'admin_models.g.dart';

$adminModelsContent

// Project-specific model metadata
class ProjectModelMetadata {
  static const projectName = '$projectName';
  static const backendUrl = '$backendUrl';
  static const generatedAt = '${metadata['generated_at']}';
  
  static final apps = ${_generateAppsMetadata(metadata)};
}
''';

    await _writeFile(adminPath, 'lib/src/models/admin_models.dart', modelsContent);
  }

  /// Generate apps metadata
  String _generateAppsMetadata(Map<String, dynamic> metadata) {
    final apps = metadata['apps'] as Map<String, dynamic>;
    final appsJson = JsonEncoder.withIndent('  ').convert(apps);
    return appsJson;
  }

  /// Generate BLoCs
  Future<void> _generateBlocs(String adminPath, Map<String, dynamic> metadata) async {
    // Copy BLoCs from dartango_admin package
    final sourceBlocsPath = '/Users/samuel/IdeaProjects/dartango/packages/dartango_admin/lib/src/blocs';
    final targetBlocsPath = path.join(adminPath, 'lib/src/blocs');
    
    await _copyDirectory(sourceBlocsPath, targetBlocsPath);
  }

  /// Generate screens
  Future<void> _generateScreens(String adminPath, Map<String, dynamic> metadata) async {
    // Copy base screens from dartango_admin package
    final sourceScreensPath = '/Users/samuel/IdeaProjects/dartango/packages/dartango_admin/lib/src/screens';
    final targetScreensPath = path.join(adminPath, 'lib/src/screens');
    
    await _copyDirectory(sourceScreensPath, targetScreensPath);
    
    // Generate model-specific screens
    await _generateModelScreens(adminPath, metadata);
  }

  /// Generate model-specific screens
  Future<void> _generateModelScreens(String adminPath, Map<String, dynamic> metadata) async {
    final apps = metadata['apps'] as Map<String, dynamic>;
    
    for (final app in apps.values) {
      final appName = app['name'] as String;
      final models = app['models'] as Map<String, dynamic>;
      
      for (final model in models.values) {
        // Generate list screen
        await _generateModelListScreen(adminPath, appName, model);
        
        // Generate detail screen
        await _generateModelDetailScreen(adminPath, appName, model);
        
        // Generate form screen
        await _generateModelFormScreen(adminPath, appName, model);
      }
    }
  }

  /// Generate model list screen
  Future<void> _generateModelListScreen(String adminPath, String appName, Map<String, dynamic> model) async {
    final modelName = model['name'] as String;
    final modelLower = modelName.toLowerCase();
    final verboseNamePlural = model['verbose_name_plural'] as String;
    final adminConfig = model['admin_config'] as Map<String, dynamic>;
    final listDisplay = List<String>.from(adminConfig['list_display'] ?? []);
    
    final screenContent = '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/models/models_bloc.dart';
import '../../widgets/common/admin_data_table.dart';
import '../../widgets/common/loading_indicator.dart';

class ${modelName}ListScreen extends StatefulWidget {
  const ${modelName}ListScreen({Key? key}) : super(key: key);

  @override
  State<${modelName}ListScreen> createState() => _${modelName}ListScreenState();
}

class _${modelName}ListScreenState extends State<${modelName}ListScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<ModelsBloc>().add(
      ModelsEvent.loadModelList('$appName', '$modelLower'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$verboseNamePlural'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/$modelLower/add'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: BlocBuilder<ModelsBloc, ModelsState>(
        builder: (context, state) {
          if (state.listLoading && state.modelList.isEmpty) {
            return const LoadingIndicator();
          }

          if (state.listError != null && state.modelList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: \${state.listError}'),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return AdminDataTable<Map<String, dynamic>>(
            items: state.modelList,
            columns: [
${listDisplay.map((field) => "              DataColumn(label: Text('${_humanize(field)}')),").join('\n')}
            ],
            cellBuilder: (item, columnIndex) {
              final fields = ${jsonEncode(listDisplay)};
              final field = fields[columnIndex];
              return Text(item[field]?.toString() ?? 'N/A');
            },
            onRowTap: (item) => context.go('/$modelLower/\${item['id']}'),
            selectable: true,
            selectedItems: state.selectedItems,
            onSelectionChanged: (id, selected) {
              context.read<ModelsBloc>().add(
                ModelsEvent.toggleItemSelection(id),
              );
            },
            loading: state.listLoading,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/$modelLower/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
''';

    await _writeFile(adminPath, 'lib/src/screens/$modelLower/${modelLower}_list_screen.dart', screenContent);
  }

  /// Generate model detail screen
  Future<void> _generateModelDetailScreen(String adminPath, String appName, Map<String, dynamic> model) async {
    final modelName = model['name'] as String;
    final modelLower = modelName.toLowerCase();
    final verboseName = model['verbose_name'] as String;
    
    final screenContent = '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/models/models_bloc.dart';
import '../../widgets/common/loading_indicator.dart';

class ${modelName}DetailScreen extends StatefulWidget {
  final String id;

  const ${modelName}DetailScreen({Key? key, required this.id}) : super(key: key);

  @override
  State<${modelName}DetailScreen> createState() => _${modelName}DetailScreenState();
}

class _${modelName}DetailScreenState extends State<${modelName}DetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<ModelsBloc>().add(
      ModelsEvent.loadModelDetail('$appName', '$modelLower', widget.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$verboseName Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/$modelLower/\${widget.id}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: BlocConsumer<ModelsBloc, ModelsState>(
        listener: (context, state) {
          if (state.deleteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Deleted successfully')),
            );
            context.go('/$modelLower');
          } else if (state.deleteError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: \${state.deleteError}')),
            );
          }
        },
        builder: (context, state) {
          if (state.detailLoading) {
            return const LoadingIndicator();
          }

          if (state.detailError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: \${state.detailError}'),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final item = state.modelDetail;
          if (item == null) {
            return const Center(child: Text('No data available'));
          }

          return _buildDetailView(item);
        },
      ),
    );
  }

  Widget _buildDetailView(Map<String, dynamic> item) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$verboseName Information',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...item.entries.map((entry) => _buildDetailField(entry.key, entry.value)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailField(String key, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              _humanize(key),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ModelsBloc>().add(
                ModelsEvent.deleteModel('$appName', '$modelLower', widget.id),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _humanize(String input) {
    return input
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '\${match.group(1)} \${match.group(2)}')
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word)
        .join(' ');
  }
}
''';

    await _writeFile(adminPath, 'lib/src/screens/$modelLower/${modelLower}_detail_screen.dart', screenContent);
  }

  /// Generate model form screen
  Future<void> _generateModelFormScreen(String adminPath, String appName, Map<String, dynamic> model) async {
    final modelName = model['name'] as String;
    final modelLower = modelName.toLowerCase();
    final verboseName = model['verbose_name'] as String;
    final fields = model['fields'] as Map<String, dynamic>;
    
    final screenContent = '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/models/models_bloc.dart';
import '../../widgets/common/loading_button.dart';
import '../../widgets/common/loading_indicator.dart';

class ${modelName}FormScreen extends StatefulWidget {
  final String? id; // null for create, set for edit

  const ${modelName}FormScreen({Key? key, this.id}) : super(key: key);

  @override
  State<${modelName}FormScreen> createState() => _${modelName}FormScreenState();
}

class _${modelName}FormScreenState extends State<${modelName}FormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      _loadData();
    }
  }

  void _loadData() {
    context.read<ModelsBloc>().add(
      ModelsEvent.loadModelDetail('$appName', '$modelLower', widget.id!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Add $verboseName' : 'Edit $verboseName'),
        actions: [
          LoadingButton(
            onPressed: _saveForm,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: BlocConsumer<ModelsBloc, ModelsState>(
        listener: (context, state) {
          if (state.saveSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved successfully')),
            );
            context.go('/$modelLower');
          } else if (state.saveError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: \${state.saveError}')),
            );
          }
        },
        builder: (context, state) {
          if (state.detailLoading && widget.id != null) {
            return const LoadingIndicator();
          }

          return _buildForm(state);
        },
      ),
    );
  }

  Widget _buildForm(ModelsState state) {
    final initialData = widget.id != null ? state.modelDetail : <String, dynamic>{};

    return FormBuilder(
      key: _formKey,
      initialValue: initialData ?? {},
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$verboseName Information',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
${_generateFormFields(fields)}
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveForm() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      
      if (widget.id == null) {
        // Create new
        context.read<ModelsBloc>().add(
          ModelsEvent.createModel('$appName', '$modelLower', formData),
        );
      } else {
        // Update existing
        context.read<ModelsBloc>().add(
          ModelsEvent.updateModel('$appName', '$modelLower', widget.id!, formData),
        );
      }
    }
  }
}
''';

    await _writeFile(adminPath, 'lib/src/screens/$modelLower/${modelLower}_form_screen.dart', screenContent);
  }

  /// Generate form fields based on model fields
  String _generateFormFields(Map<String, dynamic> fields) {
    final buffer = StringBuffer();
    
    for (final entry in fields.entries) {
      final fieldName = entry.key;
      final field = entry.value as Map<String, dynamic>;
      final fieldType = field['type'] as String;
      final required = field['required'] as bool? ?? false;
      final label = _humanize(fieldName);
      
      switch (fieldType) {
        case 'boolean':
          buffer.writeln('''
                  FormBuilderCheckbox(
                    name: '$fieldName',
                    title: Text('$label'),
                    ${required ? "validator: FormBuilderValidators.required()," : ""}
                  ),
                  const SizedBox(height: 16),''');
          break;
        
        case 'integer':
        case 'float':
          buffer.writeln('''
                  FormBuilderTextField(
                    name: '$fieldName',
                    decoration: const InputDecoration(labelText: '$label'),
                    keyboardType: TextInputType.number,
                    ${required ? "validator: FormBuilderValidators.required()," : ""}
                  ),
                  const SizedBox(height: 16),''');
          break;
        
        case 'datetime':
          buffer.writeln('''
                  FormBuilderDateTimePicker(
                    name: '$fieldName',
                    decoration: const InputDecoration(labelText: '$label'),
                    ${required ? "validator: FormBuilderValidators.required()," : ""}
                  ),
                  const SizedBox(height: 16),''');
          break;
        
        case 'date':
          buffer.writeln('''
                  FormBuilderDateTimePicker(
                    name: '$fieldName',
                    inputType: InputType.date,
                    decoration: const InputDecoration(labelText: '$label'),
                    ${required ? "validator: FormBuilderValidators.required()," : ""}
                  ),
                  const SizedBox(height: 16),''');
          break;
        
        case 'text':
          buffer.writeln('''
                  FormBuilderTextField(
                    name: '$fieldName',
                    decoration: const InputDecoration(labelText: '$label'),
                    maxLines: 4,
                    ${required ? "validator: FormBuilderValidators.required()," : ""}
                  ),
                  const SizedBox(height: 16),''');
          break;
        
        default:
          buffer.writeln('''
                  FormBuilderTextField(
                    name: '$fieldName',
                    decoration: const InputDecoration(labelText: '$label'),
                    ${required ? "validator: FormBuilderValidators.required()," : ""}
                  ),
                  const SizedBox(height: 16),''');
          break;
      }
    }
    
    return buffer.toString();
  }

  /// Generate routing configuration
  Future<void> _generateRouting(String adminPath, Map<String, dynamic> metadata) async {
    // Copy base routing from dartango_admin package
    final sourceRoutingPath = '/Users/samuel/IdeaProjects/dartango/packages/dartango_admin/lib/src/routing/app_router.dart';
    final targetRoutingPath = path.join(adminPath, 'lib/src/routing/app_router.dart');
    
    await _copyFile(sourceRoutingPath, targetRoutingPath);
  }

  /// Generate theme and configuration
  Future<void> _generateThemeAndConfig(String adminPath, Map<String, dynamic> metadata) async {
    // Copy theme from dartango_admin package
    final sourceThemePath = '/Users/samuel/IdeaProjects/dartango/packages/dartango_admin/lib/src/theme';
    final targetThemePath = path.join(adminPath, 'lib/src/theme');
    
    await _copyDirectory(sourceThemePath, targetThemePath);
    
    // Generate app config
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

    await _writeFile(adminPath, 'lib/src/config/app_config.dart', configContent);
  }

  /// Generate common widgets
  Future<void> _generateCommonWidgets(String adminPath) async {
    // Copy widgets from dartango_admin package
    final sourceWidgetsPath = '/Users/samuel/IdeaProjects/dartango/packages/dartango_admin/lib/src/widgets';
    final targetWidgetsPath = path.join(adminPath, 'lib/src/widgets');
    
    await _copyDirectory(sourceWidgetsPath, targetWidgetsPath);
  }

  /// Generate repositories
  Future<void> _generateRepositories(String adminPath) async {
    // Copy repositories from dartango_admin package
    final sourceRepoPath = '/Users/samuel/IdeaProjects/dartango/packages/dartango_admin/lib/src/repositories';
    final targetRepoPath = path.join(adminPath, 'lib/src/repositories');
    
    await _copyDirectory(sourceRepoPath, targetRepoPath);
  }

  /// Copy assets
  Future<void> _copyAssets(String adminPath) async {
    // Create assets directories
    await Directory(path.join(adminPath, 'assets', 'images')).create(recursive: true);
    await Directory(path.join(adminPath, 'assets', 'icons')).create(recursive: true);
    await Directory(path.join(adminPath, 'fonts')).create(recursive: true);
    
    // Create placeholder files
    final placeholderImage = File(path.join(adminPath, 'assets', 'images', '.gitkeep'));
    await placeholderImage.writeAsString('');
    
    final placeholderIcon = File(path.join(adminPath, 'assets', 'icons', '.gitkeep'));
    await placeholderIcon.writeAsString('');
    
    final placeholderFont = File(path.join(adminPath, 'fonts', '.gitkeep'));
    await placeholderFont.writeAsString('');
  }

  /// Generate build configuration files
  Future<void> _generateBuildConfiguration(String adminPath) async {
    // Generate build.yaml
    final buildYaml = '''
# Build configuration for $projectName Admin
targets:
  \$default:
    builders:
      json_serializable:
        options:
          any_map: true
          checked: true
          create_to_json: true
          explicit_to_json: true
          field_rename: snake_case
          include_if_null: false
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

    await _writeFile(adminPath, 'build.yaml', buildYaml);
    
    // Generate Makefile
    await _generateMakefile(adminPath);
    
    // Generate package.json
    await _generatePackageJson(adminPath);
  }

  /// Generate Makefile
  Future<void> _generateMakefile(String adminPath) async {
    final makefile = '''
# Generated Makefile for $projectName Admin

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
''';

    await _writeFile(adminPath, 'Makefile', makefile);
  }

  /// Generate package.json
  Future<void> _generatePackageJson(String adminPath) async {
    final packageJson = {
      'name': '${projectName.toLowerCase()}-admin',
      'version': '1.0.0',
      'description': 'Auto-generated Flutter admin interface for $projectName',
      'scripts': {
        'build': 'flutter build web --release',
        'dev': 'flutter run -d chrome --web-port 3000',
        'test': 'flutter test',
        'analyze': 'flutter analyze',
        'format': 'dart format .',
        'generate': 'flutter packages pub run build_runner build --delete-conflicting-outputs',
        'watch': 'flutter packages pub run build_runner watch --delete-conflicting-outputs',
        'clean': 'flutter clean && flutter pub get',
      },
      'repository': {
        'type': 'git',
        'url': 'https://github.com/yourusername/$projectName'
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

  /// Install dependencies and run code generation
  Future<void> _installDependenciesAndGenerate(String adminPath) async {
    _log('📦 Installing Flutter dependencies...');
    
    // Run flutter pub get
    var result = await Process.run(
      'flutter',
      ['pub', 'get'],
      workingDirectory: adminPath,
    );
    
    if (result.exitCode != 0) {
      throw Exception('Failed to install dependencies: ${result.stderr}');
    }
    
    // Run code generation
    _log('⚙️  Running code generation...');
    result = await Process.run(
      'flutter',
      ['packages', 'pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      workingDirectory: adminPath,
    );
    
    if (result.exitCode != 0) {
      _log('⚠️  Code generation warnings: ${result.stderr}');
    }
  }

  /// Print completion summary
  void _printCompletionSummary(String adminPath, Map<String, dynamic> metadata) {
    final apps = metadata['apps'] as Map<String, dynamic>;
    var totalModels = 0;
    
    print('\n📊 Admin Generation Summary:');
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
    print('✅ Generated integrated admin for $totalModels models in ${apps.length} apps');
    print('🌐 Backend URL: $backendUrl');
    print('📁 Admin directory: $adminPath');
    print('\n🚀 Next steps:');
    print('  1. cd ${path.relative(adminPath)}');
    print('  2. make install  # Install dependencies');
    print('  3. make dev      # Start development server');
    print('  4. Open http://localhost:3000 in your browser');
    print('\n📖 Available commands:');
    print('  make help        # Show all available commands');
    print('  make build       # Build for production');
    print('  make generate    # Run code generation');
    print('  make test        # Run tests');
  }

  /// Helper methods
  Future<void> _writeFile(String basePath, String filePath, String content) async {
    final file = File(path.join(basePath, filePath));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    
    if (verbose) {
      _log('📝 Generated: $filePath');
    }
  }

  Future<void> _copyFile(String sourcePath, String targetPath) async {
    final sourceFile = File(sourcePath);
    final targetFile = File(targetPath);
    
    if (await sourceFile.exists()) {
      await targetFile.parent.create(recursive: true);
      await sourceFile.copy(targetPath);
      
      if (verbose) {
        _log('📋 Copied: ${path.basename(targetPath)}');
      }
    }
  }

  Future<void> _copyDirectory(String sourcePath, String targetPath) async {
    final sourceDir = Directory(sourcePath);
    
    if (await sourceDir.exists()) {
      await Directory(targetPath).create(recursive: true);
      
      await for (final entity in sourceDir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = path.relative(entity.path, from: sourcePath);
          final targetFilePath = path.join(targetPath, relativePath);
          await _copyFile(entity.path, targetFilePath);
        }
      }
    }
  }

  String _toPascalCase(String input) {
    return input
        .split('_')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word)
        .join('');
  }

  String _humanize(String input) {
    return input
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match.group(1)} ${match.group(2)}')
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word)
        .join(' ');
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