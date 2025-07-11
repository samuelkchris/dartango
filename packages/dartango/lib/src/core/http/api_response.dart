import 'dart:convert';

import 'response.dart';

class ApiResponse extends HttpResponse {
  final bool success;
  final String? message;
  final dynamic data;
  final Map<String, dynamic>? errors;
  final Map<String, dynamic>? meta;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
    this.meta,
    int statusCode = 200,
    Map<String, String>? headers,
  }) : super.json(
          _buildResponseBody(success, message, data, errors, meta),
          statusCode: statusCode,
          headers: headers,
        );

  static Map<String, dynamic> _buildResponseBody(
    bool success,
    String? message,
    dynamic data,
    Map<String, dynamic>? errors,
    Map<String, dynamic>? meta,
  ) {
    final response = <String, dynamic>{
      'success': success,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (message != null) response['message'] = message;
    if (data != null) response['data'] = data;
    if (errors != null) response['errors'] = errors;
    if (meta != null) response['meta'] = meta;

    return response;
  }

  factory ApiResponse.success({
    String? message,
    dynamic data,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) {
    return ApiResponse(
      success: true,
      message: message,
      data: data,
      meta: meta,
      statusCode: 200,
      headers: headers,
    );
  }

  factory ApiResponse.created({
    String? message,
    dynamic data,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) {
    return ApiResponse(
      success: true,
      message: message ?? 'Resource created successfully',
      data: data,
      meta: meta,
      statusCode: 201,
      headers: headers,
    );
  }

  factory ApiResponse.error({
    String? message,
    Map<String, dynamic>? errors,
    Map<String, dynamic>? meta,
    int statusCode = 400,
    Map<String, String>? headers,
  }) {
    return ApiResponse(
      success: false,
      message: message ?? 'An error occurred',
      errors: errors,
      meta: meta,
      statusCode: statusCode,
      headers: headers,
    );
  }

  factory ApiResponse.validationError({
    String? message,
    required Map<String, dynamic> errors,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) {
    return ApiResponse(
      success: false,
      message: message ?? 'Validation failed',
      errors: errors,
      meta: meta,
      statusCode: 422,
      headers: headers,
    );
  }

  factory ApiResponse.unauthorized({
    String? message,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) {
    return ApiResponse(
      success: false,
      message: message ?? 'Unauthorized',
      meta: meta,
      statusCode: 401,
      headers: headers,
    );
  }

  factory ApiResponse.forbidden({
    String? message,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) {
    return ApiResponse(
      success: false,
      message: message ?? 'Forbidden',
      meta: meta,
      statusCode: 403,
      headers: headers,
    );
  }

  factory ApiResponse.notFound({
    String? message,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) {
    return ApiResponse(
      success: false,
      message: message ?? 'Resource not found',
      meta: meta,
      statusCode: 404,
      headers: headers,
    );
  }

  factory ApiResponse.serverError({
    String? message,
    Map<String, dynamic>? errors,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) {
    return ApiResponse(
      success: false,
      message: message ?? 'Internal server error',
      errors: errors,
      meta: meta,
      statusCode: 500,
      headers: headers,
    );
  }
}

class PaginatedResponse extends ApiResponse {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  PaginatedResponse({
    required List<dynamic> items,
    required this.page,
    required this.limit,
    required this.total,
    String? message,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  })  : totalPages = (total / limit).ceil(),
        hasNext = page < (total / limit).ceil(),
        hasPrevious = page > 1,
        super(
          success: true,
          message: message,
          data: items,
          meta: {
            'pagination': {
              'page': page,
              'limit': limit,
              'total': total,
              'total_pages': (total / limit).ceil(),
              'has_next': page < (total / limit).ceil(),
              'has_previous': page > 1,
            },
            ...?meta,
          },
          headers: headers,
        );

  factory PaginatedResponse.fromQuery({
    required List<dynamic> items,
    required int page,
    required int limit,
    required int total,
    String? message,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) {
    return PaginatedResponse(
      items: items,
      page: page,
      limit: limit,
      total: total,
      message: message,
      meta: meta,
      headers: headers,
    );
  }
}

class ListResponse extends ApiResponse {
  final int count;

  ListResponse({
    required List<dynamic> items,
    String? message,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  })  : count = items.length,
        super(
          success: true,
          message: message,
          data: items,
          meta: {
            'count': items.length,
            ...?meta,
          },
          headers: headers,
        );
}

class DetailResponse extends ApiResponse {
  DetailResponse({
    required dynamic item,
    String? message,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) : super(
          success: true,
          message: message,
          data: item,
          meta: meta,
          headers: headers,
        );
}

class MessageResponse extends ApiResponse {
  MessageResponse({
    required String message,
    Map<String, dynamic>? meta,
    int statusCode = 200,
    Map<String, String>? headers,
  }) : super(
          success: true,
          message: message,
          meta: meta,
          statusCode: statusCode,
          headers: headers,
        );
}

extension ApiResponseExtensions on HttpResponse {
  static ApiResponse success({
    String? message,
    dynamic data,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) =>
      ApiResponse.success(
        message: message,
        data: data,
        meta: meta,
        headers: headers,
      );

  static ApiResponse error({
    String? message,
    Map<String, dynamic>? errors,
    Map<String, dynamic>? meta,
    int statusCode = 400,
    Map<String, String>? headers,
  }) =>
      ApiResponse.error(
        message: message,
        errors: errors,
        meta: meta,
        statusCode: statusCode,
        headers: headers,
      );

  static PaginatedResponse paginated({
    required List<dynamic> items,
    required int page,
    required int limit,
    required int total,
    String? message,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) =>
      PaginatedResponse(
        items: items,
        page: page,
        limit: limit,
        total: total,
        message: message,
        meta: meta,
        headers: headers,
      );
}

mixin ApiResponseMixin {
  ApiResponse success({
    String? message,
    dynamic data,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) =>
      ApiResponse.success(
        message: message,
        data: data,
        meta: meta,
        headers: headers,
      );

  ApiResponse created({
    String? message,
    dynamic data,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) =>
      ApiResponse.created(
        message: message,
        data: data,
        meta: meta,
        headers: headers,
      );

  ApiResponse error({
    String? message,
    Map<String, dynamic>? errors,
    Map<String, dynamic>? meta,
    int statusCode = 400,
    Map<String, String>? headers,
  }) =>
      ApiResponse.error(
        message: message,
        errors: errors,
        meta: meta,
        statusCode: statusCode,
        headers: headers,
      );

  ApiResponse validationError({
    String? message,
    required Map<String, dynamic> errors,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) =>
      ApiResponse.validationError(
        message: message,
        errors: errors,
        meta: meta,
        headers: headers,
      );

  ApiResponse unauthorized({
    String? message,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) =>
      ApiResponse.unauthorized(
        message: message,
        meta: meta,
        headers: headers,
      );

  ApiResponse forbidden({
    String? message,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) =>
      ApiResponse.forbidden(
        message: message,
        meta: meta,
        headers: headers,
      );

  ApiResponse notFound({
    String? message,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) =>
      ApiResponse.notFound(
        message: message,
        meta: meta,
        headers: headers,
      );

  PaginatedResponse paginated({
    required List<dynamic> items,
    required int page,
    required int limit,
    required int total,
    String? message,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) =>
      PaginatedResponse(
        items: items,
        page: page,
        limit: limit,
        total: total,
        message: message,
        meta: meta,
        headers: headers,
      );

  ListResponse list({
    required List<dynamic> items,
    String? message,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) =>
      ListResponse(
        items: items,
        message: message,
        meta: meta,
        headers: headers,
      );

  DetailResponse detail({
    required dynamic item,
    String? message,
    Map<String, dynamic>? meta,
    Map<String, String>? headers,
  }) =>
      DetailResponse(
        item: item,
        message: message,
        meta: meta,
        headers: headers,
      );
}
