import 'package:shelf/shelf.dart' as shelf;
import '../../lib/src/core/http/request.dart';

/// Creates an HttpRequest for testing purposes
HttpRequest createTestRequest(
  String method,
  String path, {
  Map<String, String>? headers,
  String? body,
  dynamic user,
}) {
  final uri = Uri.parse('http://localhost$path');
  final shelfHeaders = headers ?? {};
  final shelfRequest = shelf.Request(
    method,
    uri,
    headers: shelfHeaders,
    body: body ?? '',
  );
  final request = HttpRequest(shelfRequest);

  if (user != null) {
    request.middlewareState['user'] = user;
  }

  return request;
}
