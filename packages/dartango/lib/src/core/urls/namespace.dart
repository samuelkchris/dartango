import 'resolver.dart';

class NamespaceResolver extends URLResolver {
  final String? _appName;
  final String? _namespace;

  NamespaceResolver({
    required List<URLPattern> urlPatterns,
    String? appName,
    String? namespace,
    bool enableCaching = true,
  })  : _appName = appName,
        _namespace = namespace,
        super(
          urlPatterns: urlPatterns,
          appName: appName,
          namespace: namespace,
          enableCaching: enableCaching,
        );

  @override
  ResolverMatch? resolve(String path) {
    final match = super.resolve(path);
    if (match == null) return null;

    return ResolverMatch(
      func: match.func,
      args: match.args,
      kwargs: match.kwargs,
      urlName: match.urlName,
      appName: _appName ?? match.appName,
      namespace: _namespace ?? match.namespace,
      namespaces: [
        if (_namespace != null) _namespace!,
        ...match.namespaces,
      ],
      route: match.route,
    );
  }

  @override
  String? reverse(String viewName,
      {Map<String, String>? kwargs, List<String>? args}) {
    String targetViewName = viewName;
    List<String> expectedNamespaces = [];

    if (viewName.contains(':')) {
      final parts = viewName.split(':');
      expectedNamespaces = parts.take(parts.length - 1).toList();
      targetViewName = parts.last;
    }

    if (expectedNamespaces.isNotEmpty) {
      if (_namespace != null && expectedNamespaces.first == _namespace) {
        expectedNamespaces.removeAt(0);
        if (expectedNamespaces.isNotEmpty) {
          targetViewName = '${expectedNamespaces.join(':')}:$targetViewName';
        }
      } else if (_namespace != null) {
        return null;
      }
    }

    return super.reverse(targetViewName, kwargs: kwargs, args: args);
  }
}

class IncludeNamespace extends URLPattern {
  final String prefix;
  final NamespaceResolver resolver;
  @override
  final String? name;
  @override
  final List<String> allowedMethods;

  IncludeNamespace({
    required this.prefix,
    required this.resolver,
    this.name,
    this.allowedMethods = const [
      'GET',
      'POST',
      'PUT',
      'DELETE',
      'PATCH',
      'HEAD',
      'OPTIONS',
      'TRACE'
    ],
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
  String? reverse(String viewName,
      {Map<String, String>? kwargs,
      List<String>? args,
      List<String>? namespaces}) {
    final url = resolver.reverse(viewName, kwargs: kwargs, args: args);
    if (url == null) return null;

    return '$prefix$url';
  }
}

URLPattern includeNamespace(String prefix, List<URLPattern> patterns,
    {String? namespace, String? appName}) {
  final resolver = NamespaceResolver(
    urlPatterns: patterns,
    namespace: namespace,
    appName: appName,
  );
  return IncludeNamespace(prefix: prefix, resolver: resolver);
}

class URLNamespace {
  final String name;
  final List<URLPattern> patterns;
  final String? appName;

  const URLNamespace({
    required this.name,
    required this.patterns,
    this.appName,
  });
}

class AppNamespace {
  final String name;
  final List<URLPattern> patterns;

  const AppNamespace({
    required this.name,
    required this.patterns,
  });
}

class NamespaceManager {
  final Map<String, URLNamespace> _namespaces = {};
  final Map<String, AppNamespace> _appNamespaces = {};

  void registerNamespace(String name, List<URLPattern> patterns,
      {String? appName}) {
    _namespaces[name] = URLNamespace(
      name: name,
      patterns: patterns,
      appName: appName,
    );
  }

  void registerApp(String name, List<URLPattern> patterns) {
    _appNamespaces[name] = AppNamespace(
      name: name,
      patterns: patterns,
    );
  }

  URLNamespace? getNamespace(String name) {
    return _namespaces[name];
  }

  AppNamespace? getApp(String name) {
    return _appNamespaces[name];
  }

  List<String> get namespaceNames => _namespaces.keys.toList();
  List<String> get appNames => _appNamespaces.keys.toList();

  void clear() {
    _namespaces.clear();
    _appNamespaces.clear();
  }
}

final namespaceManager = NamespaceManager();

String reverseNamespace(String namespacedView,
    {Map<String, String>? kwargs, List<String>? args}) {
  final parts = namespacedView.split(':');
  if (parts.length < 2) {
    throw ArgumentError(
        'Namespaced view must contain at least one colon: $namespacedView');
  }

  final namespacePath = parts.take(parts.length - 1).join(':');
  final viewName = parts.last;

  final namespace = namespaceManager.getNamespace(namespacePath);
  if (namespace == null) {
    throw NoReverseMatch('No namespace found for: $namespacePath');
  }

  final resolver = NamespaceResolver(
    urlPatterns: namespace.patterns,
    namespace: namespace.name,
    appName: namespace.appName,
  );

  final url = resolver.reverse(viewName, kwargs: kwargs, args: args);
  if (url == null) {
    throw NoReverseMatch('No reverse match found for: $namespacedView');
  }

  return url;
}
