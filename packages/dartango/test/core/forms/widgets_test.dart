import 'package:test/test.dart';
import '../../../lib/src/core/forms/widgets.dart';
import '../../../lib/src/core/forms/fields.dart';

void main() {
  group('New Widget Tests', () {
    group('URLInput', () {
      test('should render URL input type', () {
        const widget = URLInput();
        final html = widget.render('website', 'https://example.com');

        expect(html, contains('type="url"'));
        expect(html, contains('name="website"'));
        expect(html, contains('value="https://example.com"'));
      });
    });

    group('ColorInput', () {
      test('should render color input with default value', () {
        const widget = ColorInput();
        final html = widget.render('color', null);

        expect(html, contains('type="color"'));
        expect(html, contains('name="color"'));
        expect(html, contains('value="#000000"'));
      });

      test('should render color input with hex value', () {
        const widget = ColorInput();
        final html = widget.render('color', '#FF5733');

        expect(html, contains('value="#FF5733"'));
      });

      test('should default to black for invalid color', () {
        const widget = ColorInput();
        final html = widget.render('color', 'invalid');

        expect(html, contains('value="#000000"'));
      });
    });

    group('RangeInput', () {
      test('should render range input with min/max/step', () {
        const widget = RangeInput(min: 0, max: 100, step: '5');
        final html = widget.render('volume', '50');

        expect(html, contains('type="range"'));
        expect(html, contains('name="volume"'));
        expect(html, contains('value="50"'));
        expect(html, contains('min="0"'));
        expect(html, contains('max="100"'));
        expect(html, contains('step="5"'));
      });
    });

    group('NullBooleanSelect', () {
      test('should render select with Yes/No/Unknown options', () {
        const widget = NullBooleanSelect();
        final html = widget.render('agree', null);

        expect(html, contains('<select'));
        expect(html, contains('name="agree"'));
        expect(html, contains('Unknown'));
        expect(html, contains('Yes'));
        expect(html, contains('No'));
      });

      test('should select Unknown for null value', () {
        const widget = NullBooleanSelect();
        final html = widget.render('agree', null);

        expect(html, contains('value=""'));
      });

      test('should select Yes for true value', () {
        const widget = NullBooleanSelect();
        final html = widget.render('agree', true);

        expect(html, contains('selected="selected"'));
      });
    });

    group('SelectDateWidget', () {
      test('should render three select dropdowns', () {
        final widget = SelectDateWidget();
        final html = widget.render('birthdate', DateTime(1990, 5, 15));

        expect(html, contains('name="birthdate_year"'));
        expect(html, contains('name="birthdate_month"'));
        expect(html, contains('name="birthdate_day"'));
        expect(html, contains('<select'));
      });

      test('should select correct date values', () {
        final widget = SelectDateWidget();
        final html = widget.render('birthdate', DateTime(1990, 5, 15));

        expect(html, contains('value="1990"'));
        expect(html, contains('value="5"'));
        expect(html, contains('value="15"'));
      });
    });

    group('ClearableFileInput', () {
      test('should render file input without clear option when no value', () {
        const widget = ClearableFileInput();
        final html = widget.render('document', null);

        expect(html, contains('type="file"'));
        expect(html, contains('name="document"'));
        expect(html, isNot(contains('Clear')));
      });

      test('should render clear checkbox when value exists', () {
        const widget = ClearableFileInput();
        final html = widget.render('document', 'file.pdf');

        expect(html, contains('type="file"'));
        expect(html, contains('Clear'));
        expect(html, contains('Currently: file.pdf'));
        expect(html, contains('name="document_clear"'));
      });

      test('should respect showClearCheckbox setting', () {
        const widget = ClearableFileInput(showClearCheckbox: false);
        final html = widget.render('document', 'file.pdf');

        expect(html, isNot(contains('Clear')));
      });
    });

    group('MultiWidget', () {
      test('should render multiple widgets', () {
        const widget = SplitHiddenDateTimeWidget();
        final html = widget.render('appointment', DateTime(2023, 6, 15, 14, 30));

        expect(html, contains('name="appointment_date"'));
        expect(html, contains('name="appointment_time"'));
        expect(html, contains('type="date"'));
        expect(html, contains('type="hidden"'));
      });
    });

    group('SplitHiddenDateTimeWidget', () {
      test('should render visible date and hidden time', () {
        const widget = SplitHiddenDateTimeWidget();
        final html = widget.render('meeting', DateTime(2023, 12, 25, 10, 30));

        expect(html, contains('type="date"'));
        expect(html, contains('type="hidden"'));
        expect(html, contains('2023-12-25'));
        expect(html, contains('10:30'));
      });

      test('should handle null values', () {
        const widget = SplitHiddenDateTimeWidget();
        final html = widget.render('meeting', null);

        expect(html, contains('type="date"'));
        expect(html, contains('type="hidden"'));
      });
    });

    group('Widget JSON Serialization', () {
      test('URLInput should serialize to JSON', () {
        const widget = URLInput();
        final json = widget.toJson();

        expect(json['widget'], equals('URLInput'));
      });

      test('ColorInput should serialize to JSON', () {
        const widget = ColorInput();
        final json = widget.toJson();

        expect(json['widget'], equals('ColorInput'));
      });

      test('RangeInput should serialize to JSON', () {
        const widget = RangeInput(min: 0, max: 100, step: '1');
        final json = widget.toJson();

        expect(json['widget'], equals('RangeInput'));
        expect(json['min'], equals(0));
        expect(json['max'], equals(100));
        expect(json['step'], equals('1'));
      });

      test('NullBooleanSelect should serialize to JSON', () {
        const widget = NullBooleanSelect();
        final json = widget.toJson();

        expect(json['widget'], equals('NullBooleanSelect'));
      });

      test('SelectDateWidget should serialize to JSON', () {
        final widget = SelectDateWidget(startYear: 1900, endYear: 2100);
        final json = widget.toJson();

        expect(json['widget'], equals('SelectDateWidget'));
        expect(json['start_year'], equals(1900));
        expect(json['end_year'], equals(2100));
      });

      test('ClearableFileInput should serialize to JSON', () {
        const widget = ClearableFileInput(clearCheckboxLabel: 'Remove');
        final json = widget.toJson();

        expect(json['widget'], equals('ClearableFileInput'));
        expect(json['clear_checkbox_label'], equals('Remove'));
      });

      test('SplitHiddenDateTimeWidget should serialize to JSON', () {
        const widget = SplitHiddenDateTimeWidget();
        final json = widget.toJson();

        expect(json['widget'], equals('SplitHiddenDateTimeWidget'));
      });
    });
  });
}
