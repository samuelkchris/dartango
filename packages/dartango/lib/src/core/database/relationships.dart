import 'dart:async';
import 'dart:mirrors';

import 'fields.dart';
import 'models.dart';
import 'queryset.dart';
import 'connection.dart';
import 'query.dart';
import 'exceptions.dart';
import 'validators.dart';

class ForeignKey<T extends Model> extends Field<T> {
  final Type relatedModel;
  final String? relatedName;
  final String? relatedQueryName;
  final bool toField;
  final String? limitChoicesTo;
  final String onDelete;
  final String onUpdate;

  ForeignKey({
    required this.relatedModel,
    this.relatedName,
    this.relatedQueryName,
    this.toField = false,
    this.limitChoicesTo,
    this.onDelete = 'CASCADE',
    this.onUpdate = 'CASCADE',
    String? columnName,
    bool allowNull = false,
    T? defaultValue,
    String? helpText,
    List<Validator<T>>? validators,
    bool editable = true,
    bool indexed = true,
    bool primaryKey = false,
    bool unique = false,
  }) : super(
          columnName: columnName,
          allowNull: allowNull,
          defaultValue: defaultValue,
          helpText: helpText,
          validators: validators ?? const [],
          editable: editable,
          indexed: indexed,
          primaryKey: primaryKey,
          unique: unique,
        );

  @override
  String get sqlType => 'INTEGER';

  @override
  String get dartType => relatedModel.toString();

  String get foreignKeyColumn => columnName ?? '${_fieldName}_id';
  String get relatedTableName => Model.getTableName(relatedModel);
  String get effectiveRelatedName => relatedName ?? '${_getModelName()}_set';

  String _fieldName = '';

  String _getModelName() {
    return runtimeType.toString().split('<')[0].toLowerCase();
  }

  @override
  T? clean(dynamic value) {
    if (value == null) return null;
    if (value is T) return value;
    if (value is int) {
      return _getRelatedObjectById(value);
    }
    throw ValidationException('Invalid value for ForeignKey');
  }

  T? _getRelatedObjectById(int id) {
    return (relatedModel as dynamic).objects.get({'id': id});
  }

  @override
  String toSqlValue(T? value) {
    if (value == null) return 'NULL';
    return value.pk.toString();
  }

  @override
  T? fromSqlValue(dynamic value) {
    if (value == null) return null;
    return _getRelatedObjectById(value as int);
  }

  @override
  void validate(T? value) {
    for (final validator in validators) {
      validator.validate(value);
    }
    if (value != null && value.pk == null) {
      throw ValidationException(
          'Related object must be saved before assignment');
    }
  }

  Future<T?> get(Model instance) async {
    final foreignKeyValue = instance.getField(foreignKeyColumn);
    if (foreignKeyValue == null) return null;

    final relatedQuerySet = (relatedModel as dynamic).objects as QuerySet<T>;
    return await relatedQuerySet.get({'id': foreignKeyValue});
  }

  Future<void> set(Model instance, T? value) async {
    if (value != null && value.pk == null) {
      await value.save();
    }
    instance.setField(foreignKeyColumn, value?.pk);
  }

  Future<void> clear(Model instance) async {
    instance.setField(foreignKeyColumn, null);
  }

  QuerySet<T> getRelatedManager(Model instance) {
    return (relatedModel as dynamic).objects as QuerySet<T>;
  }
}

class OneToOneField<T extends Model> extends ForeignKey<T> {
  OneToOneField({
    required super.relatedModel,
    super.relatedName,
    super.relatedQueryName,
    super.toField = false,
    super.limitChoicesTo,
    super.onDelete = 'CASCADE',
    super.onUpdate = 'CASCADE',
    super.columnName,
    super.allowNull = false,
    super.defaultValue,
    super.helpText,
    super.validators,
    super.editable = true,
    super.indexed = true,
    super.primaryKey = false,
    super.unique = true,
  });

  @override
  String get sqlType => 'INTEGER UNIQUE';
}

class ManyToManyField<T extends Model> extends Field<List<T>> {
  final Type relatedModel;
  final String? relatedName;
  final String? relatedQueryName;
  final String? dbTable;
  final bool blank;
  final String? limitChoicesTo;
  final bool symmetrical;
  final String? through;
  final String? throughFields;

  ManyToManyField({
    required this.relatedModel,
    this.relatedName,
    this.relatedQueryName,
    this.dbTable,
    this.blank = false,
    this.limitChoicesTo,
    this.symmetrical = true,
    this.through,
    this.throughFields,
    super.columnName,
    super.allowNull = true,
    super.defaultValue,
    super.helpText,
    super.validators = const [],
    super.editable = true,
    super.indexed = false,
    super.primaryKey = false,
    super.unique = false,
  });

  @override
  String get sqlType => '';

  @override
  String get dartType => 'List<${relatedModel.toString()}>';

  String get throughTableName {
    if (dbTable != null) return dbTable!;
    if (through != null) return through!;

    final modelNames = [_getModelName(), relatedTableName]..sort();
    return '${modelNames[0]}_${modelNames[1]}';
  }

