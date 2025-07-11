import 'dart:convert';
import 'dart:typed_data';

import 'exceptions.dart';
import 'validators.dart';

abstract class Field<T> {
  final String? columnName;
  final T? defaultValue;
  final bool allowNull;
  final bool primaryKey;
  final bool unique;
  final bool indexed;
  final String? helpText;
  final List<Validator<T>> validators;
  final Map<String, dynamic> choices;
  final bool editable;
  final bool blank;

  const Field({
    this.columnName,
    this.defaultValue,
    this.allowNull = false,
    this.primaryKey = false,
    this.unique = false,
    this.indexed = false,
    this.helpText,
    this.validators = const [],
    this.choices = const {},
    this.editable = true,
    this.blank = false,
  });

  String get sqlType;
  String get dartType;

  T? clean(dynamic value);
  void validate(T? value);
  String toSqlValue(T? value);
  T? fromSqlValue(dynamic value);

  Map<String, dynamic> toJson() {
    return {
      'type': runtimeType.toString(),
      'column_name': columnName,
      'default_value': defaultValue,
      'allow_null': allowNull,
      'primary_key': primaryKey,
      'unique': unique,
      'indexed': indexed,
      'help_text': helpText,
      'choices': choices,
      'editable': editable,
      'blank': blank,
    };
  }

  String generateSqlDefinition(String columnName) {
    final buffer = StringBuffer();
    buffer.write('$columnName $sqlType');

    if (primaryKey) {
      buffer.write(' PRIMARY KEY');
    }

    if (!allowNull && !primaryKey) {
      buffer.write(' NOT NULL');
    }

    if (unique && !primaryKey) {
      buffer.write(' UNIQUE');
    }

    if (defaultValue != null) {
      buffer.write(' DEFAULT ${toSqlValue(defaultValue)}');
    }

    return buffer.toString();
  }
}

class AutoField extends Field<int> {
  const AutoField({
    String? columnName,
    String? helpText,
    bool editable = false,
  }) : super(
          columnName: columnName,
          primaryKey: true,
          allowNull: false,
          unique: true,
          helpText: helpText,
          editable: editable,
        );

  @override
  String get sqlType => 'INTEGER PRIMARY KEY AUTOINCREMENT';

  @override
  String get dartType => 'int';

  @override
  int? clean(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    throw ValidationException('Invalid integer value: $value');
  }

  @override
  void validate(int? value) {
    if (value != null && value < 0) {
      throw ValidationException('AutoField must be positive');
    }
  }

  @override
  String toSqlValue(int? value) => value?.toString() ?? 'NULL';

