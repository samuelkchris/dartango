import 'dart:async';

import '../http/request.dart';
import '../http/response.dart';
import 'resolver.dart';
import 'converters.dart';

class MethodBasedView {
  final Map<String, ViewFunction> _methods = {};
  final List<String> _allowedMethods = [];
  
  MethodBasedView({
    ViewFunction? get,
    ViewFunction? post,
    ViewFunction? put,
    ViewFunction? patch,
    ViewFunction? delete,
    ViewFunction? head,
    ViewFunction? options,
    ViewFunction? trace,
  }) {
    if (get != null) {
      _methods['GET'] = get;
      _allowedMethods.add('GET');
    }
    if (post != null) {
      _methods['POST'] = post;
      _allowedMethods.add('POST');
    }
    if (put != null) {
      _methods['PUT'] = put;
      _allowedMethods.add('PUT');
    }
    if (patch != null) {
      _methods['PATCH'] = patch;
      _allowedMethods.add('PATCH');
    }
    if (delete != null) {
      _methods['DELETE'] = delete;
      _allowedMethods.add('DELETE');
    }
    if (head != null) {
      _methods['HEAD'] = head;
      _allowedMethods.add('HEAD');
    }
    if (options != null) {
      _methods['OPTIONS'] = options;
      _allowedMethods.add('OPTIONS');
    }
    if (trace != null) {
      _methods['TRACE'] = trace;
      _allowedMethods.add('TRACE');
    }
    
    if (_allowedMethods.isEmpty) {
      throw ArgumentError('At least one HTTP method must be provided');
    }
  }
  
  void addMethod(String method, ViewFunction view) {
    final upperMethod = method.toUpperCase();
    _methods[upperMethod] = view;
    if (!_allowedMethods.contains(upperMethod)) {
      _allowedMethods.add(upperMethod);
    }
  }
  
  void removeMethod(String method) {
    final upperMethod = method.toUpperCase();
    _methods.remove(upperMethod);
    _allowedMethods.remove(upperMethod);
  }
  
  List<String> get allowedMethods => List.unmodifiable(_allowedMethods);
  
  FutureOr<HttpResponse> dispatch(HttpRequest request, Map<String, String> kwargs) {
    final method = request.method.toUpperCase();
    
    if (!_allowedMethods.contains(method)) {
      throw HttpMethodNotAllowed(
        'Method $method not allowed',
        allowedMethods: _allowedMethods,
      );
    }
    
    final view = _methods[method];
    if (view == null) {
      throw HttpMethodNotAllowed(
        'Method $method not implemented',
        allowedMethods: _allowedMethods,
      );
    }
    
    return view(request, kwargs);
  }
}

class MethodRoute extends URLPattern {
  @override
  final String pattern;
  final MethodBasedView view;
  @override
  final String? name;
  @override
  final List<String> allowedMethods;
  final RegExp _regex;
  final List<String> _groupNames;
  final Map<String, PathConverter> _converters;

  MethodRoute({
    required this.pattern,
    required this.view,
    this.name,
  }) : allowedMethods = view.allowedMethods,
       _regex = Route.compilePattern(pattern).$1,
       _groupNames = Route.compilePattern(pattern).$2,
       _converters = Route.extractConverters(pattern);

  @override
  ResolverMatch? resolve(String path) {
    final match = _regex.firstMatch(path);
    if (match == null) return null;

    final kwargs = <String, String>{};
    final args = <String>[];

    for (final groupName in _groupNames) {
      final value = match.namedGroup(groupName);
      if (value != null) {
        final converter = _converters[groupName];
        if (converter != null) {
          try {
            final convertedValue = converter.convert(value);
            kwargs[groupName] = convertedValue.toString();
          } catch (e) {
            return null;
          }
        } else {
          kwargs[groupName] = value;
        }
      }
    }

    return ResolverMatch(
      func: (request, kwargs) => view.dispatch(request, kwargs),
      args: args,
      kwargs: kwargs,
      urlName: name ?? '',
      appName: '',
      namespace: '',
      namespaces: [],
      route: this,
    );
  }

  @override
  String? reverse(String viewName, {Map<String, String>? kwargs, List<String>? args, List<String>? namespaces}) {
    if (name != viewName) return null;

    String url = pattern;
    final providedKwargs = kwargs ?? {};

    for (final groupName in _groupNames) {
      final value = providedKwargs[groupName];
      if (value == null) return null;

      final converter = _converters[groupName];
      if (converter != null) {
        try {
          final convertedValue = converter.convert(value);
          url = url.replaceAll('<${converter.name}:$groupName>', convertedValue.toString());
        } catch (e) {
          return null;
        }
      } else {
        url = url.replaceAll('<$groupName>', value);
      }
    }

    final remainingConverters = RegExp(r'<[^>]+>');
    if (remainingConverters.hasMatch(url)) {
      return null;
    }

    return url;
  }
}

URLPattern methodPath(String route, MethodBasedView view, {String? name}) {
  return MethodRoute(pattern: route, view: view, name: name);
}

URLPattern get(String route, ViewFunction view, {String? name}) {
  return Route(
    pattern: route,
    view: view,
    name: name,
    allowedMethods: ['GET', 'HEAD'],
  );
}

URLPattern post(String route, ViewFunction view, {String? name}) {
  return Route(
    pattern: route,
    view: view,
    name: name,
    allowedMethods: ['POST'],
  );
}

URLPattern put(String route, ViewFunction view, {String? name}) {
  return Route(
    pattern: route,
    view: view,
    name: name,
    allowedMethods: ['PUT'],
  );
}

URLPattern patch(String route, ViewFunction view, {String? name}) {
  return Route(
    pattern: route,
    view: view,
    name: name,
    allowedMethods: ['PATCH'],
  );
}

URLPattern delete(String route, ViewFunction view, {String? name}) {
  return Route(
    pattern: route,
    view: view,
    name: name,
    allowedMethods: ['DELETE'],
  );
}

URLPattern head(String route, ViewFunction view, {String? name}) {
  return Route(
    pattern: route,
    view: view,
    name: name,
    allowedMethods: ['HEAD'],
  );
}

URLPattern options(String route, ViewFunction view, {String? name}) {
  return Route(
    pattern: route,
    view: view,
    name: name,
    allowedMethods: ['OPTIONS'],
  );
}

URLPattern trace(String route, ViewFunction view, {String? name}) {
  return Route(
    pattern: route,
    view: view,
    name: name,
    allowedMethods: ['TRACE'],
  );
}

class HttpMethodNotAllowed implements Exception {
  final String message;
  final List<String> allowedMethods;
  final int statusCode;
  
  HttpMethodNotAllowed(this.message, {required this.allowedMethods}) 
      : statusCode = 405;
  
  HttpResponse toResponse() {
    return HttpResponse.methodNotAllowed(
      message,
      allowedMethods: allowedMethods,
    );
  }
  
  @override
  String toString() => 'HttpMethodNotAllowed: $message';
}