import 'package:test/test.dart';
import 'package:dartango/src/core/forms/fields.dart';
import 'package:dartango/src/core/forms/forms.dart';

class TestContactForm extends Form {
  final CharField name = CharField(
    name: 'name',
    label: 'Full Name',
    maxLength: 100,
  );
  final EmailField email = EmailField(
    name: 'email',
    label: 'Email Address',
  );
  final IntegerField age = IntegerField(
    name: 'age',
    label: 'Age',
    minValue: 0,
    maxValue: 120,
    required: false,
  );
  final BooleanField subscribe = BooleanField(
    name: 'subscribe',
    label: 'Subscribe to newsletter',
    required: false,
  );

  TestContactForm({
    super.data,
    super.initial,
    super.prefix,
  });

  @override
  Future<void> clean() async {
    super.clean();

    // Custom form-level validation
    final nameValue = cleanedData['name'] as String?;
    final emailValue = cleanedData['email'] as String?;

    if (nameValue != null && emailValue != null) {
      if (nameValue.toLowerCase() == 'admin' && !emailValue.contains('admin')) {
        throw ValidationError('Admin users must have admin email addresses');
      }
    }
  }
}

class TestRegistrationForm extends Form {
  final CharField username = CharField(
    name: 'username',
    minLength: 3,
    maxLength: 20,
  );
  final PasswordField password = PasswordField(
    name: 'password',
    minLength: 8,
  );
  final PasswordField confirmPassword = PasswordField(
    name: 'confirm_password',
    label: 'Confirm Password',
    minLength: 8,
  );

  TestRegistrationForm({
    super.data,
    super.initial,
    super.prefix,
  });

  @override
  Future<void> clean() async {
    super.clean();

    final password = cleanedData['password'] as String?;
    final confirmPassword = cleanedData['confirm_password'] as String?;

    if (password != null &&
        confirmPassword != null &&
        password != confirmPassword) {
      throw ValidationError('Passwords do not match');
    }
  }
}

