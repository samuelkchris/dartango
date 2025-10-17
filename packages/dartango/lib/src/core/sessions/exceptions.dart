import '../database/exceptions.dart';

class SessionException extends DartangoException {
  SessionException(super.message, {super.code});
}

class SessionNotFoundError extends SessionException {
  SessionNotFoundError(String sessionKey) 
      : super('Session with key "$sessionKey" not found', code: 'SESSION_NOT_FOUND');
}

class SessionExpiredError extends SessionException {
  SessionExpiredError(String sessionKey) 
      : super('Session with key "$sessionKey" has expired', code: 'SESSION_EXPIRED');
}

class SessionBackendError extends SessionException {
  SessionBackendError(String message, {String? backend}) 
      : super(backend != null ? '[$backend] $message' : message, code: 'SESSION_BACKEND_ERROR');
}

class InvalidSessionDataError extends SessionException {
  InvalidSessionDataError(String message) 
      : super('Invalid session data: $message', code: 'INVALID_SESSION_DATA');
}

class SessionSecurityError extends SessionException {
  SessionSecurityError(String message) 
      : super('Session security error: $message', code: 'SESSION_SECURITY_ERROR');
}

class SessionCookieError extends SessionException {
  SessionCookieError(String message) 
      : super('Session cookie error: $message', code: 'SESSION_COOKIE_ERROR');
}

class SessionSerializationError extends SessionException {
  SessionSerializationError(String message) 
      : super('Session serialization error: $message', code: 'SESSION_SERIALIZATION_ERROR');
}