import 'package:json_annotation/json_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:equatable/equatable.dart';

part 'admin_models.freezed.dart';
part 'admin_models.g.dart';

/// Base response wrapper
@Freezed(genericArgumentFactories: true)
class BaseResponse<T> with _$BaseResponse<T> {
  const factory BaseResponse({
    required bool success,
    String? message,
    T? data,
    Map<String, dynamic>? errors,
    @JsonKey(name: 'error_code') String? errorCode,
  }) = _BaseResponse<T>;

  factory BaseResponse.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$BaseResponseFromJson(json, fromJsonT);
}

/// Authentication models
@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String username,
    required String password,
    @JsonKey(name: 'remember_me') @Default(false) bool rememberMe,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required String token,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'expires_in') required int expiresIn,
    required UserProfile user,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}

@freezed
class RefreshTokenRequest with _$RefreshTokenRequest {
  const factory RefreshTokenRequest({
    @JsonKey(name: 'refresh_token') required String refreshToken,
  }) = _RefreshTokenRequest;

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenRequestFromJson(json);
}

@freezed
class LogoutResponse with _$LogoutResponse {
  const factory LogoutResponse({
    required String message,
  }) = _LogoutResponse;

  factory LogoutResponse.fromJson(Map<String, dynamic> json) =>
      _$LogoutResponseFromJson(json);
}

/// User models
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required int id,
    required String username,
    required String email,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'is_staff') required bool isStaff,
    @JsonKey(name: 'is_superuser') required bool isSuperuser,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'date_joined') required DateTime dateJoined,
    @JsonKey(name: 'last_login') DateTime? lastLogin,
    List<String>? permissions,
    List<AdminGroup>? groups,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

@freezed
class AdminUser with _$AdminUser {
  const factory AdminUser({
    required int id,
    required String username,
    required String email,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'is_staff') required bool isStaff,
    @JsonKey(name: 'is_superuser') required bool isSuperuser,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'date_joined') required DateTime dateJoined,
    @JsonKey(name: 'last_login') DateTime? lastLogin,
  }) = _AdminUser;

  factory AdminUser.fromJson(Map<String, dynamic> json) =>
      _$AdminUserFromJson(json);
}

@freezed
class CreateUserRequest with _$CreateUserRequest {
  const factory CreateUserRequest({
    required String username,
    required String email,
    required String password,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'is_staff') @Default(false) bool isStaff,
    @JsonKey(name: 'is_superuser') @Default(false) bool isSuperuser,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _CreateUserRequest;

  factory CreateUserRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateUserRequestFromJson(json);
}

@freezed
class UpdateUserRequest with _$UpdateUserRequest {
  const factory UpdateUserRequest({
    String? username,
    String? email,
    String? password,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'is_staff') bool? isStaff,
    @JsonKey(name: 'is_superuser') bool? isSuperuser,
    @JsonKey(name: 'is_active') bool? isActive,
  }) = _UpdateUserRequest;

  factory UpdateUserRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserRequestFromJson(json);
}

/// Group models
@freezed
class AdminGroup with _$AdminGroup {
  const factory AdminGroup({
    required int id,
    required String name,
    List<String>? permissions,
  }) = _AdminGroup;

  factory AdminGroup.fromJson(Map<String, dynamic> json) =>
      _$AdminGroupFromJson(json);
}

@freezed
class CreateGroupRequest with _$CreateGroupRequest {
  const factory CreateGroupRequest({
    required String name,
    List<String>? permissions,
  }) = _CreateGroupRequest;

  factory CreateGroupRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateGroupRequestFromJson(json);
}

@freezed
class UpdateGroupRequest with _$UpdateGroupRequest {
  const factory UpdateGroupRequest({
    String? name,
    List<String>? permissions,
  }) = _UpdateGroupRequest;

  factory UpdateGroupRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateGroupRequestFromJson(json);
}

