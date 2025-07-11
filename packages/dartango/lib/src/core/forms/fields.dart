import 'dart:async';
import 'dart:io';

// Form-specific validator interface
abstract class FormValidator<T> {
  Future<void> validate(T? value);
  String get message => 'Invalid value';
}

abstract class FormField<T> {
  final String? label;
  final String? helpText;
  final bool required;
  final T? initialValue;
  final Map<String, String> widgetAttributes;
  final List<FormValidator<T>> validators;
  final bool disabled;
  final String? errorMessage;
  final String name;

  FormField({
    required this.name,
    this.label,
    this.helpText,
    this.required = true,
    this.initialValue,
    this.widgetAttributes = const {},
    this.validators = const [],
    this.disabled = false,
    this.errorMessage,
  });

  T? clean(dynamic value);
  String toHtml({Map<String, String> attributes = const {}});
  Map<String, dynamic> toJson();

  Future<void> validate(T? value) async {
    if (required && (value == null || (value is String && value.isEmpty))) {
      throw ValidationError('This field is required.');
    }

    if (value != null) {
      for (final validator in validators) {
        await validator.validate(value);
      }
    }
  }

  String getLabel() => label ?? _humanizeName(name);

  String _humanizeName(String fieldName) {
    return fieldName
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'),
            (match) => '${match.group(1)} ${match.group(2)}')
        .split('_')
        .map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Map<String, String> _mergeAttributes(Map<String, String> additional) {
    final merged = Map<String, String>.from(widgetAttributes);
    merged.addAll(additional);
    if (disabled) merged['disabled'] = 'disabled';
    if (required) merged['required'] = 'required';
    return merged;
  }

  String _attributesToString(Map<String, String> attributes) {
    return attributes.entries
        .map((entry) => '${entry.key}="${entry.value}"')
        .join(' ');
  }
}

class CharField extends FormField<String> {
  final int? maxLength;
  final int? minLength;
  final bool stripWhitespace;

  CharField({
    required super.name,
    super.label,
    super.helpText,
    super.required = true,
    super.initialValue,
    super.widgetAttributes = const {},
    super.validators = const [],
    super.disabled = false,
    super.errorMessage,
    this.maxLength,
    this.minLength,
    this.stripWhitespace = true,
  });

  @override
  String? clean(dynamic value) {
    if (value == null) return null;

    String stringValue = value.toString();
    if (stripWhitespace) {
      stringValue = stringValue.trim();
    }

    if (stringValue.isEmpty) return null;

    if (maxLength != null && stringValue.length > maxLength!) {
      throw ValidationError(
          'Ensure this value has at most $maxLength characters (it has ${stringValue.length}).');
    }

    if (minLength != null && stringValue.length < minLength!) {
      throw ValidationError(
          'Ensure this value has at least $minLength characters (it has ${stringValue.length}).');
    }

    return stringValue;
  }

  @override
  String toHtml({Map<String, String> attributes = const {}}) {
    final attrs = _mergeAttributes(attributes);
    attrs['type'] = 'text';
    attrs['name'] = name;
    if (initialValue != null) attrs['value'] = initialValue!;
    if (maxLength != null) attrs['maxlength'] = maxLength.toString();

    return '<input ${_attributesToString(attrs)} />';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'CharField',
      'name': name,
      'label': getLabel(),
      'required': required,
      'max_length': maxLength,
      'min_length': minLength,
      'help_text': helpText,
      'initial': initialValue,
    };
  }
}

class EmailField extends CharField {
  EmailField({
    required super.name,
    super.label,
    super.helpText,
    super.required = true,
    super.initialValue,
    super.widgetAttributes = const {},
    super.validators = const [],
    super.disabled = false,
    super.errorMessage,
    super.maxLength = 254,
  });

  @override
  String? clean(dynamic value) {
    final cleanedValue = super.clean(value);
    if (cleanedValue == null) return null;

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(cleanedValue)) {
      throw ValidationError('Enter a valid email address.');
    }

