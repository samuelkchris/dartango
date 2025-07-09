class DatabaseException implements Exception {
  final String message;
  final String? code;
  final Exception? innerException;

  DatabaseException(this.message, {this.code, this.innerException});

  @override
  String toString() => 'DatabaseException: $message';
}

class ConnectionException extends DatabaseException {
  ConnectionException(String message, {String? code, Exception? innerException})
      : super(message, code: code, innerException: innerException);
}

class QueryException extends DatabaseException {
  final String? query;
  final List<dynamic>? parameters;

  QueryException(String message, {this.query, this.parameters, String? code, Exception? innerException})
      : super(message, code: code, innerException: innerException);

  @override
  String toString() {
    final buffer = StringBuffer('QueryException: $message');
    if (query != null) {
      buffer.write('\nQuery: $query');
    }
    if (parameters != null && parameters!.isNotEmpty) {
      buffer.write('\nParameters: $parameters');
    }
    return buffer.toString();
  }
}

class TransactionException extends DatabaseException {
  TransactionException(String message, {String? code, Exception? innerException})
      : super(message, code: code, innerException: innerException);
}

class MigrationException extends DatabaseException {
  final String? migrationName;
  final String? operation;

  MigrationException(String message, {this.migrationName, this.operation, String? code, Exception? innerException})
      : super(message, code: code, innerException: innerException);

  @override
  String toString() {
    final buffer = StringBuffer('MigrationException: $message');
    if (migrationName != null) {
      buffer.write('\nMigration: $migrationName');
    }
    if (operation != null) {
      buffer.write('\nOperation: $operation');
    }
    return buffer.toString();
  }
}

class ValidationException extends DatabaseException {
  final String? fieldName;
  final dynamic value;

  ValidationException(String message, {this.fieldName, this.value, String? code, Exception? innerException})
      : super(message, code: code, innerException: innerException);

  @override
  String toString() {
    final buffer = StringBuffer('ValidationException: $message');
    if (fieldName != null) {
      buffer.write('\nField: $fieldName');
    }
    if (value != null) {
      buffer.write('\nValue: $value');
    }
    return buffer.toString();
  }
}

class IntegrityException extends DatabaseException {
  final String? constraintName;
  final String? tableName;

  IntegrityException(String message, {this.constraintName, this.tableName, String? code, Exception? innerException})
      : super(message, code: code, innerException: innerException);

  @override
  String toString() {
    final buffer = StringBuffer('IntegrityException: $message');
    if (constraintName != null) {
      buffer.write('\nConstraint: $constraintName');
    }
    if (tableName != null) {
      buffer.write('\nTable: $tableName');
    }
    return buffer.toString();
  }
}

class DoesNotExistException extends DatabaseException {
  final String? modelName;
  final Map<String, dynamic>? lookupArgs;

  DoesNotExistException(String message, {this.modelName, this.lookupArgs, String? code, Exception? innerException})
      : super(message, code: code, innerException: innerException);

  @override
  String toString() {
    final buffer = StringBuffer('DoesNotExistException: $message');
    if (modelName != null) {
      buffer.write('\nModel: $modelName');
    }
    if (lookupArgs != null) {
      buffer.write('\nLookup args: $lookupArgs');
    }
    return buffer.toString();
  }
}

class MultipleObjectsReturnedException extends DatabaseException {
  final String? modelName;
  final Map<String, dynamic>? lookupArgs;

  MultipleObjectsReturnedException(String message, {this.modelName, this.lookupArgs, String? code, Exception? innerException})
      : super(message, code: code, innerException: innerException);

  @override
  String toString() {
    final buffer = StringBuffer('MultipleObjectsReturnedException: $message');
    if (modelName != null) {
      buffer.write('\nModel: $modelName');
    }
    if (lookupArgs != null) {
      buffer.write('\nLookup args: $lookupArgs');
    }
    return buffer.toString();
  }
}

class FieldException extends DatabaseException {
  final String? fieldName;
  final String? modelName;

  FieldException(String message, {this.fieldName, this.modelName, String? code, Exception? innerException})
      : super(message, code: code, innerException: innerException);

  @override
  String toString() {
    final buffer = StringBuffer('FieldException: $message');
    if (fieldName != null) {
      buffer.write('\nField: $fieldName');
    }
    if (modelName != null) {
      buffer.write('\nModel: $modelName');
    }
    return buffer.toString();
  }
}

class ModelException extends DatabaseException {
  final String? modelName;
  final String? operation;

  ModelException(String message, {this.modelName, this.operation, String? code, Exception? innerException})
      : super(message, code: code, innerException: innerException);

  @override
  String toString() {
    final buffer = StringBuffer('ModelException: $message');
    if (modelName != null) {
      buffer.write('\nModel: $modelName');
    }
    if (operation != null) {
      buffer.write('\nOperation: $operation');
    }
    return buffer.toString();
  }
}

class QuerySetException extends DatabaseException {
  final String? operation;

  QuerySetException(String message, {this.operation, String? code, Exception? innerException})
      : super(message, code: code, innerException: innerException);

  @override
  String toString() {
    final buffer = StringBuffer('QuerySetException: $message');
    if (operation != null) {
      buffer.write('\nOperation: $operation');
    }
    return buffer.toString();
  }
}

class SchemaException extends DatabaseException {
  final String? tableName;
  final String? operation;

  SchemaException(String message, {this.tableName, this.operation, String? code, Exception? innerException})
      : super(message, code: code, innerException: innerException);

  @override
  String toString() {
    final buffer = StringBuffer('SchemaException: $message');
    if (tableName != null) {
      buffer.write('\nTable: $tableName');
    }
    if (operation != null) {
      buffer.write('\nOperation: $operation');
    }
    return buffer.toString();
  }
}