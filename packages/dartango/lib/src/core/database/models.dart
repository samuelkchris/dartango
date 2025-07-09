import 'dart:async';
import 'dart:mirrors';

import 'connection.dart';
import 'exceptions.dart';
import 'fields.dart';
import 'managers.dart';
import 'query.dart';

class ModelMeta {
  final String? tableName;
  final String? appLabel;
  final List<String> ordering;
  final List<String> indexes;
  final List<String> constraints;
  final Map<String, String> permissions;
  final bool abstract;
  final bool proxy;
  final String? defaultManagerName;
  final List<String> uniqueTogether;
  final List<String> indexTogether;
  final String? dbTable;
  final String? verboseName;
  final String? verboseNamePlural;
  final bool managed;
  final Map<String, dynamic> options;

  const ModelMeta({
    this.tableName,
    this.appLabel,
    this.ordering = const [],
    this.indexes = const [],
    this.constraints = const [],
    this.permissions = const {},
    this.abstract = false,
    this.proxy = false,
    this.defaultManagerName,
    this.uniqueTogether = const [],
    this.indexTogether = const [],
    this.dbTable,
    this.verboseName,
    this.verboseNamePlural,
    this.managed = true,
    this.options = const {},
  });

  String get effectiveTableName => tableName ?? dbTable ?? _generateTableName();

  String _generateTableName() {
    final className = runtimeType.toString().toLowerCase();
    if (appLabel != null) {
      return '${appLabel}_$className';
    }
    return className;
  }

  ModelMeta copyWith({
    String? tableName,
    String? appLabel,
    List<String>? ordering,
    List<String>? indexes,
    List<String>? constraints,
    Map<String, String>? permissions,
    bool? abstract,
    bool? proxy,
    String? defaultManagerName,
    List<String>? uniqueTogether,
    List<String>? indexTogether,
    String? dbTable,
    String? verboseName,
    String? verboseNamePlural,
    bool? managed,
    Map<String, dynamic>? options,
  }) {
    return ModelMeta(
      tableName: tableName ?? this.tableName,
      appLabel: appLabel ?? this.appLabel,
      ordering: ordering ?? this.ordering,
      indexes: indexes ?? this.indexes,
      constraints: constraints ?? this.constraints,
      permissions: permissions ?? this.permissions,
      abstract: abstract ?? this.abstract,
      proxy: proxy ?? this.proxy,
      defaultManagerName: defaultManagerName ?? this.defaultManagerName,
      uniqueTogether: uniqueTogether ?? this.uniqueTogether,
      indexTogether: indexTogether ?? this.indexTogether,
      dbTable: dbTable ?? this.dbTable,
      verboseName: verboseName ?? this.verboseName,
      verboseNamePlural: verboseNamePlural ?? this.verboseNamePlural,
      managed: managed ?? this.managed,
      options: options ?? this.options,
    );
  }
}

abstract class Model {
  static late Manager<Model> objects;
  
  Map<String, dynamic> _fieldValues = {};
  Map<String, Field> _fields = {};
  bool _isLoaded = false;
  bool _hasChanged = false;
  Set<String> _changedFields = {};

  Model() {
    _initializeFields();
    _initializeManagers();
  }

  Model.fromMap(Map<String, dynamic> data) {
    _initializeFields();
    _initializeManagers();
    _loadFromMap(data);
  }

  ModelMeta get meta => const ModelMeta();
  String get tableName => meta.effectiveTableName;
  String? get database => null;

  void _initializeFields() {
    final mirror = reflect(this);
    final classMirror = mirror.type;
    
    for (final declaration in classMirror.declarations.values) {
      if (declaration is VariableMirror) {
        final fieldName = MirrorSystem.getName(declaration.simpleName);
        final field = mirror.getField(declaration.simpleName).reflectee;
        
        if (field is Field) {
          _fields[fieldName] = field;
          if (_fieldValues[fieldName] == null && field.defaultValue != null) {
            _fieldValues[fieldName] = field.defaultValue;
          }
        }
      }
    }
  }

  void _initializeManagers() {
    objects = Manager<Model>(this);
  }