    return cleanedValue;
  }

  @override
  String toHtml({Map<String, String> attributes = const {}}) {
    final attrs = _mergeAttributes(attributes);
    attrs['type'] = 'email';
    attrs['name'] = name;
    if (initialValue != null) attrs['value'] = initialValue!;

    return '<input ${_attributesToString(attrs)} />';
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = 'EmailField';
    return json;
  }
}

class PasswordField extends CharField {
  final bool renderValue;

  PasswordField({
    required super.name,
    super.label,
    super.helpText,
    super.required = true,
    super.initialValue,
    super.widgetAttributes = const {},
    super.validators = const [],
    super.disabled = false,
    super.errorMessage,
    super.maxLength,
    super.minLength,
    this.renderValue = false,
  });

  @override
  String toHtml({Map<String, String> attributes = const {}}) {
    final attrs = _mergeAttributes(attributes);
    attrs['type'] = 'password';
    attrs['name'] = name;
    if (renderValue && initialValue != null) attrs['value'] = initialValue!;

    return '<input ${_attributesToString(attrs)} />';
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = 'PasswordField';
    json['render_value'] = renderValue;
    return json;
  }
}

class IntegerField extends FormField<int> {
  final int? maxValue;
  final int? minValue;

  IntegerField({
    required super.name,
    super.label,
    super.helpText,
    super.required = true,
    super.initialValue,
    super.widgetAttributes = const {},
    super.validators = const [],
    super.disabled = false,
    super.errorMessage,
    this.maxValue,
    this.minValue,
  });

  @override
  int? clean(dynamic value) {
    if (value == null) return null;

    int? intValue;
    if (value is int) {
      intValue = value;
    } else if (value is String) {
      if (value.trim().isEmpty) return null;
      intValue = int.tryParse(value.trim());
      if (intValue == null) {
        throw ValidationError('Enter a whole number.');
      }
    } else {
      throw ValidationError('Enter a whole number.');
    }

    if (maxValue != null && intValue > maxValue!) {
      throw ValidationError(
          'Ensure this value is less than or equal to $maxValue.');
    }

    if (minValue != null && intValue < minValue!) {
      throw ValidationError(
          'Ensure this value is greater than or equal to $minValue.');
    }

    return intValue;
  }

  @override
  String toHtml({Map<String, String> attributes = const {}}) {
    final attrs = _mergeAttributes(attributes);
    attrs['type'] = 'number';
    attrs['name'] = name;
    attrs['step'] = '1';
    if (initialValue != null) attrs['value'] = initialValue.toString();
    if (maxValue != null) attrs['max'] = maxValue.toString();
    if (minValue != null) attrs['min'] = minValue.toString();

    return '<input ${_attributesToString(attrs)} />';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'IntegerField',
      'name': name,
      'label': getLabel(),
      'required': required,
      'max_value': maxValue,
      'min_value': minValue,
      'help_text': helpText,
      'initial': initialValue,
    };
  }
}

class FloatField extends FormField<double> {
  final double? maxValue;
  final double? minValue;

  FloatField({
    required super.name,
    super.label,
    super.helpText,
    super.required = true,
    super.initialValue,
    super.widgetAttributes = const {},
    super.validators = const [],
    super.disabled = false,
    super.errorMessage,
    this.maxValue,
    this.minValue,
  });

  @override
  double? clean(dynamic value) {
    if (value == null) return null;

    double? doubleValue;
    if (value is double) {
      doubleValue = value;
    } else if (value is int) {
      doubleValue = value.toDouble();
    } else if (value is String) {
      if (value.trim().isEmpty) return null;
      doubleValue = double.tryParse(value.trim());
      if (doubleValue == null) {
        throw ValidationError('Enter a number.');
      }
    } else {
      throw ValidationError('Enter a number.');
    }

    if (maxValue != null && doubleValue > maxValue!) {
      throw ValidationError(
          'Ensure this value is less than or equal to $maxValue.');
    }

    if (minValue != null && doubleValue < minValue!) {
      throw ValidationError(
          'Ensure this value is greater than or equal to $minValue.');
    }

    return doubleValue;
  }