  @override
  int? fromSqlValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class IntegerField extends Field<int> {
  const IntegerField({
    String? columnName,
    int? defaultValue,
    bool allowNull = false,
    bool primaryKey = false,
    bool unique = false,
    bool indexed = false,
    String? helpText,
    List<Validator<int>> validators = const [],
    Map<String, dynamic> choices = const {},
    bool editable = true,
    bool blank = false,
  }) : super(
          columnName: columnName,
          defaultValue: defaultValue,
          allowNull: allowNull,
          primaryKey: primaryKey,
          unique: unique,
          indexed: indexed,
          helpText: helpText,
          validators: validators,
          choices: choices,
          editable: editable,
          blank: blank,
        );

  @override
  String get sqlType => 'INTEGER';

  @override
  String get dartType => 'int';

  @override
  int? clean(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    throw ValidationException('Invalid integer value: $value');
  }

  @override
  void validate(int? value) {
    if (value == null && !allowNull) {
      throw ValidationException('This field cannot be null');
    }

    if (value != null && choices.isNotEmpty && !choices.containsKey(value)) {
      throw ValidationException('Invalid choice: $value');
    }

    for (final validator in validators) {
      validator.validate(value);
    }
  }

  @override
  String toSqlValue(int? value) => value?.toString() ?? 'NULL';

  @override
  int? fromSqlValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class CharField extends Field<String> {
  final int maxLength;
  final int? minLength;

  const CharField({
    String? columnName,
    String? defaultValue,
    bool allowNull = false,
    bool primaryKey = false,
    bool unique = false,
    bool indexed = false,
    String? helpText,
    List<Validator<String>> validators = const [],
    Map<String, dynamic> choices = const {},
    bool editable = true,
    bool blank = false,
    this.maxLength = 255,
    this.minLength,
  }) : super(
          columnName: columnName,
          defaultValue: defaultValue,
          allowNull: allowNull,
          primaryKey: primaryKey,
          unique: unique,
          indexed: indexed,
          helpText: helpText,
          validators: validators,
          choices: choices,
          editable: editable,
          blank: blank,
        );

  @override
  String get sqlType => 'VARCHAR($maxLength)';

  @override
  String get dartType => 'String';

  @override
  String? clean(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  @override
  void validate(String? value) {
    if (value == null && !allowNull) {
      throw ValidationException('This field cannot be null');
    }

    if (value != null) {
      if (value.length > maxLength) {
        throw ValidationException(
            'String too long (max $maxLength characters)');
      }

      if (minLength != null && value.length < minLength!) {
        throw ValidationException(
            'String too short (min $minLength characters)');
      }

      if (choices.isNotEmpty && !choices.containsKey(value)) {
        throw ValidationException('Invalid choice: $value');
      }
    }

    for (final validator in validators) {
      validator.validate(value);
    }
  }

  @override
  String toSqlValue(String? value) =>
      value != null ? "'${value.replaceAll("'", "''")}'" : 'NULL';

  @override
  String? fromSqlValue(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }
}

class TextField extends Field<String> {
  const TextField({
    String? columnName,
    String? defaultValue,
    bool allowNull = false,
    bool primaryKey = false,
    bool unique = false,
    bool indexed = false,
    String? helpText,
    List<Validator<String>> validators = const [],
    Map<String, dynamic> choices = const {},
    bool editable = true,
    bool blank = false,
  }) : super(
          columnName: columnName,
          defaultValue: defaultValue,
          allowNull: allowNull,
          primaryKey: primaryKey,
          unique: unique,
          indexed: indexed,
          helpText: helpText,
          validators: validators,
          choices: choices,
          editable: editable,
          blank: blank,
        );

  @override
  String get sqlType => 'TEXT';

  @override
  String get dartType => 'String';

  @override
  String? clean(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  @override
  void validate(String? value) {
    if (value == null && !allowNull) {
      throw ValidationException('This field cannot be null');
    }

    if (value != null && choices.isNotEmpty && !choices.containsKey(value)) {
      throw ValidationException('Invalid choice: $value');
    }

    for (final validator in validators) {
      validator.validate(value);
    }
  }

  @override
  String toSqlValue(String? value) =>
      value != null ? "'${value.replaceAll("'", "''")}'" : 'NULL';

  @override
  String? fromSqlValue(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }
}

class BooleanField extends Field<bool> {
  const BooleanField({
    String? columnName,
    bool? defaultValue,
    bool allowNull = false,
    bool primaryKey = false,
    bool unique = false,
    bool indexed = false,
    String? helpText,
    List<Validator<bool>> validators = const [],
    Map<String, dynamic> choices = const {},
    bool editable = true,
    bool blank = false,
  }) : super(
          columnName: columnName,
          defaultValue: defaultValue,
          allowNull: allowNull,
          primaryKey: primaryKey,
          unique: unique,
          indexed: indexed,
          helpText: helpText,
          validators: validators,
          choices: choices,
          editable: editable,
          blank: blank,
        );

  @override
  String get sqlType => 'BOOLEAN';

  @override
  String get dartType => 'bool';

  @override
  bool? clean(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    throw ValidationException('Invalid boolean value: $value');
  }

  @override
  void validate(bool? value) {
    if (value == null && !allowNull) {
      throw ValidationException('This field cannot be null');
    }

    for (final validator in validators) {
      validator.validate(value);
    }
  }

  @override
  String toSqlValue(bool? value) {
    if (value == null) return 'NULL';
    return value ? 'TRUE' : 'FALSE';
  }

  @override
  bool? fromSqlValue(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return null;
  }
}

class DateTimeField extends Field<DateTime> {
  final bool autoNow;
  final bool autoNowAdd;

  const DateTimeField({
    String? columnName,
    DateTime? defaultValue,
    bool allowNull = false,
    bool primaryKey = false,
    bool unique = false,
    bool indexed = false,
    String? helpText,
    List<Validator<DateTime>> validators = const [],
    Map<String, dynamic> choices = const {},
    bool editable = true,
    bool blank = false,
    this.autoNow = false,
    this.autoNowAdd = false,
  }) : super(
          columnName: columnName,
          defaultValue: defaultValue,
          allowNull: allowNull,
          primaryKey: primaryKey,
          unique: unique,
          indexed: indexed,
          helpText: helpText,
          validators: validators,
          choices: choices,
          editable: editable,
          blank: blank,
        );

  @override
  String get sqlType => 'TIMESTAMP';

  @override
  String get dartType => 'DateTime';

  @override
  DateTime? clean(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    throw ValidationException('Invalid datetime value: $value');
  }

  @override
  void validate(DateTime? value) {
    if (value == null && !allowNull) {
      throw ValidationException('This field cannot be null');
    }

    for (final validator in validators) {
      validator.validate(value);
    }
  }

  @override
  String toSqlValue(DateTime? value) {
    if (value == null) return 'NULL';
    return "'${value.toIso8601String()}'";
  }

  @override
  DateTime? fromSqlValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}

class DateField extends Field<DateTime> {
  const DateField({
    String? columnName,
    DateTime? defaultValue,
    bool allowNull = false,
    bool primaryKey = false,
    bool unique = false,
    bool indexed = false,
    String? helpText,
    List<Validator<DateTime>> validators = const [],
    Map<String, dynamic> choices = const {},
    bool editable = true,
    bool blank = false,
  }) : super(
          columnName: columnName,
          defaultValue: defaultValue,
          allowNull: allowNull,
          primaryKey: primaryKey,
          unique: unique,
          indexed: indexed,
          helpText: helpText,
          validators: validators,
          choices: choices,
          editable: editable,
          blank: blank,
        );

  @override
  String get sqlType => 'DATE';

  @override
  String get dartType => 'DateTime';

  @override
  DateTime? clean(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return DateTime(value.year, value.month, value.day);
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null)
        return DateTime(parsed.year, parsed.month, parsed.day);
    }
    throw ValidationException('Invalid date value: $value');
  }

  @override
  void validate(DateTime? value) {
    if (value == null && !allowNull) {
      throw ValidationException('This field cannot be null');
    }

    for (final validator in validators) {
      validator.validate(value);
    }
  }

  @override
  String toSqlValue(DateTime? value) {
    if (value == null) return 'NULL';
    return "'${value.toIso8601String().split('T')[0]}'";
  }

  @override
  DateTime? fromSqlValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return DateTime(value.year, value.month, value.day);
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null)
        return DateTime(parsed.year, parsed.month, parsed.day);
    }
    return null;
  }
}