  void _loadFromMap(Map<String, dynamic> data) {
    _fieldValues.clear();
    _changedFields.clear();
    
    for (final entry in data.entries) {
      final fieldName = entry.key;
      final field = _fields[fieldName];
      
      if (field != null) {
        _fieldValues[fieldName] = field.fromSqlValue(entry.value);
      } else {
        _fieldValues[fieldName] = entry.value;
      }
    }
    
    _isLoaded = true;
    _hasChanged = false;
  }

  T? getField<T>(String fieldName) {
    return _fieldValues[fieldName] as T?;
  }

  void setField<T>(String fieldName, T? value) {
    final field = _fields[fieldName];
    if (field != null) {
      final cleanValue = field.clean(value);
      field.validate(cleanValue);
      
      if (_fieldValues[fieldName] != cleanValue) {
        _fieldValues[fieldName] = cleanValue;
        _changedFields.add(fieldName);
        _hasChanged = true;
      }
    } else {
      if (_fieldValues[fieldName] != value) {
        _fieldValues[fieldName] = value;
        _changedFields.add(fieldName);
        _hasChanged = true;
      }
    }
  }

  dynamic get pk => getField(primaryKeyField);
  set pk(dynamic value) => setField(primaryKeyField, value);

  String get primaryKeyField {
    for (final entry in _fields.entries) {
      if (entry.value.primaryKey) {
        return entry.key;
      }
    }
    return 'id';
  }

