abstract class DartangoException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? extra;

  const DartangoException(this.message, [this.statusCode, this.extra]);

  @override
  String toString() => 'DartangoException: $message';
}

class ImproperlyConfiguredException extends DartangoException {
  const ImproperlyConfiguredException(String message, [Map<String, dynamic>? extra]) 
      : super(message, null, extra);
}

class ValidationException extends DartangoException {
  const ValidationException(String message, [Map<String, dynamic>? extra]) 
      : super(message, 400, extra);
}

class SystemCheckException extends DartangoException {
  const SystemCheckException(String message, [Map<String, dynamic>? extra]) 
      : super(message, null, extra);
}

class MiddlewareNotUsedException extends DartangoException {
  const MiddlewareNotUsedException(String message, [Map<String, dynamic>? extra]) 
      : super(message, null, extra);
}

class ViewDoesNotExistException extends DartangoException {
  const ViewDoesNotExistException(String message, [Map<String, dynamic>? extra]) 
      : super(message, null, extra);
}

class PermissionDeniedException extends DartangoException {
  const PermissionDeniedException(String message, [Map<String, dynamic>? extra]) 
      : super(message, 403, extra);
}

class SuspiciousOperationException extends DartangoException {
  const SuspiciousOperationException(String message, [Map<String, dynamic>? extra]) 
      : super(message, 400, extra);
}

class DisallowedHostException extends SuspiciousOperationException {
  const DisallowedHostException(String message, [Map<String, dynamic>? extra]) 
      : super(message, extra);
}

class DisallowedRedirectException extends SuspiciousOperationException {
  const DisallowedRedirectException(String message, [Map<String, dynamic>? extra]) 
      : super(message, extra);
}

class TooManyFieldsSentException extends SuspiciousOperationException {
  const TooManyFieldsSentException(String message, [Map<String, dynamic>? extra]) 
      : super(message, extra);
}

class RequestDataTooBigException extends SuspiciousOperationException {
  const RequestDataTooBigException(String message, [Map<String, dynamic>? extra]) 
      : super(message, extra);
}

class SuspiciousFileOperationException extends SuspiciousOperationException {
  const SuspiciousFileOperationException(String message, [Map<String, dynamic>? extra]) 
      : super(message, extra);
}

class SuspiciousMultipartFormException extends SuspiciousOperationException {
  const SuspiciousMultipartFormException(String message, [Map<String, dynamic>? extra]) 
      : super(message, extra);
}

class UnreadablePostErrorException extends DartangoException {
  const UnreadablePostErrorException(String message, [Map<String, dynamic>? extra]) 
      : super(message, 400, extra);
}

class EmptyResultSetException extends DartangoException {
  const EmptyResultSetException(String message, [Map<String, dynamic>? extra]) 
      : super(message, null, extra);
}

class FullResultSetException extends DartangoException {
  const FullResultSetException(String message, [Map<String, dynamic>? extra]) 
      : super(message, null, extra);
}

class ObjectDoesNotExistException extends DartangoException {
  const ObjectDoesNotExistException(String message, [Map<String, dynamic>? extra]) 
      : super(message, 404, extra);
}

class MultipleObjectsReturnedException extends DartangoException {
  const MultipleObjectsReturnedException(String message, [Map<String, dynamic>? extra]) 
      : super(message, null, extra);
}

class FieldDoesNotExistException extends DartangoException {
  const FieldDoesNotExistException(String message, [Map<String, dynamic>? extra]) 
      : super(message, null, extra);
}

class FieldErrorException extends DartangoException {
  const FieldErrorException(String message, [Map<String, dynamic>? extra]) 
      : super(message, 400, extra);
}

class AppRegistryNotReadyException extends DartangoException {
  const AppRegistryNotReadyException(String message, [Map<String, dynamic>? extra]) 
      : super(message, null, extra);
}