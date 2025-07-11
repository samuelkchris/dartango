import 'dart:async';

import '../http/request.dart';
import '../http/response.dart';
import '../exceptions/http.dart';
import '../templates/engine.dart';
import '../templates/context.dart';

abstract class View {
  final List<String> httpMethodNames = [
    'get',
    'post',
    'put',
    'patch',
    'delete',
    'head',
    'options',
    'trace'
  ];

  Future<HttpResponse> dispatch(HttpRequest request,
      [Map<String, dynamic>? kwargs]) async {
    kwargs ??= {};

    final method = request.method.toLowerCase();

    if (!httpMethodNames.contains(method)) {
      throw MethodNotAllowedException(httpMethodNames);
    }

    final handler = getHandler(method);
    if (handler == null) {
      throw MethodNotAllowedException(getAllowedMethods());
    }

    return await handler(request, kwargs);
  }

  Future<HttpResponse> Function(HttpRequest, Map<String, dynamic>)? getHandler(
      String method) {
    switch (method) {
      case 'get':
        return get;
      case 'post':
        return post;
      case 'put':
        return put;
      case 'patch':
        return patch;
      case 'delete':
        return delete;
      case 'head':
        return head;
      case 'options':
        return options;
      case 'trace':
        return trace;
      default:
        return null;
    }
  }

  List<String> getAllowedMethods() {
    final methods = <String>[];
    for (final method in httpMethodNames) {
      if (getHandler(method) != null) {
        methods.add(method.toUpperCase());
      }
    }
    return methods;
  }

  Future<HttpResponse> get(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    throw MethodNotAllowedException(getAllowedMethods());
  }

  Future<HttpResponse> post(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    throw MethodNotAllowedException(getAllowedMethods());
  }

  Future<HttpResponse> put(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    throw MethodNotAllowedException(getAllowedMethods());
  }

  Future<HttpResponse> patch(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    throw MethodNotAllowedException(getAllowedMethods());
  }

  Future<HttpResponse> delete(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    throw MethodNotAllowedException(getAllowedMethods());
  }

  Future<HttpResponse> head(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    final response = await get(request, kwargs);
    return HttpResponse(
      '',
      statusCode: response.statusCode,
      headers: response.headers,
    );
  }

  Future<HttpResponse> options(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    final response = HttpResponse('');
    response.headers['Allow'] = getAllowedMethods().join(', ');
    response.headers['Content-Length'] = '0';
    return response;
  }

  Future<HttpResponse> trace(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    final response = HttpResponse(request.toString());
    response.headers['Content-Type'] = 'message/http';
    return response;
  }
}

abstract class TemplateView extends View {
  String? templateName;
  String? contentType;
  Map<String, dynamic>? extraContext;

  TemplateView({
    this.templateName,
    this.contentType,
    this.extraContext,
  });

  @override
  Future<HttpResponse> get(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    final context = getContext(request, kwargs);
    return await renderToResponse(context, request);
  }

  Map<String, dynamic> getContext(
      HttpRequest request, Map<String, dynamic> kwargs) {
    final context = <String, dynamic>{
      'view': this,
      'request': request,
    };

    context.addAll(kwargs);

    if (extraContext != null) {
      context.addAll(extraContext!);
    }

    context.addAll(getContextData(request, kwargs));

    return context;
  }

  Map<String, dynamic> getContextData(
      HttpRequest request, Map<String, dynamic> kwargs) {
    return {};
  }

  Future<HttpResponse> renderToResponse(
      Map<String, dynamic> context, HttpRequest request) async {
    final template = getTemplate(request);
    final content = await template.render(TemplateContext(context));

    return HttpResponse.html(
      content,
      headers: contentType != null ? {'Content-Type': contentType!} : null,
    );
  }

  Template getTemplate(HttpRequest request) {
    final name = getTemplateName(request);
    if (name == null) {
      throw ViewException(
          'TemplateView requires either a templateName or an implementation of getTemplateName()');
    }

    return TemplateEngine.instance.getTemplate(name);
  }

  String? getTemplateName(HttpRequest request) {
    return templateName;
  }
}

abstract class RedirectView extends View {
  String? url;
  String? patternName;
  bool permanent = false;
  Map<String, dynamic>? queryStringParams;

  RedirectView({
    this.url,
    this.patternName,
    this.permanent = false,
    this.queryStringParams,
  });

  @override
  Future<HttpResponse> get(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    final redirectUrl = getRedirectUrl(request, kwargs);
    if (redirectUrl == null) {
      throw GoneException();
    }

    return permanent
        ? HttpResponse.permanentRedirect(redirectUrl)
        : HttpResponse.redirect(redirectUrl);
  }

  @override
  Future<HttpResponse> post(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    return await get(request, kwargs);
  }

