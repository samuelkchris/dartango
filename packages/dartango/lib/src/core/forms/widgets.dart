import 'fields.dart';

abstract class Widget {
  final Map<String, String> attributes;
  final bool isHidden;

  const Widget({
    this.attributes = const {},
    this.isHidden = false,
  });

  String render(String name, dynamic value,
      {Map<String, String> attrs = const {}});
  Map<String, dynamic> toJson();

  Map<String, String> _mergeAttributes(Map<String, String> additional) {
    final merged = Map<String, String>.from(attributes);
    merged.addAll(additional);
    return merged;
  }

  String _attributesToString(Map<String, String> attributes) {
    return attributes.entries
        .map((entry) => '${entry.key}="${_escapeHtml(entry.value)}"')
        .join(' ');
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }
}

class TextInput extends Widget {
  final String inputType;

  const TextInput({
    this.inputType = 'text',
    super.attributes,
  });

  @override
  String render(String name, dynamic value,
      {Map<String, String> attrs = const {}}) {
    final allAttrs = _mergeAttributes(attrs);
    allAttrs['type'] = inputType;
    allAttrs['name'] = name;
    if (value != null) allAttrs['value'] = value.toString();

    return '<input ${_attributesToString(allAttrs)} />';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'widget': 'TextInput',
      'input_type': inputType,
      'attributes': attributes,
    };
  }
}

class EmailInput extends TextInput {
  const EmailInput({super.attributes}) : super(inputType: 'email');

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['widget'] = 'EmailInput';
    return json;
  }
}

class PasswordInput extends TextInput {
  final bool renderValue;

  const PasswordInput({
    this.renderValue = false,
    super.attributes,
  }) : super(inputType: 'password');

  @override
  String render(String name, dynamic value,
      {Map<String, String> attrs = const {}}) {
    final allAttrs = _mergeAttributes(attrs);
    allAttrs['type'] = 'password';
    allAttrs['name'] = name;
    if (renderValue && value != null) allAttrs['value'] = value.toString();

    return '<input ${_attributesToString(allAttrs)} />';
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['widget'] = 'PasswordInput';
    json['render_value'] = renderValue;
    return json;
  }
}

class NumberInput extends TextInput {
  final num? min;
  final num? max;
  final String? step;

  const NumberInput({
    this.min,
    this.max,
    this.step,
    super.attributes,
  }) : super(inputType: 'number');

  @override
  String render(String name, dynamic value,
      {Map<String, String> attrs = const {}}) {
    final allAttrs = _mergeAttributes(attrs);
    allAttrs['type'] = 'number';
    allAttrs['name'] = name;
    if (value != null) allAttrs['value'] = value.toString();
    if (min != null) allAttrs['min'] = min.toString();
    if (max != null) allAttrs['max'] = max.toString();
    if (step != null) allAttrs['step'] = step!;

    return '<input ${_attributesToString(allAttrs)} />';
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['widget'] = 'NumberInput';
    json['min'] = min;
    json['max'] = max;
    json['step'] = step;
    return json;
  }
}

class TextArea extends Widget {
  final int rows;
  final int cols;

  const TextArea({
    this.rows = 4,
    this.cols = 40,
    super.attributes,
  });

  @override
  String render(String name, dynamic value,
      {Map<String, String> attrs = const {}}) {
    final allAttrs = _mergeAttributes(attrs);
    allAttrs['name'] = name;
    allAttrs['rows'] = rows.toString();
    allAttrs['cols'] = cols.toString();

    final textValue = value?.toString() ?? '';
    return '<textarea ${_attributesToString(allAttrs)}>${_escapeHtml(textValue)}</textarea>';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'widget': 'TextArea',
      'rows': rows,
      'cols': cols,
      'attributes': attributes,
    };
  }
}

class CheckboxInput extends Widget {
  final bool checkTest;

  const CheckboxInput({
    this.checkTest = true,
    super.attributes,
  });

  @override
  String render(String name, dynamic value,
      {Map<String, String> attrs = const {}}) {
    final allAttrs = _mergeAttributes(attrs);
    allAttrs['type'] = 'checkbox';
    allAttrs['name'] = name;
    allAttrs['value'] = '1';

    final isChecked = _isChecked(value);
    if (isChecked) allAttrs['checked'] = 'checked';

    return '<input ${_attributesToString(allAttrs)} />';
  }

  bool _isChecked(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final lowerValue = value.toLowerCase();
      return lowerValue == 'true' || lowerValue == '1' || lowerValue == 'on';
    }
    if (value is int) return value != 0;
    return false;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'widget': 'CheckboxInput',
      'check_test': checkTest,
      'attributes': attributes,
    };
  }
}

