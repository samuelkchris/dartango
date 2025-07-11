import 'dart:io';
import 'package:path/path.dart' as path;

class ModelGenerator {
  final String name;
  final String app;
  final String outputPath;
  final bool force;

  ModelGenerator({
    required this.name,
    required this.app,
    required this.outputPath,
    this.force = false,
  });

  Future<void> generate() async {
    final modelsDir = Directory(outputPath);
    await modelsDir.create(recursive: true);

    final modelFileName = '${_toSnakeCase(name)}.dart';
    final modelFile = File(path.join(modelsDir.path, modelFileName));

    if (await modelFile.exists() && !force) {
      throw Exception('Model file already exists: ${modelFile.path}');
    }

    final modelContent = _generateModelContent();
    await modelFile.writeAsString(modelContent);

    // Generate migration file
    await _generateMigration();
  }

  String _generateModelContent() {
    final className = _toPascalCase(name);
    final tableName = '${app}_${_toSnakeCase(name)}';

    return '''
import 'package:dartango/dartango.dart';

class $className extends Model {
  static const String tableName = '$tableName';
  
  // Primary key (auto-generated)
  final AutoField id = AutoField(primaryKey: true);
  
  // Common fields - customize as needed
  final CharField name = CharField(
    maxLength: 100,
    verbose_name: 'Name',
    help_text: 'Enter the name',
  );
  
  final TextField description = TextField(
    verbose_name: 'Description',
    help_text: 'Enter a description',
    blank: true,
  );
  
  final BooleanField isActive = BooleanField(
    default: true,
    verbose_name: 'Active',
    help_text: 'Whether this item is active',
  );
  
  final DateTimeField createdAt = DateTimeField(
    autoNow: true,
    verbose_name: 'Created At',
  );
  
  final DateTimeField updatedAt = DateTimeField(
    autoNowAdd: true,
    verbose_name: 'Updated At',
  );
  
  @override
  String toString() {
    return name.value ?? 'Unnamed $className';
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id.value,
      'name': name.value,
      'description': description.value,
      'is_active': isActive.value,
      'created_at': createdAt.value?.toIso8601String(),
      'updated_at': updatedAt.value?.toIso8601String(),
    };
  }
  
  @override
  void fromJson(Map<String, dynamic> json) {
    id.value = json['id'];
    name.value = json['name'];
    description.value = json['description'];
    isActive.value = json['is_active'] ?? true;
    createdAt.value = json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : null;
    updatedAt.value = json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : null;
  }
  
  // Custom methods
  Future<void> activate() async {
    isActive.value = true;
    await save();
  }
  
  Future<void> deactivate() async {
    isActive.value = false;
    await save();
  }
  
  // Custom querysets
  static Future<List<$className>> getActive() async {
    return await objects.filter({'is_active': true}).all();
  }
  
  static Future<List<$className>> getByName(String namePattern) async {
    return await objects.filter({'name__icontains': namePattern}).all();
  }
  
  // Meta class for additional configuration
  class Meta {
    static const String tableName = '$tableName';
    static const String verbose_name = '${_toTitleCase(name)}';
    static const String verbose_name_plural = '${_toTitleCase(name)}s';
    static const List<String> ordering = ['-created_at'];
    static const Map<String, dynamic> indexes = {
      'name_idx': ['name'],
      'active_idx': ['is_active'],
    };
  }
}

// Custom manager for additional query methods
class ${className}Manager extends Manager<$className> {
  ${className}Manager() : super($className);
  
  Future<List<$className>> getActiveByName(String name) async {
    return await filter({
      'is_active': true,
      'name__icontains': name,
    }).all();
  }
  
  Future<$className?> getByNameExact(String name) async {
    try {
      return await get({'name': name});
    } catch (e) {
      return null;
    }
  }
  
  Future<int> getActiveCount() async {
    return await filter({'is_active': true}).count();
  }
}

// Add custom manager to model
extension ${className}Objects on $className {
  static ${className}Manager get objects => ${className}Manager();
}
''';
  }

  Future<void> _generateMigration() async {
    final migrationsDir = Directory(path.join(outputPath, '..', 'migrations'));
    await migrationsDir.create(recursive: true);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final migrationFileName = '${timestamp}_create_${_toSnakeCase(name)}.dart';
    final migrationFile =
        File(path.join(migrationsDir.path, migrationFileName));

    final migrationContent = _generateMigrationContent();
    await migrationFile.writeAsString(migrationContent);
  }

  String _generateMigrationContent() {
    final className = _toPascalCase(name);
    final tableName = '${app}_${_toSnakeCase(name)}';

    return '''
import 'package:dartango/dartango.dart';

class Create$className extends Migration {
  @override
  List<Operation> get operations => [
    CreateTable(
      name: '$tableName',
      fields: [
        Field('id', FieldType.autoField, primaryKey: true),
        Field('name', FieldType.charField, maxLength: 100, null: false),
        Field('description', FieldType.textField, null: true),
        Field('is_active', FieldType.booleanField, default: true),
        Field('created_at', FieldType.dateTimeField, autoNow: true),
        Field('updated_at', FieldType.dateTimeField, autoNowAdd: true),
      ],
      indexes: [
        Index(fields: ['name'], name: '${tableName}_name_idx'),
        Index(fields: ['is_active'], name: '${tableName}_active_idx'),
      ],
    ),
  ];
  
  @override
  List<Operation> get reverseOperations => [
    DropTable(name: '$tableName'),
  ];
}
''';
  }

  String _toPascalCase(String input) {
    return input
        .split('_')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join('');
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
            RegExp(r'([A-Z])'), (match) => '_${match.group(1)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '')
        .toLowerCase();
  }

  String _toTitleCase(String input) {
    return input
        .split('_')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }
}
