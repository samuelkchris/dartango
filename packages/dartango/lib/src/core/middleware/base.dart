import 'dart:async';

import '../http/request.dart';
import '../http/response.dart';
import '../exceptions/base.dart';

abstract class BaseMiddleware {
  const BaseMiddleware();

  FutureOr<HttpResponse?> processRequest(HttpRequest request) {
    return null;
  }

  FutureOr<HttpResponse?> processView(
    HttpRequest request,
    Function viewFunc,
    List<dynamic> viewArgs,
    Map<String, dynamic> viewKwargs,
  ) {
    return null;
  }

  FutureOr<HttpResponse?> processException(
    HttpRequest request,
    Exception exception,
  ) {
    return null;
  }

  FutureOr<HttpResponse> processResponse(
    HttpRequest request,
    HttpResponse response,
  ) {
    return response;
  }

  FutureOr<HttpResponse> processTemplateResponse(
    HttpRequest request,
    HttpResponse response,
  ) {
    return response;
  }
}

typedef MiddlewareFunction = FutureOr<HttpResponse?> Function(
  HttpRequest request,
  Future<HttpResponse> Function() getResponse,
);

class FunctionalMiddleware extends BaseMiddleware {
  final MiddlewareFunction function;

  const FunctionalMiddleware(this.function);

  @override
  FutureOr<HttpResponse?> processRequest(HttpRequest request) {
    return function(request, () async => HttpResponse.ok(''));
  }
}

class MiddlewareChain {
  final List<BaseMiddleware> _middlewares;

  MiddlewareChain(this._middlewares);

  Future<HttpResponse> process(
    HttpRequest request,
    Future<HttpResponse> Function(HttpRequest) handler,
  ) async {
    for (final middleware in _middlewares) {
      final response = await middleware.processRequest(request);
      if (response != null) {
        return await _applyResponseMiddlewares(request, response);
      }
    }

    HttpResponse response;
    try {
      response = await handler(request);
    } catch (e) {
      if (e is Exception) {
        for (final middleware in _middlewares) {
          final exceptionResponse = await middleware.processException(request, e);
          if (exceptionResponse != null) {
            return await _applyResponseMiddlewares(request, exceptionResponse);
          }
        }
      }
      rethrow;
    }

    return await _applyResponseMiddlewares(request, response);
  }

  Future<HttpResponse> processView(
    HttpRequest request,
    Function viewFunc,
    List<dynamic> viewArgs,
    Map<String, dynamic> viewKwargs,
    Future<HttpResponse> Function() executeView,
  ) async {
    for (final middleware in _middlewares) {
      final response = await middleware.processView(
        request,
        viewFunc,
        viewArgs,
        viewKwargs,
      );
      if (response != null) {
        return await _applyResponseMiddlewares(request, response);
      }
    }

    return await executeView();
  }

  Future<HttpResponse> _applyResponseMiddlewares(
    HttpRequest request,
    HttpResponse response,
  ) async {
    var currentResponse = response;

    for (final middleware in _middlewares.reversed) {
      if (response.headers.containsKey('X-Template-Response')) {
        currentResponse = await middleware.processTemplateResponse(
          request,
          currentResponse,
        );
      }
      currentResponse = await middleware.processResponse(
        request,
        currentResponse,
      );
    }

    return currentResponse;
  }
}

class MiddlewareException extends DartangoException {
  MiddlewareException(String message, {Exception? cause})
      : super(message);
}

class MiddlewareNotCallable extends MiddlewareException {
  MiddlewareNotCallable(String middlewareName)
      : super('Middleware $middlewareName is not callable');
}

class MiddlewareOrderingError extends MiddlewareException {
  MiddlewareOrderingError(String message) : super(message);
}

abstract class AsyncMiddleware extends BaseMiddleware {
  const AsyncMiddleware();

  @override
  Future<HttpResponse?> processRequest(HttpRequest request) async {
    return null;
  }

  @override
  Future<HttpResponse?> processView(
    HttpRequest request,
    Function viewFunc,
    List<dynamic> viewArgs,
    Map<String, dynamic> viewKwargs,
  ) async {
    return null;
  }

  @override
  Future<HttpResponse?> processException(
    HttpRequest request,
    Exception exception,
  ) async {
    return null;
  }

  @override
  Future<HttpResponse> processResponse(
    HttpRequest request,
    HttpResponse response,
  ) async {
    return response;
  }

  @override
  Future<HttpResponse> processTemplateResponse(
    HttpRequest request,
    HttpResponse response,
  ) async {
    return response;
  }
}

mixin MiddlewareMixin {
  List<BaseMiddleware> get middleware => [];

  MiddlewareChain createMiddlewareChain() {
    return MiddlewareChain(middleware);
  }
}

class ConditionalMiddleware extends BaseMiddleware {
  final BaseMiddleware middleware;
  final bool Function(HttpRequest request) condition;

  const ConditionalMiddleware({
    required this.middleware,
    required this.condition,
  });

  @override
  FutureOr<HttpResponse?> processRequest(HttpRequest request) {
    if (!condition(request)) {
      return null;
    }
    return middleware.processRequest(request);
  }

  @override
  FutureOr<HttpResponse?> processView(
    HttpRequest request,
    Function viewFunc,
    List<dynamic> viewArgs,
    Map<String, dynamic> viewKwargs,
  ) {
    if (!condition(request)) {
      return null;
    }
    return middleware.processView(request, viewFunc, viewArgs, viewKwargs);
  }

  @override
  FutureOr<HttpResponse?> processException(
    HttpRequest request,
    Exception exception,
  ) {
    if (!condition(request)) {
      return null;
    }
    return middleware.processException(request, exception);
  }

  @override
  FutureOr<HttpResponse> processResponse(
    HttpRequest request,
    HttpResponse response,
  ) {
    if (!condition(request)) {
      return response;
    }
    return middleware.processResponse(request, response);
  }

  @override
  FutureOr<HttpResponse> processTemplateResponse(
    HttpRequest request,
    HttpResponse response,
  ) {
    if (!condition(request)) {
      return response;
    }
    return middleware.processTemplateResponse(request, response);
  }
}

class MiddlewareStack {
  final List<BaseMiddleware> _middlewares = [];

  void add(BaseMiddleware middleware) {
    _middlewares.add(middleware);
  }

  void insert(int index, BaseMiddleware middleware) {
    _middlewares.insert(index, middleware);
  }

  void remove(BaseMiddleware middleware) {
    _middlewares.remove(middleware);
  }

  void clear() {
    _middlewares.clear();
  }

  List<BaseMiddleware> get middlewares => List.unmodifiable(_middlewares);

  bool get isEmpty => _middlewares.isEmpty;
  bool get isNotEmpty => _middlewares.isNotEmpty;
  int get length => _middlewares.length;

  MiddlewareChain toChain() => MiddlewareChain(_middlewares);
}