/// Generic model responses
@Freezed(genericArgumentFactories: true)
class ModelListResponse<T> with _$ModelListResponse<T> {
  const factory ModelListResponse({
    required List<T> results,
    required int count,
    String? next,
    String? previous,
    @JsonKey(name: 'page_size') int? pageSize,
    @JsonKey(name: 'total_pages') int? totalPages,
  }) = _ModelListResponse<T>;

  factory ModelListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$ModelListResponseFromJson(json, fromJsonT);
}

@Freezed(genericArgumentFactories: true)
class ModelDetailResponse<T> with _$ModelDetailResponse<T> {
  const factory ModelDetailResponse({
    required T object,
    Map<String, dynamic>? meta,
  }) = _ModelDetailResponse<T>;

  factory ModelDetailResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$ModelDetailResponseFromJson(json, fromJsonT);
}

@freezed
class DeleteResponse with _$DeleteResponse {
  const factory DeleteResponse({
    required bool success,
    String? message,
  }) = _DeleteResponse;

  factory DeleteResponse.fromJson(Map<String, dynamic> json) =>
      _$DeleteResponseFromJson(json);
}

/// Bulk operations
@freezed
class BulkDeleteRequest with _$BulkDeleteRequest {
  const factory BulkDeleteRequest({
    required List<String> ids,
  }) = _BulkDeleteRequest;

  factory BulkDeleteRequest.fromJson(Map<String, dynamic> json) =>
      _$BulkDeleteRequestFromJson(json);
}

@freezed
class BulkDeleteResponse with _$BulkDeleteResponse {
  const factory BulkDeleteResponse({
    required int deleted,
    required bool success,
    String? message,
  }) = _BulkDeleteResponse;

  factory BulkDeleteResponse.fromJson(Map<String, dynamic> json) =>
      _$BulkDeleteResponseFromJson(json);
}

@freezed
class BulkUpdateRequest with _$BulkUpdateRequest {
  const factory BulkUpdateRequest({
    required List<String> ids,
    required Map<String, dynamic> data,
  }) = _BulkUpdateRequest;

  factory BulkUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$BulkUpdateRequestFromJson(json);
}

@freezed
class BulkUpdateResponse with _$BulkUpdateResponse {
  const factory BulkUpdateResponse({
    required int updated,
    required bool success,
    String? message,
  }) = _BulkUpdateResponse;

  factory BulkUpdateResponse.fromJson(Map<String, dynamic> json) =>
      _$BulkUpdateResponseFromJson(json);
}

/// Admin configuration models
@freezed
class AdminIndexResponse with _$AdminIndexResponse {
  const factory AdminIndexResponse({
    @JsonKey(name: 'site_title') required String siteTitle,
    @JsonKey(name: 'site_header') required String siteHeader,
    @JsonKey(name: 'index_title') required String indexTitle,
    required Map<String, List<String>> models,
    @JsonKey(name: 'admin_url') required String adminUrl,
  }) = _AdminIndexResponse;

  factory AdminIndexResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminIndexResponseFromJson(json);
}

@freezed
class AppsListResponse with _$AppsListResponse {
  const factory AppsListResponse({
    required List<AdminApp> apps,
  }) = _AppsListResponse;

  factory AppsListResponse.fromJson(Map<String, dynamic> json) =>
      _$AppsListResponseFromJson(json);
}

@freezed
class AdminApp with _$AdminApp {
  const factory AdminApp({
    required String name,
    @JsonKey(name: 'app_label') required String appLabel,
    required List<AdminModel> models,
  }) = _AdminApp;

  factory AdminApp.fromJson(Map<String, dynamic> json) =>
      _$AdminAppFromJson(json);
}

@freezed
class AdminModel with _$AdminModel {
  const factory AdminModel({
    required String name,
    @JsonKey(name: 'object_name') required String objectName,
    required AdminModelPermissions perms,
    @JsonKey(name: 'admin_url') required String adminUrl,
    @JsonKey(name: 'add_url') required String addUrl,
    @JsonKey(name: 'verbose_name') String? verboseName,
    @JsonKey(name: 'verbose_name_plural') String? verboseNamePlural,
  }) = _AdminModel;