class FloatField extends Field<double> {
  const FloatField({
    String? columnName,
    double? defaultValue,
    bool allowNull = false,
    bool primaryKey = false,
    bool unique = false,
    bool indexed = false,
    String? helpText,
    List<Validator<double>> validators = const [],
    Map<String, dynamic> choices = const {},
    bool editable = true,
    bool blank = false,
  }) : super(
          columnName: columnName,
          defaultValue: defaultValue,
          allowNull: allowNull,
          primaryKey: primaryKey,
          unique: unique,
          indexed: indexed,
          helpText: helpText,
          validators: validators,
          choices: choices,
          editable: editable,
          blank: blank,
        );

  @override
  String get sqlType => 'FLOAT';

  @override
  String get dartType => 'double';

  @override
  double? clean(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    throw ValidationException('Invalid float value: $value');
  }

  @override
  void validate(double? value) {
    if (value == null && !allowNull) {
      throw ValidationException('This field cannot be null');
    }

    if (value != null && choices.isNotEmpty && !choices.containsKey(value)) {
      throw ValidationException('Invalid choice: $value');
    }

    for (final validator in validators) {
      validator.validate(value);
    }
  }

  @override
  String toSqlValue(double? value) => value?.toString() ?? 'NULL';

  @override
  double? fromSqlValue(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class DecimalField extends Field<double> {
  final int maxDigits;
  final int decimalPlaces;

  const DecimalField({
    String? columnName,
    double? defaultValue,
    bool allowNull = false,
    bool primaryKey = false,
    bool unique = false,
    bool indexed = false,
    String? helpText,
    List<Validator<double>> validators = const [],
    Map<String, dynamic> choices = const {},
    bool editable = true,
    bool blank = false,
    this.maxDigits = 10,
    this.decimalPlaces = 2,
  }) : super(
          columnName: columnName,
          defaultValue: defaultValue,
          allowNull: allowNull,
          primaryKey: primaryKey,
          unique: unique,
          indexed: indexed,
          helpText: helpText,
          validators: validators,
          choices: choices,
          editable: editable,
          blank: blank,
        );

  @override
  String get sqlType => 'DECIMAL($maxDigits,$decimalPlaces)';

  @override
  String get dartType => 'double';

  @override
  double? clean(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    throw ValidationException('Invalid decimal value: $value');
  }

  @override
  void validate(double? value) {
    if (value == null && !allowNull) {
      throw ValidationException('This field cannot be null');
    }

    if (value != null) {
      final valueStr = value.toString();
      final parts = valueStr.split('.');
      final integerPart = parts[0].replaceAll('-', '');
      final decimalPart = parts.length > 1 ? parts[1] : '';

      if (integerPart.length + decimalPart.length > maxDigits) {
        throw ValidationException('Number has too many digits');
      }

      if (decimalPart.length > decimalPlaces) {
        throw ValidationException('Number has too many decimal places');
      }
    }

    for (final validator in validators) {
      validator.validate(value);
    }
  }

  @override
  String toSqlValue(double? value) => value?.toString() ?? 'NULL';

  @override
  double? fromSqlValue(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class EmailField extends CharField {
  const EmailField({
    String? columnName,
    String? defaultValue,
    bool allowNull = false,
    bool primaryKey = false,
    bool unique = false,
    bool indexed = false,
    String? helpText,
    List<Validator<String>> validators = const [],
    Map<String, dynamic> choices = const {},
    bool editable = true,
    bool blank = false,
    int maxLength = 254,
  }) : super(
          columnName: columnName,
          defaultValue: defaultValue,
          allowNull: allowNull,
          primaryKey: primaryKey,
          unique: unique,
          indexed: indexed,
          helpText: helpText,
          validators: validators,
          choices: choices,
          editable: editable,
          blank: blank,
          maxLength: maxLength,
        );

  @override
  void validate(String? value) {
    super.validate(value);

    if (value != null && value.isNotEmpty) {
      final emailRegex =
          RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(value)) {
        throw ValidationException('Invalid email format');
      }
    }
  }
}

class URLField extends CharField {
  const URLField({
    String? columnName,
    String? defaultValue,
    bool allowNull = false,
    bool primaryKey = false,
    bool unique = false,
    bool indexed = false,
    String? helpText,
    List<Validator<String>> validators = const [],
    Map<String, dynamic> choices = const {},
    bool editable = true,
    bool blank = false,
    int maxLength = 200,
  }) : super(
          columnName: columnName,
          defaultValue: defaultValue,
          allowNull: allowNull,
          primaryKey: primaryKey,
          unique: unique,
          indexed: indexed,
          helpText: helpText,
          validators: validators,
          choices: choices,
          editable: editable,
          blank: blank,
          maxLength: maxLength,
        );

  @override
  void validate(String? value) {
    super.validate(value);

    if (value != null && value.isNotEmpty) {
      final uri = Uri.tryParse(value);
      if (uri == null || (!uri.hasScheme) || (!uri.hasAuthority)) {
        throw ValidationException('Invalid URL format');
      }
    }
  }
}

class JSONField extends Field<dynamic> {
  const JSONField({
    String? columnName,
    dynamic defaultValue,
    bool allowNull = false,
    bool primaryKey = false,
    bool unique = false,
    bool indexed = false,
    String? helpText,
    List<Validator<dynamic>> validators = const [],
    Map<String, dynamic> choices = const {},
    bool editable = true,
    bool blank = false,
  }) : super(
          columnName: columnName,
          defaultValue: defaultValue,
          allowNull: allowNull,
          primaryKey: primaryKey,
          unique: unique,
          indexed: indexed,
          helpText: helpText,
          validators: validators,
          choices: choices,
          editable: editable,
          blank: blank,
        );

  @override
  String get sqlType => 'JSON';

  @override
  String get dartType => 'dynamic';

  @override
  dynamic clean(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return jsonDecode(value);
      } catch (e) {
        throw ValidationException('Invalid JSON format');
      }
    }
    return value;
  }

  @override
  void validate(dynamic value) {
    if (value == null && !allowNull) {
      throw ValidationException('This field cannot be null');
    }

    for (final validator in validators) {
      validator.validate(value);
    }
  }

  @override
  String toSqlValue(dynamic value) {
    if (value == null) return 'NULL';
    return "'${jsonEncode(value).replaceAll("'", "''")}'";
  }

  @override
  dynamic fromSqlValue(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return jsonDecode(value);
      } catch (e) {
        return value;
      }
    }
    return value;
  }
}

