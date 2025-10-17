import 'dart:io';
import 'dart:convert';
import 'dart:mirrors';
import 'package:path/path.dart' as path;

import 'admin.dart';

/// Model inspector for automatic admin generation
class ModelInspector {
  static final ModelInspector _instance = ModelInspector._internal();
  factory ModelInspector() => _instance;
  ModelInspector._internal();

  final Map<Type, ModelMetadata> _modelCache = {};
  final Map<String, List<ModelMetadata>> _appModels = {};

  /// Inspect all models and generate metadata
  Future<Map<String, dynamic>> inspectAllModels({
    AdminSite? adminSite,
    String? outputPath,
  }) async {
    final site = adminSite ?? AdminSite();
    final metadata = <String, dynamic>{
      'admin_config': _getAdminSiteConfig(site),
      'apps': <String, dynamic>{},
      'generated_at': DateTime.now().toIso8601String(),
      'dartango_version': '1.0.0',
    };

    // Inspect registered models
    for (final entry in site.registry.entries) {
      final modelType = entry.key;
      final adminClass = entry.value;
      
      final modelMeta = await _inspectModel(modelType, adminClass);
      final appLabel = adminClass.getAppLabel();
      
      if (!metadata['apps'].containsKey(appLabel)) {
        metadata['apps'][appLabel] = <String, dynamic>{
          'name': appLabel,
          'verbose_name': _humanize(appLabel),
          'models': <String, dynamic>{},
        };
      }
      
      metadata['apps'][appLabel]['models'][modelMeta.name] = modelMeta.toJson();
    }

    // Write to file if path provided
    if (outputPath != null) {
      await _writeMetadataToFile(metadata, outputPath);
    }

    return metadata;
  }

  /// Inspect a single model
  Future<ModelMetadata> _inspectModel(Type modelType, ModelAdmin adminClass) async {
    if (_modelCache.containsKey(modelType)) {
      return _modelCache[modelType]!;
    }

    final metadata = ModelMetadata(
      name: modelType.toString(),
      appLabel: adminClass.getAppLabel(),
      verboseName: adminClass.getVerboseName(),
      verboseNamePlural: adminClass.getVerboseNamePlural(),
      tableName: _getTableName(modelType),
      fields: await _inspectModelFields(modelType),
      adminConfig: _getAdminConfig(adminClass),
      relationships: await _inspectRelationships(modelType),
      permissions: _getPermissionConfig(adminClass),
      meta: _getModelMeta(modelType),
    );

    _modelCache[modelType] = metadata;
    return metadata;
  }

  /// Inspect model fields using reflection
  Future<Map<String, FieldMetadata>> _inspectModelFields(Type modelType) async {
    final fields = <String, FieldMetadata>{};
    
    // Use reflection to inspect the model
    final classMirror = reflectClass(modelType);
    
    for (final declaration in classMirror.declarations.values) {
      if (declaration is VariableMirror && _isModelField(declaration)) {
        final fieldName = MirrorSystem.getName(declaration.simpleName);
        final fieldType = declaration.type.reflectedType;
        
        final fieldMeta = await _inspectField(fieldName, fieldType, declaration);
        fields[fieldName] = fieldMeta;
      }
    }

    return fields;
  }

  /// Inspect a single field
  Future<FieldMetadata> _inspectField(
    String name,
    Type type,
    VariableMirror mirror,
  ) async {
    final fieldType = _determineFieldType(type);
    final constraints = _extractFieldConstraints(mirror);
    
    return FieldMetadata(
      name: name,
      type: fieldType,
      dartType: type.toString(),
      sqlType: _getSqlType(fieldType),
      label: _humanize(name),
      helpText: constraints['help_text'],
      required: constraints['required'] ?? false,
      nullable: constraints['nullable'] ?? true,
      unique: constraints['unique'] ?? false,
      indexed: constraints['indexed'] ?? false,
      primaryKey: constraints['primary_key'] ?? false,
      autoIncrement: constraints['auto_increment'] ?? false,
      defaultValue: constraints['default_value'],
      maxLength: constraints['max_length'],
      minLength: constraints['min_length'],
      choices: constraints['choices'] ?? {},
      validators: constraints['validators'] ?? [],
      editable: constraints['editable'] ?? true,
      blank: constraints['blank'] ?? false,
      relatedModel: _getRelatedModel(type),
      relatedName: constraints['related_name'],
      onDelete: constraints['on_delete'],
      onUpdate: constraints['on_update'],
    );
  }

