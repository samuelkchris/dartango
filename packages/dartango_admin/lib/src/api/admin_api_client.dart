import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:json_annotation/json_annotation.dart';

import '../models/admin_models.dart';

part 'admin_api_client.g.dart';

/// Auto-generated API client for Dartango admin interface
@RestApi()
abstract class AdminApiClient {
  factory AdminApiClient(Dio dio, {String baseUrl}) = _AdminApiClient;

  /// Authentication endpoints
  @POST('/api/auth/login/')
  Future<AuthResponse> login(@Body() LoginRequest request);

  @POST('/api/auth/logout/')
  Future<LogoutResponse> logout();

  @POST('/api/auth/refresh/')
  Future<AuthResponse> refreshToken(@Body() RefreshTokenRequest request);

  @GET('/api/auth/user/')
  Future<UserProfile> getCurrentUser();

  /// Admin dashboard endpoints
  @GET('/admin/api/')
  Future<AdminIndexResponse> getAdminIndex();

  @GET('/admin/api/apps/')
  Future<AppsListResponse> getAppsList();

  /// Generic model endpoints (auto-generated for each model)
  @GET('/admin/api/{app}/{model}/')
  Future<ModelListResponse<T>> getModelList<T>(
    @Path('app') String app,
    @Path('model') String model, {
    @Query('search') String? search,
    @Query('page') int? page,
    @Query('page_size') int? pageSize,
    @Queries() Map<String, dynamic>? filters,
  });

  @GET('/admin/api/{app}/{model}/{id}/')
  Future<ModelDetailResponse<T>> getModelDetail<T>(
    @Path('app') String app,
    @Path('model') String model,
    @Path('id') String id,
  );

  @POST('/admin/api/{app}/{model}/')
  Future<ModelDetailResponse<T>> createModel<T>(
    @Path('app') String app,
    @Path('model') String model,
    @Body() Map<String, dynamic> data,
  );

  @PUT('/admin/api/{app}/{model}/{id}/')
  Future<ModelDetailResponse<T>> updateModel<T>(
    @Path('app') String app,
    @Path('model') String model,
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  @DELETE('/admin/api/{app}/{model}/{id}/')
  Future<DeleteResponse> deleteModel(
    @Path('app') String app,
    @Path('model') String model,
    @Path('id') String id,
  );

  /// Bulk operations
  @POST('/admin/api/{app}/{model}/bulk_delete/')
  Future<BulkDeleteResponse> bulkDeleteModels(
    @Path('app') String app,
    @Path('model') String model,
    @Body() BulkDeleteRequest request,
  );

  @POST('/admin/api/{app}/{model}/bulk_update/')
  Future<BulkUpdateResponse> bulkUpdateModels(
    @Path('app') String app,
    @Path('model') String model,
    @Body() BulkUpdateRequest request,
  );

  /// Model-specific generated endpoints will be added here
  /// These are auto-generated based on discovered models
  
  // User management (built-in)
  @GET('/admin/api/auth/user/')
  Future<ModelListResponse<AdminUser>> getUsers({
    @Query('search') String? search,
    @Query('page') int? page,
    @Query('page_size') int? pageSize,
    @Query('is_staff') bool? isStaff,
    @Query('is_active') bool? isActive,
  });

  @POST('/admin/api/auth/user/')
  Future<ModelDetailResponse<AdminUser>> createUser(@Body() CreateUserRequest request);

  @PUT('/admin/api/auth/user/{id}/')
  Future<ModelDetailResponse<AdminUser>> updateUser(
    @Path('id') int id,
    @Body() UpdateUserRequest request,
  );

  @DELETE('/admin/api/auth/user/{id}/')
  Future<DeleteResponse> deleteUser(@Path('id') int id);

  // Group management (built-in)
  @GET('/admin/api/auth/group/')
  Future<ModelListResponse<AdminGroup>> getGroups({
    @Query('search') String? search,
    @Query('page') int? page,
    @Query('page_size') int? pageSize,
  });

  @POST('/admin/api/auth/group/')
  Future<ModelDetailResponse<AdminGroup>> createGroup(@Body() CreateGroupRequest request);

  @PUT('/admin/api/auth/group/{id}/')
  Future<ModelDetailResponse<AdminGroup>> updateGroup(
    @Path('id') int id,
    @Body() UpdateGroupRequest request,
  );

  @DELETE('/admin/api/auth/group/{id}/')
  Future<DeleteResponse> deleteGroup(@Path('id') int id);

  /// Dashboard analytics
  @GET('/admin/api/analytics/dashboard/')
  Future<DashboardAnalytics> getDashboardAnalytics();

  @GET('/admin/api/analytics/model_stats/')
  Future<ModelStatsResponse> getModelStats();

  @GET('/admin/api/analytics/user_activity/')
  Future<UserActivityResponse> getUserActivity({
    @Query('days') int? days,
    @Query('limit') int? limit,
  });

  /// File upload endpoints
  @POST('/admin/api/upload/')
  @MultiPart()
  Future<FileUploadResponse> uploadFile(@Part(name: 'file') File file);

  @GET('/admin/api/files/')
  Future<FileListResponse> getFiles({
    @Query('page') int? page,
    @Query('search') String? search,
  });

  /// Export endpoints
  @GET('/admin/api/{app}/{model}/export/')
  Future<ExportResponse> exportModels(
    @Path('app') String app,
    @Path('model') String model, {
    @Query('format') String format = 'csv',
    @Query('filters') String? filters,
  });

  /// Import endpoints
  @POST('/admin/api/{app}/{model}/import/')
  @MultiPart()
  Future<ImportResponse> importModels(
    @Path('app') String app,
    @Path('model') String model,
    @Part(name: 'file') File file,
  );
}

/// API client factory with authentication and error handling
class AdminApiClientFactory {
  static const String defaultBaseUrl = 'http://localhost:8000';
  
