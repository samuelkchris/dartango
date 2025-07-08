import 'dart:async';

import '../http/request.dart';
import '../http/response.dart';
import 'converters.dart';

typedef ViewFunction = FutureOr<HttpResponse> Function(HttpRequest request, Map<String, String> kwargs);

class ResolverMatch {
  final ViewFunction func;
  final List<String> args;
  final Map<String, String> kwargs;
  final String urlName;
  final String appName;
  final String namespace;
  final List<String> namespaces;
  final URLPattern route;

  const ResolverMatch({
    required this.func,
    required this.args,
    required this.kwargs,
    required this.urlName,
    required this.appName,
    required this.namespace,
    required this.namespaces,
    required this.route,
  });

  @override
  String toString() {
    return 'ResolverMatch(func: $func, args: $args, kwargs: $kwargs, '
        'url_name: $urlName, app_name: $appName, namespace: $namespace, '
        'namespaces: $namespaces)';
  }
}

class URLResolver {
  final List<URLPattern> urlPatterns;
  final String? appName;
  final String? namespace;
  final Map<String, ResolverMatch> _cache = {};
  final bool _enableCaching;

  URLResolver({
    required this.urlPatterns,
    this.appName,
    this.namespace,
    bool enableCaching = true,
  }) : _enableCaching = enableCaching;

  ResolverMatch? resolve(String path) {
    if (_enableCaching && _cache.containsKey(path)) {
      return _cache[path];
    }

    for (final pattern in urlPatterns) {
      final match = pattern.resolve(path);
      if (match != null) {
        final resolverMatch = ResolverMatch(
          func: match.func,
          args: match.args,
          kwargs: match.kwargs,
          urlName: match.urlName,
          appName: appName ?? match.appName,
          namespace: namespace ?? match.namespace,
          namespaces: [
            if (namespace != null) namespace!,
            ...match.namespaces,
          ],
          route: match.route,
        );

        if (_enableCaching) {
          _cache[path] = resolverMatch;
        }

        return resolverMatch;
      }
    }

    return null;
  }

  String? reverse(String viewName, {Map<String, String>? kwargs, List<String>? args}) {
    final namespaces = <String>[];
    if (namespace != null) {
      namespaces.add(namespace!);
    }

    String targetViewName = viewName;
    if (targetViewName.contains(':')) {
      final parts = targetViewName.split(':');
      if (parts.length >= 2) {
        namespaces.addAll(parts.take(parts.length - 1));
        targetViewName = parts.last;
      }
    }

    for (final pattern in urlPatterns) {
      final url = pattern.reverse(targetViewName, kwargs: kwargs, args: args, namespaces: namespaces);
      if (url != null) {
        return url;
      }
    }

    return null;
  }

  void clearCache() {
    _cache.clear();
  }
}

abstract class URLPattern {
  String get pattern;
  String? get name;
  List<String> get allowedMethods;
  
  ResolverMatch? resolve(String path);
  String? reverse(String viewName, {Map<String, String>? kwargs, List<String>? args, List<String>? namespaces});
}

class Route extends URLPattern {
  @override
  final String pattern;
  final ViewFunction view;
  @override
  final String? name;
  @override
  final List<String> allowedMethods;
  final RegExp _regex;
  final List<String> _groupNames;
  final Map<String, PathConverter> _converters;

  Route({
    required this.pattern,
    required this.view,
    this.name,
    this.allowedMethods = const ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS', 'TRACE'],
  }) : _regex = compilePattern(pattern).$1,
       _groupNames = compilePattern(pattern).$2,
       _converters = extractConverters(pattern);

  static (RegExp, List<String>) compilePattern(String pattern) {
    final groupNames = <String>[];
    String regexPattern = pattern;

    final converterRegex = RegExp(r'<(?:([^:>]+):)?([^>]+)>');
    final matches = converterRegex.allMatches(pattern);

    for (final match in matches) {
      final converter = match.group(1) ?? 'str';
      final parameter = match.group(2)!;
      groupNames.add(parameter);

      final converterPattern = PathConverter.getConverter(converter).pattern;
      regexPattern = regexPattern.replaceFirst(match.group(0)!, '(?<$parameter>$converterPattern)');
    }

    regexPattern = '^$regexPattern\$';
    return (RegExp(regexPattern), groupNames);
  }

  static Map<String, PathConverter> extractConverters(String pattern) {
    final converters = <String, PathConverter>{};
    final converterRegex = RegExp(r'<(?:([^:>]+):)?([^>]+)>');
    final matches = converterRegex.allMatches(pattern);

    for (final match in matches) {
      final converter = match.group(1) ?? 'str';
      final parameter = match.group(2)!;
      converters[parameter] = PathConverter.getConverter(converter);
    }

    return converters;
  }

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
      func: view,
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

class Include extends URLPattern {
  final String prefix;
  final URLResolver resolver;
  @override
  final String? name;
  @override
  final List<String> allowedMethods;

  Include({
    required this.prefix,
    required this.resolver,
    this.name,
    this.allowedMethods = const ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS', 'TRACE'],
  });

  @override
  String get pattern => prefix;

  @override
  ResolverMatch? resolve(String path) {
    if (!path.startsWith(prefix)) return null;

    final remainingPath = path.substring(prefix.length);
    final match = resolver.resolve(remainingPath);
    if (match == null) return null;

    return ResolverMatch(
      func: match.func,
      args: match.args,
      kwargs: match.kwargs,
      urlName: match.urlName,
      appName: match.appName,
      namespace: match.namespace,
      namespaces: match.namespaces,
      route: match.route,
    );
  }

  @override
  String? reverse(String viewName, {Map<String, String>? kwargs, List<String>? args, List<String>? namespaces}) {
    final url = resolver.reverse(viewName, kwargs: kwargs, args: args);
    if (url == null) return null;

    return '$prefix$url';
  }
}

class URLConfiguration {
  final URLResolver _resolver;
  
  URLConfiguration(List<URLPattern> urlPatterns, {String? appName, String? namespace})
      : _resolver = URLResolver(
          urlPatterns: urlPatterns,
          appName: appName,
          namespace: namespace,
        );

  ResolverMatch? resolve(String path) => _resolver.resolve(path);
  String? reverse(String viewName, {Map<String, String>? kwargs, List<String>? args}) => 
      _resolver.reverse(viewName, kwargs: kwargs, args: args);
  void clearCache() => _resolver.clearCache();
}

URLPattern path(String route, ViewFunction view, {String? name}) {
  return Route(pattern: route, view: view, name: name);
}

URLPattern re_path(String route, ViewFunction view, {String? name}) {
  return Route(pattern: route, view: view, name: name);
}

URLPattern include(String prefix, URLResolver resolver, {String? name}) {
  return Include(prefix: prefix, resolver: resolver, name: name);
}

class NoReverseMatch implements Exception {
  final String message;
  
  const NoReverseMatch(this.message);
  
  @override
  String toString() => 'NoReverseMatch: $message';
}

class Resolver404 implements Exception {
  final String message;
  
  const Resolver404(this.message);
  
  @override
  String toString() => 'Resolver404: $message';
}