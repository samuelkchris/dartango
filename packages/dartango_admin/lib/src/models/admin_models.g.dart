// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BaseResponseImpl<T> _$$BaseResponseImplFromJson<T>(
  Map json,
  T Function(Object? json) fromJsonT,
) =>
    $checkedCreate(
      r'_$BaseResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$BaseResponseImpl<T>(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
          data: $checkedConvert(
              'data', (v) => _$nullableGenericFromJson(v, fromJsonT)),
          errors: $checkedConvert(
              'errors',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
          errorCode: $checkedConvert('error_code', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'errorCode': 'error_code'},
    );

Map<String, dynamic> _$$BaseResponseImplToJson<T>(
  _$BaseResponseImpl<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'success': instance.success,
      if (instance.message case final value?) 'message': value,
      if (_$nullableGenericToJson(instance.data, toJsonT) case final value?)
        'data': value,
      if (instance.errors case final value?) 'errors': value,
      if (instance.errorCode case final value?) 'error_code': value,
    };

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) =>
    input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) =>
    input == null ? null : toJson(input);

_$LoginRequestImpl _$$LoginRequestImplFromJson(Map json) => $checkedCreate(
      r'_$LoginRequestImpl',
      json,
      ($checkedConvert) {
        final val = _$LoginRequestImpl(
          username: $checkedConvert('username', (v) => v as String),
          password: $checkedConvert('password', (v) => v as String),
          rememberMe:
              $checkedConvert('remember_me', (v) => v as bool? ?? false),
        );
        return val;
      },
      fieldKeyMap: const {'rememberMe': 'remember_me'},
    );

Map<String, dynamic> _$$LoginRequestImplToJson(_$LoginRequestImpl instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'remember_me': instance.rememberMe,
    };

_$AuthResponseImpl _$$AuthResponseImplFromJson(Map json) => $checkedCreate(
      r'_$AuthResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AuthResponseImpl(
          token: $checkedConvert('token', (v) => v as String),
          refreshToken: $checkedConvert('refresh_token', (v) => v as String),
          expiresIn: $checkedConvert('expires_in', (v) => (v as num).toInt()),
          user: $checkedConvert('user',
              (v) => UserProfile.fromJson(Map<String, dynamic>.from(v as Map))),
        );
        return val;
      },
      fieldKeyMap: const {
        'refreshToken': 'refresh_token',
        'expiresIn': 'expires_in'
      },
    );

Map<String, dynamic> _$$AuthResponseImplToJson(_$AuthResponseImpl instance) =>
    <String, dynamic>{
      'token': instance.token,
      'refresh_token': instance.refreshToken,
      'expires_in': instance.expiresIn,
      'user': instance.user.toJson(),
    };