  /// Inspect model relationships
  Future<Map<String, RelationshipMetadata>> _inspectRelationships(Type modelType) async {
    final relationships = <String, RelationshipMetadata>{};
    final classMirror = reflectClass(modelType);
    
    for (final declaration in classMirror.declarations.values) {
      if (declaration is VariableMirror && _isRelationshipField(declaration)) {
        final fieldName = MirrorSystem.getName(declaration.simpleName);
        final relationshipType = _getRelationshipType(declaration.type.reflectedType);
        
        if (relationshipType != null) {
          relationships[fieldName] = RelationshipMetadata(
            name: fieldName,
            type: relationshipType,
            relatedModel: _getRelatedModel(declaration.type.reflectedType),
            relatedName: _getRelatedName(declaration),
            symmetrical: _isSymmetrical(declaration),
            throughModel: _getThroughModel(declaration),
            dbConstraint: _hasDbConstraint(declaration),
          );
        }
      }
    }

    return relationships;
  }

  /// Get admin configuration
  AdminConfigMetadata _getAdminConfig(ModelAdmin adminClass) {
    return AdminConfigMetadata(
      listDisplay: adminClass.listDisplay,
      listFilter: adminClass.listFilter,
      searchFields: adminClass.searchFields,
      orderingFields: adminClass.orderingFields,
      readonlyFields: adminClass.readonlyFields,
      excludeFields: adminClass.excludeFields,
      fieldsets: adminClass.fieldsets,
      listPerPage: adminClass.listPerPage,
      listMaxShowAll: adminClass.listMaxShowAll,
      actions: adminClass.actions.map((action) => ActionMetadata(
        name: action.name,
        description: action.description,
        requiresConfirmation: action.requiresConfirmation,
      )).toList(),
      permissions: PermissionMetadata(
        add: adminClass.hasAddPermission,
        change: adminClass.hasChangePermission,
        delete: adminClass.hasDeletePermission,
        view: adminClass.hasViewPermission,
      ),
    );
  }

  /// Get admin site configuration
  Map<String, dynamic> _getAdminSiteConfig(AdminSite site) {
    return {
      'site_header': site.siteHeader,
      'site_title': site.siteTitle,
      'index_title': site.indexTitle,
      'admin_url': site.adminUrl,
      'enable_nav_sidebar': site.enableNavSidebar,
    };
  }

  /// Get permission configuration
  Map<String, bool> _getPermissionConfig(ModelAdmin adminClass) {
    return {
      'add': adminClass.hasAddPermission,
      'change': adminClass.hasChangePermission,
      'delete': adminClass.hasDeletePermission,
      'view': adminClass.hasViewPermission,
    };
  }

  /// Get model metadata
  Map<String, dynamic> _getModelMeta(Type modelType) {
    return {
      'abstract': false,
      'proxy': false,
      'ordering': [],
      'indexes': [],
      'constraints': [],
      'default_permissions': ['add', 'change', 'delete', 'view'],
    };
  }

  /// Write metadata to file
  Future<void> _writeMetadataToFile(Map<String, dynamic> metadata, String outputPath) async {
    final file = File(outputPath);
    await file.parent.create(recursive: true);
    
    final encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(metadata);
    
    await file.writeAsString(jsonString);
    print('📄 Model metadata written to: $outputPath');
  }

