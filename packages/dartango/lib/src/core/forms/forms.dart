import 'dart:async';
import 'dart:mirrors';

import 'fields.dart';

abstract class Form {
  final Map<String, FormField> _fields = {};
  final Map<String, List<String>> _errors = {};
  final Map<String, dynamic> _cleanedData = {};
  final Map<String, dynamic> _data;
  final String? prefix;
  final Map<String, dynamic> _initial;
  bool _isValid = false;
  bool _hasValidated = false;

  Form({
    Map<String, dynamic> data = const {},
    Map<String, dynamic> initial = const {},
    this.prefix,
  })  : _data = Map<String, dynamic>.from(data),
        _initial = Map<String, dynamic>.from(initial) {
    _initializeFields();
  }

  void _initializeFields() {
    final mirror = reflect(this);
    final classMirror = mirror.type;

    for (final declaration in classMirror.declarations.values) {
      if (declaration is VariableMirror) {
        final fieldName = MirrorSystem.getName(declaration.simpleName);
        final field = mirror.getField(declaration.simpleName).reflectee;

        if (field is FormField) {
          _fields[fieldName] = field;
        }
      }
    }
  }

  Map<String, FormField> get fields => Map.unmodifiable(_fields);
  Map<String, List<String>> get errors => Map.unmodifiable(_errors);
  Map<String, dynamic> get cleanedData => Map.unmodifiable(_cleanedData);
  Map<String, dynamic> get data => Map.unmodifiable(_data);
  bool get isValid => _hasValidated && _isValid;
  bool get hasErrors => _errors.isNotEmpty;

  String? getFieldName(String name) {
    return prefix != null ? '${prefix}_$name' : name;
  }

  dynamic getFieldValue(String fieldName) {
    final fullName = getFieldName(fieldName);
    return _data[fullName] ?? _initial[fieldName];
  }

  void addError(String fieldName, String error) {
    _errors.putIfAbsent(fieldName, () => []).add(error);
    if (!_hasValidated) {
      _isValid = false;
    }
  }

  void addFieldError(String fieldName, String error) {
    addError(fieldName, error);
  }

  void addNonFieldError(String error) {
    addError('__all__', error);
  }

  List<String> getFieldErrors(String fieldName) {
    return _errors[fieldName] ?? [];
  }

  List<String> getNonFieldErrors() {
    return _errors['__all__'] ?? [];
  }

  Future<bool> isValidAsync() async {
    if (_hasValidated) return _isValid;

    _errors.clear();
    _cleanedData.clear();
    _isValid = true;

    // Clean and validate each field
    for (final entry in _fields.entries) {
      final field = entry.value;
      final fieldName = field.name;

      try {
        final rawValue = getFieldValue(fieldName);
        final cleanedValue = field.clean(rawValue);

        // Validate cleaned value
        await field.validate(cleanedValue);

        _cleanedData[fieldName] = cleanedValue;
      } catch (e) {
        final errorMessage = e is ValidationError ? e.message : e.toString();
        addFieldError(fieldName, errorMessage);
      }
    }

    // Run form-level validation
    if (_isValid) {
      try {
        await clean();
      } catch (e) {
        final errorMessage = e is ValidationError ? e.message : e.toString();
        addNonFieldError(errorMessage);
      }
    }

    _hasValidated = true;
    return _isValid;
  }

  Future<void> clean() async {
    // Override in subclasses for form-level validation
  }

  String _renderField(FormField field, String fieldName, dynamic value) {
    // Create a copy of the field with the current value for rendering
    if (field is CharField) {
      return _renderCharField(field, fieldName, value);
    } else if (field is IntegerField) {
      return _renderIntegerField(field, fieldName, value);
    } else if (field is FloatField) {
      return _renderFloatField(field, fieldName, value);
    } else if (field is BooleanField) {
      return _renderBooleanField(field, fieldName, value);
    } else if (field is DateTimeField) {
      return _renderDateTimeField(field, fieldName, value);
    } else if (field is ChoiceField) {
      return _renderChoiceField(field, fieldName, value);
    } else if (field is FileField) {
      return _renderFileField(field, fieldName, value);
    }
    return field.toHtml(attributes: {'id': 'id_$fieldName'});
  }

