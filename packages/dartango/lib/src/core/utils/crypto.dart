import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class SecureKeyGenerator {
  static const String _charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=[]{}|;:,.<>?';
  static final Random _secureRandom = Random.secure();

  /// Generate a cryptographically secure random key
  static String generateSecretKey({int length = 50}) {
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(_charset[_secureRandom.nextInt(_charset.length)]);
    }
    return buffer.toString();
  }

  /// Generate a secure random token for CSRF, sessions, etc.
  static String generateToken({int length = 32}) {
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = _secureRandom.nextInt(256);
    }
    return base64Url.encode(bytes);
  }

  /// Generate a secure random string using only URL-safe characters
  static String generateUrlSafeToken({int length = 32}) {
    const urlSafeChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(urlSafeChars[_secureRandom.nextInt(urlSafeChars.length)]);
    }
    return buffer.toString();
  }

  /// Generate a secure random hex string
  static String generateHexToken({int length = 32}) {
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = _secureRandom.nextInt(256);
    }
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Generate a Django-style secret key
  static String generateDjangoSecretKey() {
    return generateSecretKey(length: 50);
  }

  /// Check if a key is secure (not default/weak)
  static bool isSecureKey(String key) {
    final weakKeys = [
      'default-secret-key',
      'your-secret-key-here',
      'change-me',
      'secret',
      'key',
      'password',
      '123456',
      'django-insecure-key',
      '',
    ];
    
    if (weakKeys.contains(key.toLowerCase())) {
      return false;
    }
    
    // Check minimum length
    if (key.length < 32) {
      return false;
    }
    
    // Check for basic complexity (has letters, numbers, and special chars)
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(key);
    final hasNumber = RegExp(r'[0-9]').hasMatch(key);
    final hasSpecial = RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(key);
    
    return hasLetter && hasNumber && hasSpecial;
  }

  /// Generate a secure hash of a value using SHA-256
  static String secureHash(String value, {String? salt}) {
    final input = salt != null ? '$salt$value' : value;
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate a secure salt for password hashing
  static String generateSalt({int length = 16}) {
    return generateHexToken(length: length);
  }
}

class CryptoUtils {
  static final Random _secureRandom = Random.secure();
  
  static String generateSecureToken(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(_secureRandom.nextInt(chars.length)))
    );
  }
  
  static String generateSecureBytes(int length) {
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = _secureRandom.nextInt(256);
    }
    return base64Encode(bytes);
  }
  
  static String signValue(String value, String secretKey, [String? salt]) {
    salt ??= 'dartango.sessions';
    
    final key = utf8.encode(secretKey);
    final message = utf8.encode('$salt$value');
    
    final hmac = Hmac(sha256, key);
    final signature = hmac.convert(message);
    
    return '$value.${base64Encode(signature.bytes)}';
  }
  
  static String? unsignValue(String signedValue, String secretKey, [String? salt]) {
    final parts = signedValue.split('.');
    if (parts.length != 2) return null;
    
    final value = parts[0];
    final signature = parts[1];
    
    try {
      final expectedSignature = signValue(value, secretKey, salt);
      final expectedParts = expectedSignature.split('.');
      
      if (expectedParts.length != 2) return null;
      
      if (constantTimeEquals(signature, expectedParts[1])) {
        return value;
      }
    } catch (e) {
      return null;
    }
    
    return null;
  }
  
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    
    return result == 0;
  }
  
  static String createCsrfToken() {
    return generateSecureToken(32);
  }
  
  static String pbkdf2(String password, String salt, int iterations, int keyLength) {
    final passwordBytes = utf8.encode(password);
    final saltBytes = utf8.encode(salt);
    
    final derivedKey = _pbkdf2(passwordBytes, saltBytes, iterations, keyLength);
    return base64Encode(derivedKey);
  }
  
  static Uint8List _pbkdf2(Uint8List password, Uint8List salt, int iterations, int keyLength) {
    final hmac = Hmac(sha256, password);
    final derivedKey = Uint8List(keyLength);
    
    final blockCount = (keyLength + 31) ~/ 32;
    
    for (int i = 1; i <= blockCount; i++) {
      final block = _pbkdf2Block(hmac, salt, iterations, i);
      final offset = (i - 1) * 32;
      final length = min(32, keyLength - offset);
      
      for (int j = 0; j < length; j++) {
        derivedKey[offset + j] = block[j];
      }
    }
    
    return derivedKey;
  }
  
  static Uint8List _pbkdf2Block(Hmac hmac, Uint8List salt, int iterations, int blockIndex) {
    final block = Uint8List(32);
    final u = Uint8List(32);
    
    final input = Uint8List(salt.length + 4);
    input.setAll(0, salt);
    input[salt.length] = (blockIndex >> 24) & 0xff;
    input[salt.length + 1] = (blockIndex >> 16) & 0xff;
    input[salt.length + 2] = (blockIndex >> 8) & 0xff;
    input[salt.length + 3] = blockIndex & 0xff;
    
    final digest = hmac.convert(input).bytes;
    for (int i = 0; i < 32; i++) {
      block[i] = digest[i];
      u[i] = digest[i];
    }
    
    for (int i = 1; i < iterations; i++) {
      final newDigest = hmac.convert(u).bytes;
      for (int j = 0; j < 32; j++) {
        u[j] = newDigest[j];
        block[j] ^= newDigest[j];
      }
    }
    
    return block;
  }
}