  /// Generate Flutter admin configuration files
  Future<void> generateFlutterAdminConfig({
    required String projectPath,
    AdminSite? adminSite,
  }) async {
    final metadata = await inspectAllModels(adminSite: adminSite);
    final adminDir = path.join(projectPath, 'admin', 'generated');
    
    // Ensure admin directory exists
    await Directory(adminDir).create(recursive: true);
    
    // Generate model metadata
    await _writeMetadataToFile(
      metadata,
      path.join(adminDir, 'models_metadata.json'),
    );
    
    // Generate API client configuration
    await _generateApiClientConfig(metadata, adminDir);
    
    // Generate BLoC files for each model
    await _generateBlocFiles(metadata, adminDir);
    
    // Generate screen files for each model
    await _generateScreenFiles(metadata, adminDir);
    
    // Generate routing configuration
    await _generateRoutingConfig(metadata, adminDir);
    
    // Generate main admin app
    await _generateMainAdminApp(metadata, adminDir);
    
    print('✅ Flutter admin configuration generated in: $adminDir');
  }

  /// Generate API client configuration
  Future<void> _generateApiClientConfig(Map<String, dynamic> metadata, String outputDir) async {
    final config = _buildApiClientConfig(metadata);
    final file = File(path.join(outputDir, 'api_client_config.dart'));
    await file.writeAsString(config);
  }

  /// Generate BLoC files for each model
  Future<void> _generateBlocFiles(Map<String, dynamic> metadata, String outputDir) async {
    final blocDir = path.join(outputDir, 'blocs');
    await Directory(blocDir).create(recursive: true);
    
    final apps = metadata['apps'] as Map<String, dynamic>;
    for (final app in apps.values) {
      final models = app['models'] as Map<String, dynamic>;
      for (final model in models.values) {
        final modelMeta = ModelMetadata.fromJson(model);
        final blocCode = _generateModelBloc(modelMeta);
        
        final fileName = '${modelMeta.name.toLowerCase()}_bloc.dart';
        final file = File(path.join(blocDir, fileName));
        await file.writeAsString(blocCode);
      }
    }
  }

  /// Generate screen files for each model
  Future<void> _generateScreenFiles(Map<String, dynamic> metadata, String outputDir) async {
    final screensDir = path.join(outputDir, 'screens');
    await Directory(screensDir).create(recursive: true);
    
    final apps = metadata['apps'] as Map<String, dynamic>;
    for (final app in apps.values) {
      final models = app['models'] as Map<String, dynamic>;
      for (final model in models.values) {
        final modelMeta = ModelMetadata.fromJson(model);
        
        // Generate list screen
        final listScreenCode = _generateListScreen(modelMeta);
        final listFile = File(path.join(screensDir, '${modelMeta.name.toLowerCase()}_list_screen.dart'));
        await listFile.writeAsString(listScreenCode);
        
        // Generate detail screen
        final detailScreenCode = _generateDetailScreen(modelMeta);
        final detailFile = File(path.join(screensDir, '${modelMeta.name.toLowerCase()}_detail_screen.dart'));
        await detailFile.writeAsString(detailScreenCode);
        
        // Generate form screen
        final formScreenCode = _generateFormScreen(modelMeta);
        final formFile = File(path.join(screensDir, '${modelMeta.name.toLowerCase()}_form_screen.dart'));
        await formFile.writeAsString(formScreenCode);
      }
    }
  }

  /// Generate routing configuration
  Future<void> _generateRoutingConfig(Map<String, dynamic> metadata, String outputDir) async {
    final routingCode = _buildRoutingConfig(metadata);
    final file = File(path.join(outputDir, 'app_router.dart'));
    await file.writeAsString(routingCode);
  }

  /// Generate main admin app
  Future<void> _generateMainAdminApp(Map<String, dynamic> metadata, String outputDir) async {
    final appCode = _buildMainAdminApp(metadata);
    final file = File(path.join(outputDir, 'admin_app.dart'));
    await file.writeAsString(appCode);
  }

  // Helper methods for determining field types and constraints
  String _determineFieldType(Type type) {
    if (type == int) return 'integer';
    if (type == double) return 'float';
    if (type == bool) return 'boolean';
    if (type == String) return 'text';
    if (type == DateTime) return 'datetime';
    if (type.toString().contains('Field')) {
      return type.toString().toLowerCase().replaceAll('field', '');
    }
    return 'text';
  }