  String _renderCharField(CharField field, String fieldName, dynamic value) {
    final attrs = <String, String>{
      'id': 'id_$fieldName',
      'type': field is PasswordField ? 'password' : (field is EmailField ? 'email' : 'text'),
      'name': fieldName,
    };
    if (value != null) attrs['value'] = value.toString();
    if (field.maxLength != null) attrs['maxlength'] = field.maxLength.toString();
    if (field.disabled) attrs['disabled'] = 'disabled';
    if (field.required) attrs['required'] = 'required';

    if (field is TextAreaField) {
      attrs.remove('type');
      attrs.remove('value');
      attrs['rows'] = field.rows.toString();
      attrs['cols'] = field.cols.toString();
      final content = value?.toString() ?? '';
      return '<textarea ${_attributesToString(attrs)}>$content</textarea>';
    }

    return '<input ${_attributesToString(attrs)} />';
  }

  String _renderIntegerField(IntegerField field, String fieldName, dynamic value) {
    final attrs = <String, String>{
      'id': 'id_$fieldName',
      'type': 'number',
      'name': fieldName,
      'step': '1',
    };
    if (value != null) attrs['value'] = value.toString();
    if (field.maxValue != null) attrs['max'] = field.maxValue.toString();
    if (field.minValue != null) attrs['min'] = field.minValue.toString();
    if (field.disabled) attrs['disabled'] = 'disabled';
    if (field.required) attrs['required'] = 'required';

    return '<input ${_attributesToString(attrs)} />';
  }

  String _renderFloatField(FloatField field, String fieldName, dynamic value) {
    final attrs = <String, String>{
      'id': 'id_$fieldName',
      'type': 'number',
      'name': fieldName,
      'step': 'any',
    };
    if (value != null) attrs['value'] = value.toString();
    if (field.maxValue != null) attrs['max'] = field.maxValue.toString();
    if (field.minValue != null) attrs['min'] = field.minValue.toString();
    if (field.disabled) attrs['disabled'] = 'disabled';
    if (field.required) attrs['required'] = 'required';

    return '<input ${_attributesToString(attrs)} />';
  }

  String _renderBooleanField(BooleanField field, String fieldName, dynamic value) {
    final attrs = <String, String>{
      'id': 'id_$fieldName',
      'type': 'checkbox',
      'name': fieldName,
      'value': '1',
    };
    if (value == true || value == 'true' || value == '1' || value == 'on') {
      attrs['checked'] = 'checked';
    }
    if (field.disabled) attrs['disabled'] = 'disabled';

    return '<input ${_attributesToString(attrs)} />';
  }

  String _renderDateTimeField(DateTimeField field, String fieldName, dynamic value) {
    final attrs = <String, String>{
      'id': 'id_$fieldName',
      'type': field.includeTime ? 'datetime-local' : 'date',
      'name': fieldName,
    };
    if (value != null) {
      if (value is DateTime) {
        if (field.includeTime) {
          attrs['value'] = value.toIso8601String().substring(0, 19);
        } else {
          attrs['value'] = value.toIso8601String().substring(0, 10);
        }
      } else {
        attrs['value'] = value.toString();
      }
    }
    if (field.disabled) attrs['disabled'] = 'disabled';
    if (field.required) attrs['required'] = 'required';

    return '<input ${_attributesToString(attrs)} />';
  }

  String _renderChoiceField(ChoiceField field, String fieldName, dynamic value) {
    final attrs = <String, String>{
      'id': 'id_$fieldName',
      'name': fieldName,
    };
    if (field.multiple) attrs['multiple'] = 'multiple';
    if (field.disabled) attrs['disabled'] = 'disabled';

    final optionsHtml = field.choices.map((choice) {
      final selected = choice.value == value ? ' selected="selected"' : '';
      return '<option value="${choice.value}"$selected>${choice.label}</option>';
    }).join('\n');

    return '<select ${_attributesToString(attrs)}>\n$optionsHtml\n</select>';
  }

  String _renderFileField(FileField field, String fieldName, dynamic value) {
    final attrs = <String, String>{
      'id': 'id_$fieldName',
      'type': 'file',
      'name': fieldName,
    };
    if (field.allowedExtensions.isNotEmpty) {
      attrs['accept'] = field.allowedExtensions.map((ext) => '.$ext').join(',');
    }
    if (field.disabled) attrs['disabled'] = 'disabled';
    if (field.required) attrs['required'] = 'required';

    return '<input ${_attributesToString(attrs)} />';
  }

  String _attributesToString(Map<String, String> attributes) {
    return attributes.entries
        .map((entry) => '${entry.key}="${entry.value}"')
        .join(' ');
  }