  bool get isNew => pk == null;
  bool get hasChanged => _hasChanged;
  Set<String> get changedFields => Set.unmodifiable(_changedFields);

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    for (final entry in _fieldValues.entries) {
      final field = _fields[entry.key];
      if (field != null) {
        result[entry.key] = field.toSqlValue(entry.value);
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  Map<String, dynamic> toJson() {
    return Map<String, dynamic>.from(_fieldValues);
  }

  void validate() {
    for (final entry in _fields.entries) {
      final fieldName = entry.key;
      final field = entry.value;
      final value = _fieldValues[fieldName];
      
      try {
        field.validate(value);
      } catch (e) {
        throw ValidationException('Field $fieldName: ${e.toString()}', fieldName: fieldName, value: value);
      }
    }
    
    fullClean();
  }

  void fullClean() {
    cleanFields();
    clean();
    validateUnique();
  }

  void cleanFields() {
    for (final entry in _fields.entries) {
      final fieldName = entry.key;
      final field = entry.value;
      final value = _fieldValues[fieldName];
      
      if (value == null && !field.allowNull && field.defaultValue == null) {
        throw ValidationException('Field $fieldName cannot be null', fieldName: fieldName);
      }
      
      if (value != null) {
        try {
          final cleanValue = field.clean(value);
          _fieldValues[fieldName] = cleanValue;
        } catch (e) {
          throw ValidationException('Field $fieldName: ${e.toString()}', fieldName: fieldName, value: value);
        }
      }
    }
  }

  void clean() {
    // Override in subclasses for custom validation
  }

  void validateUnique() {
    // Check unique constraints
    for (final entry in _fields.entries) {
      final fieldName = entry.key;
      final field = entry.value;
      
      if (field.unique) {
        final value = _fieldValues[fieldName];
        if (value != null) {
          _validateFieldUnique(fieldName, value);
        }
      }
    }
    
    // Check unique_together constraints
    for (final uniqueSet in meta.uniqueTogether) {
      final fields = uniqueSet.split(',').map((f) => f.trim()).toList();
      final values = <String, dynamic>{};
      
      for (final fieldName in fields) {
        values[fieldName] = _fieldValues[fieldName];
      }
      
      _validateUniqueTogetherConstraint(fields, values);
    }
  }

  void _validateFieldUnique(String fieldName, dynamic value) {
    // In a real implementation, this would check the database
    // For now, we'll skip the actual uniqueness check
  }

  void _validateUniqueTogetherConstraint(List<String> fields, Map<String, dynamic> values) {
    // In a real implementation, this would check the database
    // For now, we'll skip the actual uniqueness check
  }

  Future<void> save({bool forceInsert = false, bool forceUpdate = false, List<String>? updateFields}) async {
    if (forceInsert && forceUpdate) {
      throw ModelException('Cannot force both insert and update');
    }
    
    validate();
    
    if (isNew && !forceUpdate) {
      await _insert();
    } else if (!isNew && !forceInsert) {
      await _update(updateFields: updateFields);
    } else if (forceInsert) {
      await _insert();
    } else if (forceUpdate) {
      await _update(updateFields: updateFields);
    }
    
    _hasChanged = false;
    _changedFields.clear();
    _isLoaded = true;
  }

  Future<void> _insert() async {
    final connection = await DatabaseRouter.getConnection(database);
    try {
      final insertData = <String, dynamic>{};
      for (final entry in _fieldValues.entries) {
        final field = _fields[entry.key];
        if (field != null && !field.primaryKey) {
          insertData[entry.key] = entry.value;
        }
      }
      
      final builder = InsertQueryBuilder(tableName).values(insertData);
      final result = await connection.execute(builder.toSql(), builder.parameters);
      
      if (result.insertId != null) {
        setField(primaryKeyField, result.insertId);
      }
    } finally {
      await DatabaseRouter.releaseConnection(connection, database);
    }
  }

  Future<void> _update({List<String>? updateFields}) async {
    final connection = await DatabaseRouter.getConnection(database);
    try {
      final updateData = <String, dynamic>{};
      final fieldsToUpdate = updateFields ?? _changedFields.toList();
      
      for (final fieldName in fieldsToUpdate) {
        final field = _fields[fieldName];
        if (field != null && !field.primaryKey) {
          updateData[fieldName] = _fieldValues[fieldName];
        }
      }
      
      if (updateData.isEmpty) return;
      
      final builder = UpdateQueryBuilder(tableName)
          .set(updateData)
          .where('${primaryKeyField} = ?', [pk]);
      
      await connection.execute(builder.toSql(), builder.parameters);
    } finally {
      await DatabaseRouter.releaseConnection(connection, database);
    }
  }

  Future<void> delete() async {
    if (isNew) {
      throw ModelException('Cannot delete unsaved model instance');
    }
    
    final connection = await DatabaseRouter.getConnection(database);
    try {
      final builder = DeleteQueryBuilder(tableName)
          .where('${primaryKeyField} = ?', [pk]);
      
      await connection.execute(builder.toSql(), builder.parameters);
      
      _fieldValues.clear();
      _hasChanged = false;
      _changedFields.clear();
      _isLoaded = false;
    } finally {
      await DatabaseRouter.releaseConnection(connection, database);
    }
  }

  Future<void> refresh() async {
    if (isNew) {
      throw ModelException('Cannot refresh unsaved model instance');
    }
    
    final connection = await DatabaseRouter.getConnection(database);
    try {
      final builder = QueryBuilder()
          .select(['*'])
          .from(tableName)
          .where('${primaryKeyField} = ?', [pk]);
      
      final result = await connection.query(builder.toSql(), builder.parameters);
      
      if (result.isEmpty) {
        throw DoesNotExistException('Model instance no longer exists in database');
      }
      
      _loadFromMap(result.first);
    } finally {
      await DatabaseRouter.releaseConnection(connection, database);
    }
  }

  Model copy() {
    // In a real implementation, this would use reflection to create a new instance
    // For now, we'll return the same instance as a placeholder
    return this;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Model) return false;
    if (other.runtimeType != runtimeType) return false;
    
    final thisPk = pk;
    final otherPk = other.pk;
    
    if (thisPk == null || otherPk == null) {
      return false;
    }
    
    return thisPk == otherPk;
  }

  @override
  int get hashCode => pk?.hashCode ?? 0;

  @override
  String toString() {
    final className = runtimeType.toString();
    if (pk != null) {
      return '$className(pk=$pk)';
    }
    return '$className(unsaved)';
  }

  // Static methods for model introspection
  static String getTableName(Type modelType) {
    // In a real implementation, this would use reflection
    return modelType.toString().toLowerCase();
  }

  static Map<String, Field> getFields(Type modelType) {
    // In a real implementation, this would use reflection
    return {};
  }

  static Field? getModelField(Type modelType, String fieldName) {
    final fields = getFields(modelType);
    return fields[fieldName];
  }

  static List<String> getFieldNames(Type modelType) {
    final fields = getFields(modelType);
    return fields.keys.toList();
  }

  static String getPrimaryKeyField(Type modelType) {
    final fields = getFields(modelType);
    for (final entry in fields.entries) {
      if (entry.value.primaryKey) {
        return entry.key;
      }
    }
    return 'id';
  }

  static bool hasField(Type modelType, String fieldName) {
    final fields = getFields(modelType);
    return fields.containsKey(fieldName);
  }

  // Relationship methods
  Future<List<Model>> getRelatedObjects(String relatedField) async {
    // In a real implementation, this would handle foreign key relationships
    return [];
  }

  Future<void> setRelatedObjects(String relatedField, List<Model> objects) async {
    // In a real implementation, this would handle foreign key relationships
  }

  Future<void> addRelatedObject(String relatedField, Model object) async {
    // In a real implementation, this would handle many-to-many relationships
  }

  Future<void> removeRelatedObject(String relatedField, Model object) async {
    // In a real implementation, this would handle many-to-many relationships
  }

  Future<void> clearRelatedObjects(String relatedField) async {
    // In a real implementation, this would handle many-to-many relationships
  }

  // Signal methods
  void preSave() {
    // Override in subclasses for pre-save logic
  }

  void postSave() {
    // Override in subclasses for post-save logic
  }

  void preDelete() {
    // Override in subclasses for pre-delete logic
  }

  void postDelete() {
    // Override in subclasses for post-delete logic
  }

  // Utility methods
  bool isDirty([String? fieldName]) {
    if (fieldName != null) {
      return _changedFields.contains(fieldName);
    }
    return _hasChanged;
  }

  dynamic getOriginalValue(String fieldName) {
    // In a real implementation, this would track original values
    return _fieldValues[fieldName];
  }

  void revertField(String fieldName) {
    // In a real implementation, this would revert to original value
    _changedFields.remove(fieldName);
    if (_changedFields.isEmpty) {
      _hasChanged = false;
    }
  }

  void revertAll() {
    // In a real implementation, this would revert all changes
    _changedFields.clear();
    _hasChanged = false;
  }

  Map<String, dynamic> getDirtyFields() {
    final result = <String, dynamic>{};
    for (final fieldName in _changedFields) {
      result[fieldName] = _fieldValues[fieldName];
    }
    return result;
  }

  bool wasFieldChanged(String fieldName) {
    return _changedFields.contains(fieldName);
  }

  List<String> getChangedFields() {
    return _changedFields.toList();
  }

  // Database operations
  Future<bool> exists() async {
    if (isNew) return false;
    
    final connection = await DatabaseRouter.getConnection(database);
    try {
      final builder = QueryBuilder()
          .select(['COUNT(*) as count'])
          .from(tableName)
          .where('${primaryKeyField} = ?', [pk]);
      
      final result = await connection.query(builder.toSql(), builder.parameters);
      return result.first['count'] > 0;
    } finally {
      await DatabaseRouter.releaseConnection(connection, database);
    }
  }

  Future<void> saveOrUpdate() async {
    if (await exists()) {
      await save(forceUpdate: true);
    } else {
      await save(forceInsert: true);
    }
  }

  Future<Model> reload() async {
    await refresh();
    return this;
  }

  // Batch operations
  static Future<List<Model>> bulkCreate(List<Model> objects, {int batchSize = 1000}) async {
    if (objects.isEmpty) return [];
    
    final connection = await DatabaseRouter.getConnection(objects.first.database);
    try {
      final batches = <List<Model>>[];
      for (int i = 0; i < objects.length; i += batchSize) {
        final end = (i + batchSize < objects.length) ? i + batchSize : objects.length;
        batches.add(objects.sublist(i, end));
      }
      
      final results = <Model>[];
      for (final batch in batches) {
        final batchData = batch.map((obj) => obj.toMap()).toList();
        final builder = InsertQueryBuilder(objects.first.tableName).bulkValues(batchData);
        
        await connection.execute(builder.toSql(), builder.parameters);
        results.addAll(batch);
      }
      
      return results;
    } finally {
      await DatabaseRouter.releaseConnection(connection, objects.first.database);
    }
  }

  static Future<int> bulkUpdate(List<Model> objects, List<String> fields, {int batchSize = 1000}) async {
    if (objects.isEmpty) return 0;
    
    int updated = 0;
    final batches = <List<Model>>[];
    for (int i = 0; i < objects.length; i += batchSize) {
      final end = (i + batchSize < objects.length) ? i + batchSize : objects.length;
      batches.add(objects.sublist(i, end));
    }
    
    for (final batch in batches) {
      for (final obj in batch) {
        await obj.save(updateFields: fields);
        updated++;
      }
    }
    
    return updated;
  }

  static Future<int> bulkDelete(List<Model> objects, {int batchSize = 1000}) async {
    if (objects.isEmpty) return 0;
    
    int deleted = 0;
    final batches = <List<Model>>[];
    for (int i = 0; i < objects.length; i += batchSize) {
      final end = (i + batchSize < objects.length) ? i + batchSize : objects.length;
      batches.add(objects.sublist(i, end));
    }
    
    for (final batch in batches) {
      for (final obj in batch) {
        await obj.delete();
        deleted++;
      }
    }
    
    return deleted;
  }
}

// Abstract base classes for model inheritance
abstract class AbstractModel extends Model {
  @override
  ModelMeta get meta => const ModelMeta(abstract: true);
}

class ProxyModel extends Model {
  final Model _target;
  
