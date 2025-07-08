import 'package:test/test.dart';
import 'package:dartango/src/core/urls/converters.dart';

void main() {
  group('StringConverter', () {
    late StringConverter converter;

    setUp(() {
      converter = StringConverter();
    });

    test('should have correct name and pattern', () {
      expect(converter.name, equals('str'));
      expect(converter.pattern, equals(r'[^/]+'));
    });

    test('should convert string value', () {
      final result = converter.convert('hello');
      expect(result, equals('hello'));
    });

    test('should reverse string value', () {
      final result = converter.reverse('hello');
      expect(result, equals('hello'));
    });

    test('should reverse non-string value', () {
      final result = converter.reverse(123);
      expect(result, equals('123'));
    });
  });

  group('IntConverter', () {
    late IntConverter converter;

    setUp(() {
      converter = IntConverter();
    });

    test('should have correct name and pattern', () {
      expect(converter.name, equals('int'));
      expect(converter.pattern, equals(r'[0-9]+'));
    });

    test('should convert valid integer string', () {
      final result = converter.convert('123');
      expect(result, equals(123));
    });

    test('should convert zero', () {
      final result = converter.convert('0');
      expect(result, equals(0));
    });

    test('should throw on invalid integer string', () {
      expect(() => converter.convert('abc'), throwsArgumentError);
    });

    test('should throw on negative number', () {
      expect(() => converter.convert('-123'), throwsArgumentError);
    });

    test('should reverse integer value', () {
      final result = converter.reverse(123);
      expect(result, equals('123'));
    });

    test('should throw on non-integer reverse', () {
      expect(() => converter.reverse('abc'), throwsArgumentError);
    });
  });

  group('SlugConverter', () {
    late SlugConverter converter;

    setUp(() {
      converter = SlugConverter();
    });

    test('should have correct name and pattern', () {
      expect(converter.name, equals('slug'));
      expect(converter.pattern, equals(r'[-a-zA-Z0-9_]+'));
    });

    test('should convert valid slug', () {
      final result = converter.convert('hello-world');
      expect(result, equals('hello-world'));
    });

    test('should convert slug with underscores', () {
      final result = converter.convert('hello_world');
      expect(result, equals('hello_world'));
    });

    test('should convert slug with numbers', () {
      final result = converter.convert('hello123');
      expect(result, equals('hello123'));
    });

    test('should throw on invalid slug', () {
      expect(() => converter.convert('hello world'), throwsArgumentError);
      expect(() => converter.convert('hello@world'), throwsArgumentError);
      expect(() => converter.convert('hello/world'), throwsArgumentError);
    });

    test('should reverse valid slug', () {
      final result = converter.reverse('hello-world');
      expect(result, equals('hello-world'));
    });

    test('should throw on invalid slug reverse', () {
      expect(() => converter.reverse('hello world'), throwsArgumentError);
    });
  });

  group('UuidConverter', () {
    late UuidConverter converter;

    setUp(() {
      converter = UuidConverter();
    });

    test('should have correct name and pattern', () {
      expect(converter.name, equals('uuid'));
      expect(converter.pattern, equals(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'));
    });

    test('should convert valid UUID', () {
      final uuid = '123e4567-e89b-12d3-a456-426614174000';
      final result = converter.convert(uuid);
      expect(result, equals(uuid));
    });

    test('should convert uppercase UUID to lowercase', () {
      final uuid = '123E4567-E89B-12D3-A456-426614174000';
      final result = converter.convert(uuid);
      expect(result, equals('123e4567-e89b-12d3-a456-426614174000'));
    });

    test('should throw on invalid UUID', () {
      expect(() => converter.convert('invalid-uuid'), throwsArgumentError);
      expect(() => converter.convert('123e4567-e89b-12d3-a456'), throwsArgumentError);
    });

    test('should reverse valid UUID', () {
      final uuid = '123e4567-e89b-12d3-a456-426614174000';
      final result = converter.reverse(uuid);
      expect(result, equals(uuid));
    });

    test('should reverse uppercase UUID to lowercase', () {
      final uuid = '123E4567-E89B-12D3-A456-426614174000';
      final result = converter.reverse(uuid);
      expect(result, equals('123e4567-e89b-12d3-a456-426614174000'));
    });

    test('should throw on invalid UUID reverse', () {
      expect(() => converter.reverse('invalid-uuid'), throwsArgumentError);
    });
  });

  group('PathPathConverter', () {
    late PathPathConverter converter;

    setUp(() {
      converter = PathPathConverter();
    });

    test('should have correct name and pattern', () {
      expect(converter.name, equals('path'));
      expect(converter.pattern, equals(r'.+'));
    });

    test('should convert any path', () {
      final result = converter.convert('path/to/resource');
      expect(result, equals('path/to/resource'));
    });

    test('should convert path with special characters', () {
      final result = converter.convert('path/to/resource?query=value');
      expect(result, equals('path/to/resource?query=value'));
    });

    test('should reverse any path', () {
      final result = converter.reverse('path/to/resource');
      expect(result, equals('path/to/resource'));
    });
  });

  group('FloatConverter', () {
    late FloatConverter converter;

    setUp(() {
      converter = FloatConverter();
    });

    test('should have correct name and pattern', () {
      expect(converter.name, equals('float'));
      expect(converter.pattern, equals(r'[0-9]+(?:\.[0-9]+)?'));
    });

    test('should convert valid float string', () {
      final result = converter.convert('123.45');
      expect(result, equals(123.45));
    });

    test('should convert integer string to double', () {
      final result = converter.convert('123');
      expect(result, equals(123.0));
    });

    test('should throw on invalid float string', () {
      expect(() => converter.convert('abc'), throwsArgumentError);
    });

    test('should reverse double value', () {
      final result = converter.reverse(123.45);
      expect(result, equals('123.45'));
    });

    test('should reverse integer value', () {
      final result = converter.reverse(123);
      expect(result, equals('123'));
    });

    test('should throw on non-numeric reverse', () {
      expect(() => converter.reverse('abc'), throwsArgumentError);
    });
  });

  group('BoolConverter', () {
    late BoolConverter converter;

    setUp(() {
      converter = BoolConverter();
    });

    test('should have correct name and pattern', () {
      expect(converter.name, equals('bool'));
      expect(converter.pattern, equals(r'(?:true|false|1|0)'));
    });

    test('should convert true values', () {
      expect(converter.convert('true'), isTrue);
      expect(converter.convert('TRUE'), isTrue);
      expect(converter.convert('1'), isTrue);
    });

    test('should convert false values', () {
      expect(converter.convert('false'), isFalse);
      expect(converter.convert('FALSE'), isFalse);
      expect(converter.convert('0'), isFalse);
    });

    test('should throw on invalid boolean string', () {
      expect(() => converter.convert('invalid'), throwsArgumentError);
      expect(() => converter.convert('yes'), throwsArgumentError);
    });

    test('should reverse boolean values', () {
      expect(converter.reverse(true), equals('true'));
      expect(converter.reverse(false), equals('false'));
    });

    test('should throw on non-boolean reverse', () {
      expect(() => converter.reverse('true'), throwsArgumentError);
      expect(() => converter.reverse(1), throwsArgumentError);
    });
  });

  group('AlphaConverter', () {
    late AlphaConverter converter;

    setUp(() {
      converter = AlphaConverter();
    });

    test('should have correct name and pattern', () {
      expect(converter.name, equals('alpha'));
      expect(converter.pattern, equals(r'[a-zA-Z]+'));
    });

    test('should convert valid alpha string', () {
      final result = converter.convert('hello');
      expect(result, equals('hello'));
    });

    test('should convert mixed case alpha string', () {
      final result = converter.convert('HelloWorld');
      expect(result, equals('HelloWorld'));
    });

    test('should throw on string with numbers', () {
      expect(() => converter.convert('hello123'), throwsArgumentError);
    });

    test('should throw on string with special characters', () {
      expect(() => converter.convert('hello-world'), throwsArgumentError);
    });

    test('should reverse valid alpha string', () {
      final result = converter.reverse('hello');
      expect(result, equals('hello'));
    });

    test('should throw on invalid alpha reverse', () {
      expect(() => converter.reverse('hello123'), throwsArgumentError);
    });
  });

  group('PathConverter.getConverter', () {
    test('should return correct converter instances', () {
      expect(PathConverter.getConverter('str'), isA<StringConverter>());
      expect(PathConverter.getConverter('int'), isA<IntConverter>());
      expect(PathConverter.getConverter('slug'), isA<SlugConverter>());
      expect(PathConverter.getConverter('uuid'), isA<UuidConverter>());
      expect(PathConverter.getConverter('path'), isA<PathPathConverter>());
    });

    test('should default to StringConverter for unknown types', () {
      expect(PathConverter.getConverter('unknown'), isA<StringConverter>());
    });
  });

  group('HexConverter', () {
    late HexConverter converter;

    setUp(() {
      converter = HexConverter();
    });

    test('should have correct name and pattern', () {
      expect(converter.name, equals('hex'));
      expect(converter.pattern, equals(r'[0-9a-fA-F]+'));
    });

    test('should convert valid hex string', () {
      expect(converter.convert('ff'), equals(255));
      expect(converter.convert('FF'), equals(255));
      expect(converter.convert('123'), equals(291));
    });

    test('should throw on invalid hex string', () {
      expect(() => converter.convert('xyz'), throwsArgumentError);
    });

    test('should reverse integer to hex', () {
      expect(converter.reverse(255), equals('ff'));
      expect(converter.reverse(291), equals('123'));
    });

    test('should throw on non-integer reverse', () {
      expect(() => converter.reverse('ff'), throwsArgumentError);
    });
  });

  group('EmailConverter', () {
    late EmailConverter converter;

    setUp(() {
      converter = EmailConverter();
    });

    test('should have correct name and pattern', () {
      expect(converter.name, equals('email'));
      expect(converter.pattern, equals(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'));
    });

    test('should convert valid email', () {
      final email = 'test@example.com';
      expect(converter.convert(email), equals(email));
    });

    test('should convert email with subdomains', () {
      final email = 'test@mail.example.com';
      expect(converter.convert(email), equals(email));
    });

    test('should throw on invalid email', () {
      expect(() => converter.convert('invalid-email'), throwsArgumentError);
      expect(() => converter.convert('test@'), throwsArgumentError);
      expect(() => converter.convert('@example.com'), throwsArgumentError);
    });

    test('should reverse valid email', () {
      final email = 'test@example.com';
      expect(converter.reverse(email), equals(email));
    });

    test('should throw on invalid email reverse', () {
      expect(() => converter.reverse('invalid-email'), throwsArgumentError);
    });
  });
}