class BinaryField extends Field<Uint8List> {
  const BinaryField({
    String? columnName,
    Uint8List? defaultValue,
    bool allowNull = false,
    bool primaryKey = false,
    bool unique = false,
    bool indexed = false,
    String? helpText,
    List<Validator<Uint8List>> validators = const [],
    Map<String, dynamic> choices = const {},
    bool editable = true,
    bool blank = false,
  }) : super(
          columnName: columnName,
          defaultValue: defaultValue,
          allowNull: allowNull,
          primaryKey: primaryKey,
          unique: unique,
          indexed: indexed,
          helpText: helpText,
          validators: validators,
          choices: choices,
          editable: editable,
          blank: blank,
        );

  @override
  String get sqlType => 'BLOB';

  @override
  String get dartType => 'Uint8List';

  @override
  Uint8List? clean(dynamic value) {
    if (value == null) return null;
    if (value is Uint8List) return value;
    if (value is List<int>) return Uint8List.fromList(value);
    if (value is String) return Uint8List.fromList(utf8.encode(value));
    throw ValidationException('Invalid binary value: $value');
  }

  @override
  void validate(Uint8List? value) {
    if (value == null && !allowNull) {
      throw ValidationException('This field cannot be null');
    }

    for (final validator in validators) {
      validator.validate(value);
    }
  }