  ProxyModel(this._target) {
    _fieldValues = _target._fieldValues;
    _fields = _target._fields;
    _isLoaded = _target._isLoaded;
    _hasChanged = _target._hasChanged;
    _changedFields = _target._changedFields;
  }
  
  @override
  ModelMeta get meta => _target.meta.copyWith(proxy: true);
  
  @override
  String get tableName => _target.tableName;
  
  @override
  String? get database => _target.database;
}

// Model registry for managing model relationships
class ModelRegistry {
  static final Map<Type, ModelMeta> _registry = {};
  static final Map<String, Type> _tableToModel = {};
  
  static void register(Type modelType, ModelMeta meta) {
    _registry[modelType] = meta;
    _tableToModel[meta.effectiveTableName] = modelType;
  }
  
  static ModelMeta? getMeta(Type modelType) {
    return _registry[modelType];
  }
  
  static Type? getModelByTable(String tableName) {
    return _tableToModel[tableName];
  }
  
  static List<Type> getAllModels() {
    return _registry.keys.toList();
  }
  
  static Map<Type, ModelMeta> getAllRegistry() {
    return Map.unmodifiable(_registry);
  }
  
  static void clear() {
    _registry.clear();
    _tableToModel.clear();
  }
}

// Model state tracking
class ModelState {
  final Map<String, dynamic> originalValues;
  final Map<String, dynamic> currentValues;
  final Set<String> changedFields;
  final bool isLoaded;
  final bool isNew;
  