  bool _isModelField(VariableMirror mirror) {
    final type = mirror.type.reflectedType;
    return type.toString().contains('Field') || 
           _isPrimitiveType(type) ||
           type == DateTime;
  }

  bool _isRelationshipField(VariableMirror mirror) {
    final type = mirror.type.reflectedType;
    return type.toString().contains('ForeignKey') ||
           type.toString().contains('OneToOne') ||
           type.toString().contains('ManyToMany');
  }

  bool _isPrimitiveType(Type type) {
    return type == int || type == double || type == bool || type == String;
  }

  String _getTableName(Type modelType) {
    return '${modelType.toString().toLowerCase()}s';
  }

  String _getSqlType(String fieldType) {
    switch (fieldType) {
      case 'integer': return 'INTEGER';
      case 'float': return 'FLOAT';
      case 'boolean': return 'BOOLEAN';
      case 'datetime': return 'TIMESTAMP';
      case 'date': return 'DATE';
      case 'text': return 'TEXT';
      case 'char': return 'VARCHAR';
      default: return 'TEXT';
    }
  }

  Map<String, dynamic> _extractFieldConstraints(VariableMirror mirror) {
    // This would need to be implemented based on field annotations
    // For now, return default constraints
    return {
      'required': false,
      'nullable': true,
      'unique': false,
      'indexed': false,
      'primary_key': false,
      'auto_increment': false,
      'editable': true,
      'blank': false,
    };
  }

  String? _getRelatedModel(Type type) {
    final typeName = type.toString();
    if (typeName.contains('ForeignKey') || 
        typeName.contains('OneToOne') || 
        typeName.contains('ManyToMany')) {
      // Extract related model from generic type
      return type.toString();
    }
    return null;
  }

  String? _getRelationshipType(Type type) {
    final typeName = type.toString();
    if (typeName.contains('ForeignKey')) return 'foreign_key';
    if (typeName.contains('OneToOne')) return 'one_to_one';
    if (typeName.contains('ManyToMany')) return 'many_to_many';
    return null;
  }

  String? _getRelatedName(VariableMirror mirror) {
    // Extract from field configuration
    return null;
  }

  bool _isSymmetrical(VariableMirror mirror) {
    // Check field configuration
    return true;
  }

  String? _getThroughModel(VariableMirror mirror) {
    // Extract from field configuration
    return null;
  }

  bool _hasDbConstraint(VariableMirror mirror) {
    // Check field configuration
    return true;
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

  // Code generation methods (will be implemented in separate files)
  String _buildApiClientConfig(Map<String, dynamic> metadata) {
    // Implementation in api_client_generator.dart
    return '';
  }

  String _generateModelBloc(ModelMetadata model) {
    // Implementation in bloc_generator.dart
    return '';
  }

  String _generateListScreen(ModelMetadata model) {
    // Implementation in screen_generator.dart
    return '';
  }

  String _generateDetailScreen(ModelMetadata model) {
    // Implementation in screen_generator.dart
    return '';
  }

  String _generateFormScreen(ModelMetadata model) {
    // Implementation in screen_generator.dart
    return '';
  }

  String _buildRoutingConfig(Map<String, dynamic> metadata) {
    // Implementation in routing_generator.dart
    return '';
  }

  String _buildMainAdminApp(Map<String, dynamic> metadata) {
    // Implementation in app_generator.dart
    return '';
  }
}

/// Metadata classes for model inspection
class ModelMetadata {
  final String name;
  final String appLabel;
  final String verboseName;
  final String verboseNamePlural;
  final String tableName;
  final Map<String, FieldMetadata> fields;
  final AdminConfigMetadata adminConfig;
  final Map<String, RelationshipMetadata> relationships;
  final Map<String, bool> permissions;
  final Map<String, dynamic> meta;