  factory AdminModel.fromJson(Map<String, dynamic> json) =>
      _$AdminModelFromJson(json);
}

@freezed
class AdminModelPermissions with _$AdminModelPermissions {
  const factory AdminModelPermissions({
    required bool add,
    required bool change,
    required bool delete,
    required bool view,
  }) = _AdminModelPermissions;

  factory AdminModelPermissions.fromJson(Map<String, dynamic> json) =>
      _$AdminModelPermissionsFromJson(json);
}

/// Dashboard analytics
@freezed
class DashboardAnalytics with _$DashboardAnalytics {
  const factory DashboardAnalytics({
    @JsonKey(name: 'total_users') required int totalUsers,
    @JsonKey(name: 'active_users') required int activeUsers,
    @JsonKey(name: 'total_models') required int totalModels,
    @JsonKey(name: 'recent_activity') required List<ActivityItem> recentActivity,
    @JsonKey(name: 'model_counts') required Map<String, int> modelCounts,
    @JsonKey(name: 'user_growth') required List<DataPoint> userGrowth,
  }) = _DashboardAnalytics;

  factory DashboardAnalytics.fromJson(Map<String, dynamic> json) =>
      _$DashboardAnalyticsFromJson(json);
}

@freezed
class ActivityItem with _$ActivityItem {
  const factory ActivityItem({
    required String action,
    required String model,
    @JsonKey(name: 'object_name') required String objectName,
    required String user,
    required DateTime timestamp,
  }) = _ActivityItem;

  factory ActivityItem.fromJson(Map<String, dynamic> json) =>
      _$ActivityItemFromJson(json);
}

@freezed
class DataPoint with _$DataPoint {
  const factory DataPoint({
    required DateTime date,
    required double value,
  }) = _DataPoint;

  factory DataPoint.fromJson(Map<String, dynamic> json) =>
      _$DataPointFromJson(json);
}

@freezed
class ModelStatsResponse with _$ModelStatsResponse {
  const factory ModelStatsResponse({
    required Map<String, ModelStats> stats,
  }) = _ModelStatsResponse;

  factory ModelStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$ModelStatsResponseFromJson(json);
}

@freezed
class ModelStats with _$ModelStats {
  const factory ModelStats({
    required int count,
    @JsonKey(name: 'recent_changes') required int recentChanges,
    @JsonKey(name: 'growth_rate') required double growthRate,
  }) = _ModelStats;

  factory ModelStats.fromJson(Map<String, dynamic> json) =>
      _$ModelStatsFromJson(json);
}

@freezed
class UserActivityResponse with _$UserActivityResponse {
  const factory UserActivityResponse({
    required List<UserActivityItem> activities,
    required int total,
  }) = _UserActivityResponse;

  factory UserActivityResponse.fromJson(Map<String, dynamic> json) =>
      _$UserActivityResponseFromJson(json);
}

@freezed
class UserActivityItem with _$UserActivityItem {
  const factory UserActivityItem({
    required String username,
    required String action,
    required String model,
    @JsonKey(name: 'object_id') String? objectId,
    required DateTime timestamp,
    @JsonKey(name: 'ip_address') String? ipAddress,
  }) = _UserActivityItem;

  factory UserActivityItem.fromJson(Map<String, dynamic> json) =>
      _$UserActivityItemFromJson(json);
}

/// File management
@freezed
class FileUploadResponse with _$FileUploadResponse {
  const factory FileUploadResponse({
    required String url,
    required String name,
    required int size,
    @JsonKey(name: 'content_type') required String contentType,
  }) = _FileUploadResponse;

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$FileUploadResponseFromJson(json);
}

@freezed
class FileListResponse with _$FileListResponse {
  const factory FileListResponse({
    required List<AdminFile> files,
    required int count,
  }) = _FileListResponse;