  @override
  Future<HttpResponse> put(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    return await get(request, kwargs);
  }

  @override
  Future<HttpResponse> patch(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    return await get(request, kwargs);
  }

  @override
  Future<HttpResponse> delete(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    return await get(request, kwargs);
  }

  @override
  Future<HttpResponse> head(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    return await get(request, kwargs);
  }

  @override
  Future<HttpResponse> options(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    return await get(request, kwargs);
  }

  @override
  Future<HttpResponse> trace(
      HttpRequest request, Map<String, dynamic> kwargs) async {
    return await get(request, kwargs);
  }

  String? getRedirectUrl(HttpRequest request, Map<String, dynamic> kwargs) {
    if (url != null) {
      return interpolateUrl(url!, kwargs);
    }

    if (patternName != null) {
      return reverseUrl(patternName!, kwargs);
    }

    return null;
  }

  String interpolateUrl(String url, Map<String, dynamic> kwargs) {
    var result = url;
    for (final entry in kwargs.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value.toString());
    }

    if (queryStringParams != null && queryStringParams!.isNotEmpty) {
      final params = queryStringParams!.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      result += result.contains('?') ? '&$params' : '?$params';
    }

    return result;
  }

  String reverseUrl(String patternName, Map<String, dynamic> kwargs) {
    return patternName;
  }
}

class ViewException implements Exception {
  final String message;

  ViewException(this.message);

  @override
  String toString() => 'ViewException: $message';
}

typedef ViewFunction = Future<HttpResponse> Function(HttpRequest request,
    [Map<String, dynamic>? kwargs]);

class FunctionBasedView extends View {
  final ViewFunction viewFunction;

  FunctionBasedView(this.viewFunction);

  @override
  Future<HttpResponse> dispatch(HttpRequest request,
      [Map<String, dynamic>? kwargs]) async {
    return await viewFunction(request, kwargs);
  }
}

mixin LoginRequiredMixin on View {
  String get loginUrl => '/login/';

  String get redirectFieldName => 'next';

  @override
  Future<HttpResponse> dispatch(HttpRequest request,
      [Map<String, dynamic>? kwargs]) async {
    if (!await isAuthenticated(request)) {
      return await handleNoPermission(request);
    }

    return await super.dispatch(request, kwargs);
  }

  Future<bool> isAuthenticated(HttpRequest request) async {
    return request.user != null && request.user!.isAuthenticated;
  }

  Future<HttpResponse> handleNoPermission(HttpRequest request) async {
    final nextUrl = request.uri.toString();
    final loginUrlWithNext =
        '$loginUrl?$redirectFieldName=${Uri.encodeComponent(nextUrl)}';

    return HttpResponse.redirect(loginUrlWithNext);
  }
}

mixin PermissionRequiredMixin on View {
  List<String> get requiredPermissions => [];

  bool get raiseException => false;

  @override
  Future<HttpResponse> dispatch(HttpRequest request,
      [Map<String, dynamic>? kwargs]) async {
    if (!await hasPermission(request)) {
      return await handleNoPermission(request);
    }

    return await super.dispatch(request, kwargs);
  }

  Future<bool> hasPermission(HttpRequest request) async {
    if (request.user == null || !request.user!.isAuthenticated) {
      return false;
    }

    for (final permission in requiredPermissions) {
      if (!await request.user!.hasPermission(permission)) {
        return false;
      }
    }

    return true;
  }

  Future<HttpResponse> handleNoPermission(HttpRequest request) async {
    if (raiseException) {
      throw ForbiddenException();
    }

    return HttpResponse.redirect('/login/');
  }
}

mixin UserPassesTestMixin on View {
  Future<bool> testFunction(HttpRequest request) async {
    return true;
  }

  String get loginUrl => '/login/';

  String get redirectFieldName => 'next';

  bool get raiseException => false;

  @override
  Future<HttpResponse> dispatch(HttpRequest request,
      [Map<String, dynamic>? kwargs]) async {
    if (!await testFunction(request)) {
      return await handleNoPermission(request);
    }

    return await super.dispatch(request, kwargs);
  }

  Future<HttpResponse> handleNoPermission(HttpRequest request) async {
    if (raiseException) {
      throw ForbiddenException();
    }

    final nextUrl = request.uri.toString();
    final loginUrlWithNext =
        '$loginUrl?$redirectFieldName=${Uri.encodeComponent(nextUrl)}';

    return HttpResponse.redirect(loginUrlWithNext);
  }
}

extension HttpRequestUserExtension on HttpRequest {
  dynamic get user => middlewareState['user'];
}

extension UserExtension on dynamic {
  bool get isAuthenticated => this != null;

  Future<bool> hasPermission(String permission) async {
    return true;
  }
}
