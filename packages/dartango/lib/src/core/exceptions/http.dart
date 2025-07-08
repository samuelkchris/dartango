import 'base.dart';

abstract class HttpException extends DartangoException {
  const HttpException(String message, int statusCode, [Map<String, dynamic>? extra]) 
      : super(message, statusCode, extra);
}

class BadRequestException extends HttpException {
  const BadRequestException([String message = 'Bad Request', Map<String, dynamic>? extra]) 
      : super(message, 400, extra);
}

class UnauthorizedException extends HttpException {
  const UnauthorizedException([String message = 'Unauthorized', Map<String, dynamic>? extra]) 
      : super(message, 401, extra);
}

class ForbiddenException extends HttpException {
  const ForbiddenException([String message = 'Forbidden', Map<String, dynamic>? extra]) 
      : super(message, 403, extra);
}

class NotFoundException extends HttpException {
  const NotFoundException([String message = 'Not Found', Map<String, dynamic>? extra]) 
      : super(message, 404, extra);
}

class MethodNotAllowedException extends HttpException {
  final List<String> allowedMethods;

  const MethodNotAllowedException(this.allowedMethods, [String message = 'Method Not Allowed', Map<String, dynamic>? extra]) 
      : super(message, 405, extra);
}

class NotAcceptableException extends HttpException {
  const NotAcceptableException([String message = 'Not Acceptable', Map<String, dynamic>? extra]) 
      : super(message, 406, extra);
}

class ConflictException extends HttpException {
  const ConflictException([String message = 'Conflict', Map<String, dynamic>? extra]) 
      : super(message, 409, extra);
}

class GoneException extends HttpException {
  const GoneException([String message = 'Gone', Map<String, dynamic>? extra]) 
      : super(message, 410, extra);
}

class PreconditionFailedException extends HttpException {
  const PreconditionFailedException([String message = 'Precondition Failed', Map<String, dynamic>? extra]) 
      : super(message, 412, extra);
}

class RequestEntityTooLargeException extends HttpException {
  const RequestEntityTooLargeException([String message = 'Request Entity Too Large', Map<String, dynamic>? extra]) 
      : super(message, 413, extra);
}

class UnsupportedMediaTypeException extends HttpException {
  const UnsupportedMediaTypeException([String message = 'Unsupported Media Type', Map<String, dynamic>? extra]) 
      : super(message, 415, extra);
}

class UnprocessableEntityException extends HttpException {
  const UnprocessableEntityException([String message = 'Unprocessable Entity', Map<String, dynamic>? extra]) 
      : super(message, 422, extra);
}

class TooManyRequestsException extends HttpException {
  const TooManyRequestsException([String message = 'Too Many Requests', Map<String, dynamic>? extra]) 
      : super(message, 429, extra);
}

class InternalServerErrorException extends HttpException {
  const InternalServerErrorException([String message = 'Internal Server Error', Map<String, dynamic>? extra]) 
      : super(message, 500, extra);
}

class NotImplementedException extends HttpException {
  const NotImplementedException([String message = 'Not Implemented', Map<String, dynamic>? extra]) 
      : super(message, 501, extra);
}

class BadGatewayException extends HttpException {
  const BadGatewayException([String message = 'Bad Gateway', Map<String, dynamic>? extra]) 
      : super(message, 502, extra);
}

class ServiceUnavailableException extends HttpException {
  const ServiceUnavailableException([String message = 'Service Unavailable', Map<String, dynamic>? extra]) 
      : super(message, 503, extra);
}

class GatewayTimeoutException extends HttpException {
  const GatewayTimeoutException([String message = 'Gateway Timeout', Map<String, dynamic>? extra]) 
      : super(message, 504, extra);
}

class HttpVersionNotSupportedException extends HttpException {
  const HttpVersionNotSupportedException([String message = 'HTTP Version Not Supported', Map<String, dynamic>? extra]) 
      : super(message, 505, extra);
}

class Http404Exception extends NotFoundException {
  const Http404Exception([String message = 'Page not found', Map<String, dynamic>? extra]) 
      : super(message, extra);
}

class Http500Exception extends InternalServerErrorException {
  const Http500Exception([String message = 'Server Error', Map<String, dynamic>? extra]) 
      : super(message, extra);
}

class RedirectException extends HttpException {
  final String redirectUrl;
  final bool permanent;

  const RedirectException(this.redirectUrl, {this.permanent = false, String message = 'Redirect'}) 
      : super(message, permanent ? 301 : 302);
}

class ResponseException extends HttpException {
  final String? content;
  final String? contentType;
  final Map<String, String>? headers;

  const ResponseException(
    int statusCode, {
    this.content,
    this.contentType,
    this.headers,
    String? message,
  }) : super(message ?? 'HTTP $statusCode', statusCode);
}