_$RefreshTokenRequestImpl _$$RefreshTokenRequestImplFromJson(Map json) =>
    $checkedCreate(
      r'_$RefreshTokenRequestImpl',
      json,
      ($checkedConvert) {
        final val = _$RefreshTokenRequestImpl(
          refreshToken: $checkedConvert('refresh_token', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'refreshToken': 'refresh_token'},
    );

Map<String, dynamic> _$$RefreshTokenRequestImplToJson(
        _$RefreshTokenRequestImpl instance) =>
    <String, dynamic>{
      'refresh_token': instance.refreshToken,
    };

_$LogoutResponseImpl _$$LogoutResponseImplFromJson(Map json) => $checkedCreate(
      r'_$LogoutResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$LogoutResponseImpl(
          message: $checkedConvert('message', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$$LogoutResponseImplToJson(
        _$LogoutResponseImpl instance) =>
    <String, dynamic>{
      'message': instance.message,
    };

_$UserProfileImpl _$$UserProfileImplFromJson(Map json) => $checkedCreate(
      r'_$UserProfileImpl',
      json,
      ($checkedConvert) {
        final val = _$UserProfileImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          username: $checkedConvert('username', (v) => v as String),
          email: $checkedConvert('email', (v) => v as String),
          firstName: $checkedConvert('first_name', (v) => v as String?),
          lastName: $checkedConvert('last_name', (v) => v as String?),
          isStaff: $checkedConvert('is_staff', (v) => v as bool),
          isSuperuser: $checkedConvert('is_superuser', (v) => v as bool),
          isActive: $checkedConvert('is_active', (v) => v as bool),
          dateJoined: $checkedConvert(
              'date_joined', (v) => DateTime.parse(v as String)),
          lastLogin: $checkedConvert('last_login',
              (v) => v == null ? null : DateTime.parse(v as String)),
          permissions: $checkedConvert('permissions',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          groups: $checkedConvert(
              'groups',
              (v) => (v as List<dynamic>?)
                  ?.map((e) =>
                      AdminGroup.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'firstName': 'first_name',
        'lastName': 'last_name',
        'isStaff': 'is_staff',
        'isSuperuser': 'is_superuser',
        'isActive': 'is_active',
        'dateJoined': 'date_joined',
        'lastLogin': 'last_login'
      },
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      if (instance.firstName case final value?) 'first_name': value,
      if (instance.lastName case final value?) 'last_name': value,
      'is_staff': instance.isStaff,
      'is_superuser': instance.isSuperuser,
      'is_active': instance.isActive,
      'date_joined': instance.dateJoined.toIso8601String(),
      if (instance.lastLogin?.toIso8601String() case final value?)
        'last_login': value,
      if (instance.permissions case final value?) 'permissions': value,
      if (instance.groups?.map((e) => e.toJson()).toList() case final value?)
        'groups': value,
    };

_$AdminUserImpl _$$AdminUserImplFromJson(Map json) => $checkedCreate(
      r'_$AdminUserImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminUserImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          username: $checkedConvert('username', (v) => v as String),
          email: $checkedConvert('email', (v) => v as String),
          firstName: $checkedConvert('first_name', (v) => v as String?),
          lastName: $checkedConvert('last_name', (v) => v as String?),
          isStaff: $checkedConvert('is_staff', (v) => v as bool),
          isSuperuser: $checkedConvert('is_superuser', (v) => v as bool),
          isActive: $checkedConvert('is_active', (v) => v as bool),
          dateJoined: $checkedConvert(
              'date_joined', (v) => DateTime.parse(v as String)),
          lastLogin: $checkedConvert('last_login',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'firstName': 'first_name',
        'lastName': 'last_name',
        'isStaff': 'is_staff',
        'isSuperuser': 'is_superuser',
        'isActive': 'is_active',
        'dateJoined': 'date_joined',
        'lastLogin': 'last_login'
      },
    );

Map<String, dynamic> _$$AdminUserImplToJson(_$AdminUserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      if (instance.firstName case final value?) 'first_name': value,
      if (instance.lastName case final value?) 'last_name': value,
      'is_staff': instance.isStaff,
      'is_superuser': instance.isSuperuser,
      'is_active': instance.isActive,
      'date_joined': instance.dateJoined.toIso8601String(),
      if (instance.lastLogin?.toIso8601String() case final value?)
        'last_login': value,
    };

_$CreateUserRequestImpl _$$CreateUserRequestImplFromJson(Map json) =>
    $checkedCreate(
      r'_$CreateUserRequestImpl',
      json,
      ($checkedConvert) {
        final val = _$CreateUserRequestImpl(
          username: $checkedConvert('username', (v) => v as String),
          email: $checkedConvert('email', (v) => v as String),
          password: $checkedConvert('password', (v) => v as String),
          firstName: $checkedConvert('first_name', (v) => v as String?),
          lastName: $checkedConvert('last_name', (v) => v as String?),
          isStaff: $checkedConvert('is_staff', (v) => v as bool? ?? false),
          isSuperuser:
              $checkedConvert('is_superuser', (v) => v as bool? ?? false),
          isActive: $checkedConvert('is_active', (v) => v as bool? ?? true),
        );
        return val;
      },
      fieldKeyMap: const {
        'firstName': 'first_name',
        'lastName': 'last_name',
        'isStaff': 'is_staff',
        'isSuperuser': 'is_superuser',
        'isActive': 'is_active'
      },
    );

Map<String, dynamic> _$$CreateUserRequestImplToJson(
        _$CreateUserRequestImpl instance) =>
    <String, dynamic>{
      'username': instance.username,
      'email': instance.email,
      'password': instance.password,
      if (instance.firstName case final value?) 'first_name': value,
      if (instance.lastName case final value?) 'last_name': value,
      'is_staff': instance.isStaff,
      'is_superuser': instance.isSuperuser,
      'is_active': instance.isActive,
    };

_$UpdateUserRequestImpl _$$UpdateUserRequestImplFromJson(Map json) =>
    $checkedCreate(
      r'_$UpdateUserRequestImpl',
      json,
      ($checkedConvert) {
        final val = _$UpdateUserRequestImpl(
          username: $checkedConvert('username', (v) => v as String?),
          email: $checkedConvert('email', (v) => v as String?),
          password: $checkedConvert('password', (v) => v as String?),
          firstName: $checkedConvert('first_name', (v) => v as String?),
          lastName: $checkedConvert('last_name', (v) => v as String?),
          isStaff: $checkedConvert('is_staff', (v) => v as bool?),
          isSuperuser: $checkedConvert('is_superuser', (v) => v as bool?),
          isActive: $checkedConvert('is_active', (v) => v as bool?),
        );
        return val;
      },
      fieldKeyMap: const {
        'firstName': 'first_name',
        'lastName': 'last_name',
        'isStaff': 'is_staff',
        'isSuperuser': 'is_superuser',
        'isActive': 'is_active'
      },
    );

Map<String, dynamic> _$$UpdateUserRequestImplToJson(
        _$UpdateUserRequestImpl instance) =>
    <String, dynamic>{
      if (instance.username case final value?) 'username': value,
      if (instance.email case final value?) 'email': value,
      if (instance.password case final value?) 'password': value,
      if (instance.firstName case final value?) 'first_name': value,
      if (instance.lastName case final value?) 'last_name': value,
      if (instance.isStaff case final value?) 'is_staff': value,
      if (instance.isSuperuser case final value?) 'is_superuser': value,
      if (instance.isActive case final value?) 'is_active': value,
    };

_$AdminGroupImpl _$$AdminGroupImplFromJson(Map json) => $checkedCreate(
      r'_$AdminGroupImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminGroupImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          name: $checkedConvert('name', (v) => v as String),
          permissions: $checkedConvert('permissions',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AdminGroupImplToJson(_$AdminGroupImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      if (instance.permissions case final value?) 'permissions': value,
    };

_$CreateGroupRequestImpl _$$CreateGroupRequestImplFromJson(Map json) =>
    $checkedCreate(
      r'_$CreateGroupRequestImpl',
      json,
      ($checkedConvert) {
        final val = _$CreateGroupRequestImpl(
          name: $checkedConvert('name', (v) => v as String),
          permissions: $checkedConvert('permissions',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$CreateGroupRequestImplToJson(
        _$CreateGroupRequestImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      if (instance.permissions case final value?) 'permissions': value,
    };

_$UpdateGroupRequestImpl _$$UpdateGroupRequestImplFromJson(Map json) =>
    $checkedCreate(
      r'_$UpdateGroupRequestImpl',
      json,
      ($checkedConvert) {
        final val = _$UpdateGroupRequestImpl(
          name: $checkedConvert('name', (v) => v as String?),
          permissions: $checkedConvert('permissions',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$UpdateGroupRequestImplToJson(
        _$UpdateGroupRequestImpl instance) =>
    <String, dynamic>{
      if (instance.name case final value?) 'name': value,
      if (instance.permissions case final value?) 'permissions': value,
    };

_$ModelListResponseImpl<T> _$$ModelListResponseImplFromJson<T>(
  Map json,
  T Function(Object? json) fromJsonT,
) =>
    $checkedCreate(
      r'_$ModelListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ModelListResponseImpl<T>(
          results: $checkedConvert(
              'results', (v) => (v as List<dynamic>).map(fromJsonT).toList()),
          count: $checkedConvert('count', (v) => (v as num).toInt()),
          next: $checkedConvert('next', (v) => v as String?),
          previous: $checkedConvert('previous', (v) => v as String?),
          pageSize: $checkedConvert('page_size', (v) => (v as num?)?.toInt()),
          totalPages:
              $checkedConvert('total_pages', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
      fieldKeyMap: const {'pageSize': 'page_size', 'totalPages': 'total_pages'},
    );

Map<String, dynamic> _$$ModelListResponseImplToJson<T>(
  _$ModelListResponseImpl<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'results': instance.results.map(toJsonT).toList(),
      'count': instance.count,
      if (instance.next case final value?) 'next': value,
      if (instance.previous case final value?) 'previous': value,
      if (instance.pageSize case final value?) 'page_size': value,
      if (instance.totalPages case final value?) 'total_pages': value,
    };

_$ModelDetailResponseImpl<T> _$$ModelDetailResponseImplFromJson<T>(
  Map json,
  T Function(Object? json) fromJsonT,
) =>
    $checkedCreate(
      r'_$ModelDetailResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ModelDetailResponseImpl<T>(
          object: $checkedConvert('object', (v) => fromJsonT(v)),
          meta: $checkedConvert(
              'meta',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ModelDetailResponseImplToJson<T>(
  _$ModelDetailResponseImpl<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'object': toJsonT(instance.object),
      if (instance.meta case final value?) 'meta': value,
    };

_$DeleteResponseImpl _$$DeleteResponseImplFromJson(Map json) => $checkedCreate(
      r'_$DeleteResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$DeleteResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$DeleteResponseImplToJson(
        _$DeleteResponseImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      if (instance.message case final value?) 'message': value,
    };

_$BulkDeleteRequestImpl _$$BulkDeleteRequestImplFromJson(Map json) =>
    $checkedCreate(
      r'_$BulkDeleteRequestImpl',
      json,
      ($checkedConvert) {
        final val = _$BulkDeleteRequestImpl(
          ids: $checkedConvert('ids',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$BulkDeleteRequestImplToJson(
        _$BulkDeleteRequestImpl instance) =>
    <String, dynamic>{
      'ids': instance.ids,
    };

_$BulkDeleteResponseImpl _$$BulkDeleteResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$BulkDeleteResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$BulkDeleteResponseImpl(
          deleted: $checkedConvert('deleted', (v) => (v as num).toInt()),
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$BulkDeleteResponseImplToJson(
        _$BulkDeleteResponseImpl instance) =>
    <String, dynamic>{
      'deleted': instance.deleted,
      'success': instance.success,
      if (instance.message case final value?) 'message': value,
    };

_$BulkUpdateRequestImpl _$$BulkUpdateRequestImplFromJson(Map json) =>
    $checkedCreate(
      r'_$BulkUpdateRequestImpl',
      json,
      ($checkedConvert) {
        final val = _$BulkUpdateRequestImpl(
          ids: $checkedConvert('ids',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          data: $checkedConvert(
              'data', (v) => Map<String, dynamic>.from(v as Map)),
        );
        return val;
      },
    );

Map<String, dynamic> _$$BulkUpdateRequestImplToJson(
        _$BulkUpdateRequestImpl instance) =>
    <String, dynamic>{
      'ids': instance.ids,
      'data': instance.data,
    };

_$BulkUpdateResponseImpl _$$BulkUpdateResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$BulkUpdateResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$BulkUpdateResponseImpl(
          updated: $checkedConvert('updated', (v) => (v as num).toInt()),
          success: $checkedConvert('success', (v) => v as bool),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$BulkUpdateResponseImplToJson(
        _$BulkUpdateResponseImpl instance) =>
    <String, dynamic>{
      'updated': instance.updated,
      'success': instance.success,
      if (instance.message case final value?) 'message': value,
    };

_$AdminIndexResponseImpl _$$AdminIndexResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AdminIndexResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminIndexResponseImpl(
          siteTitle: $checkedConvert('site_title', (v) => v as String),
          siteHeader: $checkedConvert('site_header', (v) => v as String),
          indexTitle: $checkedConvert('index_title', (v) => v as String),
          models: $checkedConvert(
              'models',
              (v) => (v as Map).map(
                    (k, e) => MapEntry(k as String,
                        (e as List<dynamic>).map((e) => e as String).toList()),
                  )),
          adminUrl: $checkedConvert('admin_url', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'siteTitle': 'site_title',
        'siteHeader': 'site_header',
        'indexTitle': 'index_title',
        'adminUrl': 'admin_url'
      },
    );

Map<String, dynamic> _$$AdminIndexResponseImplToJson(
        _$AdminIndexResponseImpl instance) =>
    <String, dynamic>{
      'site_title': instance.siteTitle,
      'site_header': instance.siteHeader,
      'index_title': instance.indexTitle,
      'models': instance.models,
      'admin_url': instance.adminUrl,
    };

_$AppsListResponseImpl _$$AppsListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AppsListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$AppsListResponseImpl(
          apps: $checkedConvert(
              'apps',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      AdminApp.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AppsListResponseImplToJson(
        _$AppsListResponseImpl instance) =>
    <String, dynamic>{
      'apps': instance.apps.map((e) => e.toJson()).toList(),
    };

_$AdminAppImpl _$$AdminAppImplFromJson(Map json) => $checkedCreate(
      r'_$AdminAppImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminAppImpl(
          name: $checkedConvert('name', (v) => v as String),
          appLabel: $checkedConvert('app_label', (v) => v as String),
          models: $checkedConvert(
              'models',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      AdminModel.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {'appLabel': 'app_label'},
    );

Map<String, dynamic> _$$AdminAppImplToJson(_$AdminAppImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'app_label': instance.appLabel,
      'models': instance.models.map((e) => e.toJson()).toList(),
    };

_$AdminModelImpl _$$AdminModelImplFromJson(Map json) => $checkedCreate(
      r'_$AdminModelImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminModelImpl(
          name: $checkedConvert('name', (v) => v as String),
          objectName: $checkedConvert('object_name', (v) => v as String),
          perms: $checkedConvert(
              'perms',
              (v) => AdminModelPermissions.fromJson(
                  Map<String, dynamic>.from(v as Map))),
          adminUrl: $checkedConvert('admin_url', (v) => v as String),
          addUrl: $checkedConvert('add_url', (v) => v as String),
          verboseName: $checkedConvert('verbose_name', (v) => v as String?),
          verboseNamePlural:
              $checkedConvert('verbose_name_plural', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'objectName': 'object_name',
        'adminUrl': 'admin_url',
        'addUrl': 'add_url',
        'verboseName': 'verbose_name',
        'verboseNamePlural': 'verbose_name_plural'
      },
    );

Map<String, dynamic> _$$AdminModelImplToJson(_$AdminModelImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'object_name': instance.objectName,
      'perms': instance.perms.toJson(),
      'admin_url': instance.adminUrl,
      'add_url': instance.addUrl,
      if (instance.verboseName case final value?) 'verbose_name': value,
      if (instance.verboseNamePlural case final value?)
        'verbose_name_plural': value,
    };

_$AdminModelPermissionsImpl _$$AdminModelPermissionsImplFromJson(Map json) =>
    $checkedCreate(
      r'_$AdminModelPermissionsImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminModelPermissionsImpl(
          add: $checkedConvert('add', (v) => v as bool),
          change: $checkedConvert('change', (v) => v as bool),
          delete: $checkedConvert('delete', (v) => v as bool),
          view: $checkedConvert('view', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$$AdminModelPermissionsImplToJson(
        _$AdminModelPermissionsImpl instance) =>
    <String, dynamic>{
      'add': instance.add,
      'change': instance.change,
      'delete': instance.delete,
      'view': instance.view,
    };

_$DashboardAnalyticsImpl _$$DashboardAnalyticsImplFromJson(Map json) =>
    $checkedCreate(
      r'_$DashboardAnalyticsImpl',
      json,
      ($checkedConvert) {
        final val = _$DashboardAnalyticsImpl(
          totalUsers: $checkedConvert('total_users', (v) => (v as num).toInt()),
          activeUsers:
              $checkedConvert('active_users', (v) => (v as num).toInt()),
          totalModels:
              $checkedConvert('total_models', (v) => (v as num).toInt()),
          recentActivity: $checkedConvert(
              'recent_activity',
              (v) => (v as List<dynamic>)
                  .map((e) => ActivityItem.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
          modelCounts: $checkedConvert(
              'model_counts', (v) => Map<String, int>.from(v as Map)),
          userGrowth: $checkedConvert(
              'user_growth',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      DataPoint.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalUsers': 'total_users',
        'activeUsers': 'active_users',
        'totalModels': 'total_models',
        'recentActivity': 'recent_activity',
        'modelCounts': 'model_counts',
        'userGrowth': 'user_growth'
      },
    );

Map<String, dynamic> _$$DashboardAnalyticsImplToJson(
        _$DashboardAnalyticsImpl instance) =>
    <String, dynamic>{
      'total_users': instance.totalUsers,
      'active_users': instance.activeUsers,
      'total_models': instance.totalModels,
      'recent_activity':
          instance.recentActivity.map((e) => e.toJson()).toList(),
      'model_counts': instance.modelCounts,
      'user_growth': instance.userGrowth.map((e) => e.toJson()).toList(),
    };

_$ActivityItemImpl _$$ActivityItemImplFromJson(Map json) => $checkedCreate(
      r'_$ActivityItemImpl',
      json,
      ($checkedConvert) {
        final val = _$ActivityItemImpl(
          action: $checkedConvert('action', (v) => v as String),
          model: $checkedConvert('model', (v) => v as String),
          objectName: $checkedConvert('object_name', (v) => v as String),
          user: $checkedConvert('user', (v) => v as String),
          timestamp:
              $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'objectName': 'object_name'},
    );

Map<String, dynamic> _$$ActivityItemImplToJson(_$ActivityItemImpl instance) =>
    <String, dynamic>{
      'action': instance.action,
      'model': instance.model,
      'object_name': instance.objectName,
      'user': instance.user,
      'timestamp': instance.timestamp.toIso8601String(),
    };

_$DataPointImpl _$$DataPointImplFromJson(Map json) => $checkedCreate(
      r'_$DataPointImpl',
      json,
      ($checkedConvert) {
        final val = _$DataPointImpl(
          date: $checkedConvert('date', (v) => DateTime.parse(v as String)),
          value: $checkedConvert('value', (v) => (v as num).toDouble()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$DataPointImplToJson(_$DataPointImpl instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'value': instance.value,
    };

_$ModelStatsResponseImpl _$$ModelStatsResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ModelStatsResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ModelStatsResponseImpl(
          stats: $checkedConvert(
              'stats',
              (v) => (v as Map).map(
                    (k, e) => MapEntry(
                        k as String,
                        ModelStats.fromJson(
                            Map<String, dynamic>.from(e as Map))),
                  )),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ModelStatsResponseImplToJson(
        _$ModelStatsResponseImpl instance) =>
    <String, dynamic>{
      'stats': instance.stats.map((k, e) => MapEntry(k, e.toJson())),
    };

_$ModelStatsImpl _$$ModelStatsImplFromJson(Map json) => $checkedCreate(
      r'_$ModelStatsImpl',
      json,
      ($checkedConvert) {
        final val = _$ModelStatsImpl(
          count: $checkedConvert('count', (v) => (v as num).toInt()),
          recentChanges:
              $checkedConvert('recent_changes', (v) => (v as num).toInt()),
          growthRate:
              $checkedConvert('growth_rate', (v) => (v as num).toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'recentChanges': 'recent_changes',
        'growthRate': 'growth_rate'
      },
    );

Map<String, dynamic> _$$ModelStatsImplToJson(_$ModelStatsImpl instance) =>
    <String, dynamic>{
      'count': instance.count,
      'recent_changes': instance.recentChanges,
      'growth_rate': instance.growthRate,
    };

_$UserActivityResponseImpl _$$UserActivityResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$UserActivityResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$UserActivityResponseImpl(
          activities: $checkedConvert(
              'activities',
              (v) => (v as List<dynamic>)
                  .map((e) => UserActivityItem.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
          total: $checkedConvert('total', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$UserActivityResponseImplToJson(
        _$UserActivityResponseImpl instance) =>
    <String, dynamic>{
      'activities': instance.activities.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };

_$UserActivityItemImpl _$$UserActivityItemImplFromJson(Map json) =>
    $checkedCreate(
      r'_$UserActivityItemImpl',
      json,
      ($checkedConvert) {
        final val = _$UserActivityItemImpl(
          username: $checkedConvert('username', (v) => v as String),
          action: $checkedConvert('action', (v) => v as String),
          model: $checkedConvert('model', (v) => v as String),
          objectId: $checkedConvert('object_id', (v) => v as String?),
          timestamp:
              $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
          ipAddress: $checkedConvert('ip_address', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'objectId': 'object_id', 'ipAddress': 'ip_address'},
    );

Map<String, dynamic> _$$UserActivityItemImplToJson(
        _$UserActivityItemImpl instance) =>
    <String, dynamic>{
      'username': instance.username,
      'action': instance.action,
      'model': instance.model,
      if (instance.objectId case final value?) 'object_id': value,
      'timestamp': instance.timestamp.toIso8601String(),
      if (instance.ipAddress case final value?) 'ip_address': value,
    };

_$FileUploadResponseImpl _$$FileUploadResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$FileUploadResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$FileUploadResponseImpl(
          url: $checkedConvert('url', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          size: $checkedConvert('size', (v) => (v as num).toInt()),
          contentType: $checkedConvert('content_type', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'contentType': 'content_type'},
    );

Map<String, dynamic> _$$FileUploadResponseImplToJson(
        _$FileUploadResponseImpl instance) =>
    <String, dynamic>{
      'url': instance.url,
      'name': instance.name,
      'size': instance.size,
      'content_type': instance.contentType,
    };

_$FileListResponseImpl _$$FileListResponseImplFromJson(Map json) =>
    $checkedCreate(
      r'_$FileListResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$FileListResponseImpl(
          files: $checkedConvert(
              'files',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      AdminFile.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()),
          count: $checkedConvert('count', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$FileListResponseImplToJson(
        _$FileListResponseImpl instance) =>
    <String, dynamic>{
      'files': instance.files.map((e) => e.toJson()).toList(),
      'count': instance.count,
    };

_$AdminFileImpl _$$AdminFileImplFromJson(Map json) => $checkedCreate(
      r'_$AdminFileImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminFileImpl(
          name: $checkedConvert('name', (v) => v as String),
          url: $checkedConvert('url', (v) => v as String),
          size: $checkedConvert('size', (v) => (v as num).toInt()),
          contentType: $checkedConvert('content_type', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'contentType': 'content_type',
        'createdAt': 'created_at'
      },
    );

Map<String, dynamic> _$$AdminFileImplToJson(_$AdminFileImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'url': instance.url,
      'size': instance.size,
      'content_type': instance.contentType,
      'created_at': instance.createdAt.toIso8601String(),
    };

_$ExportResponseImpl _$$ExportResponseImplFromJson(Map json) => $checkedCreate(
      r'_$ExportResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ExportResponseImpl(
          downloadUrl: $checkedConvert('download_url', (v) => v as String),
          format: $checkedConvert('format', (v) => v as String),
          fileSize: $checkedConvert('file_size', (v) => (v as num).toInt()),
          recordCount:
              $checkedConvert('record_count', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'downloadUrl': 'download_url',
        'fileSize': 'file_size',
        'recordCount': 'record_count'
      },
    );

Map<String, dynamic> _$$ExportResponseImplToJson(
        _$ExportResponseImpl instance) =>
    <String, dynamic>{
      'download_url': instance.downloadUrl,
      'format': instance.format,
      'file_size': instance.fileSize,
      'record_count': instance.recordCount,
    };

_$ImportResponseImpl _$$ImportResponseImplFromJson(Map json) => $checkedCreate(
      r'_$ImportResponseImpl',
      json,
      ($checkedConvert) {
        final val = _$ImportResponseImpl(
          success: $checkedConvert('success', (v) => v as bool),
          importedCount:
              $checkedConvert('imported_count', (v) => (v as num).toInt()),
          errorCount: $checkedConvert('error_count', (v) => (v as num).toInt()),
          errors: $checkedConvert('errors',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'importedCount': 'imported_count',
        'errorCount': 'error_count'
      },
    );

Map<String, dynamic> _$$ImportResponseImplToJson(
        _$ImportResponseImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      'imported_count': instance.importedCount,
      'error_count': instance.errorCount,
      if (instance.errors case final value?) 'errors': value,
    };

_$ModelFieldDefinitionImpl _$$ModelFieldDefinitionImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ModelFieldDefinitionImpl',
      json,
      ($checkedConvert) {
        final val = _$ModelFieldDefinitionImpl(
          name: $checkedConvert('name', (v) => v as String),
          type: $checkedConvert('type', (v) => v as String),
          label: $checkedConvert('label', (v) => v as String),
          required: $checkedConvert('required', (v) => v as bool? ?? false),
          readonly: $checkedConvert('readonly', (v) => v as bool? ?? false),
          helpText: $checkedConvert('help_text', (v) => v as String?),
          defaultValue: $checkedConvert('default_value', (v) => v),
          choices: $checkedConvert(
              'choices',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
          validation: $checkedConvert(
              'validation',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
        );
        return val;
      },
      fieldKeyMap: const {
        'helpText': 'help_text',
        'defaultValue': 'default_value'
      },
    );

Map<String, dynamic> _$$ModelFieldDefinitionImplToJson(
        _$ModelFieldDefinitionImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'label': instance.label,
      'required': instance.required,
      'readonly': instance.readonly,
      if (instance.helpText case final value?) 'help_text': value,
      if (instance.defaultValue case final value?) 'default_value': value,
      if (instance.choices case final value?) 'choices': value,
      if (instance.validation case final value?) 'validation': value,
    };

_$ModelFormDefinitionImpl _$$ModelFormDefinitionImplFromJson(Map json) =>
    $checkedCreate(
      r'_$ModelFormDefinitionImpl',
      json,
      ($checkedConvert) {
        final val = _$ModelFormDefinitionImpl(
          fields: $checkedConvert(
              'fields',
              (v) => (v as List<dynamic>)
                  .map((e) => ModelFieldDefinition.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()),
          fieldsets: $checkedConvert(
              'fieldsets',
              (v) => (v as Map).map(
                    (k, e) => MapEntry(k as String,
                        (e as List<dynamic>).map((e) => e as String).toList()),
                  )),
          readonlyFields: $checkedConvert('readonly_fields',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
      fieldKeyMap: const {'readonlyFields': 'readonly_fields'},
    );

Map<String, dynamic> _$$ModelFormDefinitionImplToJson(
        _$ModelFormDefinitionImpl instance) =>
    <String, dynamic>{
      'fields': instance.fields.map((e) => e.toJson()).toList(),
      'fieldsets': instance.fieldsets,
      'readonly_fields': instance.readonlyFields,
    };

_$AdminApiErrorImpl _$$AdminApiErrorImplFromJson(Map json) => $checkedCreate(
      r'_$AdminApiErrorImpl',
      json,
      ($checkedConvert) {
        final val = _$AdminApiErrorImpl(
          message: $checkedConvert('message', (v) => v as String),
          statusCode: $checkedConvert(
              'status_code', (v) => (v as num?)?.toInt() ?? 500),
          code: $checkedConvert('code', (v) => v as String?),
          details: $checkedConvert(
              'details',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
        );
        return val;
      },
      fieldKeyMap: const {'statusCode': 'status_code'},
    );

Map<String, dynamic> _$$AdminApiErrorImplToJson(_$AdminApiErrorImpl instance) =>
    <String, dynamic>{
      'message': instance.message,
      'status_code': instance.statusCode,
      if (instance.code case final value?) 'code': value,
      if (instance.details case final value?) 'details': value,
    };