  String asTable() {
    final buffer = StringBuffer();

    for (final entry in _fields.entries) {
      final field = entry.value;
      final fieldName = field.name;
      final fieldErrors = getFieldErrors(fieldName);
      final fieldValue = getFieldValue(fieldName);

      buffer.writeln('<tr>');
      buffer.writeln(
          '<td><label for="id_$fieldName">${field.getLabel()}:</label></td>');
      buffer.writeln('<td>');

      if (fieldErrors.isNotEmpty) {
        buffer.writeln('<ul class="errorlist">');
        for (final error in fieldErrors) {
          buffer.writeln('<li>$error</li>');
        }
        buffer.writeln('</ul>');
      }

      buffer.writeln(_renderField(field, fieldName, fieldValue));

      if (field.helpText != null) {
        buffer.writeln('<div class="helptext">${field.helpText}</div>');
      }

      buffer.writeln('</td>');
      buffer.writeln('</tr>');
    }

    final nonFieldErrors = getNonFieldErrors();
    if (nonFieldErrors.isNotEmpty) {
      buffer.writeln('<tr>');
      buffer.writeln('<td colspan="2">');
      buffer.writeln('<ul class="errorlist nonfield">');
      for (final error in nonFieldErrors) {
        buffer.writeln('<li>$error</li>');
      }
      buffer.writeln('</ul>');
      buffer.writeln('</td>');
      buffer.writeln('</tr>');
    }

    return buffer.toString();
  }

  String asDiv() {
    final buffer = StringBuffer();

    final nonFieldErrors = getNonFieldErrors();
    if (nonFieldErrors.isNotEmpty) {
      buffer.writeln('<div class="errorlist nonfield">');
      buffer.writeln('<ul>');
      for (final error in nonFieldErrors) {
        buffer.writeln('<li>$error</li>');
      }
      buffer.writeln('</ul>');
      buffer.writeln('</div>');
    }

    for (final entry in _fields.entries) {
      final field = entry.value;
      final fieldName = field.name;
      final fieldErrors = getFieldErrors(fieldName);
      final fieldValue = getFieldValue(fieldName);

      buffer.writeln('<div class="form-group">');
      buffer.writeln('<label for="id_$fieldName">${field.getLabel()}</label>');

      if (fieldErrors.isNotEmpty) {
        buffer.writeln('<ul class="errorlist">');
        for (final error in fieldErrors) {
          buffer.writeln('<li>$error</li>');
        }
        buffer.writeln('</ul>');
      }

      buffer.writeln(_renderField(field, fieldName, fieldValue));

      if (field.helpText != null) {
        buffer.writeln('<div class="helptext">${field.helpText}</div>');
      }

      buffer.writeln('</div>');
    }

    return buffer.toString();
  }

  String asParagraph() {
    final buffer = StringBuffer();

    final nonFieldErrors = getNonFieldErrors();
    if (nonFieldErrors.isNotEmpty) {
      buffer.writeln('<div class="errorlist nonfield">');
      buffer.writeln('<ul>');
      for (final error in nonFieldErrors) {
        buffer.writeln('<li>$error</li>');
      }
      buffer.writeln('</ul>');
      buffer.writeln('</div>');
    }

    for (final entry in _fields.entries) {
      final field = entry.value;
      final fieldName = field.name;
      final fieldErrors = getFieldErrors(fieldName);
      final fieldValue = getFieldValue(fieldName);

      buffer.writeln('<p>');
      buffer.writeln('<label for="id_$fieldName">${field.getLabel()}</label>');

      if (fieldErrors.isNotEmpty) {
        buffer.writeln('<ul class="errorlist">');
        for (final error in fieldErrors) {
          buffer.writeln('<li>$error</li>');
        }
        buffer.writeln('</ul>');
      }

      buffer.writeln(_renderField(field, fieldName, fieldValue));

      if (field.helpText != null) {
        buffer.writeln('<span class="helptext">${field.helpText}</span>');
      }

      buffer.writeln('</p>');
    }

    return buffer.toString();
  }

  @override
  String toString() => asTable();

  Map<String, dynamic> toJson() {
    return {
      'fields': _fields.map((key, field) => MapEntry(key, field.toJson())),
      'errors': _errors,
      'is_valid': isValid,
      'has_errors': hasErrors,
    };
  }

  static Map<String, dynamic> parseData(String formData) {
    final data = <String, dynamic>{};

    if (formData.isEmpty) return data;

    final pairs = formData.split('&');
    for (final pair in pairs) {
      final keyValue = pair.split('=');
      if (keyValue.length == 2) {
        final key = Uri.decodeComponent(keyValue[0].replaceAll('+', ' '));
        final value = Uri.decodeComponent(keyValue[1].replaceAll('+', ' '));

        // Handle multiple values for the same key (e.g., checkboxes)
        if (data.containsKey(key)) {
          final existing = data[key];
          if (existing is List) {
            existing.add(value);
          } else {
            data[key] = [existing, value];
          }
        } else {
          data[key] = value;
        }
      }
    }

    return data;
  }
}

