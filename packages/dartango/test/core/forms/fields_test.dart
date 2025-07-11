import 'package:test/test.dart';
import 'package:dartango/src/core/forms/fields.dart';

class TestValidator<T> implements FormValidator<T> {
  final Future<void> Function(T? value) validateFunc;

  TestValidator({required this.validateFunc});

  @override
  Future<void> validate(T? value) => validateFunc(value);

  @override
  String get message => 'Validation failed';
}

void main() {
  group('CharField Tests', () {
    test('should clean valid string', () {
      final field = CharField(name: 'test');
      expect(field.clean('hello'), equals('hello'));
      expect(field.clean('  hello  '), equals('hello')); // stripped
    });

    test('should handle empty values', () {
      final field = CharField(name: 'test', required: false);
      expect(field.clean(''), isNull);
      expect(field.clean('   '), isNull);
      expect(field.clean(null), isNull);
    });

    test('should validate max length', () {
      final field = CharField(name: 'test', maxLength: 5);
      expect(() => field.clean('hello'), returnsNormally);
      expect(() => field.clean('hello world'), throwsA(isA<ValidationError>()));
    });

    test('should validate min length', () {
      final field = CharField(name: 'test', minLength: 3);
      expect(() => field.clean('hello'), returnsNormally);
      expect(() => field.clean('hi'), throwsA(isA<ValidationError>()));
    });

    test('should validate required field', () async {
      final field = CharField(name: 'test', required: true);
      await expectLater(field.validate(null), throwsA(isA<ValidationError>()));
      await expectLater(field.validate(''), throwsA(isA<ValidationError>()));
      await expectLater(field.validate('hello'), completes);
    });

    test('should generate correct HTML', () {
      final field = CharField(name: 'username', initialValue: 'john');
      final html = field.toHtml();
      expect(html, contains('type="text"'));
      expect(html, contains('name="username"'));
      expect(html, contains('value="john"'));
      expect(html, contains('required="required"'));
    });

    test('should generate correct JSON', () {
      final field = CharField(
        name: 'username',
        label: 'Username',
        maxLength: 50,
        helpText: 'Enter your username',
      );
      final json = field.toJson();
      expect(json['type'], equals('CharField'));
      expect(json['name'], equals('username'));
      expect(json['label'], equals('Username'));
      expect(json['max_length'], equals(50));
      expect(json['help_text'], equals('Enter your username'));
    });
  });

  group('EmailField Tests', () {
    test('should validate valid email addresses', () {
      final field = EmailField(name: 'email');
      expect(field.clean('test@example.com'), equals('test@example.com'));
      expect(field.clean('user.name+tag@domain.co.uk'),
          equals('user.name+tag@domain.co.uk'));
    });

    test('should reject invalid email addresses', () {
      final field = EmailField(name: 'email');
      expect(
          () => field.clean('invalid-email'), throwsA(isA<ValidationError>()));
      expect(() => field.clean('test@'), throwsA(isA<ValidationError>()));
      expect(
          () => field.clean('@example.com'), throwsA(isA<ValidationError>()));
      expect(
          () => field.clean('test@example'), throwsA(isA<ValidationError>()));
    });

    test('should generate email input HTML', () {
      final field = EmailField(name: 'email');
      final html = field.toHtml();
      expect(html, contains('type="email"'));
      expect(html, contains('name="email"'));
    });
  });

  group('PasswordField Tests', () {
    test('should clean password values', () {
      final field = PasswordField(name: 'password');
      expect(field.clean('secret123'), equals('secret123'));
    });

    test('should not render value by default', () {
      final field = PasswordField(name: 'password', initialValue: 'secret');
      final html = field.toHtml();
      expect(html, contains('type="password"'));
      expect(html, isNot(contains('value="secret"')));
    });

    test('should render value when enabled', () {
      final field = PasswordField(
          name: 'password', initialValue: 'secret', renderValue: true);
      final html = field.toHtml();
      expect(html, contains('value="secret"'));
    });
  });

  group('IntegerField Tests', () {
    test('should clean valid integers', () {
      final field = IntegerField(name: 'age');
      expect(field.clean(25), equals(25));
      expect(field.clean('25'), equals(25));
      expect(field.clean('  25  '), equals(25));
    });

    test('should reject invalid integers', () {
      final field = IntegerField(name: 'age');
      expect(() => field.clean('abc'), throwsA(isA<ValidationError>()));
      expect(() => field.clean('25.5'), throwsA(isA<ValidationError>()));
    });

    test('should validate min/max values', () {
      final field = IntegerField(name: 'age', minValue: 0, maxValue: 100);
      expect(field.clean(50), equals(50));
      expect(() => field.clean(-1), throwsA(isA<ValidationError>()));
      expect(() => field.clean(101), throwsA(isA<ValidationError>()));
    });

    test('should generate number input HTML', () {
      final field = IntegerField(name: 'age', minValue: 0, maxValue: 100);
      final html = field.toHtml();
      expect(html, contains('type="number"'));
      expect(html, contains('step="1"'));
      expect(html, contains('min="0"'));
      expect(html, contains('max="100"'));
    });
  });

  group('FloatField Tests', () {
    test('should clean valid floats', () {
      final field = FloatField(name: 'price');
      expect(field.clean(25.5), equals(25.5));
      expect(field.clean('25.5'), equals(25.5));
      expect(field.clean(25), equals(25.0));
      expect(field.clean('25'), equals(25.0));
    });

    test('should reject invalid floats', () {
      final field = FloatField(name: 'price');
      expect(() => field.clean('abc'), throwsA(isA<ValidationError>()));
    });

    test('should validate min/max values', () {
      final field = FloatField(name: 'price', minValue: 0.0, maxValue: 100.0);
      expect(field.clean(50.5), equals(50.5));
      expect(() => field.clean(-0.1), throwsA(isA<ValidationError>()));
      expect(() => field.clean(100.1), throwsA(isA<ValidationError>()));
    });
  });

  group('BooleanField Tests', () {
    test('should clean boolean values', () {
      final field = BooleanField(name: 'active');
      expect(field.clean(true), isTrue);
      expect(field.clean(false), isFalse);
      expect(field.clean('true'), isTrue);
      expect(field.clean('false'), isFalse);
      expect(field.clean('1'), isTrue);
      expect(field.clean('0'), isFalse);
      expect(field.clean('on'), isTrue);
      expect(field.clean('off'), isFalse);
      expect(field.clean(1), isTrue);
      expect(field.clean(0), isFalse);
      expect(field.clean(''), isFalse);
      expect(field.clean(null), isFalse);
    });

    test('should generate checkbox HTML', () {
      final field = BooleanField(name: 'active', initialValue: true);
      final html = field.toHtml();
      expect(html, contains('type="checkbox"'));
      expect(html, contains('value="1"'));
      expect(html, contains('checked="checked"'));
    });
  });

  group('DateTimeField Tests', () {
    test('should clean DateTime values', () {
      final field = DateTimeField(name: 'created');
      final now = DateTime.now();
      expect(field.clean(now), equals(now));
      expect(field.clean('2023-01-01T12:00:00'), isA<DateTime>());
    });

    test('should reject invalid date strings', () {
      final field = DateTimeField(name: 'created');
      expect(
          () => field.clean('invalid-date'), throwsA(isA<ValidationError>()));
    });

    test('should generate datetime input HTML', () {
      final field = DateTimeField(name: 'created');
      final html = field.toHtml();
      expect(html, contains('type="datetime-local"'));
    });
  });

  group('DateField Tests', () {
    test('should clean date values', () {
      final field = DateField(name: 'birthday');
      final date = DateTime.parse('2023-01-01');
      expect(field.clean(date), equals(date));
      expect(field.clean('2023-01-01'), isA<DateTime>());
    });

    test('should generate date input HTML', () {
      final field = DateField(name: 'birthday');
      final html = field.toHtml();
      expect(html, contains('type="date"'));
    });
  });

  group('ChoiceField Tests', () {
    test('should validate choices', () {
      final choices = [
        Choice('red', 'Red'),
        Choice('blue', 'Blue'),
        Choice('green', 'Green'),
      ];
      final field = ChoiceField(name: 'color', choices: choices);

      expect(field.clean('red'), equals('red'));
      expect(field.clean('blue'), equals('blue'));
      expect(() => field.clean('yellow'), throwsA(isA<ValidationError>()));
    });

    test('should generate select HTML', () {
      final choices = [
        Choice('red', 'Red'),
        Choice('blue', 'Blue'),
      ];
      final field =
          ChoiceField(name: 'color', choices: choices, initialValue: 'red');
      final html = field.toHtml();

      expect(html, contains('<select'));
      expect(html, contains('name="color"'));
      expect(html, contains('value="red"'));
      expect(html, contains('selected="selected"'));
      expect(html, contains('>Red</option>'));
      expect(html, contains('>Blue</option>'));
    });
  });

  group('TextAreaField Tests', () {
    test('should inherit from CharField', () {
      final field = TextAreaField(name: 'description');
      expect(field.clean('Hello world'), equals('Hello world'));
    });

    test('should generate textarea HTML', () {
      final field = TextAreaField(
        name: 'description',
        rows: 5,
        cols: 50,
        initialValue: 'Hello world',
      );
      final html = field.toHtml();

      expect(html, contains('<textarea'));
      expect(html, contains('name="description"'));
      expect(html, contains('rows="5"'));
      expect(html, contains('cols="50"'));
      expect(html, contains('>Hello world</textarea>'));
    });
  });

  group('Field Label and Help Text Tests', () {
    test('should generate label from field name', () {
      final field = CharField(name: 'firstName');
      expect(field.getLabel(), equals('First Name'));

      final field2 = CharField(name: 'user_email');
      expect(field2.getLabel(), equals('User Email'));
    });

    test('should use custom label when provided', () {
      final field = CharField(name: 'firstName', label: 'Your First Name');
      expect(field.getLabel(), equals('Your First Name'));
    });

    test('should include help text in JSON', () {
      final field = CharField(
        name: 'username',
        helpText: 'Enter a unique username',
      );
      final json = field.toJson();
      expect(json['help_text'], equals('Enter a unique username'));
    });
  });

  group('Field Validation Tests', () {
    test('should validate required fields', () async {
      final field = CharField(name: 'required_field', required: true);

      await expectLater(field.validate(null), throwsA(isA<ValidationError>()));
      await expectLater(field.validate(''), throwsA(isA<ValidationError>()));
      await expectLater(field.validate('value'), completes);
    });

    test('should allow empty values for non-required fields', () async {
      final field = CharField(name: 'optional_field', required: false);

      await expectLater(field.validate(null), completes);
      await expectLater(field.validate(''), completes);
      await expectLater(field.validate('value'), completes);
    });

    test('should run custom validators', () async {
      final customValidator = TestValidator<String>(
        validateFunc: (value) async {
          if (value != null && value.contains('bad')) {
            throw ValidationError('Value cannot contain "bad"');
          }
        },
      );

      final field = CharField(
        name: 'content',
        validators: [customValidator],
      );

      await expectLater(field.validate('good content'), completes);
      await expectLater(
          field.validate('bad content'), throwsA(isA<ValidationError>()));
    });
  });

  group('Choice Tests', () {
    test('should create choices correctly', () {
      final choice = Choice('value', 'Label');
      expect(choice.value, equals('value'));
      expect(choice.label, equals('Label'));
      expect(choice.toString(), equals('Label'));
    });

    test('should compare choices by value', () {
      final choice1 = Choice('value', 'Label 1');
      final choice2 = Choice('value', 'Label 2');
      final choice3 = Choice('other', 'Label 3');

      expect(choice1, equals(choice2));
      expect(choice1, isNot(equals(choice3)));
      expect(choice1.hashCode, equals(choice2.hashCode));
    });
  });
}