  String _getModelName() {
    return runtimeType.toString().split('<')[0].toLowerCase();
  }

  String get relatedTableName => Model.getTableName(relatedModel);

  String get sourceColumnName => '${_getModelName()}_id';
  String get targetColumnName => '${relatedTableName.toLowerCase()}_id';

  @override
  List<T>? clean(dynamic value) {
    if (value == null) return [];
    if (value is List<T>) return value;
    if (value is List) {
      return value.map((v) => v as T).toList();
    }
    throw ValidationException('Invalid value for ManyToManyField');
  }

  @override
  String toSqlValue(List<T>? value) {
    return '';
  }

  @override
  List<T>? fromSqlValue(dynamic value) {
    return [];
  }

  @override
  void validate(List<T>? value) {
    for (final validator in validators) {
      validator.validate(value);
    }
    if (value != null && !blank && value.isEmpty) {
      throw ValidationException('This field cannot be blank');
    }
  }

  ManyToManyManager<T> getRelatedManager(Model instance) {
    return ManyToManyManager<T>(
      instance: instance,
      relatedModel: relatedModel,
      throughTable: throughTableName,
      sourceColumn: sourceColumnName,
      targetColumn: targetColumnName,
    );
  }
}

class ManyToManyManager<T extends Model> {
  final Model instance;
  final Type relatedModel;
  final String throughTable;
  final String sourceColumn;
  final String targetColumn;

  ManyToManyManager({
    required this.instance,
    required this.relatedModel,
    required this.throughTable,
    required this.sourceColumn,
    required this.targetColumn,
  });

  QuerySet<T> all() {
    final relatedTable = Model.getTableName(relatedModel);
    final query = QuerySet<T>(relatedModel, relatedTable).extra(
      tables: [throughTable],
      where:
          '$throughTable.$sourceColumn = ? AND $throughTable.$targetColumn = $relatedTable.id',
      params: [instance.pk],
    );
    return query;
  }

  QuerySet<T> filter(Map<String, dynamic> filters) {
    return all().filter(filters);
  }

  Future<void> add(T object) async {
    if (object.pk == null) {
      await object.save();
    }

    final connection = await DatabaseRouter.getConnection(instance.database);
    try {
      final builder = InsertQueryBuilder(throughTable).values({
        sourceColumn: instance.pk,
        targetColumn: object.pk,
      });

      await connection.execute(builder.toSql(), builder.parameters);
    } finally {
      await DatabaseRouter.releaseConnection(connection, instance.database);
    }
  }

  Future<void> addAll(List<T> objects) async {
    for (final object in objects) {
      await add(object);
    }
  }

  Future<void> remove(T object) async {
    final connection = await DatabaseRouter.getConnection(instance.database);
    try {
      final builder = DeleteQueryBuilder(throughTable).where(
          '$sourceColumn = ? AND $targetColumn = ?', [instance.pk, object.pk]);

      await connection.execute(builder.toSql(), builder.parameters);
    } finally {
      await DatabaseRouter.releaseConnection(connection, instance.database);
    }
  }

  Future<void> removeAll(List<T> objects) async {
    for (final object in objects) {
      await remove(object);
    }
  }

  Future<void> clear() async {
    final connection = await DatabaseRouter.getConnection(instance.database);
    try {
      final builder = DeleteQueryBuilder(throughTable)
          .where('$sourceColumn = ?', [instance.pk]);

      await connection.execute(builder.toSql(), builder.parameters);
    } finally {
      await DatabaseRouter.releaseConnection(connection, instance.database);
    }
  }

  Future<void> set(List<T> objects) async {
    await clear();
    await addAll(objects);
  }

  Future<bool> contains(T object) async {
    final connection = await DatabaseRouter.getConnection(instance.database);
    try {
      final builder = QueryBuilder()
          .select(['COUNT(*) as count'])
          .from(throughTable)
          .where('$sourceColumn = ? AND $targetColumn = ?',
              [instance.pk, object.pk]);

      final result =
          await connection.query(builder.toSql(), builder.parameters);
      return result.first['count'] > 0;
    } finally {
      await DatabaseRouter.releaseConnection(connection, instance.database);
    }
  }

  Future<int> count() async {
    final connection = await DatabaseRouter.getConnection(instance.database);
    try {
      final builder = QueryBuilder()
          .select(['COUNT(*) as count'])
          .from(throughTable)
          .where('$sourceColumn = ?', [instance.pk]);

      final result =
          await connection.query(builder.toSql(), builder.parameters);
      return result.first['count'] as int;
    } finally {
      await DatabaseRouter.releaseConnection(connection, instance.database);
    }
  }

  Future<bool> exists() async {
    return await count() > 0;
  }

  Future<List<T>> create(List<Map<String, dynamic>> dataList) async {
    final objects = <T>[];

    for (final data in dataList) {
      final object = (relatedModel as dynamic).fromMap(data) as T;
      await object.save();
      objects.add(object);
    }

    await addAll(objects);
    return objects;
  }