class Select extends Widget {
  final List<Choice> choices;
  final bool multiple;

  const Select({
    required this.choices,
    this.multiple = false,
    super.attributes,
  });

  @override
  String render(String name, dynamic value,
      {Map<String, String> attrs = const {}}) {
    final allAttrs = _mergeAttributes(attrs);
    allAttrs['name'] = name;
    if (multiple) allAttrs['multiple'] = 'multiple';

    final optionsHtml = choices.map((choice) {
      final isSelected = _isSelected(choice.value, value);
      final selectedAttr = isSelected ? ' selected="selected"' : '';
      return '<option value="${_escapeHtml(choice.value.toString())}"$selectedAttr>${_escapeHtml(choice.label)}</option>';
    }).join('\n');

    return '<select ${_attributesToString(allAttrs)}>\n$optionsHtml\n</select>';
  }

  bool _isSelected(dynamic choiceValue, dynamic formValue) {
    if (multiple && formValue is List) {
      return formValue.contains(choiceValue);
    }
    return choiceValue == formValue;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'widget': 'Select',
      'choices':
          choices.map((c) => {'value': c.value, 'label': c.label}).toList(),
      'multiple': multiple,
      'attributes': attributes,
    };
  }
}

class RadioSelect extends Widget {
  final List<Choice> choices;

  const RadioSelect({
    required this.choices,
    super.attributes,
  });

  @override
  String render(String name, dynamic value,
      {Map<String, String> attrs = const {}}) {
    final allAttrs = _mergeAttributes(attrs);
    final radioButtons = <String>[];

    for (int i = 0; i < choices.length; i++) {
      final choice = choices[i];
      final radioAttrs = Map<String, String>.from(allAttrs);
      radioAttrs['type'] = 'radio';
      radioAttrs['name'] = name;
      radioAttrs['value'] = choice.value.toString();
      radioAttrs['id'] = '${name}_$i';

      if (choice.value == value) {
        radioAttrs['checked'] = 'checked';
      }

      final radioHtml = '<input ${_attributesToString(radioAttrs)} />';
      final labelHtml =
          '<label for="${name}_$i">${_escapeHtml(choice.label)}</label>';
      radioButtons.add('<div class="radio-option">$radioHtml $labelHtml</div>');
    }

    return radioButtons.join('\n');
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'widget': 'RadioSelect',
      'choices':
          choices.map((c) => {'value': c.value, 'label': c.label}).toList(),
      'attributes': attributes,
    };
  }
}

class CheckboxSelectMultiple extends Widget {
  final List<Choice> choices;

  const CheckboxSelectMultiple({
    required this.choices,
    super.attributes,
  });

  @override
  String render(String name, dynamic value,
      {Map<String, String> attrs = const {}}) {
    final allAttrs = _mergeAttributes(attrs);
    final checkboxes = <String>[];
    final selectedValues =
        value is List ? value : (value != null ? [value] : []);

    for (int i = 0; i < choices.length; i++) {
      final choice = choices[i];
      final checkboxAttrs = Map<String, String>.from(allAttrs);
      checkboxAttrs['type'] = 'checkbox';
      checkboxAttrs['name'] = name;
      checkboxAttrs['value'] = choice.value.toString();
      checkboxAttrs['id'] = '${name}_$i';

      if (selectedValues.contains(choice.value)) {
        checkboxAttrs['checked'] = 'checked';
      }

      final checkboxHtml = '<input ${_attributesToString(checkboxAttrs)} />';
      final labelHtml =
          '<label for="${name}_$i">${_escapeHtml(choice.label)}</label>';
      checkboxes
          .add('<div class="checkbox-option">$checkboxHtml $labelHtml</div>');
    }

    return checkboxes.join('\n');
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'widget': 'CheckboxSelectMultiple',
      'choices':
          choices.map((c) => {'value': c.value, 'label': c.label}).toList(),
      'attributes': attributes,
    };
  }
}

class FileInput extends Widget {
  final List<String> accept;

  const FileInput({
    this.accept = const [],
    super.attributes,
  });

  @override
  String render(String name, dynamic value,
      {Map<String, String> attrs = const {}}) {
    final allAttrs = _mergeAttributes(attrs);
    allAttrs['type'] = 'file';
    allAttrs['name'] = name;

    if (accept.isNotEmpty) {
      allAttrs['accept'] = accept.join(',');
    }

    return '<input ${_attributesToString(allAttrs)} />';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'widget': 'FileInput',
      'accept': accept,
      'attributes': attributes,
    };
  }
}

class DateInput extends TextInput {
  const DateInput({super.attributes}) : super(inputType: 'date');