  factory FileListResponse.fromJson(Map<String, dynamic> json) =>
      _$FileListResponseFromJson(json);
}

@freezed
class AdminFile with _$AdminFile {
  const factory AdminFile({
    required String name,
    required String url,
    required int size,
    @JsonKey(name: 'content_type') required String contentType,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _AdminFile;

  factory AdminFile.fromJson(Map<String, dynamic> json) =>
      _$AdminFileFromJson(json);
}

/// Export/Import
@freezed
class ExportResponse with _$ExportResponse {
  const factory ExportResponse({
    @JsonKey(name: 'download_url') required String downloadUrl,
    required String format,
    @JsonKey(name: 'file_size') required int fileSize,
    @JsonKey(name: 'record_count') required int recordCount,
  }) = _ExportResponse;

  factory ExportResponse.fromJson(Map<String, dynamic> json) =>
      _$ExportResponseFromJson(json);
}

@freezed
class ImportResponse with _$ImportResponse {
  const factory ImportResponse({
    required bool success,
    @JsonKey(name: 'imported_count') required int importedCount,
    @JsonKey(name: 'error_count') required int errorCount,
    List<String>? errors,
  }) = _ImportResponse;

  factory ImportResponse.fromJson(Map<String, dynamic> json) =>
      _$ImportResponseFromJson(json);
}

/// Model field definitions for dynamic forms
@freezed
class ModelFieldDefinition with _$ModelFieldDefinition {
  const factory ModelFieldDefinition({
    required String name,
    required String type,
    required String label,
    @Default(false) bool required,
    @Default(false) bool readonly,
    String? helpText,
    dynamic defaultValue,
    Map<String, dynamic>? choices,
    Map<String, dynamic>? validation,
  }) = _ModelFieldDefinition;

  factory ModelFieldDefinition.fromJson(Map<String, dynamic> json) =>
      _$ModelFieldDefinitionFromJson(json);
}

@freezed
class ModelFormDefinition with _$ModelFormDefinition {
  const factory ModelFormDefinition({
    required List<ModelFieldDefinition> fields,
    required Map<String, List<String>> fieldsets,
    @JsonKey(name: 'readonly_fields') required List<String> readonlyFields,
  }) = _ModelFormDefinition;

  factory ModelFormDefinition.fromJson(Map<String, dynamic> json) =>
      _$ModelFormDefinitionFromJson(json);
}

/// State management models for BLoC
abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

/// Admin API Error class for handling API errors
@freezed
class AdminApiError with _$AdminApiError {
  const factory AdminApiError({
    required String message,
    @Default(500) int statusCode,
    String? code,
    Map<String, dynamic>? details,
  }) = _AdminApiError;

  factory AdminApiError.fromJson(Map<String, dynamic> json) =>
      _$AdminApiErrorFromJson(json);
}

/// Repository interface for dependency injection
abstract class AdminRepository {
  Future<AuthResponse> login(LoginRequest request);
  Future<void> logout();
  Future<AuthResponse> refreshToken(String refreshToken);
  Future<UserProfile> getCurrentUser();
  Future<AdminIndexResponse> getAdminIndex();
  Future<AppsListResponse> getAppsList();
  Future<ModelListResponse<T>> getModelList<T>(
    String app,
    String model, {
    String? search,
    int? page,
    int? pageSize,
    Map<String, dynamic>? filters,
  });
  Future<ModelDetailResponse<T>> getModelDetail<T>(
    String app,
    String model,
    String id,
  );
  Future<ModelDetailResponse<T>> createModel<T>(
    String app,
    String model,
    Map<String, dynamic> data,
  );
  Future<ModelDetailResponse<T>> updateModel<T>(
    String app,
    String model,
    String id,
    Map<String, dynamic> data,
  );
  Future<DeleteResponse> deleteModel(String app, String model, String id);
  Future<BulkDeleteResponse> bulkDeleteModels(
    String app,
    String model,
    BulkDeleteRequest request,
  );
  Future<DashboardAnalytics> getDashboardAnalytics();
}