  Future<T> getOrCreate(Map<String, dynamic> data) async {
    final existing = await filter(data).first();
    if (existing != null) {
      return existing;
    }

    final object = (relatedModel as dynamic).fromMap(data) as T;
    await object.save();
    await add(object);
    return object;
  }

  Future<List<T>> bulkCreate(List<Map<String, dynamic>> dataList) async {
    final objects = <T>[];

    for (final data in dataList) {
      final object = (relatedModel as dynamic).fromMap(data) as T;
      objects.add(object);
    }

    await Model.bulkCreate(objects.cast<Model>());

    final connection = await DatabaseRouter.getConnection(instance.database);
    try {
      final insertData = objects
          .map((obj) => {
                sourceColumn: instance.pk,
                targetColumn: obj.pk,
              })
          .toList();

      final builder = InsertQueryBuilder(throughTable).bulkValues(insertData);
      await connection.execute(builder.toSql(), builder.parameters);
    } finally {
      await DatabaseRouter.releaseConnection(connection, instance.database);
    }

    return objects;
  }
}

class ReverseRelationshipManager<T extends Model> {
  final Model instance;
  final String relatedField;
  final Type relatedModel;

  ReverseRelationshipManager({
    required this.instance,
    required this.relatedField,
    required this.relatedModel,
  });

  QuerySet<T> all() {
    final relatedTable = Model.getTableName(relatedModel);
    return QuerySet<T>(relatedModel, relatedTable)
        .filter({relatedField: instance.pk});
  }

  QuerySet<T> filter(Map<String, dynamic> filters) {
    return all().filter(filters);
  }

  Future<T> create(Map<String, dynamic> data) async {
    data[relatedField] = instance.pk;
    final object = (relatedModel as dynamic).fromMap(data) as T;
    await object.save();
    return object;
  }

  Future<List<T>> bulkCreate(List<Map<String, dynamic>> dataList) async {
    for (final data in dataList) {
      data[relatedField] = instance.pk;
    }

    final objects = dataList
        .map((data) => (relatedModel as dynamic).fromMap(data) as T)
        .toList();
    return await Model.bulkCreate(objects.cast<Model>())
        .then((models) => models.cast<T>());
  }

  Future<T> getOrCreate(Map<String, dynamic> data) async {
    data[relatedField] = instance.pk;

    final existing = await filter(data).first();
    if (existing != null) {
      return existing;
    }

    return await create(data);
  }

  Future<int> count() async {
    return await all().count();
  }

  Future<bool> exists() async {
    return await all().exists();
  }

  Future<void> clear() async {
    await all().delete();
  }

  Future<int> update(Map<String, dynamic> values) async {
    return await all().update(values);
  }

  Future<int> delete() async {
    return await all().delete();
  }
}

class RelationshipDescriptor<T extends Model> {
  final Field<T> field;
  final String fieldName;

  RelationshipDescriptor(this.field, this.fieldName);

  T? get(Model instance) {
    if (field is ForeignKey<T>) {
      return (field as ForeignKey<T>).get(instance) as T?;
    }
    return null;
  }

  void set(Model instance, T? value) {
    if (field is ForeignKey<T>) {
      (field as ForeignKey<T>).set(instance, value);
    }
  }

  ManyToManyManager<T>? getManyToManyManager(Model instance) {
    if (field is ManyToManyField<T>) {
      return (field as ManyToManyField<T>).getRelatedManager(instance);
    }
    return null;
  }
}

Map<String, RelationshipDescriptor> extractRelationships(Model model) {
  final relationships = <String, RelationshipDescriptor>{};

  for (final entry in model._fields.entries) {
    final fieldName = entry.key;
    final field = entry.value;

    if (field is ForeignKey ||
        field is OneToOneField ||
        field is ManyToManyField) {
      relationships[fieldName] =
          RelationshipDescriptor(field as dynamic, fieldName);
    }
  }

  return relationships;
}

extension RelationshipExtensions on Model {
  Map<String, RelationshipDescriptor> get relationships =>
      extractRelationships(this);

  T? getRelated<T extends Model>(String fieldName) {
    final relationship = relationships[fieldName];
    return relationship?.get(this) as T?;
  }

  void setRelated<T extends Model>(String fieldName, T? value) {
    final relationship = relationships[fieldName];
    relationship?.set(this, value);
  }

  ManyToManyManager<T>? getManyToMany<T extends Model>(String fieldName) {
    final relationship = relationships[fieldName];
    return relationship?.getManyToManyManager(this) as ManyToManyManager<T>?;
  }

  Map<String, Field> get _fields {
    final mirror = reflect(this);
    final classMirror = mirror.type;
    final fields = <String, Field>{};

    for (final declaration in classMirror.declarations.values) {
      if (declaration is VariableMirror) {
        final fieldName = MirrorSystem.getName(declaration.simpleName);
        final field = mirror.getField(declaration.simpleName).reflectee;

        if (field is Field) {
          fields[fieldName] = field;
        }
      }
    }

    return fields;
  }
}