  @override
  String render(String name, dynamic value,
      {Map<String, String> attrs = const {}}) {
    final allAttrs = _mergeAttributes(attrs);
    allAttrs['type'] = 'date';
    allAttrs['name'] = name;

    if (value != null) {
      if (value is DateTime) {
        allAttrs['value'] = value.toIso8601String().substring(0, 10);
      } else {
        allAttrs['value'] = value.toString();
      }
    }

    return '<input ${_attributesToString(allAttrs)} />';
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['widget'] = 'DateInput';
    return json;
  }
}

class DateTimeInput extends TextInput {
  const DateTimeInput({super.attributes}) : super(inputType: 'datetime-local');

  @override
  String render(String name, dynamic value,
      {Map<String, String> attrs = const {}}) {
    final allAttrs = _mergeAttributes(attrs);
    allAttrs['type'] = 'datetime-local';
    allAttrs['name'] = name;

    if (value != null) {
      if (value is DateTime) {
        allAttrs['value'] = value.toIso8601String().substring(0, 19);
      } else {
        allAttrs['value'] = value.toString();
      }
    }

    return '<input ${_attributesToString(allAttrs)} />';
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['widget'] = 'DateTimeInput';
    return json;
  }
}

class TimeInput extends TextInput {
  const TimeInput({super.attributes}) : super(inputType: 'time');

  @override
  String render(String name, dynamic value,
      {Map<String, String> attrs = const {}}) {
    final allAttrs = _mergeAttributes(attrs);
    allAttrs['type'] = 'time';
    allAttrs['name'] = name;

    if (value != null) {
      if (value is DateTime) {
        final timeStr =
            '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
        allAttrs['value'] = timeStr;
      } else {
        allAttrs['value'] = value.toString();
      }
    }

    return '<input ${_attributesToString(allAttrs)} />';
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['widget'] = 'TimeInput';
    return json;
  }
}

class HiddenInput extends TextInput {
  const HiddenInput({super.attributes}) : super(inputType: 'hidden');

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['widget'] = 'HiddenInput';
    return json;
  }
}

class SplitDateTimeWidget extends Widget {
  final Widget dateWidget;
  final Widget timeWidget;

  const SplitDateTimeWidget({
    this.dateWidget = const DateInput(),
    this.timeWidget = const TimeInput(),
    super.attributes,
  });

  @override
  String render(String name, dynamic value,
      {Map<String, String> attrs = const {}}) {
    DateTime? dateTimeValue;
    if (value is DateTime) {
      dateTimeValue = value;
    } else if (value is String) {
      dateTimeValue = DateTime.tryParse(value);
    }

    final dateHtml =
        dateWidget.render('${name}_date', dateTimeValue, attrs: attrs);
    final timeHtml =
        timeWidget.render('${name}_time', dateTimeValue, attrs: attrs);

    return '<div class="split-datetime">$dateHtml $timeHtml</div>';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'widget': 'SplitDateTimeWidget',
      'date_widget': dateWidget.toJson(),
      'time_widget': timeWidget.toJson(),
      'attributes': attributes,
    };
  }
}

// Custom widget for multiple file uploads
class MultipleFileInput extends FileInput {
  const MultipleFileInput({super.accept, super.attributes});

  @override
  String render(String name, dynamic value,
      {Map<String, String> attrs = const {}}) {
    final allAttrs = _mergeAttributes(attrs);
    allAttrs['type'] = 'file';
    allAttrs['name'] = name;
    allAttrs['multiple'] = 'multiple';

    if (accept.isNotEmpty) {
      allAttrs['accept'] = accept.join(',');
    }

    return '<input ${_attributesToString(allAttrs)} />';
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['widget'] = 'MultipleFileInput';
    return json;
  }
}

// Widget utilities
class WidgetUtils {
  static Widget getDefaultWidget(Type fieldType) {
    switch (fieldType) {
      case CharField:
        return const TextInput();
      case EmailField:
        return const EmailInput();
      case PasswordField:
        return const PasswordInput();
      case IntegerField:
        return const NumberInput(step: '1');
      case FloatField:
        return const NumberInput(step: 'any');
      case BooleanField:
        return const CheckboxInput();
      case DateTimeField:
        return const DateTimeInput();
      case DateField:
        return const DateInput();
      case TextAreaField:
        return const TextArea();
      case FileField:
        return const FileInput();
      default:
        return const TextInput();
    }
  }

  static String renderFormField(FormField field,
      {Map<String, String> attrs = const {}}) {
    final widget = getDefaultWidget(field.runtimeType);
    return widget.render(field.name, field.initialValue, attrs: attrs);
  }
}