  @override
  String toSqlValue(Uint8List? value) {
    if (value == null) return 'NULL';
    return "X'${value.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}'";
  }

  @override
  Uint8List? fromSqlValue(dynamic value) {
    if (value == null) return null;
    if (value is Uint8List) return value;
    if (value is List<int>) return Uint8List.fromList(value);
    if (value is String) return Uint8List.fromList(utf8.encode(value));
    return null;
  }
}

class SlugField extends CharField {
  const SlugField({
    String? columnName,
    String? defaultValue,
    bool allowNull = false,
    bool primaryKey = false,
    bool unique = false,
    bool indexed = false,
    String? helpText,
    List<Validator<String>> validators = const [],
    Map<String, dynamic> choices = const {},
    bool editable = true,
    bool blank = false,
    int maxLength = 50,
  }) : super(
          columnName: columnName,
          defaultValue: defaultValue,
          allowNull: allowNull,
          primaryKey: primaryKey,
          unique: unique,
          indexed: indexed,
          helpText: helpText,
          validators: validators,
          choices: choices,
          editable: editable,
          blank: blank,
          maxLength: maxLength,
        );

  @override
  void validate(String? value) {
    super.validate(value);

    if (value != null && value.isNotEmpty) {
      final slugRegex = RegExp(r'^[-a-zA-Z0-9_]+$');
      if (!slugRegex.hasMatch(value)) {
        throw ValidationException(
            'Invalid slug format (only letters, numbers, underscores and hyphens allowed)');
      }
    }
  }
}

class UUIDField extends Field<String> {
  const UUIDField({
    String? columnName,
    String? defaultValue,
    bool allowNull = false,
    bool primaryKey = false,
    bool unique = false,
    bool indexed = false,
    String? helpText,
    List<Validator<String>> validators = const [],
    Map<String, dynamic> choices = const {},
    bool editable = true,
    bool blank = false,
  }) : super(
          columnName: columnName,
          defaultValue: defaultValue,
          allowNull: allowNull,
          primaryKey: primaryKey,
          unique: unique,
          indexed: indexed,
          helpText: helpText,
          validators: validators,
          choices: choices,
          editable: editable,
          blank: blank,
        );

  @override
  String get sqlType => 'UUID';

  @override
  String get dartType => 'String';

  @override
  String? clean(dynamic value) {
    if (value == null) return null;
    final stringValue = value.toString();
    if (_isValidUUID(stringValue)) {
      return stringValue;
    }
    throw ValidationException('Invalid UUID format');
  }

  @override
  void validate(String? value) {
    if (value == null && !allowNull) {
      throw ValidationException('This field cannot be null');
    }

    if (value != null && !_isValidUUID(value)) {
      throw ValidationException('Invalid UUID format');
    }

    for (final validator in validators) {
      validator.validate(value);
    }
  }

  @override
  String toSqlValue(String? value) => value != null ? "'$value'" : 'NULL';

  @override
  String? fromSqlValue(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  bool _isValidUUID(String value) {
    final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(value);
  }
}