  static AdminApiClient create({
    String? baseUrl,
    String? authToken,
    Map<String, String>? headers,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? defaultBaseUrl,
      connectTimeout: connectTimeout ?? const Duration(seconds: 30),
      receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
        ...?headers,
      },
    ));

    // Add interceptors
    dio.interceptors.addAll([
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
      ),
      AuthInterceptor(),
      ErrorInterceptor(),
    ]);

    return AdminApiClient(dio);
  }
}

/// Authentication interceptor
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add authentication token from storage
    final token = _getStoredToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Handle token refresh or logout
      _handleAuthError();
    }
    handler.next(err);
  }

  String? _getStoredToken() {
    // Implementation to get token from secure storage
    return null; // Placeholder
  }

  void _handleAuthError() {
    // Implementation to handle auth errors
  }
}

/// Error handling interceptor
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiError = _parseError(err);
    handler.next(DioException(
      requestOptions: err.requestOptions,
      error: apiError,
      type: err.type,
      response: err.response,
    ));
  }

  AdminApiError _parseError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AdminApiError(
          message: 'Connection timeout. Please check your internet connection.',
          code: 'NETWORK_ERROR',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final data = error.response?.data;
        
        if (statusCode >= 400 && statusCode < 500) {
          return AdminApiError(
            message: data?['message'] ?? data?['error'] ?? 'Client error occurred',
            code: 'CLIENT_ERROR',
            statusCode: statusCode,
            details: data,
          );
        } else if (statusCode >= 500) {
          return AdminApiError(
            message: 'Server error occurred. Please try again later.',
            code: 'SERVER_ERROR',
            statusCode: statusCode,
          );
        }
        break;
      case DioExceptionType.cancel:
        return AdminApiError(
          message: 'Request was cancelled',
          code: 'CANCELLED',
        );
      case DioExceptionType.unknown:
        return AdminApiError(
          message: 'An unexpected error occurred',
          code: 'UNKNOWN_ERROR',
          details: {'error': error.error.toString()},
        );
      default:
        break;
    }

    return AdminApiError(
      message: 'Unknown error occurred',
      code: 'UNKNOWN_ERROR',
    );
  }
}

enum AdminApiErrorType {
  network,
  client,
  server,
  cancelled,
  unknown,
}