  ModelState({
    required this.originalValues,
    required this.currentValues,
    required this.changedFields,
    required this.isLoaded,
    required this.isNew,
  });
  
  bool isDirty([String? fieldName]) {
    if (fieldName != null) {
      return changedFields.contains(fieldName);
    }
    return changedFields.isNotEmpty;
  }
  
  bool wasFieldChanged(String fieldName) {
    return changedFields.contains(fieldName);
  }
  
  dynamic getOriginalValue(String fieldName) {
    return originalValues[fieldName];
  }
  
  dynamic getCurrentValue(String fieldName) {
    return currentValues[fieldName];
  }
  
  Map<String, dynamic> getDirtyFields() {
    final result = <String, dynamic>{};
    for (final fieldName in changedFields) {
      result[fieldName] = currentValues[fieldName];
    }
    return result;
  }
}

// Model options for advanced configuration
class ModelOptions {
  final String? tableName;
  final String? appLabel;
  final List<String> ordering;
  final Map<String, String> permissions;
  final bool managed;
  final List<String> uniqueTogether;
  final List<String> indexTogether;
  final String? defaultManagerName;
  final bool abstract;
  final bool proxy;
  final Map<String, dynamic> meta;
  
  const ModelOptions({
    this.tableName,
    this.appLabel,
    this.ordering = const [],
    this.permissions = const {},
    this.managed = true,
    this.uniqueTogether = const [],
    this.indexTogether = const [],
    this.defaultManagerName,
    this.abstract = false,
    this.proxy = false,
    this.meta = const {},
  });
}