void main() {
  group('Form Basic Tests', () {
    test('should initialize form with fields', () {
      final form = TestContactForm();

      expect(form.fields.length, equals(4));
      expect(form.fields.containsKey('name'), isTrue);
      expect(form.fields.containsKey('email'), isTrue);
      expect(form.fields.containsKey('age'), isTrue);
      expect(form.fields.containsKey('subscribe'), isTrue);
    });

    test('should handle form data', () {
      final data = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'age': '30',
        'subscribe': 'true',
      };
      final form = TestContactForm(data: data);

      expect(form.getFieldValue('name'), equals('John Doe'));
      expect(form.getFieldValue('email'), equals('john@example.com'));
      expect(form.getFieldValue('age'), equals('30'));
      expect(form.getFieldValue('subscribe'), equals('true'));
    });

    test('should handle initial values', () {
      final initial = {
        'name': 'Jane Doe',
        'email': 'jane@example.com',
      };
      final form = TestContactForm(initial: initial);

      expect(form.getFieldValue('name'), equals('Jane Doe'));
      expect(form.getFieldValue('email'), equals('jane@example.com'));
      expect(form.getFieldValue('age'), isNull);
    });

    test('should prefer data over initial values', () {
      final data = {'name': 'Data Name'};
      final initial = {'name': 'Initial Name'};
      final form = TestContactForm(data: data, initial: initial);

      expect(form.getFieldValue('name'), equals('Data Name'));
    });
  });

  group('Form Validation Tests', () {
    test('should validate valid form', () async {
      final data = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'age': '30',
        'subscribe': 'true',
      };
      final form = TestContactForm(data: data);

      final isValid = await form.isValidAsync();
      expect(isValid, isTrue);
      expect(form.hasErrors, isFalse);
      expect(form.cleanedData['name'], equals('John Doe'));
      expect(form.cleanedData['email'], equals('john@example.com'));
      expect(form.cleanedData['age'], equals(30));
      expect(form.cleanedData['subscribe'], isTrue);
    });

    test('should handle field validation errors', () async {
      final data = {
        'name': '', // Required field
        'email': 'invalid-email', // Invalid email
        'age': '150', // Age too high
      };
      final form = TestContactForm(data: data);

      final isValid = await form.isValidAsync();
      expect(isValid, isFalse);
      expect(form.hasErrors, isTrue);

      expect(form.getFieldErrors('name').isNotEmpty, isTrue);
      expect(form.getFieldErrors('email').isNotEmpty, isTrue);
      expect(form.getFieldErrors('age').isNotEmpty, isTrue);
    });

    test('should handle form-level validation errors', () async {
      final data = {
        'name': 'admin',
        'email': 'user@example.com', // Admin should have admin email
      };
      final form = TestContactForm(data: data);

      final isValid = await form.isValidAsync();
      expect(isValid, isFalse);
      expect(form.getNonFieldErrors().isNotEmpty, isTrue);
      expect(form.getNonFieldErrors().first,
          contains('Admin users must have admin email'));
    });

    test('should validate passwords match', () async {
      final validData = {
        'username': 'john_doe',
        'password': 'password123',
        'confirm_password': 'password123',
      };
      final validForm = TestRegistrationForm(data: validData);

      expect(await validForm.isValidAsync(), isTrue);

      final invalidData = {
        'username': 'john_doe',
        'password': 'password123',
        'confirm_password': 'different456',
      };
      final invalidForm = TestRegistrationForm(data: invalidData);

      expect(await invalidForm.isValidAsync(), isFalse);
      expect(
          invalidForm.getNonFieldErrors(), contains('Passwords do not match'));
    });

    test('should validate only once', () async {
      final data = {
        'name': 'John Doe',
        'email': 'john@example.com',
      };
      final form = TestContactForm(data: data);

      expect(await form.isValidAsync(), isTrue);
      expect(form.isValid, isTrue); // Should use cached result

      // Manually add an error to test caching
      form.addError('test', 'Test error');
      expect(form.isValid, isTrue); // Should still return cached result
    });
  });

  group('Form Error Handling Tests', () {
    test('should add and retrieve field errors', () {
      final form = TestContactForm();

      form.addFieldError('name', 'Name is required');
      form.addFieldError('name', 'Name too short');

      final errors = form.getFieldErrors('name');
      expect(errors.length, equals(2));
      expect(errors, contains('Name is required'));
      expect(errors, contains('Name too short'));
    });

    test('should add and retrieve non-field errors', () {
      final form = TestContactForm();

      form.addNonFieldError('Form submission failed');
      form.addNonFieldError('Server error');

      final errors = form.getNonFieldErrors();
      expect(errors.length, equals(2));
      expect(errors, contains('Form submission failed'));
      expect(errors, contains('Server error'));
    });

    test('should return empty list for fields without errors', () {
      final form = TestContactForm();

      expect(form.getFieldErrors('nonexistent'), isEmpty);
      expect(form.getNonFieldErrors(), isEmpty);
    });
  });

  group('Form Rendering Tests', () {
    test('should render form as table', () {
      final data = {
        'name': 'John Doe',
        'email': 'john@example.com',
      };
      final form = TestContactForm(data: data);

      final html = form.asTable();
      expect(html, contains('<tr>'));
      expect(html, contains('<td>'));
      expect(html, contains('<label for="id_name">Full Name:</label>'));
      expect(html, contains('name="name"'));
      expect(html, contains('value="John Doe"'));
    });

    test('should render form as div', () {
      final form = TestContactForm();

      final html = form.asDiv();
      expect(html, contains('<div class="form-group">'));
      expect(html, contains('<label for="id_name">Full Name</label>'));
    });

    test('should render form as paragraphs', () {
      final form = TestContactForm();

      final html = form.asParagraph();
      expect(html, contains('<p>'));
      expect(html, contains('<label for="id_name">Full Name</label>'));
    });

    test('should render errors in HTML', () async {
      final data = {
        'name': '',
        'email': 'invalid-email',
      };
      final form = TestContactForm(data: data);
      await form.isValidAsync();

      final html = form.asDiv();
      expect(html, contains('<ul class="errorlist">'));
      expect(html, contains('<li>'));
    });

    test('should render non-field errors', () async {
      final data = {
        'name': 'admin',
        'email': 'user@example.com',
      };
      final form = TestContactForm(data: data);
      await form.isValidAsync();

      final html = form.asDiv();
      expect(html, contains('class="errorlist nonfield"'));
    });
  });

  group('Form Prefix Tests', () {
    test('should handle field name prefixes', () {
      final form = TestContactForm(prefix: 'contact');

      expect(form.getFieldName('name'), equals('contact_name'));
      expect(form.getFieldName('email'), equals('contact_email'));
    });

    test('should use prefixed field names for data lookup', () {
      final data = {
        'contact_name': 'John Doe',
        'contact_email': 'john@example.com',
      };
      final form = TestContactForm(data: data, prefix: 'contact');

      expect(form.getFieldValue('name'), equals('John Doe'));
      expect(form.getFieldValue('email'), equals('john@example.com'));
    });
  });

  group('Form JSON Serialization Tests', () {
    test('should serialize form to JSON', () async {
      final data = {
        'name': 'John Doe',
        'email': 'john@example.com',
      };
      final form = TestContactForm(data: data);
      await form.isValidAsync();

      final json = form.toJson();
      expect(json['fields'], isA<Map>());
      expect(json['errors'], isA<Map>());
      expect(json['is_valid'], isTrue);
      expect(json['has_errors'], isFalse);

      expect(json['fields']['name']['type'], equals('CharField'));
      expect(json['fields']['email']['type'], equals('EmailField'));
    });

    test('should include errors in JSON', () async {
      final data = {
        'name': '',
        'email': 'invalid',
      };
      final form = TestContactForm(data: data);
      await form.isValidAsync();

      final json = form.toJson();
      expect(json['is_valid'], isFalse);
      expect(json['has_errors'], isTrue);
      expect(json['errors'], isNotEmpty);
    });
  });

  group('Form Utility Tests', () {
    test('should parse form data string', () {
      final formData =
          'name=John+Doe&email=john%40example.com&age=30&subscribe=on';
      final parsed = Form.parseData(formData);

      expect(parsed['name'], equals('John Doe'));
      expect(parsed['email'], equals('john@example.com'));
      expect(parsed['age'], equals('30'));
      expect(parsed['subscribe'], equals('on'));
    });

    test('should handle multiple values for same key', () {
      final formData = 'tags=tag1&tags=tag2&tags=tag3';
      final parsed = Form.parseData(formData);

      expect(parsed['tags'], isA<List>());
      expect(parsed['tags'], equals(['tag1', 'tag2', 'tag3']));
    });

    test('should handle empty form data', () {
      expect(Form.parseData(''), isEmpty);
    });
  });

  group('FormUtils Tests', () {
    test('should encode form data', () {
      final data = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'tags': ['tag1', 'tag2'],
      };

      final encoded = FormUtils.encodeFormData(data);
      expect(encoded, contains('name=John%20Doe'));
      expect(encoded, contains('email=john%40example.com'));
      expect(encoded, contains('tags=tag1'));
      expect(encoded, contains('tags=tag2'));
    });

    test('should detect multipart content type', () {
      expect(FormUtils.isMultipart('multipart/form-data'), isTrue);
      expect(FormUtils.isMultipart('multipart/form-data; boundary=something'),
          isTrue);
      expect(
          FormUtils.isMultipart('application/x-www-form-urlencoded'), isFalse);
      expect(FormUtils.isMultipart(null), isFalse);
    });

    test('should generate CSRF token', () {
      final token = FormUtils.generateCsrfToken();
      expect(token.isNotEmpty, isTrue);
    });

    test('should render CSRF token HTML', () {
      final token = 'test-token';
      final html = FormUtils.renderCsrfToken(token);
      expect(html, contains('type="hidden"'));
      expect(html, contains('name="csrfmiddlewaretoken"'));
      expect(html, contains('value="test-token"'));
    });
  });
}