class ModelForm<T> extends Form {
  final Type modelType;
  final T? instance;
  final List<String>? fieldsToInclude;
  final List<String>? exclude;

  ModelForm({
    required this.modelType,
    this.instance,
    this.fieldsToInclude,
    this.exclude,
    super.data,
    super.initial,
    super.prefix,
  });

  @override
  void _initializeFields() {
    super._initializeFields();

    // Auto-generate fields from model if no explicit fields defined
    if (_fields.isEmpty) {
      _generateFieldsFromModel();
    }

    // Set initial values from instance
    if (instance != null) {
      _setInitialFromInstance();
    }
  }

  void _generateFieldsFromModel() {
    // This would integrate with the ORM to auto-generate form fields
    // For now, this is a placeholder that would need model introspection
  }

  void _setInitialFromInstance() {
    // Set initial values from model instance
    // This would use reflection to get values from the model instance
  }

  Future<T> save({bool commit = true}) async {
    if (!isValid) {
      throw FormError('Cannot save invalid form');
    }

    // This would integrate with the ORM to save the model instance
    // For now, this is a placeholder
    throw UnimplementedError('ModelForm.save() requires ORM integration');
  }
}

class FormSet {
  final List<Form> forms;
  final int total;
  final int initial;
  final int min;
  final int max;
  final String prefix;
  final bool canDelete;
  final bool canOrder;

  FormSet({
    required this.forms,
    this.total = 0,
    this.initial = 0,
    this.min = 0,
    this.max = 1000,
    this.prefix = 'form',
    this.canDelete = false,
    this.canOrder = false,
  });

  bool get isValid {
    return forms.every((form) => form.isValid);
  }

  List<Map<String, List<String>>> get errors {
    return forms.map((form) => form.errors).toList();
  }

  Map<String, dynamic> get cleanedData {
    return {
      'forms': forms.map((form) => form.cleanedData).toList(),
    };
  }

  Future<bool> isValidAsync() async {
    final results = await Future.wait(
      forms.map((form) => form.isValidAsync()),
    );
    return results.every((result) => result);
  }

  String asTable() {
    final buffer = StringBuffer();
    buffer.writeln('<table>');

    for (int i = 0; i < forms.length; i++) {
      final form = forms[i];
      buffer.writeln('<tr><td colspan="2"><h3>Form ${i + 1}</h3></td></tr>');
      buffer.writeln(form.asTable());
    }

    buffer.writeln('</table>');
    return buffer.toString();
  }

  String asDiv() {
    final buffer = StringBuffer();

    for (int i = 0; i < forms.length; i++) {
      final form = forms[i];
      buffer.writeln('<div class="formset-form">');
      buffer.writeln('<h3>Form ${i + 1}</h3>');
      buffer.writeln(form.asDiv());
      buffer.writeln('</div>');
    }

    return buffer.toString();
  }

  @override
  String toString() => asDiv();
}

class FormError extends Error {
  final String message;

  FormError(this.message);

  @override
  String toString() => 'FormError: $message';
}

// Utility functions for form handling
class FormUtils {
  static Map<String, dynamic> parseQueryString(String queryString) {
    return Form.parseData(queryString);
  }

  static Map<String, dynamic> parseFormData(String formData) {
    return Form.parseData(formData);
  }

  static String encodeFormData(Map<String, dynamic> data) {
    final pairs = <String>[];

    for (final entry in data.entries) {
      final key = Uri.encodeComponent(entry.key);
      final value = entry.value;

      if (value is List) {
        for (final item in value) {
          pairs.add('$key=${Uri.encodeComponent(item.toString())}');
        }
      } else {
        pairs.add('$key=${Uri.encodeComponent(value.toString())}');
      }
    }

    return pairs.join('&');
  }

  static bool isMultipart(String? contentType) {
    return contentType?.toLowerCase().startsWith('multipart/form-data') ??
        false;
  }

  static String generateCsrfToken() {
    // Generate a random CSRF token
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return random; // In production, use crypto-secure random
  }

  static String renderCsrfToken(String token) {
    return '<input type="hidden" name="csrfmiddlewaretoken" value="$token" />';
  }
}
