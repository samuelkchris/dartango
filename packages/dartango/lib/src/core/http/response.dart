import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart' as shelf;

class HttpResponse {
  final int statusCode;
  final Map<String, String> headers;
  final Object? body;
  final Encoding encoding;
  final bool streaming;
  final Stream<List<int>>? streamBody;
  final String? reasonPhrase;

  HttpResponse(
    this.body, {
    this.statusCode = 200,
    Map<String, String>? headers,
    this.encoding = utf8,
    this.streaming = false,
    this.streamBody,
    this.reasonPhrase,
  }) : headers = headers ?? <String, String>{};

  HttpResponse.ok(
    Object? body, {
    Map<String, String>? headers,
    Encoding? encoding,
  }) : this(
          body,
          statusCode: 200,
          headers: headers,
          encoding: encoding ?? utf8,
        );

  HttpResponse.created(
    Object? body, {
    Map<String, String>? headers,
    Encoding? encoding,
  }) : this(
          body,
          statusCode: 201,
          headers: headers,
          encoding: encoding ?? utf8,
        );

  HttpResponse.noContent({
    Map<String, String>? headers,
  }) : this(
          null,
          statusCode: 204,
          headers: headers,
        );

  HttpResponse.badRequest(
    Object? body, {
    Map<String, String>? headers,
    Encoding? encoding,
  }) : this(
          body,
          statusCode: 400,
          headers: headers,
          encoding: encoding ?? utf8,
        );

  HttpResponse.unauthorized(
    Object? body, {
    Map<String, String>? headers,
    Encoding? encoding,
  }) : this(
          body,
          statusCode: 401,
          headers: headers,
          encoding: encoding ?? utf8,
        );

  HttpResponse.forbidden(
    Object? body, {
    Map<String, String>? headers,
    Encoding? encoding,
  }) : this(
          body,
          statusCode: 403,
          headers: headers,
          encoding: encoding ?? utf8,
        );

  HttpResponse.notFound(
    Object? body, {
    Map<String, String>? headers,
    Encoding? encoding,
  }) : this(
          body,
          statusCode: 404,
          headers: headers,
          encoding: encoding ?? utf8,
        );

  HttpResponse.methodNotAllowed(
    Object? body, {
    required List<String> allowedMethods,
    Map<String, String>? headers,
    Encoding? encoding,
  }) : this(
          body,
          statusCode: 405,
          headers: {
            'Allow': allowedMethods.join(', '),
            ...?headers,
          },
          encoding: encoding ?? utf8,
        );

  HttpResponse.internalServerError(
    Object? body, {
    Map<String, String>? headers,
    Encoding? encoding,
  }) : this(
          body,
          statusCode: 500,
          headers: headers,
          encoding: encoding ?? utf8,
        );

