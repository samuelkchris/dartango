import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../utils/crypto.dart';

class JwtToken {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final int userId;
  final String username;

  JwtToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.userId,
    required this.username,
  });

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.toIso8601String(),
      'expires_in': expiresAt.difference(DateTime.now()).inSeconds,
      'token_type': 'Bearer',
      'user_id': userId,
      'username': username,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired;
}

class JwtService {
  static const String _algorithm = 'HS256';
  static const Duration _defaultExpiration = Duration(hours: 24);
  static const Duration _refreshExpiration = Duration(days: 7);

  final String _secretKey;

  JwtService(this._secretKey);

  /// Generate JWT token for user
  JwtToken generateToken(int userId, String username, {Duration? expiresIn}) {
    final expiration = expiresIn ?? _defaultExpiration;
    final expiresAt = DateTime.now().add(expiration);
    
    final accessToken = _createAccessToken(userId, username, expiresAt);
    final refreshToken = _createRefreshToken(userId, username);
    
    return JwtToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      userId: userId,
      username: username,
    );
  }

  /// Verify and decode JWT token
  Map<String, dynamic>? verifyToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final header = _decodeBase64(parts[0]);
      final payload = _decodeBase64(parts[1]);
      final signature = parts[2];

      // Verify algorithm
      final headerMap = jsonDecode(header);
      if (headerMap['alg'] != _algorithm) return null;

      // Verify signature
      final expectedSignature = _createSignature('${parts[0]}.${parts[1]}');
      if (signature != expectedSignature) return null;

      // Verify expiration
      final payloadMap = jsonDecode(payload);
      final exp = payloadMap['exp'] as int;
      if (DateTime.now().millisecondsSinceEpoch > exp * 1000) return null;

      return payloadMap;
    } catch (e) {
      return null;
    }
  }

  /// Create access token
  String _createAccessToken(int userId, String username, DateTime expiresAt) {
    final header = {
      'alg': _algorithm,
      'typ': 'JWT',
    };

    final payload = {
      'user_id': userId,
      'username': username,
      'exp': (expiresAt.millisecondsSinceEpoch / 1000).round(),
      'iat': (DateTime.now().millisecondsSinceEpoch / 1000).round(),
      'iss': 'dartango',
    };

    final encodedHeader = _encodeBase64(jsonEncode(header));
    final encodedPayload = _encodeBase64(jsonEncode(payload));
    final signature = _createSignature('$encodedHeader.$encodedPayload');

    return '$encodedHeader.$encodedPayload.$signature';
  }

  /// Create refresh token
  String _createRefreshToken(int userId, String username) {
    final payload = {
      'user_id': userId,
      'username': username,
      'exp': ((DateTime.now().add(_refreshExpiration)).millisecondsSinceEpoch / 1000).round(),
      'iat': (DateTime.now().millisecondsSinceEpoch / 1000).round(),
      'type': 'refresh',
    };

    final encodedPayload = _encodeBase64(jsonEncode(payload));
    final signature = _createSignature(encodedPayload);

    return '$encodedPayload.$signature';
  }

  /// Create HMAC signature
  String _createSignature(String data) {
    final key = utf8.encode(_secretKey);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Encode string to base64url
  String _encodeBase64(String data) {
    final bytes = utf8.encode(data);
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Decode base64url string
  String _decodeBase64(String data) {
    // Add padding if needed
    final padding = 4 - (data.length % 4);
    if (padding != 4) {
      data = data + ('=' * padding);
    }
    
    final bytes = base64Url.decode(data);
    return utf8.decode(bytes);
  }

  /// Refresh access token using refresh token
  JwtToken? refreshAccessToken(String refreshToken) {
    try {
      final parts = refreshToken.split('.');
      if (parts.length != 2) return null;

      final payload = _decodeBase64(parts[0]);
      final signature = parts[1];

      // Verify signature
      final expectedSignature = _createSignature(parts[0]);
      if (signature != expectedSignature) return null;

      final payloadMap = jsonDecode(payload);
      
      // Verify it's a refresh token
      if (payloadMap['type'] != 'refresh') return null;
      
      // Verify expiration
      final exp = payloadMap['exp'] as int;
      if (DateTime.now().millisecondsSinceEpoch > exp * 1000) return null;

      // Generate new access token
      final userId = payloadMap['user_id'] as int;
      final username = payloadMap['username'] as String;
      
      return generateToken(userId, username);
    } catch (e) {
      return null;
    }
  }
}

/// Session-based authentication service
class SessionAuthService {
  static final Map<String, SessionData> _sessions = {};
  static const Duration _sessionExpiration = Duration(hours: 24);

  /// Create new session
  static String createSession(int userId, String username) {
    final sessionId = SecureKeyGenerator.generateUrlSafeToken(length: 32);
    final expiresAt = DateTime.now().add(_sessionExpiration);
    
    _sessions[sessionId] = SessionData(
      userId: userId,
      username: username,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
    );
    
    return sessionId;
  }

  /// Verify session
  static SessionData? verifySession(String sessionId) {
    final session = _sessions[sessionId];
    if (session == null) return null;
    
    if (session.isExpired) {
      _sessions.remove(sessionId);
      return null;
    }
    
    return session;
  }

  /// Destroy session
  static void destroySession(String sessionId) {
    _sessions.remove(sessionId);
  }

  /// Clean up expired sessions
  static void cleanupExpiredSessions() {
    final now = DateTime.now();
    _sessions.removeWhere((_, session) => now.isAfter(session.expiresAt));
  }
}

class SessionData {
  final int userId;
  final String username;
  final DateTime createdAt;
  final DateTime expiresAt;

  SessionData({
    required this.userId,
    required this.username,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired;
}