  @override
  String toHtml({Map<String, String> attributes = const {}}) {
    final attrs = _mergeAttributes(attributes);
    attrs['type'] = 'number';
    attrs['name'] = name;
    attrs['step'] = 'any';
    if (initialValue != null) attrs['value'] = initialValue.toString();
    if (maxValue != null) attrs['max'] = maxValue.toString();
    if (minValue != null) attrs['min'] = minValue.toString();

    return '<input ${_attributesToString(attrs)} />';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'FloatField',
      'name': name,
      'label': getLabel(),
      'required': required,
      'max_value': maxValue,
      'min_value': minValue,
      'help_text': helpText,
      'initial': initialValue,
    };
  }
}

class BooleanField extends FormField<bool> {
  BooleanField({
    required super.name,
    super.label,
    super.helpText,
    super.required = false,
    super.initialValue = false,
    super.widgetAttributes = const {},
    super.validators = const [],
    super.disabled = false,
    super.errorMessage,
  });

  @override
  bool? clean(dynamic value) {
    if (value == null) return false;

    if (value is bool) return value;
    if (value is String) {
      final lowerValue = value.toLowerCase();
      if (lowerValue == 'true' || lowerValue == '1' || lowerValue == 'on')
        return true;
      if (lowerValue == 'false' ||
          lowerValue == '0' ||
          lowerValue == 'off' ||
          lowerValue.isEmpty) return false;
    }
    if (value is int) return value != 0;

    return false;
  }

  @override
  String toHtml({Map<String, String> attributes = const {}}) {
    final attrs = _mergeAttributes(attributes);
    attrs['type'] = 'checkbox';
    attrs['name'] = name;
    attrs['value'] = '1';
    if (initialValue == true) attrs['checked'] = 'checked';

    return '<input ${_attributesToString(attrs)} />';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'BooleanField',
      'name': name,
      'label': getLabel(),
      'required': required,
      'help_text': helpText,
      'initial': initialValue,
    };
  }
}

class DateTimeField extends FormField<DateTime> {
  final String inputFormat;
  final bool includeTime;

  DateTimeField({
    required super.name,
    super.label,
    super.helpText,
    super.required = true,
    super.initialValue,
    super.widgetAttributes = const {},
    super.validators = const [],
    super.disabled = false,
    super.errorMessage,
    this.inputFormat = 'yyyy-MM-dd HH:mm:ss',
    this.includeTime = true,
  });

  @override
  DateTime? clean(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is String) {
      if (value.trim().isEmpty) return null;

      try {
        return DateTime.parse(value.trim());
      } catch (e) {
        throw ValidationError('Enter a valid date/time.');
      }
    }

    throw ValidationError('Enter a valid date/time.');
  }

  @override
  String toHtml({Map<String, String> attributes = const {}}) {
    final attrs = _mergeAttributes(attributes);
    attrs['type'] = includeTime ? 'datetime-local' : 'date';
    attrs['name'] = name;
    if (initialValue != null) {
      if (includeTime) {
        attrs['value'] = initialValue!.toIso8601String().substring(0, 19);
      } else {
        attrs['value'] = initialValue!.toIso8601String().substring(0, 10);
      }
    }

    return '<input ${_attributesToString(attrs)} />';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'DateTimeField',
      'name': name,
      'label': getLabel(),
      'required': required,
      'include_time': includeTime,
      'input_format': inputFormat,
      'help_text': helpText,
      'initial': initialValue?.toIso8601String(),
    };
  }
}

class DateField extends DateTimeField {
  DateField({
    required super.name,
    super.label,
    super.helpText,
    super.required = true,
    super.initialValue,
    super.widgetAttributes = const {},
    super.validators = const [],
    super.disabled = false,
    super.errorMessage,
  }) : super(includeTime: false, inputFormat: 'yyyy-MM-dd');

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = 'DateField';
    return json;
  }
}

class ChoiceField<T> extends FormField<T> {
  final List<Choice<T>> choices;
  final bool multiple;

  ChoiceField({
    required super.name,
    required this.choices,
    super.label,
    super.helpText,
    super.required = true,
    super.initialValue,
    super.widgetAttributes = const {},
    super.validators = const [],
    super.disabled = false,
    super.errorMessage,
    this.multiple = false,
  });