  HttpResponse.json(
    Object? data, {
    int statusCode = 200,
    Map<String, String>? headers,
    JsonEncoder? encoder,
    bool? indent,
  }) : this(
          (encoder ??
                  (indent == true
                      ? JsonEncoder.withIndent('  ')
                      : JsonEncoder()))
              .convert(data),
          statusCode: statusCode,
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            ...?headers,
          },
        );

  HttpResponse.html(
    String html, {
    int statusCode = 200,
    Map<String, String>? headers,
    Encoding? encoding,
  }) : this(
          html,
          statusCode: statusCode,
          headers: {
            'Content-Type': 'text/html; charset=${(encoding ?? utf8).name}',
            ...?headers,
          },
          encoding: encoding ?? utf8,
        );

  HttpResponse.text(
    String text, {
    int statusCode = 200,
    Map<String, String>? headers,
    Encoding? encoding,
  }) : this(
          text,
          statusCode: statusCode,
          headers: {
            'Content-Type': 'text/plain; charset=${(encoding ?? utf8).name}',
            ...?headers,
          },
          encoding: encoding ?? utf8,
        );

  HttpResponse.xml(
    String xml, {
    int statusCode = 200,
    Map<String, String>? headers,
    Encoding? encoding,
  }) : this(
          xml,
          statusCode: statusCode,
          headers: {
            'Content-Type':
                'application/xml; charset=${(encoding ?? utf8).name}',
            ...?headers,
          },
          encoding: encoding ?? utf8,
        );

  HttpResponse.redirect(
    String location, {
    int statusCode = 302,
    Map<String, String>? headers,
  }) : this(
          '',
          statusCode: statusCode,
          headers: {
            'Location': location,
            ...?headers,
          },
        );

  HttpResponse.permanentRedirect(
    String location, {
    Map<String, String>? headers,
  }) : this.redirect(
          location,
          statusCode: 301,
          headers: headers,
        );

  HttpResponse.file(
    File file, {
    int statusCode = 200,
    Map<String, String>? headers,
    String? contentType,
    bool? attachment,
    String? filename,
  }) : this(
          file,
          statusCode: statusCode,
          headers: {
            'Content-Type': contentType ?? _getMimeType(file.path),
            if (attachment == true)
              'Content-Disposition':
                  'attachment${filename != null ? '; filename="$filename"' : ''}',
            'Content-Length': file.lengthSync().toString(),
            ...?headers,
          },
        );

  HttpResponse.stream(
    Stream<List<int>> stream, {
    int statusCode = 200,
    Map<String, String>? headers,
    String? contentType,
    int? contentLength,
  }) : this(
          null,
          statusCode: statusCode,
          headers: {
            'Content-Type': contentType ?? 'application/octet-stream',
            if (contentLength != null)
              'Content-Length': contentLength.toString(),
            ...?headers,
          },
          streaming: true,
          streamBody: stream,
        );

  HttpResponse.bytes(
    Uint8List bytes, {
    int statusCode = 200,
    Map<String, String>? headers,
    String? contentType,
  }) : this(
          bytes,
          statusCode: statusCode,
          headers: {
            'Content-Type': contentType ?? 'application/octet-stream',
            'Content-Length': bytes.length.toString(),
            ...?headers,
          },
        );

  static String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'html':
        return 'text/html';
      case 'css':
        return 'text/css';
      case 'js':
        return 'application/javascript';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'svg':
        return 'image/svg+xml';
      case 'pdf':
        return 'application/pdf';
      case 'zip':
        return 'application/zip';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  HttpResponse setHeader(String name, String value) {
    final newHeaders = Map<String, String>.from(headers);
    newHeaders[name] = value;
    return _copyWith(headers: newHeaders);
  }

  HttpResponse setHeaders(Map<String, String> newHeaders) {
    final mergedHeaders = Map<String, String>.from(headers);
    mergedHeaders.addAll(newHeaders);
    return _copyWith(headers: mergedHeaders);
  }

  HttpResponse removeHeader(String name) {
    final newHeaders = Map<String, String>.from(headers);
    newHeaders.remove(name);
    return _copyWith(headers: newHeaders);
  }

  HttpResponse setCookie(
    String name,
    String value, {
    String? domain,
    String? path,
    DateTime? expires,
    int? maxAge,
    bool? secure,
    bool? httpOnly,
    SameSite? sameSite,
  }) {
    final cookie = Cookie(name, value)
      ..domain = domain
      ..path = path
      ..expires = expires
      ..maxAge = maxAge
      ..secure = secure ?? false
      ..httpOnly = httpOnly ?? false
      ..sameSite = sameSite;

    return setHeader('Set-Cookie', cookie.toString());
  }

  HttpResponse deleteCookie(
    String name, {
    String? domain,
    String? path,
  }) {
    return setCookie(
      name,
      '',
      domain: domain,
      path: path,
      expires: DateTime.fromMillisecondsSinceEpoch(0),
      maxAge: 0,
    );
  }

  HttpResponse cache({
    Duration? maxAge,
    bool? private,
    bool? noCache,
    bool? noStore,
    bool? mustRevalidate,
    Duration? sMaxAge,
  }) {
    final directives = <String>[];

    if (maxAge != null) directives.add('max-age=${maxAge.inSeconds}');
    if (private == true) directives.add('private');
    if (noCache == true) directives.add('no-cache');
    if (noStore == true) directives.add('no-store');
    if (mustRevalidate == true) directives.add('must-revalidate');
    if (sMaxAge != null) directives.add('s-maxage=${sMaxAge.inSeconds}');

    return setHeader('Cache-Control', directives.join(', '));
  }

  HttpResponse etag(String etag) {
    return setHeader('ETag', '"$etag"');
  }

  HttpResponse lastModified(DateTime dateTime) {
    return setHeader('Last-Modified', HttpDate.format(dateTime));
  }

  HttpResponse vary(List<String> headers) {
    return setHeader('Vary', headers.join(', '));
  }

  HttpResponse contentLanguage(String language) {
    return setHeader('Content-Language', language);
  }

  HttpResponse contentEncoding(String encoding) {
    return setHeader('Content-Encoding', encoding);
  }

  HttpResponse cors({
    List<String>? allowOrigins,
    List<String>? allowMethods,
    List<String>? allowHeaders,
    List<String>? exposeHeaders,
    bool? allowCredentials,
    int? maxAge,
  }) {
    final corsHeaders = <String, String>{};

    if (allowOrigins != null) {
      corsHeaders['Access-Control-Allow-Origin'] = allowOrigins.join(', ');
    }
    if (allowMethods != null) {
      corsHeaders['Access-Control-Allow-Methods'] = allowMethods.join(', ');
    }
    if (allowHeaders != null) {
      corsHeaders['Access-Control-Allow-Headers'] = allowHeaders.join(', ');
    }
    if (exposeHeaders != null) {
      corsHeaders['Access-Control-Expose-Headers'] = exposeHeaders.join(', ');
    }
    if (allowCredentials == true) {
      corsHeaders['Access-Control-Allow-Credentials'] = 'true';
    }
    if (maxAge != null) {
      corsHeaders['Access-Control-Max-Age'] = maxAge.toString();
    }

    return setHeaders(corsHeaders);
  }

  HttpResponse _copyWith({
    int? statusCode,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool? streaming,
    Stream<List<int>>? streamBody,
    String? reasonPhrase,
  }) {
    return HttpResponse(
      body ?? this.body,
      statusCode: statusCode ?? this.statusCode,
      headers: headers ?? this.headers,
      encoding: encoding ?? this.encoding,
      streaming: streaming ?? this.streaming,
      streamBody: streamBody ?? this.streamBody,
      reasonPhrase: reasonPhrase ?? this.reasonPhrase,
    );
  }

  shelf.Response toShelfResponse() {
    if (streaming && streamBody != null) {
      return shelf.Response(
        statusCode,
        body: streamBody,
        headers: headers,
      );
    }

    Object? responseBody = body;
    if (body is String) {
      responseBody = encoding.encode(body as String);
    } else if (body is File) {
      responseBody = (body as File).openRead();
    }

    return shelf.Response(
      statusCode,
      body: responseBody,
      headers: headers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status_code': statusCode,
      'headers': headers,
      'body': body is String ? body : body?.toString(),
      'encoding': encoding.name,
      'streaming': streaming,
    };
  }

  @override
  String toString() => 'HttpResponse($statusCode, ${headers.length} headers)';
}

