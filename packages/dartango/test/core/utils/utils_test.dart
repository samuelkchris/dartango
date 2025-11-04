import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';

import '../../../lib/src/core/utils/crypto.dart';
import '../../../lib/src/core/utils/encoding.dart';

void main() {
  group('SecureKeyGenerator', () {
    test('should generate secret key with default length', () {
      final key = SecureKeyGenerator.generateSecretKey();

      expect(key, isNotEmpty);
      expect(key.length, equals(50));
    });

    test('should generate secret key with custom length', () {
      final key = SecureKeyGenerator.generateSecretKey(length: 100);

      expect(key.length, equals(100));
    });

    test('should generate unique keys', () {
      final key1 = SecureKeyGenerator.generateSecretKey();
      final key2 = SecureKeyGenerator.generateSecretKey();

      expect(key1, isNot(equals(key2)));
    });

    test('should generate token', () {
      final token = SecureKeyGenerator.generateToken();

      expect(token, isNotEmpty);
      expect(token, isA<String>());
    });

    test('should generate tokens with custom length', () {
      final token = SecureKeyGenerator.generateToken(length: 64);

      expect(token, isNotEmpty);
    });

    test('should generate URL-safe token', () {
      final token = SecureKeyGenerator.generateUrlSafeToken();

      expect(token, isNotEmpty);
      expect(token.length, equals(32));
      expect(RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(token), isTrue);
    });

    test('should generate hex token', () {
      final token = SecureKeyGenerator.generateHexToken();

      expect(token, isNotEmpty);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(token), isTrue);
      expect(token.length, equals(64));
    });

    test('should generate Django-style secret key', () {
      final key = SecureKeyGenerator.generateDjangoSecretKey();

      expect(key.length, equals(50));
    });

    test('should identify weak keys', () {
      expect(SecureKeyGenerator.isSecureKey('default-secret-key'), isFalse);
      expect(SecureKeyGenerator.isSecureKey('your-secret-key-here'), isFalse);
      expect(SecureKeyGenerator.isSecureKey('change-me'), isFalse);
      expect(SecureKeyGenerator.isSecureKey('secret'), isFalse);
      expect(SecureKeyGenerator.isSecureKey('password'), isFalse);
      expect(SecureKeyGenerator.isSecureKey('123456'), isFalse);
      expect(SecureKeyGenerator.isSecureKey(''), isFalse);
    });

    test('should identify short keys as insecure', () {
      expect(SecureKeyGenerator.isSecureKey('short'), isFalse);
      expect(SecureKeyGenerator.isSecureKey('abcdefghij'), isFalse);
    });

    test('should identify keys lacking complexity as insecure', () {
      expect(SecureKeyGenerator.isSecureKey('a' * 50), isFalse);
      expect(SecureKeyGenerator.isSecureKey('1' * 50), isFalse);
    });

    test('should identify secure keys', () {
      final secureKey = SecureKeyGenerator.generateSecretKey();
      expect(SecureKeyGenerator.isSecureKey(secureKey), isTrue);
    });

    test('should generate secure hash', () {
      final hash = SecureKeyGenerator.secureHash('password');

      expect(hash, isNotEmpty);
      expect(hash.length, greaterThan(32));
    });

    test('should generate consistent hashes for same input', () {
      final hash1 = SecureKeyGenerator.secureHash('password');
      final hash2 = SecureKeyGenerator.secureHash('password');

      expect(hash1, equals(hash2));
    });

    test('should generate different hashes with salt', () {
      final hash1 = SecureKeyGenerator.secureHash('password');
      final hash2 = SecureKeyGenerator.secureHash('password', salt: 'salt123');

      expect(hash1, isNot(equals(hash2)));
    });

    test('should generate salt', () {
      final salt = SecureKeyGenerator.generateSalt();

      expect(salt, isNotEmpty);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(salt), isTrue);
    });

    test('should generate unique salts', () {
      final salt1 = SecureKeyGenerator.generateSalt();
      final salt2 = SecureKeyGenerator.generateSalt();

      expect(salt1, isNot(equals(salt2)));
    });
  });

  group('CryptoUtils', () {
    test('should generate secure token', () {
      final token = CryptoUtils.generateSecureToken(32);

      expect(token, isNotEmpty);
      expect(token.length, equals(32));
      expect(RegExp(r'^[A-Za-z0-9]+$').hasMatch(token), isTrue);
    });

    test('should generate unique tokens', () {
      final token1 = CryptoUtils.generateSecureToken(32);
      final token2 = CryptoUtils.generateSecureToken(32);

      expect(token1, isNot(equals(token2)));
    });

    test('should generate secure bytes', () {
      final bytes = CryptoUtils.generateSecureBytes(16);

      expect(bytes, isNotEmpty);
      expect(bytes, isA<String>());
    });

    test('should sign value', () {
      final signed = CryptoUtils.signValue('hello', 'secret-key');

      expect(signed, contains('.'));
      expect(signed, startsWith('hello.'));
    });

    test('should unsign valid value', () {
      const value = 'test-data';
      const secretKey = 'my-secret-key';

      final signed = CryptoUtils.signValue(value, secretKey);
      final unsigned = CryptoUtils.unsignValue(signed, secretKey);

      expect(unsigned, equals(value));
    });

    test('should return null for tampered value', () {
      const value = 'test-data';
      const secretKey = 'my-secret-key';

      final signed = CryptoUtils.signValue(value, secretKey);
      final tampered = signed.replaceAll('test-data', 'tampered');

      final unsigned = CryptoUtils.unsignValue(tampered, secretKey);

      expect(unsigned, isNull);
    });

    test('should return null for invalid signature format', () {
      final unsigned = CryptoUtils.unsignValue('invalid-format', 'secret-key');

      expect(unsigned, isNull);
    });

    test('should return null for wrong secret key', () {
      const value = 'test-data';
      const secretKey1 = 'secret-key-1';
      const secretKey2 = 'secret-key-2';

      final signed = CryptoUtils.signValue(value, secretKey1);
      final unsigned = CryptoUtils.unsignValue(signed, secretKey2);

      expect(unsigned, isNull);
    });

    test('should support custom salt', () {
      const value = 'data';
      const secretKey = 'key';
      const salt1 = 'salt1';
      const salt2 = 'salt2';

      final signed1 = CryptoUtils.signValue(value, secretKey, salt1);
      final signed2 = CryptoUtils.signValue(value, secretKey, salt2);

      expect(signed1, isNot(equals(signed2)));

      final unsigned1 = CryptoUtils.unsignValue(signed1, secretKey, salt1);
      final unsigned2 = CryptoUtils.unsignValue(signed2, secretKey, salt2);

      expect(unsigned1, equals(value));
      expect(unsigned2, equals(value));
    });

    test('should perform constant time comparison', () {
      expect(CryptoUtils.constantTimeEquals('abc', 'abc'), isTrue);
      expect(CryptoUtils.constantTimeEquals('abc', 'xyz'), isFalse);
      expect(CryptoUtils.constantTimeEquals('abc', 'ab'), isFalse);
      expect(CryptoUtils.constantTimeEquals('', ''), isTrue);
    });

    test('should create CSRF token', () {
      final token = CryptoUtils.createCsrfToken();

      expect(token, isNotEmpty);
      expect(token.length, equals(32));
    });

    test('should perform PBKDF2 key derivation', () {
      final derived = CryptoUtils.pbkdf2(
        'password',
        'salt',
        1000,
        32,
      );

      expect(derived, isNotEmpty);
      expect(derived, isA<String>());
    });

    test('should produce consistent PBKDF2 results', () {
      final derived1 = CryptoUtils.pbkdf2('password', 'salt', 1000, 32);
      final derived2 = CryptoUtils.pbkdf2('password', 'salt', 1000, 32);

      expect(derived1, equals(derived2));
    });

    test('should produce different results with different inputs', () {
      final derived1 = CryptoUtils.pbkdf2('password1', 'salt', 1000, 32);
      final derived2 = CryptoUtils.pbkdf2('password2', 'salt', 1000, 32);

      expect(derived1, isNot(equals(derived2)));
    });
  });

  group('EncodingUtils', () {
    test('should detect UTF-8 encoding', () {
      final bytes = utf8.encode('Hello World');
      final encoding = EncodingUtils.detectEncoding(bytes);

      expect(encoding, equals('utf-8'));
    });

    test('should detect UTF-8 BOM', () {
      final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode('test')];
      final encoding = EncodingUtils.detectEncoding(bytes);

      expect(encoding, equals('utf-8'));
    });

    test('should detect UTF-16 BE', () {
      final bytes = [0xFE, 0xFF, 0x00, 0x41];
      final encoding = EncodingUtils.detectEncoding(bytes);

      expect(encoding, equals('utf-16be'));
    });

    test('should detect UTF-16 LE', () {
      final bytes = [0xFF, 0xFE, 0x41, 0x00];
      final encoding = EncodingUtils.detectEncoding(bytes);

      expect(encoding, equals('utf-16le'));
    });

    test('should safely decode UTF-8 string', () {
      final bytes = utf8.encode('Hello 世界');
      final decoded = EncodingUtils.safeDecodeString(bytes);

      expect(decoded, equals('Hello 世界'));
    });

    test('should safely encode UTF-8 string', () {
      final encoded = EncodingUtils.safeEncodeString('Hello World');
      final decoded = utf8.decode(encoded);

      expect(decoded, equals('Hello World'));
    });

    test('should escape HTML', () {
      final escaped = EncodingUtils.escapeHtml('<script>alert("XSS")</script>');

      expect(escaped, contains('&lt;'));
      expect(escaped, contains('&gt;'));
      expect(escaped, contains('&quot;'));
      expect(escaped, isNot(contains('<script>')));
    });

    test('should unescape HTML', () {
      final unescaped = EncodingUtils.unescapeHtml('&lt;div&gt;&amp;&quot;');

      expect(unescaped, equals('<div>&"'));
    });

    test('should escape URL', () {
      final escaped = EncodingUtils.escapeUrl('hello world & test=1');

      expect(escaped, contains('hello%20world'));
      expect(escaped, isNot(contains(' ')));
    });

    test('should unescape URL', () {
      final unescaped = EncodingUtils.unescapeUrl('hello%20world%26test%3D1');

      expect(unescaped, equals('hello world&test=1'));
    });

    test('should escape JavaScript', () {
      final escaped = EncodingUtils.escapeJs('He said: "Hi"\nNew line');

      expect(escaped, contains('\\"'));
      expect(escaped, contains('\\n'));
      expect(escaped, isNot(contains('\n')));
    });

    test('should slugify text', () {
      expect(EncodingUtils.slugify('Hello World'), equals('hello-world'));
      expect(EncodingUtils.slugify('Hello   World'), equals('hello-world'));
      expect(EncodingUtils.slugify('Hello-World!'), equals('hello-world'));
      expect(EncodingUtils.slugify('  Hello World  '), equals('hello-world'));
    });

    test('should base64 encode', () {
      final encoded = EncodingUtils.base64Encode([72, 101, 108, 108, 111]);

      expect(encoded, equals('SGVsbG8='));
    });

    test('should base64 decode', () {
      final decoded = EncodingUtils.base64Decode('SGVsbG8=');

      expect(decoded, equals([72, 101, 108, 108, 111]));
      expect(utf8.decode(decoded), equals('Hello'));
    });

    test('should base64url encode', () {
      final bytes = Uint8List.fromList([255, 254, 253]);
      final encoded = EncodingUtils.base64UrlEncode(bytes);

      expect(encoded, isA<String>());
      expect(encoded, isNot(contains('+')));
      expect(encoded, isNot(contains('/')));
    });

    test('should base64url decode', () {
      final encoded = EncodingUtils.base64UrlEncode([255, 254, 253]);
      final decoded = EncodingUtils.base64UrlDecode(encoded);

      expect(decoded, equals([255, 254, 253]));
    });

    test('should validate UTF-8', () {
      expect(EncodingUtils.isValidUtf8(utf8.encode('Hello')), isTrue);
      expect(EncodingUtils.isValidUtf8([0xFF, 0xFE]), isFalse);
    });

    test('should validate ASCII', () {
      expect(EncodingUtils.isValidAscii([65, 66, 67]), isTrue);
      expect(EncodingUtils.isValidAscii([128, 255]), isFalse);
    });

    test('should normalize line endings', () {
      expect(EncodingUtils.normalizeLineEndings('a\r\nb\rc\n'), equals('a\nb\nc\n'));
    });

    test('should truncate string', () {
      expect(EncodingUtils.truncateString('Hello World', 5), equals('He...'));
      expect(EncodingUtils.truncateString('Hi', 10), equals('Hi'));
      expect(EncodingUtils.truncateString('Hello', 8, suffix: '>>'), equals('Hello'));
    });

    test('should truncate words', () {
      expect(EncodingUtils.truncateWords('one two three four', 2), equals('one two...'));
      expect(EncodingUtils.truncateWords('one two', 3), equals('one two'));
    });

    test('should strip HTML tags', () {
      expect(EncodingUtils.stripTags('<p>Hello <b>World</b></p>'), equals('Hello World'));
      expect(EncodingUtils.stripTags('No tags here'), equals('No tags here'));
    });

    test('should split lines', () {
      final lines = EncodingUtils.splitLines('line1\nline2\r\nline3');

      expect(lines, hasLength(3));
      expect(lines, equals(['line1', 'line2', 'line3']));
    });

    test('should join lines', () {
      final joined = EncodingUtils.joinLines(['a', 'b', 'c']);

      expect(joined, equals('a\nb\nc'));
    });

    test('should pad left', () {
      expect(EncodingUtils.padLeft('5', 3, padding: '0'), equals('005'));
    });

    test('should pad right', () {
      expect(EncodingUtils.padRight('5', 3, padding: '0'), equals('500'));
    });

    test('should center text', () {
      expect(EncodingUtils.center('Hi', 6), equals('  Hi  '));
      expect(EncodingUtils.center('Hi', 5), equals(' Hi  '));
    });

    test('should repeat string', () {
      expect(EncodingUtils.repeat('ab', 3), equals('ababab'));
      expect(EncodingUtils.repeat('x', 0), equals(''));
    });

    test('should reverse string', () {
      expect(EncodingUtils.reverse('Hello'), equals('olleH'));
      expect(EncodingUtils.reverse(''), equals(''));
    });

    test('should capitalize', () {
      expect(EncodingUtils.capitalize('hello'), equals('Hello'));
      expect(EncodingUtils.capitalize('HELLO'), equals('HELLO'));
      expect(EncodingUtils.capitalize(''), equals(''));
    });

    test('should convert to title case', () {
      expect(EncodingUtils.titleCase('hello world'), equals('Hello World'));
      expect(EncodingUtils.titleCase('the quick brown fox'), equals('The Quick Brown Fox'));
    });

    test('should convert to camel case', () {
      expect(EncodingUtils.camelCase('hello_world'), equals('helloWorld'));
      expect(EncodingUtils.camelCase('hello-world'), equals('helloWorld'));
      expect(EncodingUtils.camelCase('hello world'), equals('helloWorld'));
    });

    test('should convert to snake case', () {
      expect(EncodingUtils.snakeCase('helloWorld'), equals('hello_world'));
      expect(EncodingUtils.snakeCase('HelloWorld'), equals('hello_world'));
      expect(EncodingUtils.snakeCase('hello-world'), equals('hello_world'));
    });

    test('should convert to kebab case', () {
      expect(EncodingUtils.kebabCase('helloWorld'), equals('hello-world'));
      expect(EncodingUtils.kebabCase('HelloWorld'), equals('hello-world'));
      expect(EncodingUtils.kebabCase('hello_world'), equals('hello-world'));
    });
  });

  group('Integration Tests', () {
    test('should handle secure token signing and verification', () {
      const userId = '12345';
      const secretKey = 'my-super-secret-key-that-is-very-long';

      final signed = CryptoUtils.signValue(userId, secretKey);
      final unsigned = CryptoUtils.unsignValue(signed, secretKey);

      expect(unsigned, equals(userId));
    });

    test('should handle complex HTML escaping scenarios', () {
      const dangerous = '<script>alert("XSS")</script><img src="x" onerror="alert(1)">';
      final escaped = EncodingUtils.escapeHtml(dangerous);

      expect(escaped, isNot(contains('<script>')));
      expect(escaped, isNot(contains('onerror')));
      expect(escaped, contains('&lt;'));
      expect(escaped, contains('&gt;'));
      expect(escaped, contains('&quot;'));
    });

    test('should handle password hashing with PBKDF2', () {
      const password = 'my-secure-password';
      final salt = SecureKeyGenerator.generateSalt();

      final hash1 = CryptoUtils.pbkdf2(password, salt, 10000, 32);
      final hash2 = CryptoUtils.pbkdf2(password, salt, 10000, 32);

      expect(hash1, equals(hash2));

      final differentHash = CryptoUtils.pbkdf2('different', salt, 10000, 32);
      expect(hash1, isNot(equals(differentHash)));
    });

    test('should handle text transformation chains', () {
      var text = 'Hello World Example';

      text = EncodingUtils.snakeCase(text);
      expect(text, equals('hello_world_example'));

      text = EncodingUtils.kebabCase('HelloWorldExample');
      expect(text, equals('hello-world-example'));

      text = EncodingUtils.camelCase('hello_world_example');
      expect(text, equals('helloWorldExample'));
    });

    test('should handle secure key generation and validation', () {
      final key = SecureKeyGenerator.generateSecretKey(length: 64);

      expect(SecureKeyGenerator.isSecureKey(key), isTrue);
      expect(key.length, equals(64));

      final hash = SecureKeyGenerator.secureHash('data', salt: key);
      expect(hash, isNotEmpty);
    });

    test('should handle encoding detection and conversion', () {
      final text = 'Hello 世界 🌍';
      final bytes = utf8.encode(text);

      final encoding = EncodingUtils.detectEncoding(bytes);
      expect(encoding, equals('utf-8'));

      final decoded = EncodingUtils.safeDecodeString(bytes);
      expect(decoded, equals(text));
    });
  });
}