  @override
  T? clean(dynamic value) {
    if (value == null) return null;

    final choice = choices.firstWhere(
      (choice) => choice.value == value,
      orElse: () => throw ValidationError(
          'Select a valid choice. $value is not one of the available choices.'),
    );

    return choice.value;
  }

  @override
  String toHtml({Map<String, String> attributes = const {}}) {
    final attrs = _mergeAttributes(attributes);
    attrs['name'] = name;
    if (multiple) attrs['multiple'] = 'multiple';

    final optionsHtml = choices.map((choice) {
      final selected =
          choice.value == initialValue ? ' selected="selected"' : '';
      return '<option value="${choice.value}"$selected>${choice.label}</option>';
    }).join('\n');

    return '<select ${_attributesToString(attrs)}>\n$optionsHtml\n</select>';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'ChoiceField',
      'name': name,
      'label': getLabel(),
      'required': required,
      'multiple': multiple,
      'choices':
          choices.map((c) => {'value': c.value, 'label': c.label}).toList(),
      'help_text': helpText,
      'initial': initialValue,
    };
  }
}

class FileField extends FormField<File> {
  final List<String> allowedExtensions;
  final int? maxSizeBytes;

  FileField({
    required super.name,
    super.label,
    super.helpText,
    super.required = true,
    super.initialValue,
    super.widgetAttributes = const {},
    super.validators = const [],
    super.disabled = false,
    super.errorMessage,
    this.allowedExtensions = const [],
    this.maxSizeBytes,
  });

  @override
  File? clean(dynamic value) {
    if (value == null) return null;

    if (value is! File) {
      throw ValidationError('Invalid file.');
    }

    final file = value;

    if (allowedExtensions.isNotEmpty) {
      final extension = file.path.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(extension)) {
        throw ValidationError(
            'File extension "$extension" is not allowed. Allowed extensions: ${allowedExtensions.join(", ")}');
      }
    }

    if (maxSizeBytes != null) {
      final size = file.lengthSync();
      if (size > maxSizeBytes!) {
        final maxSizeMB = (maxSizeBytes! / 1024 / 1024).toStringAsFixed(1);
        throw ValidationError(
            'File too large. Maximum size allowed is ${maxSizeMB}MB.');
      }
    }

    return file;
  }

  @override
  String toHtml({Map<String, String> attributes = const {}}) {
    final attrs = _mergeAttributes(attributes);
    attrs['type'] = 'file';
    attrs['name'] = name;
    if (allowedExtensions.isNotEmpty) {
      attrs['accept'] = allowedExtensions.map((ext) => '.$ext').join(',');
    }

    return '<input ${_attributesToString(attrs)} />';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'FileField',
      'name': name,
      'label': getLabel(),
      'required': required,
      'allowed_extensions': allowedExtensions,
      'max_size_bytes': maxSizeBytes,
      'help_text': helpText,
    };
  }
}

class TextAreaField extends CharField {
  final int rows;
  final int cols;

  TextAreaField({
    required super.name,
    super.label,
    super.helpText,
    super.required = true,
    super.initialValue,
    super.widgetAttributes = const {},
    super.validators = const [],
    super.disabled = false,
    super.errorMessage,
    super.maxLength,
    super.minLength,
    this.rows = 4,
    this.cols = 40,
  });

  @override
  String toHtml({Map<String, String> attributes = const {}}) {
    final attrs = _mergeAttributes(attributes);
    attrs['name'] = name;
    attrs['rows'] = rows.toString();
    attrs['cols'] = cols.toString();

    final value = initialValue ?? '';
    return '<textarea ${_attributesToString(attrs)}>$value</textarea>';
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = 'TextAreaField';
    json['rows'] = rows;
    json['cols'] = cols;
    return json;
  }
}

class Choice<T> {
  final T value;
  final String label;

  const Choice(this.value, this.label);

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Choice<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class ValidationError extends Error {
  final String message;
  final String? code;

  ValidationError(this.message, {this.code});

  @override
  String toString() => 'ValidationError: $message';
}
