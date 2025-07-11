import 'dart:async';

import 'connection.dart';
import 'models.dart';
import 'fields.dart';
import 'relationships.dart';

abstract class Migration {
  final String name;
  final List<String> dependencies;
  final DateTime timestamp;

  Migration({
    required this.name,
    this.dependencies = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Future<void> up(SchemaEditor editor);
  Future<void> down(SchemaEditor editor);

  @override
  String toString() => name;
}

class CreateModelMigration extends Migration {
  final Type modelType;
  final Map<String, Field> fields;
  final ModelMeta meta;

  CreateModelMigration({
    required this.modelType,
    required this.fields,
    required this.meta,
    required super.name,
    super.dependencies,
    super.timestamp,
  });

  @override
  Future<void> up(SchemaEditor editor) async {
    await editor.createModel(modelType, fields, meta);
  }

  @override
  Future<void> down(SchemaEditor editor) async {
    await editor.deleteModel(modelType);
  }
}

class DeleteModelMigration extends Migration {
  final Type modelType;
  final Map<String, Field> fields;
  final ModelMeta meta;

  DeleteModelMigration({
    required this.modelType,
    required this.fields,
    required this.meta,
    required super.name,
    super.dependencies,
    super.timestamp,
  });

  @override
  Future<void> up(SchemaEditor editor) async {
    await editor.deleteModel(modelType);
  }

  @override
  Future<void> down(SchemaEditor editor) async {
    await editor.createModel(modelType, fields, meta);
  }
}

class AddFieldMigration extends Migration {
  final Type modelType;
  final String fieldName;
  final Field field;
  final bool preserveDefault;

  AddFieldMigration({
    required this.modelType,
    required this.fieldName,
    required this.field,
    this.preserveDefault = true,
    required super.name,
    super.dependencies,
    super.timestamp,
  });

  @override
  Future<void> up(SchemaEditor editor) async {
    await editor.addField(modelType, fieldName, field, preserveDefault);
  }

  @override
  Future<void> down(SchemaEditor editor) async {
    await editor.removeField(modelType, fieldName);
  }
}

class RemoveFieldMigration extends Migration {
  final Type modelType;
  final String fieldName;
  final Field field;

  RemoveFieldMigration({
    required this.modelType,
    required this.fieldName,
    required this.field,
    required super.name,
    super.dependencies,
    super.timestamp,
  });

  @override
  Future<void> up(SchemaEditor editor) async {
    await editor.removeField(modelType, fieldName);
  }

  @override
  Future<void> down(SchemaEditor editor) async {
    await editor.addField(modelType, fieldName, field, false);
  }
}

class AlterFieldMigration extends Migration {
  final Type modelType;
  final String fieldName;
  final Field oldField;
  final Field newField;

  AlterFieldMigration({
    required this.modelType,
    required this.fieldName,
    required this.oldField,
    required this.newField,
    required super.name,
    super.dependencies,
    super.timestamp,
  });

  @override
  Future<void> up(SchemaEditor editor) async {
    await editor.alterField(modelType, fieldName, oldField, newField);
  }

  @override
  Future<void> down(SchemaEditor editor) async {
    await editor.alterField(modelType, fieldName, newField, oldField);
  }
}

class RenameFieldMigration extends Migration {
  final Type modelType;
  final String oldName;
  final String newName;
  final Field field;

  RenameFieldMigration({
    required this.modelType,
    required this.oldName,
    required this.newName,
    required this.field,
    required super.name,
    super.dependencies,
    super.timestamp,
  });

  @override
  Future<void> up(SchemaEditor editor) async {
    await editor.renameField(modelType, oldName, newName);
  }

  @override
  Future<void> down(SchemaEditor editor) async {
    await editor.renameField(modelType, newName, oldName);
  }
}

class CreateIndexMigration extends Migration {
  final Type modelType;
  final String indexName;
  final List<String> fields;
  final bool unique;
  final String? condition;

  CreateIndexMigration({
    required this.modelType,
    required this.indexName,
    required this.fields,
    this.unique = false,
    this.condition,
    required super.name,
    super.dependencies,
    super.timestamp,
  });

  @override
  Future<void> up(SchemaEditor editor) async {
    await editor.createIndex(modelType, indexName, fields, unique, condition);
  }

  @override
  Future<void> down(SchemaEditor editor) async {
    await editor.removeIndex(modelType, indexName);
  }
}

class RemoveIndexMigration extends Migration {
  final Type modelType;
  final String indexName;
  final List<String> fields;
  final bool unique;
  final String? condition;

  RemoveIndexMigration({
    required this.modelType,
    required this.indexName,
    required this.fields,
    this.unique = false,
    this.condition,
    required super.name,
    super.dependencies,
    super.timestamp,
  });

  @override
  Future<void> up(SchemaEditor editor) async {
    await editor.removeIndex(modelType, indexName);
  }

  @override
  Future<void> down(SchemaEditor editor) async {
    await editor.createIndex(modelType, indexName, fields, unique, condition);
  }
}

class RunSQLMigration extends Migration {
  final String sql;
  final String reverseSql;
  final List<dynamic> parameters;

  RunSQLMigration({
    required this.sql,
    this.reverseSql = '',
    this.parameters = const [],
    required super.name,
    super.dependencies,
    super.timestamp,
  });

  @override
  Future<void> up(SchemaEditor editor) async {
    await editor.executeSql(sql, parameters);
  }

  @override
  Future<void> down(SchemaEditor editor) async {
    if (reverseSql.isNotEmpty) {
      await editor.executeSql(reverseSql, parameters);
    }
  }
}

class SchemaEditor {
  final DatabaseConnection connection;
  final String databaseType;

  SchemaEditor(this.connection, this.databaseType);

  Future<void> createModel(
      Type modelType, Map<String, Field> fields, ModelMeta meta) async {
    final tableName = meta.effectiveTableName;
    final columns = <String>[];

    for (final entry in fields.entries) {
      final fieldName = entry.key;
      final field = entry.value;

      if (field is! ManyToManyField) {
        columns.add(_buildColumnDefinition(fieldName, field));
      }
    }

    final constraints = _buildConstraints(fields, meta);
    if (constraints.isNotEmpty) {
      columns.addAll(constraints);
    }

    final sql = 'CREATE TABLE $tableName (\n  ${columns.join(',\n  ')}\n)';
    await connection.execute(sql, []);

    for (final entry in fields.entries) {
      final field = entry.value;
      if (field is ManyToManyField) {
        await _createManyToManyTable(field, tableName);
      }
    }

    await _createIndexes(tableName, fields, meta);
  }

  Future<void> deleteModel(Type modelType) async {
    final tableName = Model.getTableName(modelType);
    final sql = 'DROP TABLE IF EXISTS $tableName';
    await connection.execute(sql, []);
  }

  Future<void> addField(Type modelType, String fieldName, Field field,
      bool preserveDefault) async {
    final tableName = Model.getTableName(modelType);

    if (field is ManyToManyField) {
      await _createManyToManyTable(field, tableName);
      return;
    }

    final columnDef = _buildColumnDefinition(fieldName, field);
    final sql = 'ALTER TABLE $tableName ADD COLUMN $columnDef';
    await connection.execute(sql, []);

    if (field.indexed) {
      await createIndex(modelType, '${tableName}_${fieldName}_idx', [fieldName],
          field.unique);
    }
  }

  Future<void> removeField(Type modelType, String fieldName) async {
    final tableName = Model.getTableName(modelType);

    if (databaseType == 'sqlite') {
      await _recreateTableWithoutColumn(tableName, fieldName);
    } else {
      final sql = 'ALTER TABLE $tableName DROP COLUMN $fieldName';
      await connection.execute(sql, []);
    }
  }

  Future<void> alterField(
      Type modelType, String fieldName, Field oldField, Field newField) async {
    final tableName = Model.getTableName(modelType);

    if (databaseType == 'sqlite') {
      await _recreateTableWithAlteredColumn(
          tableName, fieldName, oldField, newField);
    } else {
      final newColumnDef = _buildColumnDefinition(fieldName, newField);
      final sql = 'ALTER TABLE $tableName ALTER COLUMN $newColumnDef';
      await connection.execute(sql, []);
    }
  }

  Future<void> renameField(
      Type modelType, String oldName, String newName) async {
    final tableName = Model.getTableName(modelType);

    if (databaseType == 'sqlite') {
      await _recreateTableWithRenamedColumn(tableName, oldName, newName);
    } else {
      final sql = 'ALTER TABLE $tableName RENAME COLUMN $oldName TO $newName';
      await connection.execute(sql, []);
    }
  }

  Future<void> createIndex(
      Type modelType, String indexName, List<String> fields, bool unique,
      [String? condition]) async {
    final tableName = Model.getTableName(modelType);
    final uniqueStr = unique ? 'UNIQUE ' : '';
    final conditionStr = condition != null ? ' WHERE $condition' : '';
    final sql =
        'CREATE ${uniqueStr}INDEX $indexName ON $tableName (${fields.join(', ')})$conditionStr';
    await connection.execute(sql, []);
  }

  Future<void> removeIndex(Type modelType, String indexName) async {
    final sql = 'DROP INDEX IF EXISTS $indexName';
    await connection.execute(sql, []);
  }

  Future<void> executeSql(String sql, List<dynamic> parameters) async {
    await connection.execute(sql, parameters);
  }

  String _buildColumnDefinition(String fieldName, Field field) {
    final buffer = StringBuffer();

    buffer.write('$fieldName ${field.sqlType}');

    if (field.primaryKey) {
      buffer.write(' PRIMARY KEY');
      if (field is AutoField) {
        buffer.write(' AUTOINCREMENT');
      }
    }

    if (!field.allowNull && !field.primaryKey) {
      buffer.write(' NOT NULL');
    }

    if (field.unique && !field.primaryKey) {
      buffer.write(' UNIQUE');
    }

    if (field.defaultValue != null) {
      final defaultVal = field.toSqlValue(field.defaultValue);
      buffer.write(' DEFAULT $defaultVal');
    }

    return buffer.toString();
  }

  List<String> _buildConstraints(Map<String, Field> fields, ModelMeta meta) {
    final constraints = <String>[];

    for (final uniqueSet in meta.uniqueTogether) {
      final fieldNames = uniqueSet.split(',').map((f) => f.trim()).toList();
      constraints.add('UNIQUE (${fieldNames.join(', ')})');
    }

    for (final entry in fields.entries) {
      final fieldName = entry.key;
      final field = entry.value;

      if (field is ForeignKey) {
        final referencedTable = field.relatedTableName;
        final referencedColumn = 'id';
        constraints.add(
            'FOREIGN KEY ($fieldName) REFERENCES $referencedTable($referencedColumn) ON DELETE ${field.onDelete} ON UPDATE ${field.onUpdate}');
      }
    }

    return constraints;
  }

  Future<void> _createManyToManyTable(
      ManyToManyField field, String sourceTable) async {
    final throughTable = field.throughTableName;
    final sourceColumn = field.sourceColumnName;
    final targetColumn = field.targetColumnName;
    final targetTable = field.relatedTableName;

    final sql = '''
      CREATE TABLE $throughTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        $sourceColumn INTEGER NOT NULL,
        $targetColumn INTEGER NOT NULL,
        FOREIGN KEY ($sourceColumn) REFERENCES $sourceTable(id) ON DELETE CASCADE,
        FOREIGN KEY ($targetColumn) REFERENCES $targetTable(id) ON DELETE CASCADE,
        UNIQUE ($sourceColumn, $targetColumn)
      )
    ''';

    await connection.execute(sql, []);
  }

  Future<void> _createIndexes(
      String tableName, Map<String, Field> fields, ModelMeta meta) async {
    for (final entry in fields.entries) {
      final fieldName = entry.key;
      final field = entry.value;

      if (field.indexed && !field.primaryKey && !field.unique) {
        final indexName = '${tableName}_${fieldName}_idx';
        await createIndex(Type, indexName, [fieldName], false);
      }
    }

    for (final indexSet in meta.indexTogether) {
      final fieldNames = indexSet.split(',').map((f) => f.trim()).toList();
      final indexName = '${tableName}_${fieldNames.join('_')}_idx';
      await createIndex(Type, indexName, fieldNames, false);
    }
  }

  Future<void> _recreateTableWithoutColumn(
      String tableName, String columnName) async {
    final tempTableName = '${tableName}_temp';

    final existingColumns = await _getTableColumns(tableName);
    final newColumns =
        existingColumns.where((col) => col != columnName).toList();

    final createTempSql =
        'CREATE TABLE $tempTableName AS SELECT ${newColumns.join(', ')} FROM $tableName';
    await connection.execute(createTempSql, []);

    await connection.execute('DROP TABLE $tableName', []);
    await connection
        .execute('ALTER TABLE $tempTableName RENAME TO $tableName', []);
  }

  Future<void> _recreateTableWithAlteredColumn(String tableName,
      String columnName, Field oldField, Field newField) async {
    final tempTableName = '${tableName}_temp';

    await _getTableColumns(tableName);

    final createTempSql =
        'CREATE TABLE $tempTableName AS SELECT * FROM $tableName';
    await connection.execute(createTempSql, []);

    await connection.execute('DROP TABLE $tableName', []);

    final newColumnDef = _buildColumnDefinition(columnName, newField);
    await connection
        .execute('ALTER TABLE $tempTableName ALTER COLUMN $newColumnDef', []);

    await connection
        .execute('ALTER TABLE $tempTableName RENAME TO $tableName', []);
  }

  Future<void> _recreateTableWithRenamedColumn(
      String tableName, String oldName, String newName) async {
    final tempTableName = '${tableName}_temp';

    final existingColumns = await _getTableColumns(tableName);
    final newColumns = existingColumns
        .map((col) => col == oldName ? '$col AS $newName' : col)
        .toList();

    final createTempSql =
        'CREATE TABLE $tempTableName AS SELECT ${newColumns.join(', ')} FROM $tableName';
    await connection.execute(createTempSql, []);

    await connection.execute('DROP TABLE $tableName', []);
    await connection
        .execute('ALTER TABLE $tempTableName RENAME TO $tableName', []);
  }

  Future<List<String>> _getTableColumns(String tableName) async {
    final result = await connection.query('PRAGMA table_info($tableName)', []);
    return result.map((row) => row['name'] as String).toList();
  }
}

class MigrationRecorder {
  final DatabaseConnection connection;

  MigrationRecorder(this.connection);

  Future<void> ensureMigrationTable() async {
    final sql = '''
      CREATE TABLE IF NOT EXISTS dartango_migrations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        app TEXT NOT NULL,
        name TEXT NOT NULL,
        applied DATETIME NOT NULL,
        UNIQUE(app, name)
      )
    ''';
    await connection.execute(sql, []);
  }

  Future<void> recordApplied(String app, String name) async {
    await ensureMigrationTable();
    final sql =
        'INSERT OR REPLACE INTO dartango_migrations (app, name, applied) VALUES (?, ?, ?)';
    await connection
        .execute(sql, [app, name, DateTime.now().toIso8601String()]);
  }

  Future<void> recordUnapplied(String app, String name) async {
    await ensureMigrationTable();
    final sql = 'DELETE FROM dartango_migrations WHERE app = ? AND name = ?';
    await connection.execute(sql, [app, name]);
  }

  Future<List<String>> getAppliedMigrations(String app) async {
    await ensureMigrationTable();
    final sql =
        'SELECT name FROM dartango_migrations WHERE app = ? ORDER BY applied';
    final result = await connection.query(sql, [app]);
    return result.map((row) => row['name'] as String).toList();
  }

  Future<bool> isMigrationApplied(String app, String name) async {
    await ensureMigrationTable();
    final sql =
        'SELECT COUNT(*) as count FROM dartango_migrations WHERE app = ? AND name = ?';
    final result = await connection.query(sql, [app, name]);
    return result.first['count'] > 0;
  }

  Future<void> clearMigrations(String app) async {
    await ensureMigrationTable();
    final sql = 'DELETE FROM dartango_migrations WHERE app = ?';
    await connection.execute(sql, [app]);
  }
}

class MigrationExecutor {
  final DatabaseConnection connection;
  final MigrationRecorder recorder;
  final String databaseType;

  MigrationExecutor(this.connection, this.databaseType)
      : recorder = MigrationRecorder(connection);

  Future<void> migrate(String app, List<Migration> migrations,
      {String? targetMigration}) async {
    final appliedMigrations = await recorder.getAppliedMigrations(app);
    final editor = SchemaEditor(connection, databaseType);

    final migrationsToApply = <Migration>[];

    for (final migration in migrations) {
      if (targetMigration != null && migration.name == targetMigration) {
        migrationsToApply.add(migration);
        break;
      }

      if (!appliedMigrations.contains(migration.name)) {
        migrationsToApply.add(migration);
      }
    }

    for (final migration in migrationsToApply) {
      await _applyMigration(app, migration, editor);
    }
  }

  Future<void> rollback(
      String app, List<Migration> migrations, String targetMigration) async {
    final appliedMigrations = await recorder.getAppliedMigrations(app);
    final editor = SchemaEditor(connection, databaseType);

    final migrationsToRollback = <Migration>[];

    for (final migration in migrations.reversed) {
      if (appliedMigrations.contains(migration.name)) {
        migrationsToRollback.add(migration);

        if (migration.name == targetMigration) {
          break;
        }
      }
    }

    for (final migration in migrationsToRollback) {
      await _rollbackMigration(app, migration, editor);
    }
  }

  Future<void> _applyMigration(
      String app, Migration migration, SchemaEditor editor) async {
    print('Applying migration: ${migration.name}');

    await connection.transaction((conn) async {
      await migration.up(editor);
      await recorder.recordApplied(app, migration.name);
    });

    print('Applied migration: ${migration.name}');
  }

  Future<void> _rollbackMigration(
      String app, Migration migration, SchemaEditor editor) async {
    print('Rolling back migration: ${migration.name}');

    await connection.transaction((conn) async {
      await migration.down(editor);
      await recorder.recordUnapplied(app, migration.name);
    });

    print('Rolled back migration: ${migration.name}');
  }

  Future<List<String>> showMigrations(String app) async {
    return await recorder.getAppliedMigrations(app);
  }

  Future<void> fakeMigration(String app, String migrationName) async {
    await recorder.recordApplied(app, migrationName);
  }

  Future<void> unfakeMigration(String app, String migrationName) async {
    await recorder.recordUnapplied(app, migrationName);
  }
}

class MigrationPlanner {
  static List<Migration> generateMigrations(
    String app,
    Map<Type, ModelState> currentState,
    Map<Type, ModelState> targetState,
  ) {
    final migrations = <Migration>[];

    for (final entry in targetState.entries) {
      final modelType = entry.key;
      final targetModelState = entry.value;

      if (!currentState.containsKey(modelType)) {
        migrations.add(CreateModelMigration(
          modelType: modelType,
          fields: targetModelState.fields,
          meta: targetModelState.meta,
          name:
              '${DateTime.now().millisecondsSinceEpoch}_create_${modelType.toString().toLowerCase()}',
        ));
      } else {
        final currentModelState = currentState[modelType]!;
        final fieldMigrations = _generateFieldMigrations(
          app,
          modelType,
          currentModelState.fields,
          targetModelState.fields,
        );
        migrations.addAll(fieldMigrations);
      }
    }

    for (final entry in currentState.entries) {
      final modelType = entry.key;
      final currentModelState = entry.value;

      if (!targetState.containsKey(modelType)) {
        migrations.add(DeleteModelMigration(
          modelType: modelType,
          fields: currentModelState.fields,
          meta: currentModelState.meta,
          name:
              '${DateTime.now().millisecondsSinceEpoch}_delete_${modelType.toString().toLowerCase()}',
        ));
      }
    }

    return migrations;
  }

  static List<Migration> _generateFieldMigrations(
    String app,
    Type modelType,
    Map<String, Field> currentFields,
    Map<String, Field> targetFields,
  ) {
    final migrations = <Migration>[];

    for (final entry in targetFields.entries) {
      final fieldName = entry.key;
      final targetField = entry.value;

      if (!currentFields.containsKey(fieldName)) {
        migrations.add(AddFieldMigration(
          modelType: modelType,
          fieldName: fieldName,
          field: targetField,
          name:
              '${DateTime.now().millisecondsSinceEpoch}_add_${modelType.toString().toLowerCase()}_$fieldName',
        ));
      } else {
        final currentField = currentFields[fieldName]!;
        if (_fieldsAreDifferent(currentField, targetField)) {
          migrations.add(AlterFieldMigration(
            modelType: modelType,
            fieldName: fieldName,
            oldField: currentField,
            newField: targetField,
            name:
                '${DateTime.now().millisecondsSinceEpoch}_alter_${modelType.toString().toLowerCase()}_$fieldName',
          ));
        }
      }
    }

    for (final entry in currentFields.entries) {
      final fieldName = entry.key;
      final currentField = entry.value;

      if (!targetFields.containsKey(fieldName)) {
        migrations.add(RemoveFieldMigration(
          modelType: modelType,
          fieldName: fieldName,
          field: currentField,
          name:
              '${DateTime.now().millisecondsSinceEpoch}_remove_${modelType.toString().toLowerCase()}_$fieldName',
        ));
      }
    }

    return migrations;
  }

  static bool _fieldsAreDifferent(Field current, Field target) {
    return current.runtimeType != target.runtimeType ||
        current.allowNull != target.allowNull ||
        current.defaultValue != target.defaultValue ||
        current.unique != target.unique ||
        current.indexed != target.indexed ||
        current.primaryKey != target.primaryKey;
  }
}

class ModelState {
  final Map<String, Field> fields;
  final ModelMeta meta;

  ModelState(this.fields, this.meta);
}

extension MigrationExtensions on Type {
  ModelState getModelState() {
    final fields = Model.getFields(this);
    final meta = ModelRegistry.getMeta(this) ?? const ModelMeta();
    return ModelState(fields, meta);
  }
}