  ModelMetadata({
    required this.name,
    required this.appLabel,
    required this.verboseName,
    required this.verboseNamePlural,
    required this.tableName,
    required this.fields,
    required this.adminConfig,
    required this.relationships,
    required this.permissions,
    required this.meta,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'app_label': appLabel,
      'verbose_name': verboseName,
      'verbose_name_plural': verboseNamePlural,
      'table_name': tableName,
      'fields': fields.map((key, field) => MapEntry(key, field.toJson())),
      'admin_config': adminConfig.toJson(),
      'relationships': relationships.map((key, rel) => MapEntry(key, rel.toJson())),
      'permissions': permissions,
      'meta': meta,
    };
  }

  static ModelMetadata fromJson(Map<String, dynamic> json) {
    return ModelMetadata(
      name: json['name'],
      appLabel: json['app_label'],
      verboseName: json['verbose_name'],
      verboseNamePlural: json['verbose_name_plural'],
      tableName: json['table_name'],
      fields: (json['fields'] as Map<String, dynamic>).map(
        (key, field) => MapEntry(key, FieldMetadata.fromJson(field)),
      ),
      adminConfig: AdminConfigMetadata.fromJson(json['admin_config']),
      relationships: (json['relationships'] as Map<String, dynamic>).map(
        (key, rel) => MapEntry(key, RelationshipMetadata.fromJson(rel)),
      ),
      permissions: Map<String, bool>.from(json['permissions']),
      meta: Map<String, dynamic>.from(json['meta']),
    );
  }
}

class FieldMetadata {
  final String name;
  final String type;
  final String dartType;
  final String sqlType;
  final String label;
  final String? helpText;
  final bool required;
  final bool nullable;
  final bool unique;
  final bool indexed;
  final bool primaryKey;
  final bool autoIncrement;
  final dynamic defaultValue;
  final int? maxLength;
  final int? minLength;
  final Map<String, dynamic> choices;
  final List<String> validators;
  final bool editable;
  final bool blank;
  final String? relatedModel;
  final String? relatedName;
  final String? onDelete;
  final String? onUpdate;

  FieldMetadata({
    required this.name,
    required this.type,
    required this.dartType,
    required this.sqlType,
    required this.label,
    this.helpText,
    required this.required,
    required this.nullable,
    required this.unique,
    required this.indexed,
    required this.primaryKey,
    required this.autoIncrement,
    this.defaultValue,
    this.maxLength,
    this.minLength,
    required this.choices,
    required this.validators,
    required this.editable,
    required this.blank,
    this.relatedModel,
    this.relatedName,
    this.onDelete,
    this.onUpdate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'dart_type': dartType,
      'sql_type': sqlType,
      'label': label,
      'help_text': helpText,
      'required': required,
      'nullable': nullable,
      'unique': unique,
      'indexed': indexed,
      'primary_key': primaryKey,
      'auto_increment': autoIncrement,
      'default_value': defaultValue,
      'max_length': maxLength,
      'min_length': minLength,
      'choices': choices,
      'validators': validators,
      'editable': editable,
      'blank': blank,
      'related_model': relatedModel,
      'related_name': relatedName,
      'on_delete': onDelete,
      'on_update': onUpdate,
    };
  }

  static FieldMetadata fromJson(Map<String, dynamic> json) {
    return FieldMetadata(
      name: json['name'],
      type: json['type'],
      dartType: json['dart_type'],
      sqlType: json['sql_type'],
      label: json['label'],
      helpText: json['help_text'],
      required: json['required'],
      nullable: json['nullable'],
      unique: json['unique'],
      indexed: json['indexed'],
      primaryKey: json['primary_key'],
      autoIncrement: json['auto_increment'],
      defaultValue: json['default_value'],
      maxLength: json['max_length'],
      minLength: json['min_length'],
      choices: Map<String, dynamic>.from(json['choices']),
      validators: List<String>.from(json['validators']),
      editable: json['editable'],
      blank: json['blank'],
      relatedModel: json['related_model'],
      relatedName: json['related_name'],
      onDelete: json['on_delete'],
      onUpdate: json['on_update'],
    );
  }
}

class RelationshipMetadata {
  final String name;
  final String type;
  final String? relatedModel;
  final String? relatedName;
  final bool symmetrical;
  final String? throughModel;
  final bool dbConstraint;