class StreamingHttpResponse extends HttpResponse {
  final StreamController<List<int>> _controller = StreamController<List<int>>();

  StreamingHttpResponse({
    int statusCode = 200,
    Map<String, String>? headers,
    String? contentType,
  }) : super(
          null,
          statusCode: statusCode,
          headers: {
            'Content-Type': contentType ?? 'text/plain',
            ...?headers,
          },
          streaming: true,
          streamBody: null,
        );

  void write(String data) {
    _controller.add(utf8.encode(data));
  }

  void writeBytes(List<int> bytes) {
    _controller.add(bytes);
  }

  Future<void> close() async {
    await _controller.close();
  }

  @override
  shelf.Response toShelfResponse() {
    return shelf.Response(
      statusCode,
      body: _controller.stream,
      headers: headers,
    );
  }
}

class FileResponse extends HttpResponse {
  final File file;
  final String? filename;
  final bool asAttachment;

  FileResponse(
    this.file, {
    int statusCode = 200,
    Map<String, String>? headers,
    String? contentType,
    this.filename,
    this.asAttachment = false,
  }) : super.file(
          file,
          statusCode: statusCode,
          headers: headers,
          contentType: contentType,
          attachment: asAttachment,
          filename: filename,
        );
}

class JsonResponse extends HttpResponse {
  JsonResponse(
    Object? data, {
    int statusCode = 200,
    Map<String, String>? headers,
    JsonEncoder? encoder,
    bool indent = false,
  }) : super.json(
          data,
          statusCode: statusCode,
          headers: headers,
          encoder: encoder,
          indent: indent,
        );
}

class TemplateResponse extends HttpResponse {
  final String templateName;
  final Map<String, dynamic> context;

  TemplateResponse(
    this.templateName,
    this.context, {
    int statusCode = 200,
    Map<String, String>? headers,
    String? contentType,
  }) : super(
          null,
          statusCode: statusCode,
          headers: {
            'Content-Type': contentType ?? 'text/html; charset=utf-8',
            ...?headers,
          },
        );

  @override
  String toString() => 'TemplateResponse($templateName, $statusCode)';
}
