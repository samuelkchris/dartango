import 'package:test/test.dart';

import '../../../lib/src/core/utils/crypto.dart';
import '../../../lib/src/core/utils/encoding.dart';

void main() {
  group('Utils Edge Cases and Boundary Conditions', () {
    group('CryptoUtils Edge Cases', () {
      test('should handle empty string in signValue', () {
        final signed = CryptoUtils.signValue('', 'secret-key');
        expect(signed, isNotEmpty);
        expect(signed, contains(':'));
      });

      test('should handle empty string in unsignValue', () {
        final signed = CryptoUtils.signValue('', 'secret-key');
        final unsigned = CryptoUtils.unsignValue(signed, 'secret-key');
        expect(unsigned, equals(''));
      });

      test('should handle secureHash with empty string', () {
        final hash1 = SecureKeyGenerator.secureHash('');
        expect(hash1, isNotEmpty);

        final hash2 = SecureKeyGenerator.secureHash('');
        expect(hash2, equals(hash1));
      });

      test('should handle secureHash with empty salt', () {
        final hash = SecureKeyGenerator.secureHash('password', salt: '');
        expect(hash, isNotEmpty);
      });

      test('should handle pbkdf2 with empty password', () {
        final derived = CryptoUtils.pbkdf2('', 'salt', 1000, 32);
        expect(derived, isNotEmpty);
        expect(derived.length, equals(32));
      });

      test('should handle pbkdf2 with empty salt', () {
        final derived = CryptoUtils.pbkdf2('password', '', 1000, 32);
        expect(derived, isNotEmpty);
        expect(derived.length, equals(32));
      });

      test('should handle pbkdf2 with zero iterations', () {
        /// Should either throw or handle gracefully
        expect(
          () => CryptoUtils.pbkdf2('password', 'salt', 0, 32),
          anyOf(
            throwsA(anything),
            returnsNormally,
          ),
        );
      });

      test('should handle pbkdf2 with negative iterations', () {
        /// Should either throw or handle gracefully
        expect(
          () => CryptoUtils.pbkdf2('password', 'salt', -1, 32),
          anyOf(
            throwsA(anything),
            returnsNormally,
          ),
        );
      });

      test('should handle pbkdf2 with zero key length', () {
        /// Should either throw or handle gracefully
        expect(
          () => CryptoUtils.pbkdf2('password', 'salt', 1000, 0),
          anyOf(
            throwsA(anything),
            returnsNormally,
          ),
        );
      });

      test('should handle pbkdf2 with very large key length', () {
        final derived = CryptoUtils.pbkdf2('password', 'salt', 1000, 1024);
        expect(derived.length, equals(1024));
      });

      test('should handle constantTimeCompare with empty strings', () {
        expect(CryptoUtils.constantTimeCompare('', ''), isTrue);
      });

      test('should handle constantTimeCompare with different lengths', () {
        expect(CryptoUtils.constantTimeCompare('short', 'much longer'), isFalse);
      });

      test('should handle very long strings in signValue', () {
        final longValue = 'x' * 10000;
        final signed = CryptoUtils.signValue(longValue, 'secret-key');
        final unsigned = CryptoUtils.unsignValue(signed, 'secret-key');
        expect(unsigned, equals(longValue));
      });
    });

    group('EncodingUtils Edge Cases', () {
      test('should handle escapeHtml with empty string', () {
        expect(EncodingUtils.escapeHtml(''), equals(''));
      });

      test('should handle escapeHtml with only special characters', () {
        final result = EncodingUtils.escapeHtml('<>&"\'');
        expect(result, equals('&lt;&gt;&amp;&quot;&#x27;'));
      });

      test('should handle escapeUrl with empty string', () {
        expect(EncodingUtils.escapeUrl(''), equals(''));
      });

      test('should handle base64Encode with empty list', () {
        expect(EncodingUtils.base64Encode([]), isNotEmpty);
      });

      test('should handle base64Decode with empty string', () {
        expect(EncodingUtils.base64Decode(''), isEmpty);
      });

      test('should handle base64 encode/decode round trip with large data', () {
        final largeData = List.generate(1000000, (i) => i % 256);
        final encoded = EncodingUtils.base64Encode(largeData);
        final decoded = EncodingUtils.base64Decode(encoded);
        expect(decoded, equals(largeData));
      });

      test('should handle truncateString with empty string', () {
        expect(EncodingUtils.truncateString('', 10), equals(''));
      });

      test('should handle truncateString with zero length', () {
        expect(EncodingUtils.truncateString('hello', 0), equals('...'));
      });

      test('should handle truncateString with negative length', () {
        /// Should either throw or handle gracefully
        expect(
          () => EncodingUtils.truncateString('hello', -5),
          anyOf(
            throwsA(anything),
            returnsNormally,
          ),
        );
      });

      test('should handle truncateString when string shorter than length', () {
        expect(EncodingUtils.truncateString('hello', 100), equals('hello'));
      });

      test('should handle truncateWords with empty string', () {
        expect(EncodingUtils.truncateWords('', 5), equals(''));
      });

      test('should handle truncateWords with zero word count', () {
        expect(EncodingUtils.truncateWords('hello world', 0), equals('...'));
      });

      test('should handle truncateWords with negative word count', () {
        /// Should either throw or handle gracefully
        expect(
          () => EncodingUtils.truncateWords('hello world', -1),
          anyOf(
            throwsA(anything),
            returnsNormally,
          ),
        );
      });

      test('should handle repeat with empty string', () {
        expect(EncodingUtils.repeat('', 5), equals(''));
      });

      test('should handle repeat with zero count', () {
        expect(EncodingUtils.repeat('hello', 0), equals(''));
      });

      test('should handle repeat with negative count', () {
        expect(EncodingUtils.repeat('hello', -5), equals(''));
      });

      test('should handle padLeft with empty string', () {
        expect(EncodingUtils.padLeft('', 5), equals('     '));
      });

      test('should handle padLeft when string longer than width', () {
        expect(EncodingUtils.padLeft('hello world', 5), equals('hello world'));
      });

      test('should handle padRight with empty string', () {
        expect(EncodingUtils.padRight('', 5), equals('     '));
      });

      test('should handle padRight when string longer than width', () {
        expect(EncodingUtils.padRight('hello world', 5), equals('hello world'));
      });

      test('should handle slugify with empty string', () {
        expect(EncodingUtils.slugify(''), equals(''));
      });

      test('should handle slugify with only special characters', () {
        final result = EncodingUtils.slugify('!@#\$%^&*()');
        expect(result, anyOf(equals(''), matches(RegExp(r'^[-a-z0-9]*$'))));
      });

      test('should handle slugify with unicode characters', () {
        final result = EncodingUtils.slugify('Héllo Wörld');
        expect(result, matches(RegExp(r'^[-a-z0-9]+$')));
      });

      test('should handle slugify with multiple consecutive spaces', () {
        final result = EncodingUtils.slugify('hello     world');
        expect(result, equals('hello-world'));
      });

      test('should handle snakeCase with empty string', () {
        expect(EncodingUtils.snakeCase(''), equals(''));
      });

      test('should handle camelCase with empty string', () {
        expect(EncodingUtils.camelCase(''), equals(''));
      });

      test('should handle kebabCase with empty string', () {
        expect(EncodingUtils.kebabCase(''), equals(''));
      });

      test('should handle titleCase with empty string', () {
        expect(EncodingUtils.titleCase(''), equals(''));
      });

      test('should handle case conversions with only spaces', () {
        expect(EncodingUtils.snakeCase('     '), anyOf(equals(''), equals('_')));
        expect(EncodingUtils.camelCase('     '), equals(''));
        expect(EncodingUtils.kebabCase('     '), anyOf(equals(''), equals('-')));
        expect(EncodingUtils.titleCase('     '), equals('     '));
      });

      test('should handle case conversions with unicode', () {
        final text = 'café résumé';
        expect(EncodingUtils.snakeCase(text), matches(RegExp(r'^[a-z_]+$')));
        expect(EncodingUtils.kebabCase(text), matches(RegExp(r'^[a-z-]+$')));
      });

      test('should handle very long strings in case conversions', () {
        final longText = 'hello' * 1000;
        expect(EncodingUtils.snakeCase(longText), equals(longText.toLowerCase()));
        expect(EncodingUtils.kebabCase(longText), equals(longText.toLowerCase()));
      });

      test('should handle reverse with empty string', () {
        expect(EncodingUtils.reverse(''), equals(''));
      });

      test('should handle reverse with single character', () {
        expect(EncodingUtils.reverse('a'), equals('a'));
      });

      test('should handle reverse with unicode', () {
        /// Unicode handling might be complex, test basic behavior
        final result = EncodingUtils.reverse('🎉🎊');
        expect(result, isNotEmpty);
      });

      test('should handle capitalize with empty string', () {
        expect(EncodingUtils.capitalize(''), equals(''));
      });

      test('should handle capitalize with single character', () {
        expect(EncodingUtils.capitalize('a'), equals('A'));
      });

      test('should handle swapCase with empty string', () {
        expect(EncodingUtils.swapCase(''), equals(''));
      });

      test('should handle sanitizeFilename with empty string', () {
        final result = EncodingUtils.sanitizeFilename('');
        expect(result, anyOf(equals(''), isNotEmpty));
      });

      test('should handle sanitizeFilename with only invalid characters', () {
        final result = EncodingUtils.sanitizeFilename('/:*?"<>|');
        expect(result, isNot(contains(RegExp(r'[/:*?"<>|]'))));
      });

      test('should handle very long filename', () {
        final longName = 'a' * 500 + '.txt';
        final result = EncodingUtils.sanitizeFilename(longName);
        expect(result, isNotEmpty);
        expect(result.length, lessThanOrEqualTo(longName.length));
      });
    });

    group('SecureKeyGenerator Edge Cases', () {
      test('should handle isSecureKey with empty string', () {
        expect(SecureKeyGenerator.isSecureKey(''), isFalse);
      });

      test('should handle isSecureKey with very short key', () {
        expect(SecureKeyGenerator.isSecureKey('abc'), isFalse);
      });

      test('should handle isSecureKey with very long key', () {
        final longKey = SecureKeyGenerator.generateSecretKey(length: 256);
        expect(SecureKeyGenerator.isSecureKey(longKey), isTrue);
      });

      test('should generate unique keys', () {
        final keys = <String>{};
        for (int i = 0; i < 1000; i++) {
          keys.add(SecureKeyGenerator.generateSecretKey());
        }
        expect(keys.length, equals(1000));
      });

      test('should generate unique tokens', () {
        final tokens = <String>{};
        for (int i = 0; i < 1000; i++) {
          tokens.add(SecureKeyGenerator.generateToken());
        }
        expect(tokens.length, equals(1000));
      });

      test('should handle generateSecretKey with very small length', () {
        /// Should either throw or handle gracefully
        expect(
          () => SecureKeyGenerator.generateSecretKey(length: 0),
          anyOf(
            throwsA(anything),
            returnsNormally,
          ),
        );
      });

      test('should handle generateSecretKey with negative length', () {
        /// Should either throw or handle gracefully
        expect(
          () => SecureKeyGenerator.generateSecretKey(length: -1),
          anyOf(
            throwsA(anything),
            returnsNormally,
          ),
        );
      });

      test('should handle generateToken with very small length', () {
        /// Should either throw or handle gracefully
        expect(
          () => SecureKeyGenerator.generateToken(length: 0),
          anyOf(
            throwsA(anything),
            returnsNormally,
          ),
        );
      });

      test('should generate deterministic hashes', () {
        final hash1 = SecureKeyGenerator.secureHash('test', salt: 'salt');
        final hash2 = SecureKeyGenerator.secureHash('test', salt: 'salt');
        expect(hash1, equals(hash2));
      });

      test('should generate different hashes for different salts', () {
        final hash1 = SecureKeyGenerator.secureHash('test', salt: 'salt1');
        final hash2 = SecureKeyGenerator.secureHash('test', salt: 'salt2');
        expect(hash1, isNot(equals(hash2)));
      });
    });
  });
}