  RelationshipMetadata({
    required this.name,
    required this.type,
    this.relatedModel,
    this.relatedName,
    required this.symmetrical,
    this.throughModel,
    required this.dbConstraint,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'related_model': relatedModel,
      'related_name': relatedName,
      'symmetrical': symmetrical,
      'through_model': throughModel,
      'db_constraint': dbConstraint,
    };
  }

  static RelationshipMetadata fromJson(Map<String, dynamic> json) {
    return RelationshipMetadata(
      name: json['name'],
      type: json['type'],
      relatedModel: json['related_model'],
      relatedName: json['related_name'],
      symmetrical: json['symmetrical'],
      throughModel: json['through_model'],
      dbConstraint: json['db_constraint'],
    );
  }
}

class AdminConfigMetadata {
  final List<String> listDisplay;
  final List<String> listFilter;
  final List<String> searchFields;
  final List<String> orderingFields;
  final List<String> readonlyFields;
  final List<String> excludeFields;
  final Map<String, List<String>> fieldsets;
  final int listPerPage;
  final int listMaxShowAll;
  final List<ActionMetadata> actions;
  final PermissionMetadata permissions;

  AdminConfigMetadata({
    required this.listDisplay,
    required this.listFilter,
    required this.searchFields,
    required this.orderingFields,
    required this.readonlyFields,
    required this.excludeFields,
    required this.fieldsets,
    required this.listPerPage,
    required this.listMaxShowAll,
    required this.actions,
    required this.permissions,
  });

  Map<String, dynamic> toJson() {
    return {
      'list_display': listDisplay,
      'list_filter': listFilter,
      'search_fields': searchFields,
      'ordering_fields': orderingFields,
      'readonly_fields': readonlyFields,
      'exclude_fields': excludeFields,
      'fieldsets': fieldsets,
      'list_per_page': listPerPage,
      'list_max_show_all': listMaxShowAll,
      'actions': actions.map((action) => action.toJson()).toList(),
      'permissions': permissions.toJson(),
    };
  }

  static AdminConfigMetadata fromJson(Map<String, dynamic> json) {
    return AdminConfigMetadata(
      listDisplay: List<String>.from(json['list_display']),
      listFilter: List<String>.from(json['list_filter']),
      searchFields: List<String>.from(json['search_fields']),
      orderingFields: List<String>.from(json['ordering_fields']),
      readonlyFields: List<String>.from(json['readonly_fields']),
      excludeFields: List<String>.from(json['exclude_fields']),
      fieldsets: Map<String, List<String>>.from(json['fieldsets'].map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      )),
      listPerPage: json['list_per_page'],
      listMaxShowAll: json['list_max_show_all'],
      actions: (json['actions'] as List).map((action) => ActionMetadata.fromJson(action)).toList(),
      permissions: PermissionMetadata.fromJson(json['permissions']),
    );
  }
}

class ActionMetadata {
  final String name;
  final String description;
  final bool requiresConfirmation;

  ActionMetadata({
    required this.name,
    required this.description,
    required this.requiresConfirmation,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'requires_confirmation': requiresConfirmation,
    };
  }

  static ActionMetadata fromJson(Map<String, dynamic> json) {
    return ActionMetadata(
      name: json['name'],
      description: json['description'],
      requiresConfirmation: json['requires_confirmation'],
    );
  }
}

class PermissionMetadata {
  final bool add;
  final bool change;
  final bool delete;
  final bool view;

  PermissionMetadata({
    required this.add,
    required this.change,
    required this.delete,
    required this.view,
  });

  Map<String, dynamic> toJson() {
    return {
      'add': add,
      'change': change,
      'delete': delete,
      'view': view,
    };
  }

  static PermissionMetadata fromJson(Map<String, dynamic> json) {
    return PermissionMetadata(
      add: json['add'],
      change: json['change'],
      delete: json['delete'],
      view: json['view'],
    );
  }
}