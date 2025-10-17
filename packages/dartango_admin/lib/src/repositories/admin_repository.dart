import 'dart:io';
import 'package:dio/dio.dart';

import '../api/admin_api_client.dart';
import '../models/admin_models.dart';

/// Repository implementation for admin operations
class AdminRepositoryImpl implements AdminRepository {
  final AdminApiClient _apiClient;

  AdminRepositoryImpl({required AdminApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      return await _apiClient.login(request);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.logout();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final request = RefreshTokenRequest(refreshToken: refreshToken);
      return await _apiClient.refreshToken(request);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UserProfile> getCurrentUser() async {
    try {
      return await _apiClient.getCurrentUser();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AdminIndexResponse> getAdminIndex() async {
    try {
      return await _apiClient.getAdminIndex();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AppsListResponse> getAppsList() async {
    try {
      return await _apiClient.getAppsList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<ModelListResponse<T>> getModelList<T>(
    String app,
    String model, {
    String? search,
    int? page,
    int? pageSize,
    Map<String, dynamic>? filters,
  }) async {
    try {
      return await _apiClient.getModelList<T>(
        app,
        model,
        search: search,
        page: page,
        pageSize: pageSize,
        filters: filters,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<ModelDetailResponse<T>> getModelDetail<T>(
    String app,
    String model,
    String id,
  ) async {
    try {
      return await _apiClient.getModelDetail<T>(app, model, id);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<ModelDetailResponse<T>> createModel<T>(
    String app,
    String model,
    Map<String, dynamic> data,
  ) async {
    try {
      return await _apiClient.createModel<T>(app, model, data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<ModelDetailResponse<T>> updateModel<T>(
    String app,
    String model,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      return await _apiClient.updateModel<T>(app, model, id, data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<DeleteResponse> deleteModel(String app, String model, String id) async {
    try {
      return await _apiClient.deleteModel(app, model, id);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<BulkDeleteResponse> bulkDeleteModels(
    String app,
    String model,
    BulkDeleteRequest request,
  ) async {
    try {
      return await _apiClient.bulkDeleteModels(app, model, request);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<DashboardAnalytics> getDashboardAnalytics() async {
    try {
      return await _apiClient.getDashboardAnalytics();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Additional repository methods for extended functionality
  
  Future<BulkUpdateResponse> bulkUpdateModels(
    String app,
    String model,
    BulkUpdateRequest request,
  ) async {
    try {
      return await _apiClient.bulkUpdateModels(app, model, request);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ModelListResponse<AdminUser>> getUsers({
    String? search,
    int? page,
    int? pageSize,
    bool? isStaff,
    bool? isActive,
  }) async {
    try {
      return await _apiClient.getUsers(
        search: search,
        page: page,
        pageSize: pageSize,
        isStaff: isStaff,
        isActive: isActive,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ModelDetailResponse<AdminUser>> createUser(
    CreateUserRequest request,
  ) async {
    try {
      return await _apiClient.createUser(request);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ModelDetailResponse<AdminUser>> updateUser(
    int id,
    UpdateUserRequest request,
  ) async {
    try {
      return await _apiClient.updateUser(id, request);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<DeleteResponse> deleteUser(int id) async {
    try {
      return await _apiClient.deleteUser(id);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ModelListResponse<AdminGroup>> getGroups({
    String? search,
    int? page,
    int? pageSize,
  }) async {
    try {
      return await _apiClient.getGroups(
        search: search,
        page: page,
        pageSize: pageSize,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ModelDetailResponse<AdminGroup>> createGroup(
    CreateGroupRequest request,
  ) async {
    try {
      return await _apiClient.createGroup(request);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ModelDetailResponse<AdminGroup>> updateGroup(
    int id,
    UpdateGroupRequest request,
  ) async {
    try {
      return await _apiClient.updateGroup(id, request);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<DeleteResponse> deleteGroup(int id) async {
    try {
      return await _apiClient.deleteGroup(id);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ModelStatsResponse> getModelStats() async {
    try {
      return await _apiClient.getModelStats();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserActivityResponse> getUserActivity({
    int? days,
    int? limit,
  }) async {
    try {
      return await _apiClient.getUserActivity(
        days: days,
        limit: limit,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<FileUploadResponse> uploadFile(File file) async {
    try {
      return await _apiClient.uploadFile(file);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<FileListResponse> getFiles({
    int? page,
    String? search,
  }) async {
    try {
      return await _apiClient.getFiles(
        page: page,
        search: search,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ExportResponse> exportModels(
    String app,
    String model, {
    String format = 'csv',
    String? filters,
  }) async {
    try {
      return await _apiClient.exportModels(
        app,
        model,
        format: format,
        filters: filters,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ImportResponse> importModels(
    String app,
    String model,
    File file,
  ) async {
    try {
      return await _apiClient.importModels(app, model, file);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio errors and convert them to AdminApiError
  AdminApiError _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AdminApiError(
          message: 'Connection timeout. Please check your internet connection.',
          code: 'NETWORK_TIMEOUT',
        );
        
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final data = error.response?.data;
        
        if (statusCode >= 400 && statusCode < 500) {
          String message = 'Client error occurred';
          
          if (data is Map<String, dynamic>) {
            message = data['message'] ?? data['error'] ?? data['detail'] ?? message;
          } else if (data is String) {
            message = data;
          }
          
          return AdminApiError(
            message: message,
            statusCode: statusCode,
            code: 'CLIENT_ERROR',
            details: data,
          );
        } else if (statusCode >= 500) {
          return AdminApiError(
            message: 'Server error occurred. Please try again later.',
            statusCode: statusCode,
            code: 'SERVER_ERROR',
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
          message: 'Network error occurred. Please check your connection.',
          code: 'NETWORK_ERROR',
          details: {'error': error.error.toString()},
        );
        
      default:
        break;
    }

    return AdminApiError(
      message: 'An unexpected error occurred',
      code: 'UNKNOWN_ERROR',
    );
  }
}

/// Factory for creating repository instances
class AdminRepositoryFactory {
  static AdminRepository create({
    String? baseUrl,
    String? authToken,
    Map<String, String>? headers,
  }) {
    final apiClient = AdminApiClientFactory.create(
      baseUrl: baseUrl,
      authToken: authToken,
      headers: headers,
    );
    
    return AdminRepositoryImpl(apiClient: apiClient);
  }
}