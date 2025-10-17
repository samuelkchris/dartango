// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BaseResponse<T> _$BaseResponseFromJson<T>(
    Map<String, dynamic> json, T Function(Object?) fromJsonT) {
  return _BaseResponse<T>.fromJson(json, fromJsonT);
}

/// @nodoc
mixin _$BaseResponse<T> {
  bool get success => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  T? get data => throw _privateConstructorUsedError;
  Map<String, dynamic>? get errors => throw _privateConstructorUsedError;
  @JsonKey(name: 'error_code')
  String? get errorCode => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_BaseResponse<T> value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_BaseResponse<T> value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_BaseResponse<T> value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this BaseResponse to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) =>
      throw _privateConstructorUsedError;

  /// Create a copy of BaseResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BaseResponseCopyWith<T, BaseResponse<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BaseResponseCopyWith<T, $Res> {
  factory $BaseResponseCopyWith(
          BaseResponse<T> value, $Res Function(BaseResponse<T>) then) =
      _$BaseResponseCopyWithImpl<T, $Res, BaseResponse<T>>;
  @useResult
  $Res call(
      {bool success,
      String? message,
      T? data,
      Map<String, dynamic>? errors,
      @JsonKey(name: 'error_code') String? errorCode});
}

/// @nodoc
class _$BaseResponseCopyWithImpl<T, $Res, $Val extends BaseResponse<T>>
    implements $BaseResponseCopyWith<T, $Res> {
  _$BaseResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BaseResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? message = freezed,
    Object? data = freezed,
    Object? errors = freezed,
    Object? errorCode = freezed,
  }) {
    return _then(_value.copyWith(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as T?,
      errors: freezed == errors
          ? _value.errors
          : errors // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      errorCode: freezed == errorCode
          ? _value.errorCode
          : errorCode // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BaseResponseImplCopyWith<T, $Res>
    implements $BaseResponseCopyWith<T, $Res> {
  factory _$$BaseResponseImplCopyWith(_$BaseResponseImpl<T> value,
          $Res Function(_$BaseResponseImpl<T>) then) =
      __$$BaseResponseImplCopyWithImpl<T, $Res>;
  @override
  @useResult
  $Res call(
      {bool success,
      String? message,
      T? data,
      Map<String, dynamic>? errors,
      @JsonKey(name: 'error_code') String? errorCode});
}

/// @nodoc
class __$$BaseResponseImplCopyWithImpl<T, $Res>
    extends _$BaseResponseCopyWithImpl<T, $Res, _$BaseResponseImpl<T>>
    implements _$$BaseResponseImplCopyWith<T, $Res> {
  __$$BaseResponseImplCopyWithImpl(
      _$BaseResponseImpl<T> _value, $Res Function(_$BaseResponseImpl<T>) _then)
      : super(_value, _then);

  /// Create a copy of BaseResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? message = freezed,
    Object? data = freezed,
    Object? errors = freezed,
    Object? errorCode = freezed,
  }) {
    return _then(_$BaseResponseImpl<T>(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as T?,
      errors: freezed == errors
          ? _value._errors
          : errors // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      errorCode: freezed == errorCode
          ? _value.errorCode
          : errorCode // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)
class _$BaseResponseImpl<T> implements _BaseResponse<T> {
  const _$BaseResponseImpl(
      {required this.success,
      this.message,
      this.data,
      final Map<String, dynamic>? errors,
      @JsonKey(name: 'error_code') this.errorCode})
      : _errors = errors;

  factory _$BaseResponseImpl.fromJson(
          Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$$BaseResponseImplFromJson(json, fromJsonT);

  @override
  final bool success;
  @override
  final String? message;
  @override
  final T? data;
  final Map<String, dynamic>? _errors;
  @override
  Map<String, dynamic>? get errors {
    final value = _errors;
    if (value == null) return null;
    if (_errors is EqualUnmodifiableMapView) return _errors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'error_code')
  final String? errorCode;

  @override
  String toString() {
    return 'BaseResponse<$T>(success: $success, message: $message, data: $data, errors: $errors, errorCode: $errorCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BaseResponseImpl<T> &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(other.data, data) &&
            const DeepCollectionEquality().equals(other._errors, _errors) &&
            (identical(other.errorCode, errorCode) ||
                other.errorCode == errorCode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      success,
      message,
      const DeepCollectionEquality().hash(data),
      const DeepCollectionEquality().hash(_errors),
      errorCode);

  /// Create a copy of BaseResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BaseResponseImplCopyWith<T, _$BaseResponseImpl<T>> get copyWith =>
      __$$BaseResponseImplCopyWithImpl<T, _$BaseResponseImpl<T>>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_BaseResponse<T> value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_BaseResponse<T> value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_BaseResponse<T> value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
    return _$$BaseResponseImplToJson<T>(this, toJsonT);
  }
}

abstract class _BaseResponse<T> implements BaseResponse<T> {
  const factory _BaseResponse(
          {required final bool success,
          final String? message,
          final T? data,
          final Map<String, dynamic>? errors,
          @JsonKey(name: 'error_code') final String? errorCode}) =
      _$BaseResponseImpl<T>;

  factory _BaseResponse.fromJson(
          Map<String, dynamic> json, T Function(Object?) fromJsonT) =
      _$BaseResponseImpl<T>.fromJson;

  @override
  bool get success;
  @override
  String? get message;
  @override
  T? get data;
  @override
  Map<String, dynamic>? get errors;
  @override
  @JsonKey(name: 'error_code')
  String? get errorCode;

  /// Create a copy of BaseResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BaseResponseImplCopyWith<T, _$BaseResponseImpl<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) {
  return _LoginRequest.fromJson(json);
}

/// @nodoc
mixin _$LoginRequest {
  String get username => throw _privateConstructorUsedError;
  String get password => throw _privateConstructorUsedError;
  @JsonKey(name: 'remember_me')
  bool get rememberMe => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_LoginRequest value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_LoginRequest value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_LoginRequest value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this LoginRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LoginRequestCopyWith<LoginRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoginRequestCopyWith<$Res> {
  factory $LoginRequestCopyWith(
          LoginRequest value, $Res Function(LoginRequest) then) =
      _$LoginRequestCopyWithImpl<$Res, LoginRequest>;
  @useResult
  $Res call(
      {String username,
      String password,
      @JsonKey(name: 'remember_me') bool rememberMe});
}

/// @nodoc
class _$LoginRequestCopyWithImpl<$Res, $Val extends LoginRequest>
    implements $LoginRequestCopyWith<$Res> {
  _$LoginRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? password = null,
    Object? rememberMe = null,
  }) {
    return _then(_value.copyWith(
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      password: null == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String,
      rememberMe: null == rememberMe
          ? _value.rememberMe
          : rememberMe // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LoginRequestImplCopyWith<$Res>
    implements $LoginRequestCopyWith<$Res> {
  factory _$$LoginRequestImplCopyWith(
          _$LoginRequestImpl value, $Res Function(_$LoginRequestImpl) then) =
      __$$LoginRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String username,
      String password,
      @JsonKey(name: 'remember_me') bool rememberMe});
}

/// @nodoc
class __$$LoginRequestImplCopyWithImpl<$Res>
    extends _$LoginRequestCopyWithImpl<$Res, _$LoginRequestImpl>
    implements _$$LoginRequestImplCopyWith<$Res> {
  __$$LoginRequestImplCopyWithImpl(
      _$LoginRequestImpl _value, $Res Function(_$LoginRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? password = null,
    Object? rememberMe = null,
  }) {
    return _then(_$LoginRequestImpl(
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      password: null == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String,
      rememberMe: null == rememberMe
          ? _value.rememberMe
          : rememberMe // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LoginRequestImpl implements _LoginRequest {
  const _$LoginRequestImpl(
      {required this.username,
      required this.password,
      @JsonKey(name: 'remember_me') this.rememberMe = false});

  factory _$LoginRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$LoginRequestImplFromJson(json);

  @override
  final String username;
  @override
  final String password;
  @override
  @JsonKey(name: 'remember_me')
  final bool rememberMe;

  @override
  String toString() {
    return 'LoginRequest(username: $username, password: $password, rememberMe: $rememberMe)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginRequestImpl &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.rememberMe, rememberMe) ||
                other.rememberMe == rememberMe));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, username, password, rememberMe);

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoginRequestImplCopyWith<_$LoginRequestImpl> get copyWith =>
      __$$LoginRequestImplCopyWithImpl<_$LoginRequestImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_LoginRequest value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_LoginRequest value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_LoginRequest value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$LoginRequestImplToJson(
      this,
    );
  }
}

abstract class _LoginRequest implements LoginRequest {
  const factory _LoginRequest(
          {required final String username,
          required final String password,
          @JsonKey(name: 'remember_me') final bool rememberMe}) =
      _$LoginRequestImpl;

  factory _LoginRequest.fromJson(Map<String, dynamic> json) =
      _$LoginRequestImpl.fromJson;

  @override
  String get username;
  @override
  String get password;
  @override
  @JsonKey(name: 'remember_me')
  bool get rememberMe;

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoginRequestImplCopyWith<_$LoginRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) {
  return _AuthResponse.fromJson(json);
}

/// @nodoc
mixin _$AuthResponse {
  String get token => throw _privateConstructorUsedError;
  @JsonKey(name: 'refresh_token')
  String get refreshToken => throw _privateConstructorUsedError;
  @JsonKey(name: 'expires_in')
  int get expiresIn => throw _privateConstructorUsedError;
  UserProfile get user => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AuthResponse value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AuthResponse value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AuthResponse value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this AuthResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthResponseCopyWith<AuthResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthResponseCopyWith<$Res> {
  factory $AuthResponseCopyWith(
          AuthResponse value, $Res Function(AuthResponse) then) =
      _$AuthResponseCopyWithImpl<$Res, AuthResponse>;
  @useResult
  $Res call(
      {String token,
      @JsonKey(name: 'refresh_token') String refreshToken,
      @JsonKey(name: 'expires_in') int expiresIn,
      UserProfile user});

  $UserProfileCopyWith<$Res> get user;
}

/// @nodoc
class _$AuthResponseCopyWithImpl<$Res, $Val extends AuthResponse>
    implements $AuthResponseCopyWith<$Res> {
  _$AuthResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = null,
    Object? refreshToken = null,
    Object? expiresIn = null,
    Object? user = null,
  }) {
    return _then(_value.copyWith(
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
      refreshToken: null == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String,
      expiresIn: null == expiresIn
          ? _value.expiresIn
          : expiresIn // ignore: cast_nullable_to_non_nullable
              as int,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserProfile,
    ) as $Val);
  }

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserProfileCopyWith<$Res> get user {
    return $UserProfileCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AuthResponseImplCopyWith<$Res>
    implements $AuthResponseCopyWith<$Res> {
  factory _$$AuthResponseImplCopyWith(
          _$AuthResponseImpl value, $Res Function(_$AuthResponseImpl) then) =
      __$$AuthResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String token,
      @JsonKey(name: 'refresh_token') String refreshToken,
      @JsonKey(name: 'expires_in') int expiresIn,
      UserProfile user});

  @override
  $UserProfileCopyWith<$Res> get user;
}

/// @nodoc
class __$$AuthResponseImplCopyWithImpl<$Res>
    extends _$AuthResponseCopyWithImpl<$Res, _$AuthResponseImpl>
    implements _$$AuthResponseImplCopyWith<$Res> {
  __$$AuthResponseImplCopyWithImpl(
      _$AuthResponseImpl _value, $Res Function(_$AuthResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = null,
    Object? refreshToken = null,
    Object? expiresIn = null,
    Object? user = null,
  }) {
    return _then(_$AuthResponseImpl(
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
      refreshToken: null == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String,
      expiresIn: null == expiresIn
          ? _value.expiresIn
          : expiresIn // ignore: cast_nullable_to_non_nullable
              as int,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserProfile,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthResponseImpl implements _AuthResponse {
  const _$AuthResponseImpl(
      {required this.token,
      @JsonKey(name: 'refresh_token') required this.refreshToken,
      @JsonKey(name: 'expires_in') required this.expiresIn,
      required this.user});

  factory _$AuthResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthResponseImplFromJson(json);

  @override
  final String token;
  @override
  @JsonKey(name: 'refresh_token')
  final String refreshToken;
  @override
  @JsonKey(name: 'expires_in')
  final int expiresIn;
  @override
  final UserProfile user;

  @override
  String toString() {
    return 'AuthResponse(token: $token, refreshToken: $refreshToken, expiresIn: $expiresIn, user: $user)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthResponseImpl &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.refreshToken, refreshToken) ||
                other.refreshToken == refreshToken) &&
            (identical(other.expiresIn, expiresIn) ||
                other.expiresIn == expiresIn) &&
            (identical(other.user, user) || other.user == user));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, token, refreshToken, expiresIn, user);

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthResponseImplCopyWith<_$AuthResponseImpl> get copyWith =>
      __$$AuthResponseImplCopyWithImpl<_$AuthResponseImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AuthResponse value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AuthResponse value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AuthResponse value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthResponseImplToJson(
      this,
    );
  }
}

abstract class _AuthResponse implements AuthResponse {
  const factory _AuthResponse(
      {required final String token,
      @JsonKey(name: 'refresh_token') required final String refreshToken,
      @JsonKey(name: 'expires_in') required final int expiresIn,
      required final UserProfile user}) = _$AuthResponseImpl;

  factory _AuthResponse.fromJson(Map<String, dynamic> json) =
      _$AuthResponseImpl.fromJson;

  @override
  String get token;
  @override
  @JsonKey(name: 'refresh_token')
  String get refreshToken;
  @override
  @JsonKey(name: 'expires_in')
  int get expiresIn;
  @override
  UserProfile get user;

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthResponseImplCopyWith<_$AuthResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RefreshTokenRequest _$RefreshTokenRequestFromJson(Map<String, dynamic> json) {
  return _RefreshTokenRequest.fromJson(json);
}

/// @nodoc
mixin _$RefreshTokenRequest {
  @JsonKey(name: 'refresh_token')
  String get refreshToken => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_RefreshTokenRequest value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_RefreshTokenRequest value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_RefreshTokenRequest value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this RefreshTokenRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RefreshTokenRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RefreshTokenRequestCopyWith<RefreshTokenRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RefreshTokenRequestCopyWith<$Res> {
  factory $RefreshTokenRequestCopyWith(
          RefreshTokenRequest value, $Res Function(RefreshTokenRequest) then) =
      _$RefreshTokenRequestCopyWithImpl<$Res, RefreshTokenRequest>;
  @useResult
  $Res call({@JsonKey(name: 'refresh_token') String refreshToken});
}

/// @nodoc
class _$RefreshTokenRequestCopyWithImpl<$Res, $Val extends RefreshTokenRequest>
    implements $RefreshTokenRequestCopyWith<$Res> {
  _$RefreshTokenRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RefreshTokenRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? refreshToken = null,
  }) {
    return _then(_value.copyWith(
      refreshToken: null == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RefreshTokenRequestImplCopyWith<$Res>
    implements $RefreshTokenRequestCopyWith<$Res> {
  factory _$$RefreshTokenRequestImplCopyWith(_$RefreshTokenRequestImpl value,
          $Res Function(_$RefreshTokenRequestImpl) then) =
      __$$RefreshTokenRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'refresh_token') String refreshToken});
}

/// @nodoc
class __$$RefreshTokenRequestImplCopyWithImpl<$Res>
    extends _$RefreshTokenRequestCopyWithImpl<$Res, _$RefreshTokenRequestImpl>
    implements _$$RefreshTokenRequestImplCopyWith<$Res> {
  __$$RefreshTokenRequestImplCopyWithImpl(_$RefreshTokenRequestImpl _value,
      $Res Function(_$RefreshTokenRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of RefreshTokenRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? refreshToken = null,
  }) {
    return _then(_$RefreshTokenRequestImpl(
      refreshToken: null == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RefreshTokenRequestImpl implements _RefreshTokenRequest {
  const _$RefreshTokenRequestImpl(
      {@JsonKey(name: 'refresh_token') required this.refreshToken});

  factory _$RefreshTokenRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$RefreshTokenRequestImplFromJson(json);

  @override
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  @override
  String toString() {
    return 'RefreshTokenRequest(refreshToken: $refreshToken)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RefreshTokenRequestImpl &&
            (identical(other.refreshToken, refreshToken) ||
                other.refreshToken == refreshToken));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, refreshToken);

  /// Create a copy of RefreshTokenRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RefreshTokenRequestImplCopyWith<_$RefreshTokenRequestImpl> get copyWith =>
      __$$RefreshTokenRequestImplCopyWithImpl<_$RefreshTokenRequestImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_RefreshTokenRequest value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_RefreshTokenRequest value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_RefreshTokenRequest value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$RefreshTokenRequestImplToJson(
      this,
    );
  }
}

abstract class _RefreshTokenRequest implements RefreshTokenRequest {
  const factory _RefreshTokenRequest(
      {@JsonKey(name: 'refresh_token')
      required final String refreshToken}) = _$RefreshTokenRequestImpl;

  factory _RefreshTokenRequest.fromJson(Map<String, dynamic> json) =
      _$RefreshTokenRequestImpl.fromJson;

  @override
  @JsonKey(name: 'refresh_token')
  String get refreshToken;

  /// Create a copy of RefreshTokenRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RefreshTokenRequestImplCopyWith<_$RefreshTokenRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LogoutResponse _$LogoutResponseFromJson(Map<String, dynamic> json) {
  return _LogoutResponse.fromJson(json);
}

/// @nodoc
mixin _$LogoutResponse {
  String get message => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_LogoutResponse value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_LogoutResponse value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_LogoutResponse value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this LogoutResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LogoutResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LogoutResponseCopyWith<LogoutResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LogoutResponseCopyWith<$Res> {
  factory $LogoutResponseCopyWith(
          LogoutResponse value, $Res Function(LogoutResponse) then) =
      _$LogoutResponseCopyWithImpl<$Res, LogoutResponse>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$LogoutResponseCopyWithImpl<$Res, $Val extends LogoutResponse>
    implements $LogoutResponseCopyWith<$Res> {
  _$LogoutResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LogoutResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_value.copyWith(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LogoutResponseImplCopyWith<$Res>
    implements $LogoutResponseCopyWith<$Res> {
  factory _$$LogoutResponseImplCopyWith(_$LogoutResponseImpl value,
          $Res Function(_$LogoutResponseImpl) then) =
      __$$LogoutResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$LogoutResponseImplCopyWithImpl<$Res>
    extends _$LogoutResponseCopyWithImpl<$Res, _$LogoutResponseImpl>
    implements _$$LogoutResponseImplCopyWith<$Res> {
  __$$LogoutResponseImplCopyWithImpl(
      _$LogoutResponseImpl _value, $Res Function(_$LogoutResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of LogoutResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$LogoutResponseImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LogoutResponseImpl implements _LogoutResponse {
  const _$LogoutResponseImpl({required this.message});

  factory _$LogoutResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$LogoutResponseImplFromJson(json);

  @override
  final String message;

  @override
  String toString() {
    return 'LogoutResponse(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LogoutResponseImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of LogoutResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LogoutResponseImplCopyWith<_$LogoutResponseImpl> get copyWith =>
      __$$LogoutResponseImplCopyWithImpl<_$LogoutResponseImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_LogoutResponse value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_LogoutResponse value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_LogoutResponse value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$LogoutResponseImplToJson(
      this,
    );
  }
}

abstract class _LogoutResponse implements LogoutResponse {
  const factory _LogoutResponse({required final String message}) =
      _$LogoutResponseImpl;

  factory _LogoutResponse.fromJson(Map<String, dynamic> json) =
      _$LogoutResponseImpl.fromJson;

  @override
  String get message;

  /// Create a copy of LogoutResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LogoutResponseImplCopyWith<_$LogoutResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) {
  return _UserProfile.fromJson(json);
}

/// @nodoc
mixin _$UserProfile {
  int get id => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  @JsonKey(name: 'first_name')
  String? get firstName => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_name')
  String? get lastName => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_staff')
  bool get isStaff => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_superuser')
  bool get isSuperuser => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool get isActive => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_joined')
  DateTime get dateJoined => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_login')
  DateTime? get lastLogin => throw _privateConstructorUsedError;
  List<String>? get permissions => throw _privateConstructorUsedError;
  List<AdminGroup>? get groups => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_UserProfile value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_UserProfile value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_UserProfile value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
          UserProfile value, $Res Function(UserProfile) then) =
      _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call(
      {int id,
      String username,
      String email,
      @JsonKey(name: 'first_name') String? firstName,
      @JsonKey(name: 'last_name') String? lastName,
      @JsonKey(name: 'is_staff') bool isStaff,
      @JsonKey(name: 'is_superuser') bool isSuperuser,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'date_joined') DateTime dateJoined,
      @JsonKey(name: 'last_login') DateTime? lastLogin,
      List<String>? permissions,
      List<AdminGroup>? groups});
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? email = null,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? isStaff = null,
    Object? isSuperuser = null,
    Object? isActive = null,
    Object? dateJoined = null,
    Object? lastLogin = freezed,
    Object? permissions = freezed,
    Object? groups = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      isStaff: null == isStaff
          ? _value.isStaff
          : isStaff // ignore: cast_nullable_to_non_nullable
              as bool,
      isSuperuser: null == isSuperuser
          ? _value.isSuperuser
          : isSuperuser // ignore: cast_nullable_to_non_nullable
              as bool,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      dateJoined: null == dateJoined
          ? _value.dateJoined
          : dateJoined // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastLogin: freezed == lastLogin
          ? _value.lastLogin
          : lastLogin // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      permissions: freezed == permissions
          ? _value.permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      groups: freezed == groups
          ? _value.groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<AdminGroup>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
          _$UserProfileImpl value, $Res Function(_$UserProfileImpl) then) =
      __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String username,
      String email,
      @JsonKey(name: 'first_name') String? firstName,
      @JsonKey(name: 'last_name') String? lastName,
      @JsonKey(name: 'is_staff') bool isStaff,
      @JsonKey(name: 'is_superuser') bool isSuperuser,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'date_joined') DateTime dateJoined,
      @JsonKey(name: 'last_login') DateTime? lastLogin,
      List<String>? permissions,
      List<AdminGroup>? groups});
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
      _$UserProfileImpl _value, $Res Function(_$UserProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? email = null,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? isStaff = null,
    Object? isSuperuser = null,
    Object? isActive = null,
    Object? dateJoined = null,
    Object? lastLogin = freezed,
    Object? permissions = freezed,
    Object? groups = freezed,
  }) {
    return _then(_$UserProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      isStaff: null == isStaff
          ? _value.isStaff
          : isStaff // ignore: cast_nullable_to_non_nullable
              as bool,
      isSuperuser: null == isSuperuser
          ? _value.isSuperuser
          : isSuperuser // ignore: cast_nullable_to_non_nullable
              as bool,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      dateJoined: null == dateJoined
          ? _value.dateJoined
          : dateJoined // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastLogin: freezed == lastLogin
          ? _value.lastLogin
          : lastLogin // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      permissions: freezed == permissions
          ? _value._permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      groups: freezed == groups
          ? _value._groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<AdminGroup>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserProfileImpl implements _UserProfile {
  const _$UserProfileImpl(
      {required this.id,
      required this.username,
      required this.email,
      @JsonKey(name: 'first_name') this.firstName,
      @JsonKey(name: 'last_name') this.lastName,
      @JsonKey(name: 'is_staff') required this.isStaff,
      @JsonKey(name: 'is_superuser') required this.isSuperuser,
      @JsonKey(name: 'is_active') required this.isActive,
      @JsonKey(name: 'date_joined') required this.dateJoined,
      @JsonKey(name: 'last_login') this.lastLogin,
      final List<String>? permissions,
      final List<AdminGroup>? groups})
      : _permissions = permissions,
        _groups = groups;

  factory _$UserProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfileImplFromJson(json);

  @override
  final int id;
  @override
  final String username;
  @override
  final String email;
  @override
  @JsonKey(name: 'first_name')
  final String? firstName;
  @override
  @JsonKey(name: 'last_name')
  final String? lastName;
  @override
  @JsonKey(name: 'is_staff')
  final bool isStaff;
  @override
  @JsonKey(name: 'is_superuser')
  final bool isSuperuser;
  @override
  @JsonKey(name: 'is_active')
  final bool isActive;
  @override
  @JsonKey(name: 'date_joined')
  final DateTime dateJoined;
  @override
  @JsonKey(name: 'last_login')
  final DateTime? lastLogin;
  final List<String>? _permissions;
  @override
  List<String>? get permissions {
    final value = _permissions;
    if (value == null) return null;
    if (_permissions is EqualUnmodifiableListView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<AdminGroup>? _groups;
  @override
  List<AdminGroup>? get groups {
    final value = _groups;
    if (value == null) return null;
    if (_groups is EqualUnmodifiableListView) return _groups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, username: $username, email: $email, firstName: $firstName, lastName: $lastName, isStaff: $isStaff, isSuperuser: $isSuperuser, isActive: $isActive, dateJoined: $dateJoined, lastLogin: $lastLogin, permissions: $permissions, groups: $groups)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.isStaff, isStaff) || other.isStaff == isStaff) &&
            (identical(other.isSuperuser, isSuperuser) ||
                other.isSuperuser == isSuperuser) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.dateJoined, dateJoined) ||
                other.dateJoined == dateJoined) &&
            (identical(other.lastLogin, lastLogin) ||
                other.lastLogin == lastLogin) &&
            const DeepCollectionEquality()
                .equals(other._permissions, _permissions) &&
            const DeepCollectionEquality().equals(other._groups, _groups));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      username,
      email,
      firstName,
      lastName,
      isStaff,
      isSuperuser,
      isActive,
      dateJoined,
      lastLogin,
      const DeepCollectionEquality().hash(_permissions),
      const DeepCollectionEquality().hash(_groups));

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_UserProfile value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_UserProfile value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_UserProfile value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfileImplToJson(
      this,
    );
  }
}

abstract class _UserProfile implements UserProfile {
  const factory _UserProfile(
      {required final int id,
      required final String username,
      required final String email,
      @JsonKey(name: 'first_name') final String? firstName,
      @JsonKey(name: 'last_name') final String? lastName,
      @JsonKey(name: 'is_staff') required final bool isStaff,
      @JsonKey(name: 'is_superuser') required final bool isSuperuser,
      @JsonKey(name: 'is_active') required final bool isActive,
      @JsonKey(name: 'date_joined') required final DateTime dateJoined,
      @JsonKey(name: 'last_login') final DateTime? lastLogin,
      final List<String>? permissions,
      final List<AdminGroup>? groups}) = _$UserProfileImpl;

  factory _UserProfile.fromJson(Map<String, dynamic> json) =
      _$UserProfileImpl.fromJson;

  @override
  int get id;
  @override
  String get username;
  @override
  String get email;
  @override
  @JsonKey(name: 'first_name')
  String? get firstName;
  @override
  @JsonKey(name: 'last_name')
  String? get lastName;
  @override
  @JsonKey(name: 'is_staff')
  bool get isStaff;
  @override
  @JsonKey(name: 'is_superuser')
  bool get isSuperuser;
  @override
  @JsonKey(name: 'is_active')
  bool get isActive;
  @override
  @JsonKey(name: 'date_joined')
  DateTime get dateJoined;
  @override
  @JsonKey(name: 'last_login')
  DateTime? get lastLogin;
  @override
  List<String>? get permissions;
  @override
  List<AdminGroup>? get groups;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AdminUser _$AdminUserFromJson(Map<String, dynamic> json) {
  return _AdminUser.fromJson(json);
}

/// @nodoc
mixin _$AdminUser {
  int get id => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  @JsonKey(name: 'first_name')
  String? get firstName => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_name')
  String? get lastName => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_staff')
  bool get isStaff => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_superuser')
  bool get isSuperuser => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool get isActive => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_joined')
  DateTime get dateJoined => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_login')
  DateTime? get lastLogin => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AdminUser value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AdminUser value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AdminUser value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this AdminUser to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdminUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdminUserCopyWith<AdminUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminUserCopyWith<$Res> {
  factory $AdminUserCopyWith(AdminUser value, $Res Function(AdminUser) then) =
      _$AdminUserCopyWithImpl<$Res, AdminUser>;
  @useResult
  $Res call(
      {int id,
      String username,
      String email,
      @JsonKey(name: 'first_name') String? firstName,
      @JsonKey(name: 'last_name') String? lastName,
      @JsonKey(name: 'is_staff') bool isStaff,
      @JsonKey(name: 'is_superuser') bool isSuperuser,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'date_joined') DateTime dateJoined,
      @JsonKey(name: 'last_login') DateTime? lastLogin});
}

/// @nodoc
class _$AdminUserCopyWithImpl<$Res, $Val extends AdminUser>
    implements $AdminUserCopyWith<$Res> {
  _$AdminUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdminUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? email = null,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? isStaff = null,
    Object? isSuperuser = null,
    Object? isActive = null,
    Object? dateJoined = null,
    Object? lastLogin = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      isStaff: null == isStaff
          ? _value.isStaff
          : isStaff // ignore: cast_nullable_to_non_nullable
              as bool,
      isSuperuser: null == isSuperuser
          ? _value.isSuperuser
          : isSuperuser // ignore: cast_nullable_to_non_nullable
              as bool,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      dateJoined: null == dateJoined
          ? _value.dateJoined
          : dateJoined // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastLogin: freezed == lastLogin
          ? _value.lastLogin
          : lastLogin // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminUserImplCopyWith<$Res>
    implements $AdminUserCopyWith<$Res> {
  factory _$$AdminUserImplCopyWith(
          _$AdminUserImpl value, $Res Function(_$AdminUserImpl) then) =
      __$$AdminUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String username,
      String email,
      @JsonKey(name: 'first_name') String? firstName,
      @JsonKey(name: 'last_name') String? lastName,
      @JsonKey(name: 'is_staff') bool isStaff,
      @JsonKey(name: 'is_superuser') bool isSuperuser,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'date_joined') DateTime dateJoined,
      @JsonKey(name: 'last_login') DateTime? lastLogin});
}

/// @nodoc
class __$$AdminUserImplCopyWithImpl<$Res>
    extends _$AdminUserCopyWithImpl<$Res, _$AdminUserImpl>
    implements _$$AdminUserImplCopyWith<$Res> {
  __$$AdminUserImplCopyWithImpl(
      _$AdminUserImpl _value, $Res Function(_$AdminUserImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdminUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? email = null,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? isStaff = null,
    Object? isSuperuser = null,
    Object? isActive = null,
    Object? dateJoined = null,
    Object? lastLogin = freezed,
  }) {
    return _then(_$AdminUserImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      isStaff: null == isStaff
          ? _value.isStaff
          : isStaff // ignore: cast_nullable_to_non_nullable
              as bool,
      isSuperuser: null == isSuperuser
          ? _value.isSuperuser
          : isSuperuser // ignore: cast_nullable_to_non_nullable
              as bool,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      dateJoined: null == dateJoined
          ? _value.dateJoined
          : dateJoined // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastLogin: freezed == lastLogin
          ? _value.lastLogin
          : lastLogin // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminUserImpl implements _AdminUser {
  const _$AdminUserImpl(
      {required this.id,
      required this.username,
      required this.email,
      @JsonKey(name: 'first_name') this.firstName,
      @JsonKey(name: 'last_name') this.lastName,
      @JsonKey(name: 'is_staff') required this.isStaff,
      @JsonKey(name: 'is_superuser') required this.isSuperuser,
      @JsonKey(name: 'is_active') required this.isActive,
      @JsonKey(name: 'date_joined') required this.dateJoined,
      @JsonKey(name: 'last_login') this.lastLogin});

  factory _$AdminUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminUserImplFromJson(json);

  @override
  final int id;
  @override
  final String username;
  @override
  final String email;
  @override
  @JsonKey(name: 'first_name')
  final String? firstName;
  @override
  @JsonKey(name: 'last_name')
  final String? lastName;
  @override
  @JsonKey(name: 'is_staff')
  final bool isStaff;
  @override
  @JsonKey(name: 'is_superuser')
  final bool isSuperuser;
  @override
  @JsonKey(name: 'is_active')
  final bool isActive;
  @override
  @JsonKey(name: 'date_joined')
  final DateTime dateJoined;
  @override
  @JsonKey(name: 'last_login')
  final DateTime? lastLogin;

  @override
  String toString() {
    return 'AdminUser(id: $id, username: $username, email: $email, firstName: $firstName, lastName: $lastName, isStaff: $isStaff, isSuperuser: $isSuperuser, isActive: $isActive, dateJoined: $dateJoined, lastLogin: $lastLogin)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminUserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.isStaff, isStaff) || other.isStaff == isStaff) &&
            (identical(other.isSuperuser, isSuperuser) ||
                other.isSuperuser == isSuperuser) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.dateJoined, dateJoined) ||
                other.dateJoined == dateJoined) &&
            (identical(other.lastLogin, lastLogin) ||
                other.lastLogin == lastLogin));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, username, email, firstName,
      lastName, isStaff, isSuperuser, isActive, dateJoined, lastLogin);

  /// Create a copy of AdminUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminUserImplCopyWith<_$AdminUserImpl> get copyWith =>
      __$$AdminUserImplCopyWithImpl<_$AdminUserImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AdminUser value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AdminUser value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AdminUser value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminUserImplToJson(
      this,
    );
  }
}

abstract class _AdminUser implements AdminUser {
  const factory _AdminUser(
          {required final int id,
          required final String username,
          required final String email,
          @JsonKey(name: 'first_name') final String? firstName,
          @JsonKey(name: 'last_name') final String? lastName,
          @JsonKey(name: 'is_staff') required final bool isStaff,
          @JsonKey(name: 'is_superuser') required final bool isSuperuser,
          @JsonKey(name: 'is_active') required final bool isActive,
          @JsonKey(name: 'date_joined') required final DateTime dateJoined,
          @JsonKey(name: 'last_login') final DateTime? lastLogin}) =
      _$AdminUserImpl;

  factory _AdminUser.fromJson(Map<String, dynamic> json) =
      _$AdminUserImpl.fromJson;

  @override
  int get id;
  @override
  String get username;
  @override
  String get email;
  @override
  @JsonKey(name: 'first_name')
  String? get firstName;
  @override
  @JsonKey(name: 'last_name')
  String? get lastName;
  @override
  @JsonKey(name: 'is_staff')
  bool get isStaff;
  @override
  @JsonKey(name: 'is_superuser')
  bool get isSuperuser;
  @override
  @JsonKey(name: 'is_active')
  bool get isActive;
  @override
  @JsonKey(name: 'date_joined')
  DateTime get dateJoined;
  @override
  @JsonKey(name: 'last_login')
  DateTime? get lastLogin;

  /// Create a copy of AdminUser
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdminUserImplCopyWith<_$AdminUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreateUserRequest _$CreateUserRequestFromJson(Map<String, dynamic> json) {
  return _CreateUserRequest.fromJson(json);
}

/// @nodoc
mixin _$CreateUserRequest {
  String get username => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get password => throw _privateConstructorUsedError;
  @JsonKey(name: 'first_name')
  String? get firstName => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_name')
  String? get lastName => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_staff')
  bool get isStaff => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_superuser')
  bool get isSuperuser => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool get isActive => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_CreateUserRequest value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_CreateUserRequest value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_CreateUserRequest value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this CreateUserRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreateUserRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateUserRequestCopyWith<CreateUserRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateUserRequestCopyWith<$Res> {
  factory $CreateUserRequestCopyWith(
          CreateUserRequest value, $Res Function(CreateUserRequest) then) =
      _$CreateUserRequestCopyWithImpl<$Res, CreateUserRequest>;
  @useResult
  $Res call(
      {String username,
      String email,
      String password,
      @JsonKey(name: 'first_name') String? firstName,
      @JsonKey(name: 'last_name') String? lastName,
      @JsonKey(name: 'is_staff') bool isStaff,
      @JsonKey(name: 'is_superuser') bool isSuperuser,
      @JsonKey(name: 'is_active') bool isActive});
}

/// @nodoc
class _$CreateUserRequestCopyWithImpl<$Res, $Val extends CreateUserRequest>
    implements $CreateUserRequestCopyWith<$Res> {
  _$CreateUserRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateUserRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? email = null,
    Object? password = null,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? isStaff = null,
    Object? isSuperuser = null,
    Object? isActive = null,
  }) {
    return _then(_value.copyWith(
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      password: null == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      isStaff: null == isStaff
          ? _value.isStaff
          : isStaff // ignore: cast_nullable_to_non_nullable
              as bool,
      isSuperuser: null == isSuperuser
          ? _value.isSuperuser
          : isSuperuser // ignore: cast_nullable_to_non_nullable
              as bool,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CreateUserRequestImplCopyWith<$Res>
    implements $CreateUserRequestCopyWith<$Res> {
  factory _$$CreateUserRequestImplCopyWith(_$CreateUserRequestImpl value,
          $Res Function(_$CreateUserRequestImpl) then) =
      __$$CreateUserRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String username,
      String email,
      String password,
      @JsonKey(name: 'first_name') String? firstName,
      @JsonKey(name: 'last_name') String? lastName,
      @JsonKey(name: 'is_staff') bool isStaff,
      @JsonKey(name: 'is_superuser') bool isSuperuser,
      @JsonKey(name: 'is_active') bool isActive});
}

/// @nodoc
class __$$CreateUserRequestImplCopyWithImpl<$Res>
    extends _$CreateUserRequestCopyWithImpl<$Res, _$CreateUserRequestImpl>
    implements _$$CreateUserRequestImplCopyWith<$Res> {
  __$$CreateUserRequestImplCopyWithImpl(_$CreateUserRequestImpl _value,
      $Res Function(_$CreateUserRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of CreateUserRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? email = null,
    Object? password = null,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? isStaff = null,
    Object? isSuperuser = null,
    Object? isActive = null,
  }) {
    return _then(_$CreateUserRequestImpl(
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      password: null == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      isStaff: null == isStaff
          ? _value.isStaff
          : isStaff // ignore: cast_nullable_to_non_nullable
              as bool,
      isSuperuser: null == isSuperuser
          ? _value.isSuperuser
          : isSuperuser // ignore: cast_nullable_to_non_nullable
              as bool,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateUserRequestImpl implements _CreateUserRequest {
  const _$CreateUserRequestImpl(
      {required this.username,
      required this.email,
      required this.password,
      @JsonKey(name: 'first_name') this.firstName,
      @JsonKey(name: 'last_name') this.lastName,
      @JsonKey(name: 'is_staff') this.isStaff = false,
      @JsonKey(name: 'is_superuser') this.isSuperuser = false,
      @JsonKey(name: 'is_active') this.isActive = true});

  factory _$CreateUserRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateUserRequestImplFromJson(json);

  @override
  final String username;
  @override
  final String email;
  @override
  final String password;
  @override
  @JsonKey(name: 'first_name')
  final String? firstName;
  @override
  @JsonKey(name: 'last_name')
  final String? lastName;
  @override
  @JsonKey(name: 'is_staff')
  final bool isStaff;
  @override
  @JsonKey(name: 'is_superuser')
  final bool isSuperuser;
  @override
  @JsonKey(name: 'is_active')
  final bool isActive;

  @override
  String toString() {
    return 'CreateUserRequest(username: $username, email: $email, password: $password, firstName: $firstName, lastName: $lastName, isStaff: $isStaff, isSuperuser: $isSuperuser, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateUserRequestImpl &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.isStaff, isStaff) || other.isStaff == isStaff) &&
            (identical(other.isSuperuser, isSuperuser) ||
                other.isSuperuser == isSuperuser) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, username, email, password,
      firstName, lastName, isStaff, isSuperuser, isActive);

  /// Create a copy of CreateUserRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateUserRequestImplCopyWith<_$CreateUserRequestImpl> get copyWith =>
      __$$CreateUserRequestImplCopyWithImpl<_$CreateUserRequestImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_CreateUserRequest value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_CreateUserRequest value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_CreateUserRequest value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateUserRequestImplToJson(
      this,
    );
  }
}

abstract class _CreateUserRequest implements CreateUserRequest {
  const factory _CreateUserRequest(
          {required final String username,
          required final String email,
          required final String password,
          @JsonKey(name: 'first_name') final String? firstName,
          @JsonKey(name: 'last_name') final String? lastName,
          @JsonKey(name: 'is_staff') final bool isStaff,
          @JsonKey(name: 'is_superuser') final bool isSuperuser,
          @JsonKey(name: 'is_active') final bool isActive}) =
      _$CreateUserRequestImpl;

  factory _CreateUserRequest.fromJson(Map<String, dynamic> json) =
      _$CreateUserRequestImpl.fromJson;

  @override
  String get username;
  @override
  String get email;
  @override
  String get password;
  @override
  @JsonKey(name: 'first_name')
  String? get firstName;
  @override
  @JsonKey(name: 'last_name')
  String? get lastName;
  @override
  @JsonKey(name: 'is_staff')
  bool get isStaff;
  @override
  @JsonKey(name: 'is_superuser')
  bool get isSuperuser;
  @override
  @JsonKey(name: 'is_active')
  bool get isActive;

  /// Create a copy of CreateUserRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateUserRequestImplCopyWith<_$CreateUserRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UpdateUserRequest _$UpdateUserRequestFromJson(Map<String, dynamic> json) {
  return _UpdateUserRequest.fromJson(json);
}

/// @nodoc
mixin _$UpdateUserRequest {
  String? get username => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get password => throw _privateConstructorUsedError;
  @JsonKey(name: 'first_name')
  String? get firstName => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_name')
  String? get lastName => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_staff')
  bool? get isStaff => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_superuser')
  bool? get isSuperuser => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool? get isActive => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_UpdateUserRequest value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_UpdateUserRequest value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_UpdateUserRequest value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this UpdateUserRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UpdateUserRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UpdateUserRequestCopyWith<UpdateUserRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UpdateUserRequestCopyWith<$Res> {
  factory $UpdateUserRequestCopyWith(
          UpdateUserRequest value, $Res Function(UpdateUserRequest) then) =
      _$UpdateUserRequestCopyWithImpl<$Res, UpdateUserRequest>;
  @useResult
  $Res call(
      {String? username,
      String? email,
      String? password,
      @JsonKey(name: 'first_name') String? firstName,
      @JsonKey(name: 'last_name') String? lastName,
      @JsonKey(name: 'is_staff') bool? isStaff,
      @JsonKey(name: 'is_superuser') bool? isSuperuser,
      @JsonKey(name: 'is_active') bool? isActive});
}

/// @nodoc
class _$UpdateUserRequestCopyWithImpl<$Res, $Val extends UpdateUserRequest>
    implements $UpdateUserRequestCopyWith<$Res> {
  _$UpdateUserRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UpdateUserRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = freezed,
    Object? email = freezed,
    Object? password = freezed,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? isStaff = freezed,
    Object? isSuperuser = freezed,
    Object? isActive = freezed,
  }) {
    return _then(_value.copyWith(
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      password: freezed == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String?,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      isStaff: freezed == isStaff
          ? _value.isStaff
          : isStaff // ignore: cast_nullable_to_non_nullable
              as bool?,
      isSuperuser: freezed == isSuperuser
          ? _value.isSuperuser
          : isSuperuser // ignore: cast_nullable_to_non_nullable
              as bool?,
      isActive: freezed == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UpdateUserRequestImplCopyWith<$Res>
    implements $UpdateUserRequestCopyWith<$Res> {
  factory _$$UpdateUserRequestImplCopyWith(_$UpdateUserRequestImpl value,
          $Res Function(_$UpdateUserRequestImpl) then) =
      __$$UpdateUserRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? username,
      String? email,
      String? password,
      @JsonKey(name: 'first_name') String? firstName,
      @JsonKey(name: 'last_name') String? lastName,
      @JsonKey(name: 'is_staff') bool? isStaff,
      @JsonKey(name: 'is_superuser') bool? isSuperuser,
      @JsonKey(name: 'is_active') bool? isActive});
}

/// @nodoc
class __$$UpdateUserRequestImplCopyWithImpl<$Res>
    extends _$UpdateUserRequestCopyWithImpl<$Res, _$UpdateUserRequestImpl>
    implements _$$UpdateUserRequestImplCopyWith<$Res> {
  __$$UpdateUserRequestImplCopyWithImpl(_$UpdateUserRequestImpl _value,
      $Res Function(_$UpdateUserRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of UpdateUserRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = freezed,
    Object? email = freezed,
    Object? password = freezed,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? isStaff = freezed,
    Object? isSuperuser = freezed,
    Object? isActive = freezed,
  }) {
    return _then(_$UpdateUserRequestImpl(
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      password: freezed == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String?,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      isStaff: freezed == isStaff
          ? _value.isStaff
          : isStaff // ignore: cast_nullable_to_non_nullable
              as bool?,
      isSuperuser: freezed == isSuperuser
          ? _value.isSuperuser
          : isSuperuser // ignore: cast_nullable_to_non_nullable
              as bool?,
      isActive: freezed == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UpdateUserRequestImpl implements _UpdateUserRequest {
  const _$UpdateUserRequestImpl(
      {this.username,
      this.email,
      this.password,
      @JsonKey(name: 'first_name') this.firstName,
      @JsonKey(name: 'last_name') this.lastName,
      @JsonKey(name: 'is_staff') this.isStaff,
      @JsonKey(name: 'is_superuser') this.isSuperuser,
      @JsonKey(name: 'is_active') this.isActive});

  factory _$UpdateUserRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$UpdateUserRequestImplFromJson(json);

  @override
  final String? username;
  @override
  final String? email;
  @override
  final String? password;
  @override
  @JsonKey(name: 'first_name')
  final String? firstName;
  @override
  @JsonKey(name: 'last_name')
  final String? lastName;
  @override
  @JsonKey(name: 'is_staff')
  final bool? isStaff;
  @override
  @JsonKey(name: 'is_superuser')
  final bool? isSuperuser;
  @override
  @JsonKey(name: 'is_active')
  final bool? isActive;

  @override
  String toString() {
    return 'UpdateUserRequest(username: $username, email: $email, password: $password, firstName: $firstName, lastName: $lastName, isStaff: $isStaff, isSuperuser: $isSuperuser, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateUserRequestImpl &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.isStaff, isStaff) || other.isStaff == isStaff) &&
            (identical(other.isSuperuser, isSuperuser) ||
                other.isSuperuser == isSuperuser) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, username, email, password,
      firstName, lastName, isStaff, isSuperuser, isActive);

  /// Create a copy of UpdateUserRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateUserRequestImplCopyWith<_$UpdateUserRequestImpl> get copyWith =>
      __$$UpdateUserRequestImplCopyWithImpl<_$UpdateUserRequestImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_UpdateUserRequest value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_UpdateUserRequest value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_UpdateUserRequest value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$UpdateUserRequestImplToJson(
      this,
    );
  }
}

abstract class _UpdateUserRequest implements UpdateUserRequest {
  const factory _UpdateUserRequest(
          {final String? username,
          final String? email,
          final String? password,
          @JsonKey(name: 'first_name') final String? firstName,
          @JsonKey(name: 'last_name') final String? lastName,
          @JsonKey(name: 'is_staff') final bool? isStaff,
          @JsonKey(name: 'is_superuser') final bool? isSuperuser,
          @JsonKey(name: 'is_active') final bool? isActive}) =
      _$UpdateUserRequestImpl;

  factory _UpdateUserRequest.fromJson(Map<String, dynamic> json) =
      _$UpdateUserRequestImpl.fromJson;

  @override
  String? get username;
  @override
  String? get email;
  @override
  String? get password;
  @override
  @JsonKey(name: 'first_name')
  String? get firstName;
  @override
  @JsonKey(name: 'last_name')
  String? get lastName;
  @override
  @JsonKey(name: 'is_staff')
  bool? get isStaff;
  @override
  @JsonKey(name: 'is_superuser')
  bool? get isSuperuser;
  @override
  @JsonKey(name: 'is_active')
  bool? get isActive;

  /// Create a copy of UpdateUserRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateUserRequestImplCopyWith<_$UpdateUserRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AdminGroup _$AdminGroupFromJson(Map<String, dynamic> json) {
  return _AdminGroup.fromJson(json);
}

/// @nodoc
mixin _$AdminGroup {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<String>? get permissions => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AdminGroup value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AdminGroup value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AdminGroup value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this AdminGroup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdminGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdminGroupCopyWith<AdminGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminGroupCopyWith<$Res> {
  factory $AdminGroupCopyWith(
          AdminGroup value, $Res Function(AdminGroup) then) =
      _$AdminGroupCopyWithImpl<$Res, AdminGroup>;
  @useResult
  $Res call({int id, String name, List<String>? permissions});
}

/// @nodoc
class _$AdminGroupCopyWithImpl<$Res, $Val extends AdminGroup>
    implements $AdminGroupCopyWith<$Res> {
  _$AdminGroupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdminGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? permissions = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      permissions: freezed == permissions
          ? _value.permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminGroupImplCopyWith<$Res>
    implements $AdminGroupCopyWith<$Res> {
  factory _$$AdminGroupImplCopyWith(
          _$AdminGroupImpl value, $Res Function(_$AdminGroupImpl) then) =
      __$$AdminGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String name, List<String>? permissions});
}

/// @nodoc
class __$$AdminGroupImplCopyWithImpl<$Res>
    extends _$AdminGroupCopyWithImpl<$Res, _$AdminGroupImpl>
    implements _$$AdminGroupImplCopyWith<$Res> {
  __$$AdminGroupImplCopyWithImpl(
      _$AdminGroupImpl _value, $Res Function(_$AdminGroupImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdminGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? permissions = freezed,
  }) {
    return _then(_$AdminGroupImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      permissions: freezed == permissions
          ? _value._permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminGroupImpl implements _AdminGroup {
  const _$AdminGroupImpl(
      {required this.id, required this.name, final List<String>? permissions})
      : _permissions = permissions;

  factory _$AdminGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminGroupImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  final List<String>? _permissions;
  @override
  List<String>? get permissions {
    final value = _permissions;
    if (value == null) return null;
    if (_permissions is EqualUnmodifiableListView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'AdminGroup(id: $id, name: $name, permissions: $permissions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminGroupImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality()
                .equals(other._permissions, _permissions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, const DeepCollectionEquality().hash(_permissions));

  /// Create a copy of AdminGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminGroupImplCopyWith<_$AdminGroupImpl> get copyWith =>
      __$$AdminGroupImplCopyWithImpl<_$AdminGroupImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AdminGroup value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AdminGroup value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AdminGroup value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminGroupImplToJson(
      this,
    );
  }
}

abstract class _AdminGroup implements AdminGroup {
  const factory _AdminGroup(
      {required final int id,
      required final String name,
      final List<String>? permissions}) = _$AdminGroupImpl;

  factory _AdminGroup.fromJson(Map<String, dynamic> json) =
      _$AdminGroupImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  List<String>? get permissions;

  /// Create a copy of AdminGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdminGroupImplCopyWith<_$AdminGroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreateGroupRequest _$CreateGroupRequestFromJson(Map<String, dynamic> json) {
  return _CreateGroupRequest.fromJson(json);
}

/// @nodoc
mixin _$CreateGroupRequest {
  String get name => throw _privateConstructorUsedError;
  List<String>? get permissions => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_CreateGroupRequest value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_CreateGroupRequest value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_CreateGroupRequest value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this CreateGroupRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreateGroupRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateGroupRequestCopyWith<CreateGroupRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateGroupRequestCopyWith<$Res> {
  factory $CreateGroupRequestCopyWith(
          CreateGroupRequest value, $Res Function(CreateGroupRequest) then) =
      _$CreateGroupRequestCopyWithImpl<$Res, CreateGroupRequest>;
  @useResult
  $Res call({String name, List<String>? permissions});
}

/// @nodoc
class _$CreateGroupRequestCopyWithImpl<$Res, $Val extends CreateGroupRequest>
    implements $CreateGroupRequestCopyWith<$Res> {
  _$CreateGroupRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateGroupRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? permissions = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      permissions: freezed == permissions
          ? _value.permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CreateGroupRequestImplCopyWith<$Res>
    implements $CreateGroupRequestCopyWith<$Res> {
  factory _$$CreateGroupRequestImplCopyWith(_$CreateGroupRequestImpl value,
          $Res Function(_$CreateGroupRequestImpl) then) =
      __$$CreateGroupRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, List<String>? permissions});
}

/// @nodoc
class __$$CreateGroupRequestImplCopyWithImpl<$Res>
    extends _$CreateGroupRequestCopyWithImpl<$Res, _$CreateGroupRequestImpl>
    implements _$$CreateGroupRequestImplCopyWith<$Res> {
  __$$CreateGroupRequestImplCopyWithImpl(_$CreateGroupRequestImpl _value,
      $Res Function(_$CreateGroupRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of CreateGroupRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? permissions = freezed,
  }) {
    return _then(_$CreateGroupRequestImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      permissions: freezed == permissions
          ? _value._permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateGroupRequestImpl implements _CreateGroupRequest {
  const _$CreateGroupRequestImpl(
      {required this.name, final List<String>? permissions})
      : _permissions = permissions;

  factory _$CreateGroupRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateGroupRequestImplFromJson(json);

  @override
  final String name;
  final List<String>? _permissions;
  @override
  List<String>? get permissions {
    final value = _permissions;
    if (value == null) return null;
    if (_permissions is EqualUnmodifiableListView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'CreateGroupRequest(name: $name, permissions: $permissions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateGroupRequestImpl &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality()
                .equals(other._permissions, _permissions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, const DeepCollectionEquality().hash(_permissions));

  /// Create a copy of CreateGroupRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateGroupRequestImplCopyWith<_$CreateGroupRequestImpl> get copyWith =>
      __$$CreateGroupRequestImplCopyWithImpl<_$CreateGroupRequestImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_CreateGroupRequest value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_CreateGroupRequest value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_CreateGroupRequest value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateGroupRequestImplToJson(
      this,
    );
  }
}

abstract class _CreateGroupRequest implements CreateGroupRequest {
  const factory _CreateGroupRequest(
      {required final String name,
      final List<String>? permissions}) = _$CreateGroupRequestImpl;

  factory _CreateGroupRequest.fromJson(Map<String, dynamic> json) =
      _$CreateGroupRequestImpl.fromJson;

  @override
  String get name;
  @override
  List<String>? get permissions;

  /// Create a copy of CreateGroupRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateGroupRequestImplCopyWith<_$CreateGroupRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UpdateGroupRequest _$UpdateGroupRequestFromJson(Map<String, dynamic> json) {
  return _UpdateGroupRequest.fromJson(json);
}

/// @nodoc
mixin _$UpdateGroupRequest {
  String? get name => throw _privateConstructorUsedError;
  List<String>? get permissions => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_UpdateGroupRequest value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_UpdateGroupRequest value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_UpdateGroupRequest value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this UpdateGroupRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UpdateGroupRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UpdateGroupRequestCopyWith<UpdateGroupRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UpdateGroupRequestCopyWith<$Res> {
  factory $UpdateGroupRequestCopyWith(
          UpdateGroupRequest value, $Res Function(UpdateGroupRequest) then) =
      _$UpdateGroupRequestCopyWithImpl<$Res, UpdateGroupRequest>;
  @useResult
  $Res call({String? name, List<String>? permissions});
}

/// @nodoc
class _$UpdateGroupRequestCopyWithImpl<$Res, $Val extends UpdateGroupRequest>
    implements $UpdateGroupRequestCopyWith<$Res> {
  _$UpdateGroupRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UpdateGroupRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? permissions = freezed,
  }) {
    return _then(_value.copyWith(
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      permissions: freezed == permissions
          ? _value.permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UpdateGroupRequestImplCopyWith<$Res>
    implements $UpdateGroupRequestCopyWith<$Res> {
  factory _$$UpdateGroupRequestImplCopyWith(_$UpdateGroupRequestImpl value,
          $Res Function(_$UpdateGroupRequestImpl) then) =
      __$$UpdateGroupRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? name, List<String>? permissions});
}

/// @nodoc
class __$$UpdateGroupRequestImplCopyWithImpl<$Res>
    extends _$UpdateGroupRequestCopyWithImpl<$Res, _$UpdateGroupRequestImpl>
    implements _$$UpdateGroupRequestImplCopyWith<$Res> {
  __$$UpdateGroupRequestImplCopyWithImpl(_$UpdateGroupRequestImpl _value,
      $Res Function(_$UpdateGroupRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of UpdateGroupRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? permissions = freezed,
  }) {
    return _then(_$UpdateGroupRequestImpl(
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      permissions: freezed == permissions
          ? _value._permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UpdateGroupRequestImpl implements _UpdateGroupRequest {
  const _$UpdateGroupRequestImpl({this.name, final List<String>? permissions})
      : _permissions = permissions;

  factory _$UpdateGroupRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$UpdateGroupRequestImplFromJson(json);

  @override
  final String? name;
  final List<String>? _permissions;
  @override
  List<String>? get permissions {
    final value = _permissions;
    if (value == null) return null;
    if (_permissions is EqualUnmodifiableListView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'UpdateGroupRequest(name: $name, permissions: $permissions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateGroupRequestImpl &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality()
                .equals(other._permissions, _permissions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, const DeepCollectionEquality().hash(_permissions));

  /// Create a copy of UpdateGroupRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateGroupRequestImplCopyWith<_$UpdateGroupRequestImpl> get copyWith =>
      __$$UpdateGroupRequestImplCopyWithImpl<_$UpdateGroupRequestImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_UpdateGroupRequest value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_UpdateGroupRequest value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_UpdateGroupRequest value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$UpdateGroupRequestImplToJson(
      this,
    );
  }
}

abstract class _UpdateGroupRequest implements UpdateGroupRequest {
  const factory _UpdateGroupRequest(
      {final String? name,
      final List<String>? permissions}) = _$UpdateGroupRequestImpl;

  factory _UpdateGroupRequest.fromJson(Map<String, dynamic> json) =
      _$UpdateGroupRequestImpl.fromJson;

  @override
  String? get name;
  @override
  List<String>? get permissions;

  /// Create a copy of UpdateGroupRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateGroupRequestImplCopyWith<_$UpdateGroupRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ModelListResponse<T> _$ModelListResponseFromJson<T>(
    Map<String, dynamic> json, T Function(Object?) fromJsonT) {
  return _ModelListResponse<T>.fromJson(json, fromJsonT);
}

/// @nodoc
mixin _$ModelListResponse<T> {
  List<T> get results => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;
  String? get next => throw _privateConstructorUsedError;
  String? get previous => throw _privateConstructorUsedError;
  @JsonKey(name: 'page_size')
  int? get pageSize => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_pages')
  int? get totalPages => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ModelListResponse<T> value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ModelListResponse<T> value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ModelListResponse<T> value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this ModelListResponse to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) =>
      throw _privateConstructorUsedError;

  /// Create a copy of ModelListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModelListResponseCopyWith<T, ModelListResponse<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModelListResponseCopyWith<T, $Res> {
  factory $ModelListResponseCopyWith(ModelListResponse<T> value,
          $Res Function(ModelListResponse<T>) then) =
      _$ModelListResponseCopyWithImpl<T, $Res, ModelListResponse<T>>;
  @useResult
  $Res call(
      {List<T> results,
      int count,
      String? next,
      String? previous,
      @JsonKey(name: 'page_size') int? pageSize,
      @JsonKey(name: 'total_pages') int? totalPages});
}

/// @nodoc
class _$ModelListResponseCopyWithImpl<T, $Res,
        $Val extends ModelListResponse<T>>
    implements $ModelListResponseCopyWith<T, $Res> {
  _$ModelListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModelListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? results = null,
    Object? count = null,
    Object? next = freezed,
    Object? previous = freezed,
    Object? pageSize = freezed,
    Object? totalPages = freezed,
  }) {
    return _then(_value.copyWith(
      results: null == results
          ? _value.results
          : results // ignore: cast_nullable_to_non_nullable
              as List<T>,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      next: freezed == next
          ? _value.next
          : next // ignore: cast_nullable_to_non_nullable
              as String?,
      previous: freezed == previous
          ? _value.previous
          : previous // ignore: cast_nullable_to_non_nullable
              as String?,
      pageSize: freezed == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int?,
      totalPages: freezed == totalPages
          ? _value.totalPages
          : totalPages // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModelListResponseImplCopyWith<T, $Res>
    implements $ModelListResponseCopyWith<T, $Res> {
  factory _$$ModelListResponseImplCopyWith(_$ModelListResponseImpl<T> value,
          $Res Function(_$ModelListResponseImpl<T>) then) =
      __$$ModelListResponseImplCopyWithImpl<T, $Res>;
  @override
  @useResult
  $Res call(
      {List<T> results,
      int count,
      String? next,
      String? previous,
      @JsonKey(name: 'page_size') int? pageSize,
      @JsonKey(name: 'total_pages') int? totalPages});
}

/// @nodoc
class __$$ModelListResponseImplCopyWithImpl<T, $Res>
    extends _$ModelListResponseCopyWithImpl<T, $Res, _$ModelListResponseImpl<T>>
    implements _$$ModelListResponseImplCopyWith<T, $Res> {
  __$$ModelListResponseImplCopyWithImpl(_$ModelListResponseImpl<T> _value,
      $Res Function(_$ModelListResponseImpl<T>) _then)
      : super(_value, _then);

  /// Create a copy of ModelListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? results = null,
    Object? count = null,
    Object? next = freezed,
    Object? previous = freezed,
    Object? pageSize = freezed,
    Object? totalPages = freezed,
  }) {
    return _then(_$ModelListResponseImpl<T>(
      results: null == results
          ? _value._results
          : results // ignore: cast_nullable_to_non_nullable
              as List<T>,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      next: freezed == next
          ? _value.next
          : next // ignore: cast_nullable_to_non_nullable
              as String?,
      previous: freezed == previous
          ? _value.previous
          : previous // ignore: cast_nullable_to_non_nullable
              as String?,
      pageSize: freezed == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int?,
      totalPages: freezed == totalPages
          ? _value.totalPages
          : totalPages // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)
class _$ModelListResponseImpl<T> implements _ModelListResponse<T> {
  const _$ModelListResponseImpl(
      {required final List<T> results,
      required this.count,
      this.next,
      this.previous,
      @JsonKey(name: 'page_size') this.pageSize,
      @JsonKey(name: 'total_pages') this.totalPages})
      : _results = results;

  factory _$ModelListResponseImpl.fromJson(
          Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$$ModelListResponseImplFromJson(json, fromJsonT);

  final List<T> _results;
  @override
  List<T> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  final int count;
  @override
  final String? next;
  @override
  final String? previous;
  @override
  @JsonKey(name: 'page_size')
  final int? pageSize;
  @override
  @JsonKey(name: 'total_pages')
  final int? totalPages;

  @override
  String toString() {
    return 'ModelListResponse<$T>(results: $results, count: $count, next: $next, previous: $previous, pageSize: $pageSize, totalPages: $totalPages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModelListResponseImpl<T> &&
            const DeepCollectionEquality().equals(other._results, _results) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.next, next) || other.next == next) &&
            (identical(other.previous, previous) ||
                other.previous == previous) &&
            (identical(other.pageSize, pageSize) ||
                other.pageSize == pageSize) &&
            (identical(other.totalPages, totalPages) ||
                other.totalPages == totalPages));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_results),
      count,
      next,
      previous,
      pageSize,
      totalPages);

  /// Create a copy of ModelListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModelListResponseImplCopyWith<T, _$ModelListResponseImpl<T>>
      get copyWith =>
          __$$ModelListResponseImplCopyWithImpl<T, _$ModelListResponseImpl<T>>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ModelListResponse<T> value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ModelListResponse<T> value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ModelListResponse<T> value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
    return _$$ModelListResponseImplToJson<T>(this, toJsonT);
  }
}

abstract class _ModelListResponse<T> implements ModelListResponse<T> {
  const factory _ModelListResponse(
          {required final List<T> results,
          required final int count,
          final String? next,
          final String? previous,
          @JsonKey(name: 'page_size') final int? pageSize,
          @JsonKey(name: 'total_pages') final int? totalPages}) =
      _$ModelListResponseImpl<T>;

  factory _ModelListResponse.fromJson(
          Map<String, dynamic> json, T Function(Object?) fromJsonT) =
      _$ModelListResponseImpl<T>.fromJson;

  @override
  List<T> get results;
  @override
  int get count;
  @override
  String? get next;
  @override
  String? get previous;
  @override
  @JsonKey(name: 'page_size')
  int? get pageSize;
  @override
  @JsonKey(name: 'total_pages')
  int? get totalPages;

  /// Create a copy of ModelListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModelListResponseImplCopyWith<T, _$ModelListResponseImpl<T>>
      get copyWith => throw _privateConstructorUsedError;
}

ModelDetailResponse<T> _$ModelDetailResponseFromJson<T>(
    Map<String, dynamic> json, T Function(Object?) fromJsonT) {
  return _ModelDetailResponse<T>.fromJson(json, fromJsonT);
}

/// @nodoc
mixin _$ModelDetailResponse<T> {
  T get object => throw _privateConstructorUsedError;
  Map<String, dynamic>? get meta => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ModelDetailResponse<T> value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ModelDetailResponse<T> value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ModelDetailResponse<T> value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this ModelDetailResponse to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) =>
      throw _privateConstructorUsedError;

  /// Create a copy of ModelDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModelDetailResponseCopyWith<T, ModelDetailResponse<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModelDetailResponseCopyWith<T, $Res> {
  factory $ModelDetailResponseCopyWith(ModelDetailResponse<T> value,
          $Res Function(ModelDetailResponse<T>) then) =
      _$ModelDetailResponseCopyWithImpl<T, $Res, ModelDetailResponse<T>>;
  @useResult
  $Res call({T object, Map<String, dynamic>? meta});
}

/// @nodoc
class _$ModelDetailResponseCopyWithImpl<T, $Res,
        $Val extends ModelDetailResponse<T>>
    implements $ModelDetailResponseCopyWith<T, $Res> {
  _$ModelDetailResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModelDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? object = freezed,
    Object? meta = freezed,
  }) {
    return _then(_value.copyWith(
      object: freezed == object
          ? _value.object
          : object // ignore: cast_nullable_to_non_nullable
              as T,
      meta: freezed == meta
          ? _value.meta
          : meta // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModelDetailResponseImplCopyWith<T, $Res>
    implements $ModelDetailResponseCopyWith<T, $Res> {
  factory _$$ModelDetailResponseImplCopyWith(_$ModelDetailResponseImpl<T> value,
          $Res Function(_$ModelDetailResponseImpl<T>) then) =
      __$$ModelDetailResponseImplCopyWithImpl<T, $Res>;
  @override
  @useResult
  $Res call({T object, Map<String, dynamic>? meta});
}

/// @nodoc
class __$$ModelDetailResponseImplCopyWithImpl<T, $Res>
    extends _$ModelDetailResponseCopyWithImpl<T, $Res,
        _$ModelDetailResponseImpl<T>>
    implements _$$ModelDetailResponseImplCopyWith<T, $Res> {
  __$$ModelDetailResponseImplCopyWithImpl(_$ModelDetailResponseImpl<T> _value,
      $Res Function(_$ModelDetailResponseImpl<T>) _then)
      : super(_value, _then);

  /// Create a copy of ModelDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? object = freezed,
    Object? meta = freezed,
  }) {
    return _then(_$ModelDetailResponseImpl<T>(
      object: freezed == object
          ? _value.object
          : object // ignore: cast_nullable_to_non_nullable
              as T,
      meta: freezed == meta
          ? _value._meta
          : meta // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)
class _$ModelDetailResponseImpl<T> implements _ModelDetailResponse<T> {
  const _$ModelDetailResponseImpl(
      {required this.object, final Map<String, dynamic>? meta})
      : _meta = meta;

  factory _$ModelDetailResponseImpl.fromJson(
          Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$$ModelDetailResponseImplFromJson(json, fromJsonT);

  @override
  final T object;
  final Map<String, dynamic>? _meta;
  @override
  Map<String, dynamic>? get meta {
    final value = _meta;
    if (value == null) return null;
    if (_meta is EqualUnmodifiableMapView) return _meta;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'ModelDetailResponse<$T>(object: $object, meta: $meta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModelDetailResponseImpl<T> &&
            const DeepCollectionEquality().equals(other.object, object) &&
            const DeepCollectionEquality().equals(other._meta, _meta));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(object),
      const DeepCollectionEquality().hash(_meta));

  /// Create a copy of ModelDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModelDetailResponseImplCopyWith<T, _$ModelDetailResponseImpl<T>>
      get copyWith => __$$ModelDetailResponseImplCopyWithImpl<T,
          _$ModelDetailResponseImpl<T>>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ModelDetailResponse<T> value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ModelDetailResponse<T> value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ModelDetailResponse<T> value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
    return _$$ModelDetailResponseImplToJson<T>(this, toJsonT);
  }
}

abstract class _ModelDetailResponse<T> implements ModelDetailResponse<T> {
  const factory _ModelDetailResponse(
      {required final T object,
      final Map<String, dynamic>? meta}) = _$ModelDetailResponseImpl<T>;

  factory _ModelDetailResponse.fromJson(
          Map<String, dynamic> json, T Function(Object?) fromJsonT) =
      _$ModelDetailResponseImpl<T>.fromJson;

  @override
  T get object;
  @override
  Map<String, dynamic>? get meta;

  /// Create a copy of ModelDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModelDetailResponseImplCopyWith<T, _$ModelDetailResponseImpl<T>>
      get copyWith => throw _privateConstructorUsedError;
}

DeleteResponse _$DeleteResponseFromJson(Map<String, dynamic> json) {
  return _DeleteResponse.fromJson(json);
}

/// @nodoc
mixin _$DeleteResponse {
  bool get success => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_DeleteResponse value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_DeleteResponse value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_DeleteResponse value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this DeleteResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeleteResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeleteResponseCopyWith<DeleteResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeleteResponseCopyWith<$Res> {
  factory $DeleteResponseCopyWith(
          DeleteResponse value, $Res Function(DeleteResponse) then) =
      _$DeleteResponseCopyWithImpl<$Res, DeleteResponse>;
  @useResult
  $Res call({bool success, String? message});
}

/// @nodoc
class _$DeleteResponseCopyWithImpl<$Res, $Val extends DeleteResponse>
    implements $DeleteResponseCopyWith<$Res> {
  _$DeleteResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeleteResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? message = freezed,
  }) {
    return _then(_value.copyWith(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DeleteResponseImplCopyWith<$Res>
    implements $DeleteResponseCopyWith<$Res> {
  factory _$$DeleteResponseImplCopyWith(_$DeleteResponseImpl value,
          $Res Function(_$DeleteResponseImpl) then) =
      __$$DeleteResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool success, String? message});
}

/// @nodoc
class __$$DeleteResponseImplCopyWithImpl<$Res>
    extends _$DeleteResponseCopyWithImpl<$Res, _$DeleteResponseImpl>
    implements _$$DeleteResponseImplCopyWith<$Res> {
  __$$DeleteResponseImplCopyWithImpl(
      _$DeleteResponseImpl _value, $Res Function(_$DeleteResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of DeleteResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? message = freezed,
  }) {
    return _then(_$DeleteResponseImpl(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DeleteResponseImpl implements _DeleteResponse {
  const _$DeleteResponseImpl({required this.success, this.message});

  factory _$DeleteResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeleteResponseImplFromJson(json);

  @override
  final bool success;
  @override
  final String? message;

  @override
  String toString() {
    return 'DeleteResponse(success: $success, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeleteResponseImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, success, message);

  /// Create a copy of DeleteResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeleteResponseImplCopyWith<_$DeleteResponseImpl> get copyWith =>
      __$$DeleteResponseImplCopyWithImpl<_$DeleteResponseImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_DeleteResponse value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_DeleteResponse value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_DeleteResponse value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$DeleteResponseImplToJson(
      this,
    );
  }
}

abstract class _DeleteResponse implements DeleteResponse {
  const factory _DeleteResponse(
      {required final bool success,
      final String? message}) = _$DeleteResponseImpl;

  factory _DeleteResponse.fromJson(Map<String, dynamic> json) =
      _$DeleteResponseImpl.fromJson;

  @override
  bool get success;
  @override
  String? get message;

  /// Create a copy of DeleteResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeleteResponseImplCopyWith<_$DeleteResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BulkDeleteRequest _$BulkDeleteRequestFromJson(Map<String, dynamic> json) {
  return _BulkDeleteRequest.fromJson(json);
}

/// @nodoc
mixin _$BulkDeleteRequest {
  List<String> get ids => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_BulkDeleteRequest value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_BulkDeleteRequest value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_BulkDeleteRequest value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this BulkDeleteRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BulkDeleteRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BulkDeleteRequestCopyWith<BulkDeleteRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BulkDeleteRequestCopyWith<$Res> {
  factory $BulkDeleteRequestCopyWith(
          BulkDeleteRequest value, $Res Function(BulkDeleteRequest) then) =
      _$BulkDeleteRequestCopyWithImpl<$Res, BulkDeleteRequest>;
  @useResult
  $Res call({List<String> ids});
}

/// @nodoc
class _$BulkDeleteRequestCopyWithImpl<$Res, $Val extends BulkDeleteRequest>
    implements $BulkDeleteRequestCopyWith<$Res> {
  _$BulkDeleteRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BulkDeleteRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ids = null,
  }) {
    return _then(_value.copyWith(
      ids: null == ids
          ? _value.ids
          : ids // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BulkDeleteRequestImplCopyWith<$Res>
    implements $BulkDeleteRequestCopyWith<$Res> {
  factory _$$BulkDeleteRequestImplCopyWith(_$BulkDeleteRequestImpl value,
          $Res Function(_$BulkDeleteRequestImpl) then) =
      __$$BulkDeleteRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<String> ids});
}

/// @nodoc
class __$$BulkDeleteRequestImplCopyWithImpl<$Res>
    extends _$BulkDeleteRequestCopyWithImpl<$Res, _$BulkDeleteRequestImpl>
    implements _$$BulkDeleteRequestImplCopyWith<$Res> {
  __$$BulkDeleteRequestImplCopyWithImpl(_$BulkDeleteRequestImpl _value,
      $Res Function(_$BulkDeleteRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of BulkDeleteRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ids = null,
  }) {
    return _then(_$BulkDeleteRequestImpl(
      ids: null == ids
          ? _value._ids
          : ids // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BulkDeleteRequestImpl implements _BulkDeleteRequest {
  const _$BulkDeleteRequestImpl({required final List<String> ids}) : _ids = ids;

  factory _$BulkDeleteRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$BulkDeleteRequestImplFromJson(json);

  final List<String> _ids;
  @override
  List<String> get ids {
    if (_ids is EqualUnmodifiableListView) return _ids;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ids);
  }

  @override
  String toString() {
    return 'BulkDeleteRequest(ids: $ids)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BulkDeleteRequestImpl &&
            const DeepCollectionEquality().equals(other._ids, _ids));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_ids));

  /// Create a copy of BulkDeleteRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BulkDeleteRequestImplCopyWith<_$BulkDeleteRequestImpl> get copyWith =>
      __$$BulkDeleteRequestImplCopyWithImpl<_$BulkDeleteRequestImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_BulkDeleteRequest value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_BulkDeleteRequest value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_BulkDeleteRequest value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$BulkDeleteRequestImplToJson(
      this,
    );
  }
}

abstract class _BulkDeleteRequest implements BulkDeleteRequest {
  const factory _BulkDeleteRequest({required final List<String> ids}) =
      _$BulkDeleteRequestImpl;

  factory _BulkDeleteRequest.fromJson(Map<String, dynamic> json) =
      _$BulkDeleteRequestImpl.fromJson;

  @override
  List<String> get ids;

  /// Create a copy of BulkDeleteRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BulkDeleteRequestImplCopyWith<_$BulkDeleteRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BulkDeleteResponse _$BulkDeleteResponseFromJson(Map<String, dynamic> json) {
  return _BulkDeleteResponse.fromJson(json);
}

/// @nodoc
mixin _$BulkDeleteResponse {
  int get deleted => throw _privateConstructorUsedError;
  bool get success => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_BulkDeleteResponse value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_BulkDeleteResponse value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_BulkDeleteResponse value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this BulkDeleteResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BulkDeleteResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BulkDeleteResponseCopyWith<BulkDeleteResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BulkDeleteResponseCopyWith<$Res> {
  factory $BulkDeleteResponseCopyWith(
          BulkDeleteResponse value, $Res Function(BulkDeleteResponse) then) =
      _$BulkDeleteResponseCopyWithImpl<$Res, BulkDeleteResponse>;
  @useResult
  $Res call({int deleted, bool success, String? message});
}

/// @nodoc
class _$BulkDeleteResponseCopyWithImpl<$Res, $Val extends BulkDeleteResponse>
    implements $BulkDeleteResponseCopyWith<$Res> {
  _$BulkDeleteResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BulkDeleteResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deleted = null,
    Object? success = null,
    Object? message = freezed,
  }) {
    return _then(_value.copyWith(
      deleted: null == deleted
          ? _value.deleted
          : deleted // ignore: cast_nullable_to_non_nullable
              as int,
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BulkDeleteResponseImplCopyWith<$Res>
    implements $BulkDeleteResponseCopyWith<$Res> {
  factory _$$BulkDeleteResponseImplCopyWith(_$BulkDeleteResponseImpl value,
          $Res Function(_$BulkDeleteResponseImpl) then) =
      __$$BulkDeleteResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int deleted, bool success, String? message});
}

/// @nodoc
class __$$BulkDeleteResponseImplCopyWithImpl<$Res>
    extends _$BulkDeleteResponseCopyWithImpl<$Res, _$BulkDeleteResponseImpl>
    implements _$$BulkDeleteResponseImplCopyWith<$Res> {
  __$$BulkDeleteResponseImplCopyWithImpl(_$BulkDeleteResponseImpl _value,
      $Res Function(_$BulkDeleteResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of BulkDeleteResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deleted = null,
    Object? success = null,
    Object? message = freezed,
  }) {
    return _then(_$BulkDeleteResponseImpl(
      deleted: null == deleted
          ? _value.deleted
          : deleted // ignore: cast_nullable_to_non_nullable
              as int,
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BulkDeleteResponseImpl implements _BulkDeleteResponse {
  const _$BulkDeleteResponseImpl(
      {required this.deleted, required this.success, this.message});

  factory _$BulkDeleteResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$BulkDeleteResponseImplFromJson(json);

  @override
  final int deleted;
  @override
  final bool success;
  @override
  final String? message;

  @override
  String toString() {
    return 'BulkDeleteResponse(deleted: $deleted, success: $success, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BulkDeleteResponseImpl &&
            (identical(other.deleted, deleted) || other.deleted == deleted) &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, deleted, success, message);

  /// Create a copy of BulkDeleteResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BulkDeleteResponseImplCopyWith<_$BulkDeleteResponseImpl> get copyWith =>
      __$$BulkDeleteResponseImplCopyWithImpl<_$BulkDeleteResponseImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_BulkDeleteResponse value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_BulkDeleteResponse value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_BulkDeleteResponse value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$BulkDeleteResponseImplToJson(
      this,
    );
  }
}

abstract class _BulkDeleteResponse implements BulkDeleteResponse {
  const factory _BulkDeleteResponse(
      {required final int deleted,
      required final bool success,
      final String? message}) = _$BulkDeleteResponseImpl;

  factory _BulkDeleteResponse.fromJson(Map<String, dynamic> json) =
      _$BulkDeleteResponseImpl.fromJson;

  @override
  int get deleted;
  @override
  bool get success;
  @override
  String? get message;

  /// Create a copy of BulkDeleteResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BulkDeleteResponseImplCopyWith<_$BulkDeleteResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BulkUpdateRequest _$BulkUpdateRequestFromJson(Map<String, dynamic> json) {
  return _BulkUpdateRequest.fromJson(json);
}

/// @nodoc
mixin _$BulkUpdateRequest {
  List<String> get ids => throw _privateConstructorUsedError;
  Map<String, dynamic> get data => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_BulkUpdateRequest value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_BulkUpdateRequest value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_BulkUpdateRequest value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this BulkUpdateRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BulkUpdateRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BulkUpdateRequestCopyWith<BulkUpdateRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BulkUpdateRequestCopyWith<$Res> {
  factory $BulkUpdateRequestCopyWith(
          BulkUpdateRequest value, $Res Function(BulkUpdateRequest) then) =
      _$BulkUpdateRequestCopyWithImpl<$Res, BulkUpdateRequest>;
  @useResult
  $Res call({List<String> ids, Map<String, dynamic> data});
}

/// @nodoc
class _$BulkUpdateRequestCopyWithImpl<$Res, $Val extends BulkUpdateRequest>
    implements $BulkUpdateRequestCopyWith<$Res> {
  _$BulkUpdateRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BulkUpdateRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ids = null,
    Object? data = null,
  }) {
    return _then(_value.copyWith(
      ids: null == ids
          ? _value.ids
          : ids // ignore: cast_nullable_to_non_nullable
              as List<String>,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BulkUpdateRequestImplCopyWith<$Res>
    implements $BulkUpdateRequestCopyWith<$Res> {
  factory _$$BulkUpdateRequestImplCopyWith(_$BulkUpdateRequestImpl value,
          $Res Function(_$BulkUpdateRequestImpl) then) =
      __$$BulkUpdateRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<String> ids, Map<String, dynamic> data});
}

/// @nodoc
class __$$BulkUpdateRequestImplCopyWithImpl<$Res>
    extends _$BulkUpdateRequestCopyWithImpl<$Res, _$BulkUpdateRequestImpl>
    implements _$$BulkUpdateRequestImplCopyWith<$Res> {
  __$$BulkUpdateRequestImplCopyWithImpl(_$BulkUpdateRequestImpl _value,
      $Res Function(_$BulkUpdateRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of BulkUpdateRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ids = null,
    Object? data = null,
  }) {
    return _then(_$BulkUpdateRequestImpl(
      ids: null == ids
          ? _value._ids
          : ids // ignore: cast_nullable_to_non_nullable
              as List<String>,
      data: null == data
          ? _value._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BulkUpdateRequestImpl implements _BulkUpdateRequest {
  const _$BulkUpdateRequestImpl(
      {required final List<String> ids,
      required final Map<String, dynamic> data})
      : _ids = ids,
        _data = data;

  factory _$BulkUpdateRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$BulkUpdateRequestImplFromJson(json);

  final List<String> _ids;
  @override
  List<String> get ids {
    if (_ids is EqualUnmodifiableListView) return _ids;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ids);
  }

  final Map<String, dynamic> _data;
  @override
  Map<String, dynamic> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  @override
  String toString() {
    return 'BulkUpdateRequest(ids: $ids, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BulkUpdateRequestImpl &&
            const DeepCollectionEquality().equals(other._ids, _ids) &&
            const DeepCollectionEquality().equals(other._data, _data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_ids),
      const DeepCollectionEquality().hash(_data));

  /// Create a copy of BulkUpdateRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BulkUpdateRequestImplCopyWith<_$BulkUpdateRequestImpl> get copyWith =>
      __$$BulkUpdateRequestImplCopyWithImpl<_$BulkUpdateRequestImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_BulkUpdateRequest value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_BulkUpdateRequest value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_BulkUpdateRequest value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$BulkUpdateRequestImplToJson(
      this,
    );
  }
}

abstract class _BulkUpdateRequest implements BulkUpdateRequest {
  const factory _BulkUpdateRequest(
      {required final List<String> ids,
      required final Map<String, dynamic> data}) = _$BulkUpdateRequestImpl;

  factory _BulkUpdateRequest.fromJson(Map<String, dynamic> json) =
      _$BulkUpdateRequestImpl.fromJson;

  @override
  List<String> get ids;
  @override
  Map<String, dynamic> get data;

  /// Create a copy of BulkUpdateRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BulkUpdateRequestImplCopyWith<_$BulkUpdateRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BulkUpdateResponse _$BulkUpdateResponseFromJson(Map<String, dynamic> json) {
  return _BulkUpdateResponse.fromJson(json);
}

/// @nodoc
mixin _$BulkUpdateResponse {
  int get updated => throw _privateConstructorUsedError;
  bool get success => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_BulkUpdateResponse value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_BulkUpdateResponse value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_BulkUpdateResponse value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this BulkUpdateResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BulkUpdateResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BulkUpdateResponseCopyWith<BulkUpdateResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BulkUpdateResponseCopyWith<$Res> {
  factory $BulkUpdateResponseCopyWith(
          BulkUpdateResponse value, $Res Function(BulkUpdateResponse) then) =
      _$BulkUpdateResponseCopyWithImpl<$Res, BulkUpdateResponse>;
  @useResult
  $Res call({int updated, bool success, String? message});
}

/// @nodoc
class _$BulkUpdateResponseCopyWithImpl<$Res, $Val extends BulkUpdateResponse>
    implements $BulkUpdateResponseCopyWith<$Res> {
  _$BulkUpdateResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BulkUpdateResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? updated = null,
    Object? success = null,
    Object? message = freezed,
  }) {
    return _then(_value.copyWith(
      updated: null == updated
          ? _value.updated
          : updated // ignore: cast_nullable_to_non_nullable
              as int,
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BulkUpdateResponseImplCopyWith<$Res>
    implements $BulkUpdateResponseCopyWith<$Res> {
  factory _$$BulkUpdateResponseImplCopyWith(_$BulkUpdateResponseImpl value,
          $Res Function(_$BulkUpdateResponseImpl) then) =
      __$$BulkUpdateResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int updated, bool success, String? message});
}

/// @nodoc
class __$$BulkUpdateResponseImplCopyWithImpl<$Res>
    extends _$BulkUpdateResponseCopyWithImpl<$Res, _$BulkUpdateResponseImpl>
    implements _$$BulkUpdateResponseImplCopyWith<$Res> {
  __$$BulkUpdateResponseImplCopyWithImpl(_$BulkUpdateResponseImpl _value,
      $Res Function(_$BulkUpdateResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of BulkUpdateResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? updated = null,
    Object? success = null,
    Object? message = freezed,
  }) {
    return _then(_$BulkUpdateResponseImpl(
      updated: null == updated
          ? _value.updated
          : updated // ignore: cast_nullable_to_non_nullable
              as int,
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BulkUpdateResponseImpl implements _BulkUpdateResponse {
  const _$BulkUpdateResponseImpl(
      {required this.updated, required this.success, this.message});

  factory _$BulkUpdateResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$BulkUpdateResponseImplFromJson(json);

  @override
  final int updated;
  @override
  final bool success;
  @override
  final String? message;

  @override
  String toString() {
    return 'BulkUpdateResponse(updated: $updated, success: $success, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BulkUpdateResponseImpl &&
            (identical(other.updated, updated) || other.updated == updated) &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, updated, success, message);

  /// Create a copy of BulkUpdateResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BulkUpdateResponseImplCopyWith<_$BulkUpdateResponseImpl> get copyWith =>
      __$$BulkUpdateResponseImplCopyWithImpl<_$BulkUpdateResponseImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_BulkUpdateResponse value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_BulkUpdateResponse value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_BulkUpdateResponse value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$BulkUpdateResponseImplToJson(
      this,
    );
  }
}

abstract class _BulkUpdateResponse implements BulkUpdateResponse {
  const factory _BulkUpdateResponse(
      {required final int updated,
      required final bool success,
      final String? message}) = _$BulkUpdateResponseImpl;

  factory _BulkUpdateResponse.fromJson(Map<String, dynamic> json) =
      _$BulkUpdateResponseImpl.fromJson;

  @override
  int get updated;
  @override
  bool get success;
  @override
  String? get message;

  /// Create a copy of BulkUpdateResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BulkUpdateResponseImplCopyWith<_$BulkUpdateResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AdminIndexResponse _$AdminIndexResponseFromJson(Map<String, dynamic> json) {
  return _AdminIndexResponse.fromJson(json);
}

/// @nodoc
mixin _$AdminIndexResponse {
  @JsonKey(name: 'site_title')
  String get siteTitle => throw _privateConstructorUsedError;
  @JsonKey(name: 'site_header')
  String get siteHeader => throw _privateConstructorUsedError;
  @JsonKey(name: 'index_title')
  String get indexTitle => throw _privateConstructorUsedError;
  Map<String, List<String>> get models => throw _privateConstructorUsedError;
  @JsonKey(name: 'admin_url')
  String get adminUrl => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AdminIndexResponse value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AdminIndexResponse value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AdminIndexResponse value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this AdminIndexResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdminIndexResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdminIndexResponseCopyWith<AdminIndexResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminIndexResponseCopyWith<$Res> {
  factory $AdminIndexResponseCopyWith(
          AdminIndexResponse value, $Res Function(AdminIndexResponse) then) =
      _$AdminIndexResponseCopyWithImpl<$Res, AdminIndexResponse>;
  @useResult
  $Res call(
      {@JsonKey(name: 'site_title') String siteTitle,
      @JsonKey(name: 'site_header') String siteHeader,
      @JsonKey(name: 'index_title') String indexTitle,
      Map<String, List<String>> models,
      @JsonKey(name: 'admin_url') String adminUrl});
}

/// @nodoc
class _$AdminIndexResponseCopyWithImpl<$Res, $Val extends AdminIndexResponse>
    implements $AdminIndexResponseCopyWith<$Res> {
  _$AdminIndexResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdminIndexResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? siteTitle = null,
    Object? siteHeader = null,
    Object? indexTitle = null,
    Object? models = null,
    Object? adminUrl = null,
  }) {
    return _then(_value.copyWith(
      siteTitle: null == siteTitle
          ? _value.siteTitle
          : siteTitle // ignore: cast_nullable_to_non_nullable
              as String,
      siteHeader: null == siteHeader
          ? _value.siteHeader
          : siteHeader // ignore: cast_nullable_to_non_nullable
              as String,
      indexTitle: null == indexTitle
          ? _value.indexTitle
          : indexTitle // ignore: cast_nullable_to_non_nullable
              as String,
      models: null == models
          ? _value.models
          : models // ignore: cast_nullable_to_non_nullable
              as Map<String, List<String>>,
      adminUrl: null == adminUrl
          ? _value.adminUrl
          : adminUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminIndexResponseImplCopyWith<$Res>
    implements $AdminIndexResponseCopyWith<$Res> {
  factory _$$AdminIndexResponseImplCopyWith(_$AdminIndexResponseImpl value,
          $Res Function(_$AdminIndexResponseImpl) then) =
      __$$AdminIndexResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'site_title') String siteTitle,
      @JsonKey(name: 'site_header') String siteHeader,
      @JsonKey(name: 'index_title') String indexTitle,
      Map<String, List<String>> models,
      @JsonKey(name: 'admin_url') String adminUrl});
}

/// @nodoc
class __$$AdminIndexResponseImplCopyWithImpl<$Res>
    extends _$AdminIndexResponseCopyWithImpl<$Res, _$AdminIndexResponseImpl>
    implements _$$AdminIndexResponseImplCopyWith<$Res> {
  __$$AdminIndexResponseImplCopyWithImpl(_$AdminIndexResponseImpl _value,
      $Res Function(_$AdminIndexResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdminIndexResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? siteTitle = null,
    Object? siteHeader = null,
    Object? indexTitle = null,
    Object? models = null,
    Object? adminUrl = null,
  }) {
    return _then(_$AdminIndexResponseImpl(
      siteTitle: null == siteTitle
          ? _value.siteTitle
          : siteTitle // ignore: cast_nullable_to_non_nullable
              as String,
      siteHeader: null == siteHeader
          ? _value.siteHeader
          : siteHeader // ignore: cast_nullable_to_non_nullable
              as String,
      indexTitle: null == indexTitle
          ? _value.indexTitle
          : indexTitle // ignore: cast_nullable_to_non_nullable
              as String,
      models: null == models
          ? _value._models
          : models // ignore: cast_nullable_to_non_nullable
              as Map<String, List<String>>,
      adminUrl: null == adminUrl
          ? _value.adminUrl
          : adminUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminIndexResponseImpl implements _AdminIndexResponse {
  const _$AdminIndexResponseImpl(
      {@JsonKey(name: 'site_title') required this.siteTitle,
      @JsonKey(name: 'site_header') required this.siteHeader,
      @JsonKey(name: 'index_title') required this.indexTitle,
      required final Map<String, List<String>> models,
      @JsonKey(name: 'admin_url') required this.adminUrl})
      : _models = models;

  factory _$AdminIndexResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminIndexResponseImplFromJson(json);

  @override
  @JsonKey(name: 'site_title')
  final String siteTitle;
  @override
  @JsonKey(name: 'site_header')
  final String siteHeader;
  @override
  @JsonKey(name: 'index_title')
  final String indexTitle;
  final Map<String, List<String>> _models;
  @override
  Map<String, List<String>> get models {
    if (_models is EqualUnmodifiableMapView) return _models;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_models);
  }

  @override
  @JsonKey(name: 'admin_url')
  final String adminUrl;

  @override
  String toString() {
    return 'AdminIndexResponse(siteTitle: $siteTitle, siteHeader: $siteHeader, indexTitle: $indexTitle, models: $models, adminUrl: $adminUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminIndexResponseImpl &&
            (identical(other.siteTitle, siteTitle) ||
                other.siteTitle == siteTitle) &&
            (identical(other.siteHeader, siteHeader) ||
                other.siteHeader == siteHeader) &&
            (identical(other.indexTitle, indexTitle) ||
                other.indexTitle == indexTitle) &&
            const DeepCollectionEquality().equals(other._models, _models) &&
            (identical(other.adminUrl, adminUrl) ||
                other.adminUrl == adminUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, siteTitle, siteHeader,
      indexTitle, const DeepCollectionEquality().hash(_models), adminUrl);

  /// Create a copy of AdminIndexResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminIndexResponseImplCopyWith<_$AdminIndexResponseImpl> get copyWith =>
      __$$AdminIndexResponseImplCopyWithImpl<_$AdminIndexResponseImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AdminIndexResponse value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AdminIndexResponse value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AdminIndexResponse value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminIndexResponseImplToJson(
      this,
    );
  }
}

abstract class _AdminIndexResponse implements AdminIndexResponse {
  const factory _AdminIndexResponse(
          {@JsonKey(name: 'site_title') required final String siteTitle,
          @JsonKey(name: 'site_header') required final String siteHeader,
          @JsonKey(name: 'index_title') required final String indexTitle,
          required final Map<String, List<String>> models,
          @JsonKey(name: 'admin_url') required final String adminUrl}) =
      _$AdminIndexResponseImpl;

  factory _AdminIndexResponse.fromJson(Map<String, dynamic> json) =
      _$AdminIndexResponseImpl.fromJson;

  @override
  @JsonKey(name: 'site_title')
  String get siteTitle;
  @override
  @JsonKey(name: 'site_header')
  String get siteHeader;
  @override
  @JsonKey(name: 'index_title')
  String get indexTitle;
  @override
  Map<String, List<String>> get models;
  @override
  @JsonKey(name: 'admin_url')
  String get adminUrl;

  /// Create a copy of AdminIndexResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdminIndexResponseImplCopyWith<_$AdminIndexResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AppsListResponse _$AppsListResponseFromJson(Map<String, dynamic> json) {
  return _AppsListResponse.fromJson(json);
}

/// @nodoc
mixin _$AppsListResponse {
  List<AdminApp> get apps => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AppsListResponse value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AppsListResponse value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AppsListResponse value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this AppsListResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppsListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppsListResponseCopyWith<AppsListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppsListResponseCopyWith<$Res> {
  factory $AppsListResponseCopyWith(
          AppsListResponse value, $Res Function(AppsListResponse) then) =
      _$AppsListResponseCopyWithImpl<$Res, AppsListResponse>;
  @useResult
  $Res call({List<AdminApp> apps});
}

/// @nodoc
class _$AppsListResponseCopyWithImpl<$Res, $Val extends AppsListResponse>
    implements $AppsListResponseCopyWith<$Res> {
  _$AppsListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppsListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? apps = null,
  }) {
    return _then(_value.copyWith(
      apps: null == apps
          ? _value.apps
          : apps // ignore: cast_nullable_to_non_nullable
              as List<AdminApp>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppsListResponseImplCopyWith<$Res>
    implements $AppsListResponseCopyWith<$Res> {
  factory _$$AppsListResponseImplCopyWith(_$AppsListResponseImpl value,
          $Res Function(_$AppsListResponseImpl) then) =
      __$$AppsListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<AdminApp> apps});
}

/// @nodoc
class __$$AppsListResponseImplCopyWithImpl<$Res>
    extends _$AppsListResponseCopyWithImpl<$Res, _$AppsListResponseImpl>
    implements _$$AppsListResponseImplCopyWith<$Res> {
  __$$AppsListResponseImplCopyWithImpl(_$AppsListResponseImpl _value,
      $Res Function(_$AppsListResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppsListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? apps = null,
  }) {
    return _then(_$AppsListResponseImpl(
      apps: null == apps
          ? _value._apps
          : apps // ignore: cast_nullable_to_non_nullable
              as List<AdminApp>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AppsListResponseImpl implements _AppsListResponse {
  const _$AppsListResponseImpl({required final List<AdminApp> apps})
      : _apps = apps;

  factory _$AppsListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppsListResponseImplFromJson(json);

  final List<AdminApp> _apps;
  @override
  List<AdminApp> get apps {
    if (_apps is EqualUnmodifiableListView) return _apps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_apps);
  }

  @override
  String toString() {
    return 'AppsListResponse(apps: $apps)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppsListResponseImpl &&
            const DeepCollectionEquality().equals(other._apps, _apps));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_apps));

  /// Create a copy of AppsListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppsListResponseImplCopyWith<_$AppsListResponseImpl> get copyWith =>
      __$$AppsListResponseImplCopyWithImpl<_$AppsListResponseImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AppsListResponse value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AppsListResponse value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AppsListResponse value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$AppsListResponseImplToJson(
      this,
    );
  }
}

abstract class _AppsListResponse implements AppsListResponse {
  const factory _AppsListResponse({required final List<AdminApp> apps}) =
      _$AppsListResponseImpl;

  factory _AppsListResponse.fromJson(Map<String, dynamic> json) =
      _$AppsListResponseImpl.fromJson;

  @override
  List<AdminApp> get apps;

  /// Create a copy of AppsListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppsListResponseImplCopyWith<_$AppsListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AdminApp _$AdminAppFromJson(Map<String, dynamic> json) {
  return _AdminApp.fromJson(json);
}

/// @nodoc
mixin _$AdminApp {
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'app_label')
  String get appLabel => throw _privateConstructorUsedError;
  List<AdminModel> get models => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AdminApp value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AdminApp value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AdminApp value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this AdminApp to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdminApp
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdminAppCopyWith<AdminApp> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminAppCopyWith<$Res> {
  factory $AdminAppCopyWith(AdminApp value, $Res Function(AdminApp) then) =
      _$AdminAppCopyWithImpl<$Res, AdminApp>;
  @useResult
  $Res call(
      {String name,
      @JsonKey(name: 'app_label') String appLabel,
      List<AdminModel> models});
}

/// @nodoc
class _$AdminAppCopyWithImpl<$Res, $Val extends AdminApp>
    implements $AdminAppCopyWith<$Res> {
  _$AdminAppCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdminApp
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? appLabel = null,
    Object? models = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      appLabel: null == appLabel
          ? _value.appLabel
          : appLabel // ignore: cast_nullable_to_non_nullable
              as String,
      models: null == models
          ? _value.models
          : models // ignore: cast_nullable_to_non_nullable
              as List<AdminModel>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminAppImplCopyWith<$Res>
    implements $AdminAppCopyWith<$Res> {
  factory _$$AdminAppImplCopyWith(
          _$AdminAppImpl value, $Res Function(_$AdminAppImpl) then) =
      __$$AdminAppImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      @JsonKey(name: 'app_label') String appLabel,
      List<AdminModel> models});
}

/// @nodoc
class __$$AdminAppImplCopyWithImpl<$Res>
    extends _$AdminAppCopyWithImpl<$Res, _$AdminAppImpl>
    implements _$$AdminAppImplCopyWith<$Res> {
  __$$AdminAppImplCopyWithImpl(
      _$AdminAppImpl _value, $Res Function(_$AdminAppImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdminApp
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? appLabel = null,
    Object? models = null,
  }) {
    return _then(_$AdminAppImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      appLabel: null == appLabel
          ? _value.appLabel
          : appLabel // ignore: cast_nullable_to_non_nullable
              as String,
      models: null == models
          ? _value._models
          : models // ignore: cast_nullable_to_non_nullable
              as List<AdminModel>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminAppImpl implements _AdminApp {
  const _$AdminAppImpl(
      {required this.name,
      @JsonKey(name: 'app_label') required this.appLabel,
      required final List<AdminModel> models})
      : _models = models;

  factory _$AdminAppImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminAppImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey(name: 'app_label')
  final String appLabel;
  final List<AdminModel> _models;
  @override
  List<AdminModel> get models {
    if (_models is EqualUnmodifiableListView) return _models;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_models);
  }

  @override
  String toString() {
    return 'AdminApp(name: $name, appLabel: $appLabel, models: $models)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminAppImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.appLabel, appLabel) ||
                other.appLabel == appLabel) &&
            const DeepCollectionEquality().equals(other._models, _models));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, appLabel,
      const DeepCollectionEquality().hash(_models));

  /// Create a copy of AdminApp
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminAppImplCopyWith<_$AdminAppImpl> get copyWith =>
      __$$AdminAppImplCopyWithImpl<_$AdminAppImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AdminApp value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AdminApp value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AdminApp value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminAppImplToJson(
      this,
    );
  }
}

abstract class _AdminApp implements AdminApp {
  const factory _AdminApp(
      {required final String name,
      @JsonKey(name: 'app_label') required final String appLabel,
      required final List<AdminModel> models}) = _$AdminAppImpl;

  factory _AdminApp.fromJson(Map<String, dynamic> json) =
      _$AdminAppImpl.fromJson;

  @override
  String get name;
  @override
  @JsonKey(name: 'app_label')
  String get appLabel;
  @override
  List<AdminModel> get models;

  /// Create a copy of AdminApp
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdminAppImplCopyWith<_$AdminAppImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AdminModel _$AdminModelFromJson(Map<String, dynamic> json) {
  return _AdminModel.fromJson(json);
}

/// @nodoc
mixin _$AdminModel {
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'object_name')
  String get objectName => throw _privateConstructorUsedError;
  AdminModelPermissions get perms => throw _privateConstructorUsedError;
  @JsonKey(name: 'admin_url')
  String get adminUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'add_url')
  String get addUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'verbose_name')
  String? get verboseName => throw _privateConstructorUsedError;
  @JsonKey(name: 'verbose_name_plural')
  String? get verboseNamePlural => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AdminModel value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AdminModel value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AdminModel value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this AdminModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdminModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdminModelCopyWith<AdminModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminModelCopyWith<$Res> {
  factory $AdminModelCopyWith(
          AdminModel value, $Res Function(AdminModel) then) =
      _$AdminModelCopyWithImpl<$Res, AdminModel>;
  @useResult
  $Res call(
      {String name,
      @JsonKey(name: 'object_name') String objectName,
      AdminModelPermissions perms,
      @JsonKey(name: 'admin_url') String adminUrl,
      @JsonKey(name: 'add_url') String addUrl,
      @JsonKey(name: 'verbose_name') String? verboseName,
      @JsonKey(name: 'verbose_name_plural') String? verboseNamePlural});

  $AdminModelPermissionsCopyWith<$Res> get perms;
}

/// @nodoc
class _$AdminModelCopyWithImpl<$Res, $Val extends AdminModel>
    implements $AdminModelCopyWith<$Res> {
  _$AdminModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdminModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? objectName = null,
    Object? perms = null,
    Object? adminUrl = null,
    Object? addUrl = null,
    Object? verboseName = freezed,
    Object? verboseNamePlural = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      objectName: null == objectName
          ? _value.objectName
          : objectName // ignore: cast_nullable_to_non_nullable
              as String,
      perms: null == perms
          ? _value.perms
          : perms // ignore: cast_nullable_to_non_nullable
              as AdminModelPermissions,
      adminUrl: null == adminUrl
          ? _value.adminUrl
          : adminUrl // ignore: cast_nullable_to_non_nullable
              as String,
      addUrl: null == addUrl
          ? _value.addUrl
          : addUrl // ignore: cast_nullable_to_non_nullable
              as String,
      verboseName: freezed == verboseName
          ? _value.verboseName
          : verboseName // ignore: cast_nullable_to_non_nullable
              as String?,
      verboseNamePlural: freezed == verboseNamePlural
          ? _value.verboseNamePlural
          : verboseNamePlural // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of AdminModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AdminModelPermissionsCopyWith<$Res> get perms {
    return $AdminModelPermissionsCopyWith<$Res>(_value.perms, (value) {
      return _then(_value.copyWith(perms: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AdminModelImplCopyWith<$Res>
    implements $AdminModelCopyWith<$Res> {
  factory _$$AdminModelImplCopyWith(
          _$AdminModelImpl value, $Res Function(_$AdminModelImpl) then) =
      __$$AdminModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      @JsonKey(name: 'object_name') String objectName,
      AdminModelPermissions perms,
      @JsonKey(name: 'admin_url') String adminUrl,
      @JsonKey(name: 'add_url') String addUrl,
      @JsonKey(name: 'verbose_name') String? verboseName,
      @JsonKey(name: 'verbose_name_plural') String? verboseNamePlural});

  @override
  $AdminModelPermissionsCopyWith<$Res> get perms;
}

/// @nodoc
class __$$AdminModelImplCopyWithImpl<$Res>
    extends _$AdminModelCopyWithImpl<$Res, _$AdminModelImpl>
    implements _$$AdminModelImplCopyWith<$Res> {
  __$$AdminModelImplCopyWithImpl(
      _$AdminModelImpl _value, $Res Function(_$AdminModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdminModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? objectName = null,
    Object? perms = null,
    Object? adminUrl = null,
    Object? addUrl = null,
    Object? verboseName = freezed,
    Object? verboseNamePlural = freezed,
  }) {
    return _then(_$AdminModelImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      objectName: null == objectName
          ? _value.objectName
          : objectName // ignore: cast_nullable_to_non_nullable
              as String,
      perms: null == perms
          ? _value.perms
          : perms // ignore: cast_nullable_to_non_nullable
              as AdminModelPermissions,
      adminUrl: null == adminUrl
          ? _value.adminUrl
          : adminUrl // ignore: cast_nullable_to_non_nullable
              as String,
      addUrl: null == addUrl
          ? _value.addUrl
          : addUrl // ignore: cast_nullable_to_non_nullable
              as String,
      verboseName: freezed == verboseName
          ? _value.verboseName
          : verboseName // ignore: cast_nullable_to_non_nullable
              as String?,
      verboseNamePlural: freezed == verboseNamePlural
          ? _value.verboseNamePlural
          : verboseNamePlural // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminModelImpl implements _AdminModel {
  const _$AdminModelImpl(
      {required this.name,
      @JsonKey(name: 'object_name') required this.objectName,
      required this.perms,
      @JsonKey(name: 'admin_url') required this.adminUrl,
      @JsonKey(name: 'add_url') required this.addUrl,
      @JsonKey(name: 'verbose_name') this.verboseName,
      @JsonKey(name: 'verbose_name_plural') this.verboseNamePlural});

  factory _$AdminModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminModelImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey(name: 'object_name')
  final String objectName;
  @override
  final AdminModelPermissions perms;
  @override
  @JsonKey(name: 'admin_url')
  final String adminUrl;
  @override
  @JsonKey(name: 'add_url')
  final String addUrl;
  @override
  @JsonKey(name: 'verbose_name')
  final String? verboseName;
  @override
  @JsonKey(name: 'verbose_name_plural')
  final String? verboseNamePlural;

  @override
  String toString() {
    return 'AdminModel(name: $name, objectName: $objectName, perms: $perms, adminUrl: $adminUrl, addUrl: $addUrl, verboseName: $verboseName, verboseNamePlural: $verboseNamePlural)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminModelImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.objectName, objectName) ||
                other.objectName == objectName) &&
            (identical(other.perms, perms) || other.perms == perms) &&
            (identical(other.adminUrl, adminUrl) ||
                other.adminUrl == adminUrl) &&
            (identical(other.addUrl, addUrl) || other.addUrl == addUrl) &&
            (identical(other.verboseName, verboseName) ||
                other.verboseName == verboseName) &&
            (identical(other.verboseNamePlural, verboseNamePlural) ||
                other.verboseNamePlural == verboseNamePlural));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, objectName, perms,
      adminUrl, addUrl, verboseName, verboseNamePlural);

  /// Create a copy of AdminModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminModelImplCopyWith<_$AdminModelImpl> get copyWith =>
      __$$AdminModelImplCopyWithImpl<_$AdminModelImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AdminModel value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AdminModel value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AdminModel value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminModelImplToJson(
      this,
    );
  }
}

abstract class _AdminModel implements AdminModel {
  const factory _AdminModel(
      {required final String name,
      @JsonKey(name: 'object_name') required final String objectName,
      required final AdminModelPermissions perms,
      @JsonKey(name: 'admin_url') required final String adminUrl,
      @JsonKey(name: 'add_url') required final String addUrl,
      @JsonKey(name: 'verbose_name') final String? verboseName,
      @JsonKey(name: 'verbose_name_plural')
      final String? verboseNamePlural}) = _$AdminModelImpl;

  factory _AdminModel.fromJson(Map<String, dynamic> json) =
      _$AdminModelImpl.fromJson;

  @override
  String get name;
  @override
  @JsonKey(name: 'object_name')
  String get objectName;
  @override
  AdminModelPermissions get perms;
  @override
  @JsonKey(name: 'admin_url')
  String get adminUrl;
  @override
  @JsonKey(name: 'add_url')
  String get addUrl;
  @override
  @JsonKey(name: 'verbose_name')
  String? get verboseName;
  @override
  @JsonKey(name: 'verbose_name_plural')
  String? get verboseNamePlural;

  /// Create a copy of AdminModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdminModelImplCopyWith<_$AdminModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AdminModelPermissions _$AdminModelPermissionsFromJson(
    Map<String, dynamic> json) {
  return _AdminModelPermissions.fromJson(json);
}

/// @nodoc
mixin _$AdminModelPermissions {
  bool get add => throw _privateConstructorUsedError;
  bool get change => throw _privateConstructorUsedError;
  bool get delete => throw _privateConstructorUsedError;
  bool get view => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AdminModelPermissions value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AdminModelPermissions value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AdminModelPermissions value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this AdminModelPermissions to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdminModelPermissions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdminModelPermissionsCopyWith<AdminModelPermissions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminModelPermissionsCopyWith<$Res> {
  factory $AdminModelPermissionsCopyWith(AdminModelPermissions value,
          $Res Function(AdminModelPermissions) then) =
      _$AdminModelPermissionsCopyWithImpl<$Res, AdminModelPermissions>;
  @useResult
  $Res call({bool add, bool change, bool delete, bool view});
}

/// @nodoc
class _$AdminModelPermissionsCopyWithImpl<$Res,
        $Val extends AdminModelPermissions>
    implements $AdminModelPermissionsCopyWith<$Res> {
  _$AdminModelPermissionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdminModelPermissions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? add = null,
    Object? change = null,
    Object? delete = null,
    Object? view = null,
  }) {
    return _then(_value.copyWith(
      add: null == add
          ? _value.add
          : add // ignore: cast_nullable_to_non_nullable
              as bool,
      change: null == change
          ? _value.change
          : change // ignore: cast_nullable_to_non_nullable
              as bool,
      delete: null == delete
          ? _value.delete
          : delete // ignore: cast_nullable_to_non_nullable
              as bool,
      view: null == view
          ? _value.view
          : view // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminModelPermissionsImplCopyWith<$Res>
    implements $AdminModelPermissionsCopyWith<$Res> {
  factory _$$AdminModelPermissionsImplCopyWith(
          _$AdminModelPermissionsImpl value,
          $Res Function(_$AdminModelPermissionsImpl) then) =
      __$$AdminModelPermissionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool add, bool change, bool delete, bool view});
}

/// @nodoc
class __$$AdminModelPermissionsImplCopyWithImpl<$Res>
    extends _$AdminModelPermissionsCopyWithImpl<$Res,
        _$AdminModelPermissionsImpl>
    implements _$$AdminModelPermissionsImplCopyWith<$Res> {
  __$$AdminModelPermissionsImplCopyWithImpl(_$AdminModelPermissionsImpl _value,
      $Res Function(_$AdminModelPermissionsImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdminModelPermissions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? add = null,
    Object? change = null,
    Object? delete = null,
    Object? view = null,
  }) {
    return _then(_$AdminModelPermissionsImpl(
      add: null == add
          ? _value.add
          : add // ignore: cast_nullable_to_non_nullable
              as bool,
      change: null == change
          ? _value.change
          : change // ignore: cast_nullable_to_non_nullable
              as bool,
      delete: null == delete
          ? _value.delete
          : delete // ignore: cast_nullable_to_non_nullable
              as bool,
      view: null == view
          ? _value.view
          : view // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminModelPermissionsImpl implements _AdminModelPermissions {
  const _$AdminModelPermissionsImpl(
      {required this.add,
      required this.change,
      required this.delete,
      required this.view});

  factory _$AdminModelPermissionsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminModelPermissionsImplFromJson(json);

  @override
  final bool add;
  @override
  final bool change;
  @override
  final bool delete;
  @override
  final bool view;

  @override
  String toString() {
    return 'AdminModelPermissions(add: $add, change: $change, delete: $delete, view: $view)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminModelPermissionsImpl &&
            (identical(other.add, add) || other.add == add) &&
            (identical(other.change, change) || other.change == change) &&
            (identical(other.delete, delete) || other.delete == delete) &&
            (identical(other.view, view) || other.view == view));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, add, change, delete, view);

  /// Create a copy of AdminModelPermissions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminModelPermissionsImplCopyWith<_$AdminModelPermissionsImpl>
      get copyWith => __$$AdminModelPermissionsImplCopyWithImpl<
          _$AdminModelPermissionsImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AdminModelPermissions value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AdminModelPermissions value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AdminModelPermissions value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminModelPermissionsImplToJson(
      this,
    );
  }
}

abstract class _AdminModelPermissions implements AdminModelPermissions {
  const factory _AdminModelPermissions(
      {required final bool add,
      required final bool change,
      required final bool delete,
      required final bool view}) = _$AdminModelPermissionsImpl;

  factory _AdminModelPermissions.fromJson(Map<String, dynamic> json) =
      _$AdminModelPermissionsImpl.fromJson;

  @override
  bool get add;
  @override
  bool get change;
  @override
  bool get delete;
  @override
  bool get view;

  /// Create a copy of AdminModelPermissions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdminModelPermissionsImplCopyWith<_$AdminModelPermissionsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

DashboardAnalytics _$DashboardAnalyticsFromJson(Map<String, dynamic> json) {
  return _DashboardAnalytics.fromJson(json);
}

/// @nodoc
mixin _$DashboardAnalytics {
  @JsonKey(name: 'total_users')
  int get totalUsers => throw _privateConstructorUsedError;
  @JsonKey(name: 'active_users')
  int get activeUsers => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_models')
  int get totalModels => throw _privateConstructorUsedError;
  @JsonKey(name: 'recent_activity')
  List<ActivityItem> get recentActivity => throw _privateConstructorUsedError;
  @JsonKey(name: 'model_counts')
  Map<String, int> get modelCounts => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_growth')
  List<DataPoint> get userGrowth => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_DashboardAnalytics value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_DashboardAnalytics value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_DashboardAnalytics value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this DashboardAnalytics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DashboardAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DashboardAnalyticsCopyWith<DashboardAnalytics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DashboardAnalyticsCopyWith<$Res> {
  factory $DashboardAnalyticsCopyWith(
          DashboardAnalytics value, $Res Function(DashboardAnalytics) then) =
      _$DashboardAnalyticsCopyWithImpl<$Res, DashboardAnalytics>;
  @useResult
  $Res call(
      {@JsonKey(name: 'total_users') int totalUsers,
      @JsonKey(name: 'active_users') int activeUsers,
      @JsonKey(name: 'total_models') int totalModels,
      @JsonKey(name: 'recent_activity') List<ActivityItem> recentActivity,
      @JsonKey(name: 'model_counts') Map<String, int> modelCounts,
      @JsonKey(name: 'user_growth') List<DataPoint> userGrowth});
}

/// @nodoc
class _$DashboardAnalyticsCopyWithImpl<$Res, $Val extends DashboardAnalytics>
    implements $DashboardAnalyticsCopyWith<$Res> {
  _$DashboardAnalyticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DashboardAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalUsers = null,
    Object? activeUsers = null,
    Object? totalModels = null,
    Object? recentActivity = null,
    Object? modelCounts = null,
    Object? userGrowth = null,
  }) {
    return _then(_value.copyWith(
      totalUsers: null == totalUsers
          ? _value.totalUsers
          : totalUsers // ignore: cast_nullable_to_non_nullable
              as int,
      activeUsers: null == activeUsers
          ? _value.activeUsers
          : activeUsers // ignore: cast_nullable_to_non_nullable
              as int,
      totalModels: null == totalModels
          ? _value.totalModels
          : totalModels // ignore: cast_nullable_to_non_nullable
              as int,
      recentActivity: null == recentActivity
          ? _value.recentActivity
          : recentActivity // ignore: cast_nullable_to_non_nullable
              as List<ActivityItem>,
      modelCounts: null == modelCounts
          ? _value.modelCounts
          : modelCounts // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      userGrowth: null == userGrowth
          ? _value.userGrowth
          : userGrowth // ignore: cast_nullable_to_non_nullable
              as List<DataPoint>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DashboardAnalyticsImplCopyWith<$Res>
    implements $DashboardAnalyticsCopyWith<$Res> {
  factory _$$DashboardAnalyticsImplCopyWith(_$DashboardAnalyticsImpl value,
          $Res Function(_$DashboardAnalyticsImpl) then) =
      __$$DashboardAnalyticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'total_users') int totalUsers,
      @JsonKey(name: 'active_users') int activeUsers,
      @JsonKey(name: 'total_models') int totalModels,
      @JsonKey(name: 'recent_activity') List<ActivityItem> recentActivity,
      @JsonKey(name: 'model_counts') Map<String, int> modelCounts,
      @JsonKey(name: 'user_growth') List<DataPoint> userGrowth});
}

/// @nodoc
class __$$DashboardAnalyticsImplCopyWithImpl<$Res>
    extends _$DashboardAnalyticsCopyWithImpl<$Res, _$DashboardAnalyticsImpl>
    implements _$$DashboardAnalyticsImplCopyWith<$Res> {
  __$$DashboardAnalyticsImplCopyWithImpl(_$DashboardAnalyticsImpl _value,
      $Res Function(_$DashboardAnalyticsImpl) _then)
      : super(_value, _then);

  /// Create a copy of DashboardAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalUsers = null,
    Object? activeUsers = null,
    Object? totalModels = null,
    Object? recentActivity = null,
    Object? modelCounts = null,
    Object? userGrowth = null,
  }) {
    return _then(_$DashboardAnalyticsImpl(
      totalUsers: null == totalUsers
          ? _value.totalUsers
          : totalUsers // ignore: cast_nullable_to_non_nullable
              as int,
      activeUsers: null == activeUsers
          ? _value.activeUsers
          : activeUsers // ignore: cast_nullable_to_non_nullable
              as int,
      totalModels: null == totalModels
          ? _value.totalModels
          : totalModels // ignore: cast_nullable_to_non_nullable
              as int,
      recentActivity: null == recentActivity
          ? _value._recentActivity
          : recentActivity // ignore: cast_nullable_to_non_nullable
              as List<ActivityItem>,
      modelCounts: null == modelCounts
          ? _value._modelCounts
          : modelCounts // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      userGrowth: null == userGrowth
          ? _value._userGrowth
          : userGrowth // ignore: cast_nullable_to_non_nullable
              as List<DataPoint>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DashboardAnalyticsImpl implements _DashboardAnalytics {
  const _$DashboardAnalyticsImpl(
      {@JsonKey(name: 'total_users') required this.totalUsers,
      @JsonKey(name: 'active_users') required this.activeUsers,
      @JsonKey(name: 'total_models') required this.totalModels,
      @JsonKey(name: 'recent_activity')
      required final List<ActivityItem> recentActivity,
      @JsonKey(name: 'model_counts')
      required final Map<String, int> modelCounts,
      @JsonKey(name: 'user_growth') required final List<DataPoint> userGrowth})
      : _recentActivity = recentActivity,
        _modelCounts = modelCounts,
        _userGrowth = userGrowth;

  factory _$DashboardAnalyticsImpl.fromJson(Map<String, dynamic> json) =>
      _$$DashboardAnalyticsImplFromJson(json);

  @override
  @JsonKey(name: 'total_users')
  final int totalUsers;
  @override
  @JsonKey(name: 'active_users')
  final int activeUsers;
  @override
  @JsonKey(name: 'total_models')
  final int totalModels;
  final List<ActivityItem> _recentActivity;
  @override
  @JsonKey(name: 'recent_activity')
  List<ActivityItem> get recentActivity {
    if (_recentActivity is EqualUnmodifiableListView) return _recentActivity;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentActivity);
  }

  final Map<String, int> _modelCounts;
  @override
  @JsonKey(name: 'model_counts')
  Map<String, int> get modelCounts {
    if (_modelCounts is EqualUnmodifiableMapView) return _modelCounts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_modelCounts);
  }

  final List<DataPoint> _userGrowth;
  @override
  @JsonKey(name: 'user_growth')
  List<DataPoint> get userGrowth {
    if (_userGrowth is EqualUnmodifiableListView) return _userGrowth;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_userGrowth);
  }

  @override
  String toString() {
    return 'DashboardAnalytics(totalUsers: $totalUsers, activeUsers: $activeUsers, totalModels: $totalModels, recentActivity: $recentActivity, modelCounts: $modelCounts, userGrowth: $userGrowth)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardAnalyticsImpl &&
            (identical(other.totalUsers, totalUsers) ||
                other.totalUsers == totalUsers) &&
            (identical(other.activeUsers, activeUsers) ||
                other.activeUsers == activeUsers) &&
            (identical(other.totalModels, totalModels) ||
                other.totalModels == totalModels) &&
            const DeepCollectionEquality()
                .equals(other._recentActivity, _recentActivity) &&
            const DeepCollectionEquality()
                .equals(other._modelCounts, _modelCounts) &&
            const DeepCollectionEquality()
                .equals(other._userGrowth, _userGrowth));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      totalUsers,
      activeUsers,
      totalModels,
      const DeepCollectionEquality().hash(_recentActivity),
      const DeepCollectionEquality().hash(_modelCounts),
      const DeepCollectionEquality().hash(_userGrowth));

  /// Create a copy of DashboardAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardAnalyticsImplCopyWith<_$DashboardAnalyticsImpl> get copyWith =>
      __$$DashboardAnalyticsImplCopyWithImpl<_$DashboardAnalyticsImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_DashboardAnalytics value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_DashboardAnalytics value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_DashboardAnalytics value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$DashboardAnalyticsImplToJson(
      this,
    );
  }
}

abstract class _DashboardAnalytics implements DashboardAnalytics {
  const factory _DashboardAnalytics(
      {@JsonKey(name: 'total_users') required final int totalUsers,
      @JsonKey(name: 'active_users') required final int activeUsers,
      @JsonKey(name: 'total_models') required final int totalModels,
      @JsonKey(name: 'recent_activity')
      required final List<ActivityItem> recentActivity,
      @JsonKey(name: 'model_counts')
      required final Map<String, int> modelCounts,
      @JsonKey(name: 'user_growth')
      required final List<DataPoint> userGrowth}) = _$DashboardAnalyticsImpl;

  factory _DashboardAnalytics.fromJson(Map<String, dynamic> json) =
      _$DashboardAnalyticsImpl.fromJson;

  @override
  @JsonKey(name: 'total_users')
  int get totalUsers;
  @override
  @JsonKey(name: 'active_users')
  int get activeUsers;
  @override
  @JsonKey(name: 'total_models')
  int get totalModels;
  @override
  @JsonKey(name: 'recent_activity')
  List<ActivityItem> get recentActivity;
  @override
  @JsonKey(name: 'model_counts')
  Map<String, int> get modelCounts;
  @override
  @JsonKey(name: 'user_growth')
  List<DataPoint> get userGrowth;

  /// Create a copy of DashboardAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DashboardAnalyticsImplCopyWith<_$DashboardAnalyticsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ActivityItem _$ActivityItemFromJson(Map<String, dynamic> json) {
  return _ActivityItem.fromJson(json);
}

/// @nodoc
mixin _$ActivityItem {
  String get action => throw _privateConstructorUsedError;
  String get model => throw _privateConstructorUsedError;
  @JsonKey(name: 'object_name')
  String get objectName => throw _privateConstructorUsedError;
  String get user => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ActivityItem value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ActivityItem value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ActivityItem value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this ActivityItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ActivityItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActivityItemCopyWith<ActivityItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActivityItemCopyWith<$Res> {
  factory $ActivityItemCopyWith(
          ActivityItem value, $Res Function(ActivityItem) then) =
      _$ActivityItemCopyWithImpl<$Res, ActivityItem>;
  @useResult
  $Res call(
      {String action,
      String model,
      @JsonKey(name: 'object_name') String objectName,
      String user,
      DateTime timestamp});
}

/// @nodoc
class _$ActivityItemCopyWithImpl<$Res, $Val extends ActivityItem>
    implements $ActivityItemCopyWith<$Res> {
  _$ActivityItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActivityItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? action = null,
    Object? model = null,
    Object? objectName = null,
    Object? user = null,
    Object? timestamp = null,
  }) {
    return _then(_value.copyWith(
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      objectName: null == objectName
          ? _value.objectName
          : objectName // ignore: cast_nullable_to_non_nullable
              as String,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ActivityItemImplCopyWith<$Res>
    implements $ActivityItemCopyWith<$Res> {
  factory _$$ActivityItemImplCopyWith(
          _$ActivityItemImpl value, $Res Function(_$ActivityItemImpl) then) =
      __$$ActivityItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String action,
      String model,
      @JsonKey(name: 'object_name') String objectName,
      String user,
      DateTime timestamp});
}

/// @nodoc
class __$$ActivityItemImplCopyWithImpl<$Res>
    extends _$ActivityItemCopyWithImpl<$Res, _$ActivityItemImpl>
    implements _$$ActivityItemImplCopyWith<$Res> {
  __$$ActivityItemImplCopyWithImpl(
      _$ActivityItemImpl _value, $Res Function(_$ActivityItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of ActivityItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? action = null,
    Object? model = null,
    Object? objectName = null,
    Object? user = null,
    Object? timestamp = null,
  }) {
    return _then(_$ActivityItemImpl(
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      objectName: null == objectName
          ? _value.objectName
          : objectName // ignore: cast_nullable_to_non_nullable
              as String,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ActivityItemImpl implements _ActivityItem {
  const _$ActivityItemImpl(
      {required this.action,
      required this.model,
      @JsonKey(name: 'object_name') required this.objectName,
      required this.user,
      required this.timestamp});

  factory _$ActivityItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ActivityItemImplFromJson(json);

  @override
  final String action;
  @override
  final String model;
  @override
  @JsonKey(name: 'object_name')
  final String objectName;
  @override
  final String user;
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'ActivityItem(action: $action, model: $model, objectName: $objectName, user: $user, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActivityItemImpl &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.objectName, objectName) ||
                other.objectName == objectName) &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, action, model, objectName, user, timestamp);

  /// Create a copy of ActivityItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActivityItemImplCopyWith<_$ActivityItemImpl> get copyWith =>
      __$$ActivityItemImplCopyWithImpl<_$ActivityItemImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ActivityItem value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ActivityItem value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ActivityItem value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ActivityItemImplToJson(
      this,
    );
  }
}

abstract class _ActivityItem implements ActivityItem {
  const factory _ActivityItem(
      {required final String action,
      required final String model,
      @JsonKey(name: 'object_name') required final String objectName,
      required final String user,
      required final DateTime timestamp}) = _$ActivityItemImpl;

  factory _ActivityItem.fromJson(Map<String, dynamic> json) =
      _$ActivityItemImpl.fromJson;

  @override
  String get action;
  @override
  String get model;
  @override
  @JsonKey(name: 'object_name')
  String get objectName;
  @override
  String get user;
  @override
  DateTime get timestamp;

  /// Create a copy of ActivityItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActivityItemImplCopyWith<_$ActivityItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DataPoint _$DataPointFromJson(Map<String, dynamic> json) {
  return _DataPoint.fromJson(json);
}

/// @nodoc
mixin _$DataPoint {
  DateTime get date => throw _privateConstructorUsedError;
  double get value => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_DataPoint value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_DataPoint value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_DataPoint value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this DataPoint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DataPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DataPointCopyWith<DataPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DataPointCopyWith<$Res> {
  factory $DataPointCopyWith(DataPoint value, $Res Function(DataPoint) then) =
      _$DataPointCopyWithImpl<$Res, DataPoint>;
  @useResult
  $Res call({DateTime date, double value});
}

/// @nodoc
class _$DataPointCopyWithImpl<$Res, $Val extends DataPoint>
    implements $DataPointCopyWith<$Res> {
  _$DataPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DataPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? value = null,
  }) {
    return _then(_value.copyWith(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DataPointImplCopyWith<$Res>
    implements $DataPointCopyWith<$Res> {
  factory _$$DataPointImplCopyWith(
          _$DataPointImpl value, $Res Function(_$DataPointImpl) then) =
      __$$DataPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime date, double value});
}

/// @nodoc
class __$$DataPointImplCopyWithImpl<$Res>
    extends _$DataPointCopyWithImpl<$Res, _$DataPointImpl>
    implements _$$DataPointImplCopyWith<$Res> {
  __$$DataPointImplCopyWithImpl(
      _$DataPointImpl _value, $Res Function(_$DataPointImpl) _then)
      : super(_value, _then);

  /// Create a copy of DataPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? value = null,
  }) {
    return _then(_$DataPointImpl(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DataPointImpl implements _DataPoint {
  const _$DataPointImpl({required this.date, required this.value});

  factory _$DataPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$DataPointImplFromJson(json);

  @override
  final DateTime date;
  @override
  final double value;

  @override
  String toString() {
    return 'DataPoint(date: $date, value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DataPointImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, date, value);

  /// Create a copy of DataPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DataPointImplCopyWith<_$DataPointImpl> get copyWith =>
      __$$DataPointImplCopyWithImpl<_$DataPointImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_DataPoint value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_DataPoint value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_DataPoint value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$DataPointImplToJson(
      this,
    );
  }
}

abstract class _DataPoint implements DataPoint {
  const factory _DataPoint(
      {required final DateTime date,
      required final double value}) = _$DataPointImpl;

  factory _DataPoint.fromJson(Map<String, dynamic> json) =
      _$DataPointImpl.fromJson;

  @override
  DateTime get date;
  @override
  double get value;

  /// Create a copy of DataPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DataPointImplCopyWith<_$DataPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ModelStatsResponse _$ModelStatsResponseFromJson(Map<String, dynamic> json) {
  return _ModelStatsResponse.fromJson(json);
}

/// @nodoc
mixin _$ModelStatsResponse {
  Map<String, ModelStats> get stats => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ModelStatsResponse value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ModelStatsResponse value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ModelStatsResponse value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this ModelStatsResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModelStatsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModelStatsResponseCopyWith<ModelStatsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModelStatsResponseCopyWith<$Res> {
  factory $ModelStatsResponseCopyWith(
          ModelStatsResponse value, $Res Function(ModelStatsResponse) then) =
      _$ModelStatsResponseCopyWithImpl<$Res, ModelStatsResponse>;
  @useResult
  $Res call({Map<String, ModelStats> stats});
}

/// @nodoc
class _$ModelStatsResponseCopyWithImpl<$Res, $Val extends ModelStatsResponse>
    implements $ModelStatsResponseCopyWith<$Res> {
  _$ModelStatsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModelStatsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stats = null,
  }) {
    return _then(_value.copyWith(
      stats: null == stats
          ? _value.stats
          : stats // ignore: cast_nullable_to_non_nullable
              as Map<String, ModelStats>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModelStatsResponseImplCopyWith<$Res>
    implements $ModelStatsResponseCopyWith<$Res> {
  factory _$$ModelStatsResponseImplCopyWith(_$ModelStatsResponseImpl value,
          $Res Function(_$ModelStatsResponseImpl) then) =
      __$$ModelStatsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<String, ModelStats> stats});
}

/// @nodoc
class __$$ModelStatsResponseImplCopyWithImpl<$Res>
    extends _$ModelStatsResponseCopyWithImpl<$Res, _$ModelStatsResponseImpl>
    implements _$$ModelStatsResponseImplCopyWith<$Res> {
  __$$ModelStatsResponseImplCopyWithImpl(_$ModelStatsResponseImpl _value,
      $Res Function(_$ModelStatsResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of ModelStatsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stats = null,
  }) {
    return _then(_$ModelStatsResponseImpl(
      stats: null == stats
          ? _value._stats
          : stats // ignore: cast_nullable_to_non_nullable
              as Map<String, ModelStats>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ModelStatsResponseImpl implements _ModelStatsResponse {
  const _$ModelStatsResponseImpl({required final Map<String, ModelStats> stats})
      : _stats = stats;

  factory _$ModelStatsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModelStatsResponseImplFromJson(json);

  final Map<String, ModelStats> _stats;
  @override
  Map<String, ModelStats> get stats {
    if (_stats is EqualUnmodifiableMapView) return _stats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_stats);
  }

  @override
  String toString() {
    return 'ModelStatsResponse(stats: $stats)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModelStatsResponseImpl &&
            const DeepCollectionEquality().equals(other._stats, _stats));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_stats));

  /// Create a copy of ModelStatsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModelStatsResponseImplCopyWith<_$ModelStatsResponseImpl> get copyWith =>
      __$$ModelStatsResponseImplCopyWithImpl<_$ModelStatsResponseImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ModelStatsResponse value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ModelStatsResponse value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ModelStatsResponse value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ModelStatsResponseImplToJson(
      this,
    );
  }
}

abstract class _ModelStatsResponse implements ModelStatsResponse {
  const factory _ModelStatsResponse(
          {required final Map<String, ModelStats> stats}) =
      _$ModelStatsResponseImpl;

  factory _ModelStatsResponse.fromJson(Map<String, dynamic> json) =
      _$ModelStatsResponseImpl.fromJson;

  @override
  Map<String, ModelStats> get stats;

  /// Create a copy of ModelStatsResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModelStatsResponseImplCopyWith<_$ModelStatsResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ModelStats _$ModelStatsFromJson(Map<String, dynamic> json) {
  return _ModelStats.fromJson(json);
}

/// @nodoc
mixin _$ModelStats {
  int get count => throw _privateConstructorUsedError;
  @JsonKey(name: 'recent_changes')
  int get recentChanges => throw _privateConstructorUsedError;
  @JsonKey(name: 'growth_rate')
  double get growthRate => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ModelStats value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ModelStats value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ModelStats value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this ModelStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModelStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModelStatsCopyWith<ModelStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModelStatsCopyWith<$Res> {
  factory $ModelStatsCopyWith(
          ModelStats value, $Res Function(ModelStats) then) =
      _$ModelStatsCopyWithImpl<$Res, ModelStats>;
  @useResult
  $Res call(
      {int count,
      @JsonKey(name: 'recent_changes') int recentChanges,
      @JsonKey(name: 'growth_rate') double growthRate});
}

/// @nodoc
class _$ModelStatsCopyWithImpl<$Res, $Val extends ModelStats>
    implements $ModelStatsCopyWith<$Res> {
  _$ModelStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModelStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? count = null,
    Object? recentChanges = null,
    Object? growthRate = null,
  }) {
    return _then(_value.copyWith(
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      recentChanges: null == recentChanges
          ? _value.recentChanges
          : recentChanges // ignore: cast_nullable_to_non_nullable
              as int,
      growthRate: null == growthRate
          ? _value.growthRate
          : growthRate // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModelStatsImplCopyWith<$Res>
    implements $ModelStatsCopyWith<$Res> {
  factory _$$ModelStatsImplCopyWith(
          _$ModelStatsImpl value, $Res Function(_$ModelStatsImpl) then) =
      __$$ModelStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int count,
      @JsonKey(name: 'recent_changes') int recentChanges,
      @JsonKey(name: 'growth_rate') double growthRate});
}

/// @nodoc
class __$$ModelStatsImplCopyWithImpl<$Res>
    extends _$ModelStatsCopyWithImpl<$Res, _$ModelStatsImpl>
    implements _$$ModelStatsImplCopyWith<$Res> {
  __$$ModelStatsImplCopyWithImpl(
      _$ModelStatsImpl _value, $Res Function(_$ModelStatsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ModelStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? count = null,
    Object? recentChanges = null,
    Object? growthRate = null,
  }) {
    return _then(_$ModelStatsImpl(
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      recentChanges: null == recentChanges
          ? _value.recentChanges
          : recentChanges // ignore: cast_nullable_to_non_nullable
              as int,
      growthRate: null == growthRate
          ? _value.growthRate
          : growthRate // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ModelStatsImpl implements _ModelStats {
  const _$ModelStatsImpl(
      {required this.count,
      @JsonKey(name: 'recent_changes') required this.recentChanges,
      @JsonKey(name: 'growth_rate') required this.growthRate});

  factory _$ModelStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModelStatsImplFromJson(json);

  @override
  final int count;
  @override
  @JsonKey(name: 'recent_changes')
  final int recentChanges;
  @override
  @JsonKey(name: 'growth_rate')
  final double growthRate;

  @override
  String toString() {
    return 'ModelStats(count: $count, recentChanges: $recentChanges, growthRate: $growthRate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModelStatsImpl &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.recentChanges, recentChanges) ||
                other.recentChanges == recentChanges) &&
            (identical(other.growthRate, growthRate) ||
                other.growthRate == growthRate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, count, recentChanges, growthRate);

  /// Create a copy of ModelStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModelStatsImplCopyWith<_$ModelStatsImpl> get copyWith =>
      __$$ModelStatsImplCopyWithImpl<_$ModelStatsImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ModelStats value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ModelStats value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ModelStats value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ModelStatsImplToJson(
      this,
    );
  }
}

abstract class _ModelStats implements ModelStats {
  const factory _ModelStats(
          {required final int count,
          @JsonKey(name: 'recent_changes') required final int recentChanges,
          @JsonKey(name: 'growth_rate') required final double growthRate}) =
      _$ModelStatsImpl;

  factory _ModelStats.fromJson(Map<String, dynamic> json) =
      _$ModelStatsImpl.fromJson;

  @override
  int get count;
  @override
  @JsonKey(name: 'recent_changes')
  int get recentChanges;
  @override
  @JsonKey(name: 'growth_rate')
  double get growthRate;

  /// Create a copy of ModelStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModelStatsImplCopyWith<_$ModelStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserActivityResponse _$UserActivityResponseFromJson(Map<String, dynamic> json) {
  return _UserActivityResponse.fromJson(json);
}

/// @nodoc
mixin _$UserActivityResponse {
  List<UserActivityItem> get activities => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_UserActivityResponse value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_UserActivityResponse value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_UserActivityResponse value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this UserActivityResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserActivityResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserActivityResponseCopyWith<UserActivityResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserActivityResponseCopyWith<$Res> {
  factory $UserActivityResponseCopyWith(UserActivityResponse value,
          $Res Function(UserActivityResponse) then) =
      _$UserActivityResponseCopyWithImpl<$Res, UserActivityResponse>;
  @useResult
  $Res call({List<UserActivityItem> activities, int total});
}

/// @nodoc
class _$UserActivityResponseCopyWithImpl<$Res,
        $Val extends UserActivityResponse>
    implements $UserActivityResponseCopyWith<$Res> {
  _$UserActivityResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserActivityResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activities = null,
    Object? total = null,
  }) {
    return _then(_value.copyWith(
      activities: null == activities
          ? _value.activities
          : activities // ignore: cast_nullable_to_non_nullable
              as List<UserActivityItem>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserActivityResponseImplCopyWith<$Res>
    implements $UserActivityResponseCopyWith<$Res> {
  factory _$$UserActivityResponseImplCopyWith(_$UserActivityResponseImpl value,
          $Res Function(_$UserActivityResponseImpl) then) =
      __$$UserActivityResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<UserActivityItem> activities, int total});
}

/// @nodoc
class __$$UserActivityResponseImplCopyWithImpl<$Res>
    extends _$UserActivityResponseCopyWithImpl<$Res, _$UserActivityResponseImpl>
    implements _$$UserActivityResponseImplCopyWith<$Res> {
  __$$UserActivityResponseImplCopyWithImpl(_$UserActivityResponseImpl _value,
      $Res Function(_$UserActivityResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserActivityResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activities = null,
    Object? total = null,
  }) {
    return _then(_$UserActivityResponseImpl(
      activities: null == activities
          ? _value._activities
          : activities // ignore: cast_nullable_to_non_nullable
              as List<UserActivityItem>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserActivityResponseImpl implements _UserActivityResponse {
  const _$UserActivityResponseImpl(
      {required final List<UserActivityItem> activities, required this.total})
      : _activities = activities;

  factory _$UserActivityResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserActivityResponseImplFromJson(json);

  final List<UserActivityItem> _activities;
  @override
  List<UserActivityItem> get activities {
    if (_activities is EqualUnmodifiableListView) return _activities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_activities);
  }

  @override
  final int total;

  @override
  String toString() {
    return 'UserActivityResponse(activities: $activities, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserActivityResponseImpl &&
            const DeepCollectionEquality()
                .equals(other._activities, _activities) &&
            (identical(other.total, total) || other.total == total));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_activities), total);

  /// Create a copy of UserActivityResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserActivityResponseImplCopyWith<_$UserActivityResponseImpl>
      get copyWith =>
          __$$UserActivityResponseImplCopyWithImpl<_$UserActivityResponseImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_UserActivityResponse value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_UserActivityResponse value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_UserActivityResponse value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$UserActivityResponseImplToJson(
      this,
    );
  }
}

abstract class _UserActivityResponse implements UserActivityResponse {
  const factory _UserActivityResponse(
      {required final List<UserActivityItem> activities,
      required final int total}) = _$UserActivityResponseImpl;

  factory _UserActivityResponse.fromJson(Map<String, dynamic> json) =
      _$UserActivityResponseImpl.fromJson;

  @override
  List<UserActivityItem> get activities;
  @override
  int get total;

  /// Create a copy of UserActivityResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserActivityResponseImplCopyWith<_$UserActivityResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

UserActivityItem _$UserActivityItemFromJson(Map<String, dynamic> json) {
  return _UserActivityItem.fromJson(json);
}

/// @nodoc
mixin _$UserActivityItem {
  String get username => throw _privateConstructorUsedError;
  String get action => throw _privateConstructorUsedError;
  String get model => throw _privateConstructorUsedError;
  @JsonKey(name: 'object_id')
  String? get objectId => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  @JsonKey(name: 'ip_address')
  String? get ipAddress => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_UserActivityItem value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_UserActivityItem value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_UserActivityItem value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this UserActivityItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserActivityItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserActivityItemCopyWith<UserActivityItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserActivityItemCopyWith<$Res> {
  factory $UserActivityItemCopyWith(
          UserActivityItem value, $Res Function(UserActivityItem) then) =
      _$UserActivityItemCopyWithImpl<$Res, UserActivityItem>;
  @useResult
  $Res call(
      {String username,
      String action,
      String model,
      @JsonKey(name: 'object_id') String? objectId,
      DateTime timestamp,
      @JsonKey(name: 'ip_address') String? ipAddress});
}

/// @nodoc
class _$UserActivityItemCopyWithImpl<$Res, $Val extends UserActivityItem>
    implements $UserActivityItemCopyWith<$Res> {
  _$UserActivityItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserActivityItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? action = null,
    Object? model = null,
    Object? objectId = freezed,
    Object? timestamp = null,
    Object? ipAddress = freezed,
  }) {
    return _then(_value.copyWith(
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      objectId: freezed == objectId
          ? _value.objectId
          : objectId // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      ipAddress: freezed == ipAddress
          ? _value.ipAddress
          : ipAddress // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserActivityItemImplCopyWith<$Res>
    implements $UserActivityItemCopyWith<$Res> {
  factory _$$UserActivityItemImplCopyWith(_$UserActivityItemImpl value,
          $Res Function(_$UserActivityItemImpl) then) =
      __$$UserActivityItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String username,
      String action,
      String model,
      @JsonKey(name: 'object_id') String? objectId,
      DateTime timestamp,
      @JsonKey(name: 'ip_address') String? ipAddress});
}

/// @nodoc
class __$$UserActivityItemImplCopyWithImpl<$Res>
    extends _$UserActivityItemCopyWithImpl<$Res, _$UserActivityItemImpl>
    implements _$$UserActivityItemImplCopyWith<$Res> {
  __$$UserActivityItemImplCopyWithImpl(_$UserActivityItemImpl _value,
      $Res Function(_$UserActivityItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserActivityItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? action = null,
    Object? model = null,
    Object? objectId = freezed,
    Object? timestamp = null,
    Object? ipAddress = freezed,
  }) {
    return _then(_$UserActivityItemImpl(
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      objectId: freezed == objectId
          ? _value.objectId
          : objectId // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      ipAddress: freezed == ipAddress
          ? _value.ipAddress
          : ipAddress // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserActivityItemImpl implements _UserActivityItem {
  const _$UserActivityItemImpl(
      {required this.username,
      required this.action,
      required this.model,
      @JsonKey(name: 'object_id') this.objectId,
      required this.timestamp,
      @JsonKey(name: 'ip_address') this.ipAddress});

  factory _$UserActivityItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserActivityItemImplFromJson(json);

  @override
  final String username;
  @override
  final String action;
  @override
  final String model;
  @override
  @JsonKey(name: 'object_id')
  final String? objectId;
  @override
  final DateTime timestamp;
  @override
  @JsonKey(name: 'ip_address')
  final String? ipAddress;

  @override
  String toString() {
    return 'UserActivityItem(username: $username, action: $action, model: $model, objectId: $objectId, timestamp: $timestamp, ipAddress: $ipAddress)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserActivityItemImpl &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.objectId, objectId) ||
                other.objectId == objectId) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.ipAddress, ipAddress) ||
                other.ipAddress == ipAddress));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, username, action, model, objectId, timestamp, ipAddress);

  /// Create a copy of UserActivityItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserActivityItemImplCopyWith<_$UserActivityItemImpl> get copyWith =>
      __$$UserActivityItemImplCopyWithImpl<_$UserActivityItemImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_UserActivityItem value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_UserActivityItem value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_UserActivityItem value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$UserActivityItemImplToJson(
      this,
    );
  }
}

abstract class _UserActivityItem implements UserActivityItem {
  const factory _UserActivityItem(
          {required final String username,
          required final String action,
          required final String model,
          @JsonKey(name: 'object_id') final String? objectId,
          required final DateTime timestamp,
          @JsonKey(name: 'ip_address') final String? ipAddress}) =
      _$UserActivityItemImpl;

  factory _UserActivityItem.fromJson(Map<String, dynamic> json) =
      _$UserActivityItemImpl.fromJson;

  @override
  String get username;
  @override
  String get action;
  @override
  String get model;
  @override
  @JsonKey(name: 'object_id')
  String? get objectId;
  @override
  DateTime get timestamp;
  @override
  @JsonKey(name: 'ip_address')
  String? get ipAddress;

  /// Create a copy of UserActivityItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserActivityItemImplCopyWith<_$UserActivityItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FileUploadResponse _$FileUploadResponseFromJson(Map<String, dynamic> json) {
  return _FileUploadResponse.fromJson(json);
}

/// @nodoc
mixin _$FileUploadResponse {
  String get url => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get size => throw _privateConstructorUsedError;
  @JsonKey(name: 'content_type')
  String get contentType => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_FileUploadResponse value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_FileUploadResponse value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_FileUploadResponse value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this FileUploadResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FileUploadResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FileUploadResponseCopyWith<FileUploadResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FileUploadResponseCopyWith<$Res> {
  factory $FileUploadResponseCopyWith(
          FileUploadResponse value, $Res Function(FileUploadResponse) then) =
      _$FileUploadResponseCopyWithImpl<$Res, FileUploadResponse>;
  @useResult
  $Res call(
      {String url,
      String name,
      int size,
      @JsonKey(name: 'content_type') String contentType});
}

/// @nodoc
class _$FileUploadResponseCopyWithImpl<$Res, $Val extends FileUploadResponse>
    implements $FileUploadResponseCopyWith<$Res> {
  _$FileUploadResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FileUploadResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? name = null,
    Object? size = null,
    Object? contentType = null,
  }) {
    return _then(_value.copyWith(
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      contentType: null == contentType
          ? _value.contentType
          : contentType // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FileUploadResponseImplCopyWith<$Res>
    implements $FileUploadResponseCopyWith<$Res> {
  factory _$$FileUploadResponseImplCopyWith(_$FileUploadResponseImpl value,
          $Res Function(_$FileUploadResponseImpl) then) =
      __$$FileUploadResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String url,
      String name,
      int size,
      @JsonKey(name: 'content_type') String contentType});
}

/// @nodoc
class __$$FileUploadResponseImplCopyWithImpl<$Res>
    extends _$FileUploadResponseCopyWithImpl<$Res, _$FileUploadResponseImpl>
    implements _$$FileUploadResponseImplCopyWith<$Res> {
  __$$FileUploadResponseImplCopyWithImpl(_$FileUploadResponseImpl _value,
      $Res Function(_$FileUploadResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of FileUploadResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? name = null,
    Object? size = null,
    Object? contentType = null,
  }) {
    return _then(_$FileUploadResponseImpl(
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      contentType: null == contentType
          ? _value.contentType
          : contentType // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FileUploadResponseImpl implements _FileUploadResponse {
  const _$FileUploadResponseImpl(
      {required this.url,
      required this.name,
      required this.size,
      @JsonKey(name: 'content_type') required this.contentType});

  factory _$FileUploadResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$FileUploadResponseImplFromJson(json);

  @override
  final String url;
  @override
  final String name;
  @override
  final int size;
  @override
  @JsonKey(name: 'content_type')
  final String contentType;

  @override
  String toString() {
    return 'FileUploadResponse(url: $url, name: $name, size: $size, contentType: $contentType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileUploadResponseImpl &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.contentType, contentType) ||
                other.contentType == contentType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, url, name, size, contentType);

  /// Create a copy of FileUploadResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FileUploadResponseImplCopyWith<_$FileUploadResponseImpl> get copyWith =>
      __$$FileUploadResponseImplCopyWithImpl<_$FileUploadResponseImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_FileUploadResponse value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_FileUploadResponse value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_FileUploadResponse value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$FileUploadResponseImplToJson(
      this,
    );
  }
}

abstract class _FileUploadResponse implements FileUploadResponse {
  const factory _FileUploadResponse(
          {required final String url,
          required final String name,
          required final int size,
          @JsonKey(name: 'content_type') required final String contentType}) =
      _$FileUploadResponseImpl;

  factory _FileUploadResponse.fromJson(Map<String, dynamic> json) =
      _$FileUploadResponseImpl.fromJson;

  @override
  String get url;
  @override
  String get name;
  @override
  int get size;
  @override
  @JsonKey(name: 'content_type')
  String get contentType;

  /// Create a copy of FileUploadResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FileUploadResponseImplCopyWith<_$FileUploadResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FileListResponse _$FileListResponseFromJson(Map<String, dynamic> json) {
  return _FileListResponse.fromJson(json);
}

/// @nodoc
mixin _$FileListResponse {
  List<AdminFile> get files => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_FileListResponse value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_FileListResponse value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_FileListResponse value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this FileListResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FileListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FileListResponseCopyWith<FileListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FileListResponseCopyWith<$Res> {
  factory $FileListResponseCopyWith(
          FileListResponse value, $Res Function(FileListResponse) then) =
      _$FileListResponseCopyWithImpl<$Res, FileListResponse>;
  @useResult
  $Res call({List<AdminFile> files, int count});
}

/// @nodoc
class _$FileListResponseCopyWithImpl<$Res, $Val extends FileListResponse>
    implements $FileListResponseCopyWith<$Res> {
  _$FileListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FileListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? files = null,
    Object? count = null,
  }) {
    return _then(_value.copyWith(
      files: null == files
          ? _value.files
          : files // ignore: cast_nullable_to_non_nullable
              as List<AdminFile>,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FileListResponseImplCopyWith<$Res>
    implements $FileListResponseCopyWith<$Res> {
  factory _$$FileListResponseImplCopyWith(_$FileListResponseImpl value,
          $Res Function(_$FileListResponseImpl) then) =
      __$$FileListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<AdminFile> files, int count});
}

/// @nodoc
class __$$FileListResponseImplCopyWithImpl<$Res>
    extends _$FileListResponseCopyWithImpl<$Res, _$FileListResponseImpl>
    implements _$$FileListResponseImplCopyWith<$Res> {
  __$$FileListResponseImplCopyWithImpl(_$FileListResponseImpl _value,
      $Res Function(_$FileListResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of FileListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? files = null,
    Object? count = null,
  }) {
    return _then(_$FileListResponseImpl(
      files: null == files
          ? _value._files
          : files // ignore: cast_nullable_to_non_nullable
              as List<AdminFile>,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FileListResponseImpl implements _FileListResponse {
  const _$FileListResponseImpl(
      {required final List<AdminFile> files, required this.count})
      : _files = files;

  factory _$FileListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$FileListResponseImplFromJson(json);

  final List<AdminFile> _files;
  @override
  List<AdminFile> get files {
    if (_files is EqualUnmodifiableListView) return _files;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_files);
  }

  @override
  final int count;

  @override
  String toString() {
    return 'FileListResponse(files: $files, count: $count)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileListResponseImpl &&
            const DeepCollectionEquality().equals(other._files, _files) &&
            (identical(other.count, count) || other.count == count));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_files), count);

  /// Create a copy of FileListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FileListResponseImplCopyWith<_$FileListResponseImpl> get copyWith =>
      __$$FileListResponseImplCopyWithImpl<_$FileListResponseImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_FileListResponse value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_FileListResponse value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_FileListResponse value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$FileListResponseImplToJson(
      this,
    );
  }
}

abstract class _FileListResponse implements FileListResponse {
  const factory _FileListResponse(
      {required final List<AdminFile> files,
      required final int count}) = _$FileListResponseImpl;

  factory _FileListResponse.fromJson(Map<String, dynamic> json) =
      _$FileListResponseImpl.fromJson;

  @override
  List<AdminFile> get files;
  @override
  int get count;

  /// Create a copy of FileListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FileListResponseImplCopyWith<_$FileListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AdminFile _$AdminFileFromJson(Map<String, dynamic> json) {
  return _AdminFile.fromJson(json);
}

/// @nodoc
mixin _$AdminFile {
  String get name => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  int get size => throw _privateConstructorUsedError;
  @JsonKey(name: 'content_type')
  String get contentType => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AdminFile value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AdminFile value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AdminFile value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this AdminFile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdminFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdminFileCopyWith<AdminFile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminFileCopyWith<$Res> {
  factory $AdminFileCopyWith(AdminFile value, $Res Function(AdminFile) then) =
      _$AdminFileCopyWithImpl<$Res, AdminFile>;
  @useResult
  $Res call(
      {String name,
      String url,
      int size,
      @JsonKey(name: 'content_type') String contentType,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$AdminFileCopyWithImpl<$Res, $Val extends AdminFile>
    implements $AdminFileCopyWith<$Res> {
  _$AdminFileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdminFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? url = null,
    Object? size = null,
    Object? contentType = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      contentType: null == contentType
          ? _value.contentType
          : contentType // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminFileImplCopyWith<$Res>
    implements $AdminFileCopyWith<$Res> {
  factory _$$AdminFileImplCopyWith(
          _$AdminFileImpl value, $Res Function(_$AdminFileImpl) then) =
      __$$AdminFileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String url,
      int size,
      @JsonKey(name: 'content_type') String contentType,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$AdminFileImplCopyWithImpl<$Res>
    extends _$AdminFileCopyWithImpl<$Res, _$AdminFileImpl>
    implements _$$AdminFileImplCopyWith<$Res> {
  __$$AdminFileImplCopyWithImpl(
      _$AdminFileImpl _value, $Res Function(_$AdminFileImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdminFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? url = null,
    Object? size = null,
    Object? contentType = null,
    Object? createdAt = null,
  }) {
    return _then(_$AdminFileImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      contentType: null == contentType
          ? _value.contentType
          : contentType // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminFileImpl implements _AdminFile {
  const _$AdminFileImpl(
      {required this.name,
      required this.url,
      required this.size,
      @JsonKey(name: 'content_type') required this.contentType,
      @JsonKey(name: 'created_at') required this.createdAt});

  factory _$AdminFileImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminFileImplFromJson(json);

  @override
  final String name;
  @override
  final String url;
  @override
  final int size;
  @override
  @JsonKey(name: 'content_type')
  final String contentType;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'AdminFile(name: $name, url: $url, size: $size, contentType: $contentType, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminFileImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.contentType, contentType) ||
                other.contentType == contentType) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, url, size, contentType, createdAt);

  /// Create a copy of AdminFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminFileImplCopyWith<_$AdminFileImpl> get copyWith =>
      __$$AdminFileImplCopyWithImpl<_$AdminFileImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AdminFile value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AdminFile value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AdminFile value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminFileImplToJson(
      this,
    );
  }
}

abstract class _AdminFile implements AdminFile {
  const factory _AdminFile(
          {required final String name,
          required final String url,
          required final int size,
          @JsonKey(name: 'content_type') required final String contentType,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$AdminFileImpl;

  factory _AdminFile.fromJson(Map<String, dynamic> json) =
      _$AdminFileImpl.fromJson;

  @override
  String get name;
  @override
  String get url;
  @override
  int get size;
  @override
  @JsonKey(name: 'content_type')
  String get contentType;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of AdminFile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdminFileImplCopyWith<_$AdminFileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExportResponse _$ExportResponseFromJson(Map<String, dynamic> json) {
  return _ExportResponse.fromJson(json);
}

/// @nodoc
mixin _$ExportResponse {
  @JsonKey(name: 'download_url')
  String get downloadUrl => throw _privateConstructorUsedError;
  String get format => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_size')
  int get fileSize => throw _privateConstructorUsedError;
  @JsonKey(name: 'record_count')
  int get recordCount => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ExportResponse value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ExportResponse value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ExportResponse value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this ExportResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExportResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExportResponseCopyWith<ExportResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExportResponseCopyWith<$Res> {
  factory $ExportResponseCopyWith(
          ExportResponse value, $Res Function(ExportResponse) then) =
      _$ExportResponseCopyWithImpl<$Res, ExportResponse>;
  @useResult
  $Res call(
      {@JsonKey(name: 'download_url') String downloadUrl,
      String format,
      @JsonKey(name: 'file_size') int fileSize,
      @JsonKey(name: 'record_count') int recordCount});
}

/// @nodoc
class _$ExportResponseCopyWithImpl<$Res, $Val extends ExportResponse>
    implements $ExportResponseCopyWith<$Res> {
  _$ExportResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExportResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? downloadUrl = null,
    Object? format = null,
    Object? fileSize = null,
    Object? recordCount = null,
  }) {
    return _then(_value.copyWith(
      downloadUrl: null == downloadUrl
          ? _value.downloadUrl
          : downloadUrl // ignore: cast_nullable_to_non_nullable
              as String,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as String,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      recordCount: null == recordCount
          ? _value.recordCount
          : recordCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExportResponseImplCopyWith<$Res>
    implements $ExportResponseCopyWith<$Res> {
  factory _$$ExportResponseImplCopyWith(_$ExportResponseImpl value,
          $Res Function(_$ExportResponseImpl) then) =
      __$$ExportResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'download_url') String downloadUrl,
      String format,
      @JsonKey(name: 'file_size') int fileSize,
      @JsonKey(name: 'record_count') int recordCount});
}

/// @nodoc
class __$$ExportResponseImplCopyWithImpl<$Res>
    extends _$ExportResponseCopyWithImpl<$Res, _$ExportResponseImpl>
    implements _$$ExportResponseImplCopyWith<$Res> {
  __$$ExportResponseImplCopyWithImpl(
      _$ExportResponseImpl _value, $Res Function(_$ExportResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExportResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? downloadUrl = null,
    Object? format = null,
    Object? fileSize = null,
    Object? recordCount = null,
  }) {
    return _then(_$ExportResponseImpl(
      downloadUrl: null == downloadUrl
          ? _value.downloadUrl
          : downloadUrl // ignore: cast_nullable_to_non_nullable
              as String,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as String,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      recordCount: null == recordCount
          ? _value.recordCount
          : recordCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExportResponseImpl implements _ExportResponse {
  const _$ExportResponseImpl(
      {@JsonKey(name: 'download_url') required this.downloadUrl,
      required this.format,
      @JsonKey(name: 'file_size') required this.fileSize,
      @JsonKey(name: 'record_count') required this.recordCount});

  factory _$ExportResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExportResponseImplFromJson(json);

  @override
  @JsonKey(name: 'download_url')
  final String downloadUrl;
  @override
  final String format;
  @override
  @JsonKey(name: 'file_size')
  final int fileSize;
  @override
  @JsonKey(name: 'record_count')
  final int recordCount;

  @override
  String toString() {
    return 'ExportResponse(downloadUrl: $downloadUrl, format: $format, fileSize: $fileSize, recordCount: $recordCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExportResponseImpl &&
            (identical(other.downloadUrl, downloadUrl) ||
                other.downloadUrl == downloadUrl) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.recordCount, recordCount) ||
                other.recordCount == recordCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, downloadUrl, format, fileSize, recordCount);

  /// Create a copy of ExportResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExportResponseImplCopyWith<_$ExportResponseImpl> get copyWith =>
      __$$ExportResponseImplCopyWithImpl<_$ExportResponseImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ExportResponse value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ExportResponse value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ExportResponse value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ExportResponseImplToJson(
      this,
    );
  }
}

abstract class _ExportResponse implements ExportResponse {
  const factory _ExportResponse(
          {@JsonKey(name: 'download_url') required final String downloadUrl,
          required final String format,
          @JsonKey(name: 'file_size') required final int fileSize,
          @JsonKey(name: 'record_count') required final int recordCount}) =
      _$ExportResponseImpl;

  factory _ExportResponse.fromJson(Map<String, dynamic> json) =
      _$ExportResponseImpl.fromJson;

  @override
  @JsonKey(name: 'download_url')
  String get downloadUrl;
  @override
  String get format;
  @override
  @JsonKey(name: 'file_size')
  int get fileSize;
  @override
  @JsonKey(name: 'record_count')
  int get recordCount;

  /// Create a copy of ExportResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExportResponseImplCopyWith<_$ExportResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ImportResponse _$ImportResponseFromJson(Map<String, dynamic> json) {
  return _ImportResponse.fromJson(json);
}

/// @nodoc
mixin _$ImportResponse {
  bool get success => throw _privateConstructorUsedError;
  @JsonKey(name: 'imported_count')
  int get importedCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'error_count')
  int get errorCount => throw _privateConstructorUsedError;
  List<String>? get errors => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ImportResponse value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ImportResponse value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ImportResponse value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this ImportResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ImportResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ImportResponseCopyWith<ImportResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImportResponseCopyWith<$Res> {
  factory $ImportResponseCopyWith(
          ImportResponse value, $Res Function(ImportResponse) then) =
      _$ImportResponseCopyWithImpl<$Res, ImportResponse>;
  @useResult
  $Res call(
      {bool success,
      @JsonKey(name: 'imported_count') int importedCount,
      @JsonKey(name: 'error_count') int errorCount,
      List<String>? errors});
}

/// @nodoc
class _$ImportResponseCopyWithImpl<$Res, $Val extends ImportResponse>
    implements $ImportResponseCopyWith<$Res> {
  _$ImportResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ImportResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? importedCount = null,
    Object? errorCount = null,
    Object? errors = freezed,
  }) {
    return _then(_value.copyWith(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      importedCount: null == importedCount
          ? _value.importedCount
          : importedCount // ignore: cast_nullable_to_non_nullable
              as int,
      errorCount: null == errorCount
          ? _value.errorCount
          : errorCount // ignore: cast_nullable_to_non_nullable
              as int,
      errors: freezed == errors
          ? _value.errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ImportResponseImplCopyWith<$Res>
    implements $ImportResponseCopyWith<$Res> {
  factory _$$ImportResponseImplCopyWith(_$ImportResponseImpl value,
          $Res Function(_$ImportResponseImpl) then) =
      __$$ImportResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool success,
      @JsonKey(name: 'imported_count') int importedCount,
      @JsonKey(name: 'error_count') int errorCount,
      List<String>? errors});
}

/// @nodoc
class __$$ImportResponseImplCopyWithImpl<$Res>
    extends _$ImportResponseCopyWithImpl<$Res, _$ImportResponseImpl>
    implements _$$ImportResponseImplCopyWith<$Res> {
  __$$ImportResponseImplCopyWithImpl(
      _$ImportResponseImpl _value, $Res Function(_$ImportResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of ImportResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? importedCount = null,
    Object? errorCount = null,
    Object? errors = freezed,
  }) {
    return _then(_$ImportResponseImpl(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      importedCount: null == importedCount
          ? _value.importedCount
          : importedCount // ignore: cast_nullable_to_non_nullable
              as int,
      errorCount: null == errorCount
          ? _value.errorCount
          : errorCount // ignore: cast_nullable_to_non_nullable
              as int,
      errors: freezed == errors
          ? _value._errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ImportResponseImpl implements _ImportResponse {
  const _$ImportResponseImpl(
      {required this.success,
      @JsonKey(name: 'imported_count') required this.importedCount,
      @JsonKey(name: 'error_count') required this.errorCount,
      final List<String>? errors})
      : _errors = errors;

  factory _$ImportResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ImportResponseImplFromJson(json);

  @override
  final bool success;
  @override
  @JsonKey(name: 'imported_count')
  final int importedCount;
  @override
  @JsonKey(name: 'error_count')
  final int errorCount;
  final List<String>? _errors;
  @override
  List<String>? get errors {
    final value = _errors;
    if (value == null) return null;
    if (_errors is EqualUnmodifiableListView) return _errors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'ImportResponse(success: $success, importedCount: $importedCount, errorCount: $errorCount, errors: $errors)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImportResponseImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.importedCount, importedCount) ||
                other.importedCount == importedCount) &&
            (identical(other.errorCount, errorCount) ||
                other.errorCount == errorCount) &&
            const DeepCollectionEquality().equals(other._errors, _errors));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, success, importedCount,
      errorCount, const DeepCollectionEquality().hash(_errors));

  /// Create a copy of ImportResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImportResponseImplCopyWith<_$ImportResponseImpl> get copyWith =>
      __$$ImportResponseImplCopyWithImpl<_$ImportResponseImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ImportResponse value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ImportResponse value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ImportResponse value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ImportResponseImplToJson(
      this,
    );
  }
}

abstract class _ImportResponse implements ImportResponse {
  const factory _ImportResponse(
      {required final bool success,
      @JsonKey(name: 'imported_count') required final int importedCount,
      @JsonKey(name: 'error_count') required final int errorCount,
      final List<String>? errors}) = _$ImportResponseImpl;

  factory _ImportResponse.fromJson(Map<String, dynamic> json) =
      _$ImportResponseImpl.fromJson;

  @override
  bool get success;
  @override
  @JsonKey(name: 'imported_count')
  int get importedCount;
  @override
  @JsonKey(name: 'error_count')
  int get errorCount;
  @override
  List<String>? get errors;

  /// Create a copy of ImportResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImportResponseImplCopyWith<_$ImportResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ModelFieldDefinition _$ModelFieldDefinitionFromJson(Map<String, dynamic> json) {
  return _ModelFieldDefinition.fromJson(json);
}

/// @nodoc
mixin _$ModelFieldDefinition {
  String get name => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  bool get required => throw _privateConstructorUsedError;
  bool get readonly => throw _privateConstructorUsedError;
  String? get helpText => throw _privateConstructorUsedError;
  dynamic get defaultValue => throw _privateConstructorUsedError;
  Map<String, dynamic>? get choices => throw _privateConstructorUsedError;
  Map<String, dynamic>? get validation => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ModelFieldDefinition value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ModelFieldDefinition value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ModelFieldDefinition value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this ModelFieldDefinition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModelFieldDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModelFieldDefinitionCopyWith<ModelFieldDefinition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModelFieldDefinitionCopyWith<$Res> {
  factory $ModelFieldDefinitionCopyWith(ModelFieldDefinition value,
          $Res Function(ModelFieldDefinition) then) =
      _$ModelFieldDefinitionCopyWithImpl<$Res, ModelFieldDefinition>;
  @useResult
  $Res call(
      {String name,
      String type,
      String label,
      bool required,
      bool readonly,
      String? helpText,
      dynamic defaultValue,
      Map<String, dynamic>? choices,
      Map<String, dynamic>? validation});
}

/// @nodoc
class _$ModelFieldDefinitionCopyWithImpl<$Res,
        $Val extends ModelFieldDefinition>
    implements $ModelFieldDefinitionCopyWith<$Res> {
  _$ModelFieldDefinitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModelFieldDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? type = null,
    Object? label = null,
    Object? required = null,
    Object? readonly = null,
    Object? helpText = freezed,
    Object? defaultValue = freezed,
    Object? choices = freezed,
    Object? validation = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      required: null == required
          ? _value.required
          : required // ignore: cast_nullable_to_non_nullable
              as bool,
      readonly: null == readonly
          ? _value.readonly
          : readonly // ignore: cast_nullable_to_non_nullable
              as bool,
      helpText: freezed == helpText
          ? _value.helpText
          : helpText // ignore: cast_nullable_to_non_nullable
              as String?,
      defaultValue: freezed == defaultValue
          ? _value.defaultValue
          : defaultValue // ignore: cast_nullable_to_non_nullable
              as dynamic,
      choices: freezed == choices
          ? _value.choices
          : choices // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      validation: freezed == validation
          ? _value.validation
          : validation // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModelFieldDefinitionImplCopyWith<$Res>
    implements $ModelFieldDefinitionCopyWith<$Res> {
  factory _$$ModelFieldDefinitionImplCopyWith(_$ModelFieldDefinitionImpl value,
          $Res Function(_$ModelFieldDefinitionImpl) then) =
      __$$ModelFieldDefinitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String type,
      String label,
      bool required,
      bool readonly,
      String? helpText,
      dynamic defaultValue,
      Map<String, dynamic>? choices,
      Map<String, dynamic>? validation});
}

/// @nodoc
class __$$ModelFieldDefinitionImplCopyWithImpl<$Res>
    extends _$ModelFieldDefinitionCopyWithImpl<$Res, _$ModelFieldDefinitionImpl>
    implements _$$ModelFieldDefinitionImplCopyWith<$Res> {
  __$$ModelFieldDefinitionImplCopyWithImpl(_$ModelFieldDefinitionImpl _value,
      $Res Function(_$ModelFieldDefinitionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ModelFieldDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? type = null,
    Object? label = null,
    Object? required = null,
    Object? readonly = null,
    Object? helpText = freezed,
    Object? defaultValue = freezed,
    Object? choices = freezed,
    Object? validation = freezed,
  }) {
    return _then(_$ModelFieldDefinitionImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      required: null == required
          ? _value.required
          : required // ignore: cast_nullable_to_non_nullable
              as bool,
      readonly: null == readonly
          ? _value.readonly
          : readonly // ignore: cast_nullable_to_non_nullable
              as bool,
      helpText: freezed == helpText
          ? _value.helpText
          : helpText // ignore: cast_nullable_to_non_nullable
              as String?,
      defaultValue: freezed == defaultValue
          ? _value.defaultValue
          : defaultValue // ignore: cast_nullable_to_non_nullable
              as dynamic,
      choices: freezed == choices
          ? _value._choices
          : choices // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      validation: freezed == validation
          ? _value._validation
          : validation // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ModelFieldDefinitionImpl implements _ModelFieldDefinition {
  const _$ModelFieldDefinitionImpl(
      {required this.name,
      required this.type,
      required this.label,
      this.required = false,
      this.readonly = false,
      this.helpText,
      this.defaultValue,
      final Map<String, dynamic>? choices,
      final Map<String, dynamic>? validation})
      : _choices = choices,
        _validation = validation;

  factory _$ModelFieldDefinitionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModelFieldDefinitionImplFromJson(json);

  @override
  final String name;
  @override
  final String type;
  @override
  final String label;
  @override
  @JsonKey()
  final bool required;
  @override
  @JsonKey()
  final bool readonly;
  @override
  final String? helpText;
  @override
  final dynamic defaultValue;
  final Map<String, dynamic>? _choices;
  @override
  Map<String, dynamic>? get choices {
    final value = _choices;
    if (value == null) return null;
    if (_choices is EqualUnmodifiableMapView) return _choices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final Map<String, dynamic>? _validation;
  @override
  Map<String, dynamic>? get validation {
    final value = _validation;
    if (value == null) return null;
    if (_validation is EqualUnmodifiableMapView) return _validation;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'ModelFieldDefinition(name: $name, type: $type, label: $label, required: $required, readonly: $readonly, helpText: $helpText, defaultValue: $defaultValue, choices: $choices, validation: $validation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModelFieldDefinitionImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.required, required) ||
                other.required == required) &&
            (identical(other.readonly, readonly) ||
                other.readonly == readonly) &&
            (identical(other.helpText, helpText) ||
                other.helpText == helpText) &&
            const DeepCollectionEquality()
                .equals(other.defaultValue, defaultValue) &&
            const DeepCollectionEquality().equals(other._choices, _choices) &&
            const DeepCollectionEquality()
                .equals(other._validation, _validation));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      type,
      label,
      required,
      readonly,
      helpText,
      const DeepCollectionEquality().hash(defaultValue),
      const DeepCollectionEquality().hash(_choices),
      const DeepCollectionEquality().hash(_validation));

  /// Create a copy of ModelFieldDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModelFieldDefinitionImplCopyWith<_$ModelFieldDefinitionImpl>
      get copyWith =>
          __$$ModelFieldDefinitionImplCopyWithImpl<_$ModelFieldDefinitionImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ModelFieldDefinition value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ModelFieldDefinition value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ModelFieldDefinition value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ModelFieldDefinitionImplToJson(
      this,
    );
  }
}

abstract class _ModelFieldDefinition implements ModelFieldDefinition {
  const factory _ModelFieldDefinition(
      {required final String name,
      required final String type,
      required final String label,
      final bool required,
      final bool readonly,
      final String? helpText,
      final dynamic defaultValue,
      final Map<String, dynamic>? choices,
      final Map<String, dynamic>? validation}) = _$ModelFieldDefinitionImpl;

  factory _ModelFieldDefinition.fromJson(Map<String, dynamic> json) =
      _$ModelFieldDefinitionImpl.fromJson;

  @override
  String get name;
  @override
  String get type;
  @override
  String get label;
  @override
  bool get required;
  @override
  bool get readonly;
  @override
  String? get helpText;
  @override
  dynamic get defaultValue;
  @override
  Map<String, dynamic>? get choices;
  @override
  Map<String, dynamic>? get validation;

  /// Create a copy of ModelFieldDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModelFieldDefinitionImplCopyWith<_$ModelFieldDefinitionImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ModelFormDefinition _$ModelFormDefinitionFromJson(Map<String, dynamic> json) {
  return _ModelFormDefinition.fromJson(json);
}

/// @nodoc
mixin _$ModelFormDefinition {
  List<ModelFieldDefinition> get fields => throw _privateConstructorUsedError;
  Map<String, List<String>> get fieldsets => throw _privateConstructorUsedError;
  @JsonKey(name: 'readonly_fields')
  List<String> get readonlyFields => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ModelFormDefinition value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ModelFormDefinition value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ModelFormDefinition value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this ModelFormDefinition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModelFormDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModelFormDefinitionCopyWith<ModelFormDefinition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModelFormDefinitionCopyWith<$Res> {
  factory $ModelFormDefinitionCopyWith(
          ModelFormDefinition value, $Res Function(ModelFormDefinition) then) =
      _$ModelFormDefinitionCopyWithImpl<$Res, ModelFormDefinition>;
  @useResult
  $Res call(
      {List<ModelFieldDefinition> fields,
      Map<String, List<String>> fieldsets,
      @JsonKey(name: 'readonly_fields') List<String> readonlyFields});
}

/// @nodoc
class _$ModelFormDefinitionCopyWithImpl<$Res, $Val extends ModelFormDefinition>
    implements $ModelFormDefinitionCopyWith<$Res> {
  _$ModelFormDefinitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModelFormDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fields = null,
    Object? fieldsets = null,
    Object? readonlyFields = null,
  }) {
    return _then(_value.copyWith(
      fields: null == fields
          ? _value.fields
          : fields // ignore: cast_nullable_to_non_nullable
              as List<ModelFieldDefinition>,
      fieldsets: null == fieldsets
          ? _value.fieldsets
          : fieldsets // ignore: cast_nullable_to_non_nullable
              as Map<String, List<String>>,
      readonlyFields: null == readonlyFields
          ? _value.readonlyFields
          : readonlyFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModelFormDefinitionImplCopyWith<$Res>
    implements $ModelFormDefinitionCopyWith<$Res> {
  factory _$$ModelFormDefinitionImplCopyWith(_$ModelFormDefinitionImpl value,
          $Res Function(_$ModelFormDefinitionImpl) then) =
      __$$ModelFormDefinitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<ModelFieldDefinition> fields,
      Map<String, List<String>> fieldsets,
      @JsonKey(name: 'readonly_fields') List<String> readonlyFields});
}

/// @nodoc
class __$$ModelFormDefinitionImplCopyWithImpl<$Res>
    extends _$ModelFormDefinitionCopyWithImpl<$Res, _$ModelFormDefinitionImpl>
    implements _$$ModelFormDefinitionImplCopyWith<$Res> {
  __$$ModelFormDefinitionImplCopyWithImpl(_$ModelFormDefinitionImpl _value,
      $Res Function(_$ModelFormDefinitionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ModelFormDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fields = null,
    Object? fieldsets = null,
    Object? readonlyFields = null,
  }) {
    return _then(_$ModelFormDefinitionImpl(
      fields: null == fields
          ? _value._fields
          : fields // ignore: cast_nullable_to_non_nullable
              as List<ModelFieldDefinition>,
      fieldsets: null == fieldsets
          ? _value._fieldsets
          : fieldsets // ignore: cast_nullable_to_non_nullable
              as Map<String, List<String>>,
      readonlyFields: null == readonlyFields
          ? _value._readonlyFields
          : readonlyFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ModelFormDefinitionImpl implements _ModelFormDefinition {
  const _$ModelFormDefinitionImpl(
      {required final List<ModelFieldDefinition> fields,
      required final Map<String, List<String>> fieldsets,
      @JsonKey(name: 'readonly_fields')
      required final List<String> readonlyFields})
      : _fields = fields,
        _fieldsets = fieldsets,
        _readonlyFields = readonlyFields;

  factory _$ModelFormDefinitionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModelFormDefinitionImplFromJson(json);

  final List<ModelFieldDefinition> _fields;
  @override
  List<ModelFieldDefinition> get fields {
    if (_fields is EqualUnmodifiableListView) return _fields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_fields);
  }

  final Map<String, List<String>> _fieldsets;
  @override
  Map<String, List<String>> get fieldsets {
    if (_fieldsets is EqualUnmodifiableMapView) return _fieldsets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_fieldsets);
  }

  final List<String> _readonlyFields;
  @override
  @JsonKey(name: 'readonly_fields')
  List<String> get readonlyFields {
    if (_readonlyFields is EqualUnmodifiableListView) return _readonlyFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_readonlyFields);
  }

  @override
  String toString() {
    return 'ModelFormDefinition(fields: $fields, fieldsets: $fieldsets, readonlyFields: $readonlyFields)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModelFormDefinitionImpl &&
            const DeepCollectionEquality().equals(other._fields, _fields) &&
            const DeepCollectionEquality()
                .equals(other._fieldsets, _fieldsets) &&
            const DeepCollectionEquality()
                .equals(other._readonlyFields, _readonlyFields));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_fields),
      const DeepCollectionEquality().hash(_fieldsets),
      const DeepCollectionEquality().hash(_readonlyFields));

  /// Create a copy of ModelFormDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModelFormDefinitionImplCopyWith<_$ModelFormDefinitionImpl> get copyWith =>
      __$$ModelFormDefinitionImplCopyWithImpl<_$ModelFormDefinitionImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ModelFormDefinition value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ModelFormDefinition value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ModelFormDefinition value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ModelFormDefinitionImplToJson(
      this,
    );
  }
}

abstract class _ModelFormDefinition implements ModelFormDefinition {
  const factory _ModelFormDefinition(
      {required final List<ModelFieldDefinition> fields,
      required final Map<String, List<String>> fieldsets,
      @JsonKey(name: 'readonly_fields')
      required final List<String> readonlyFields}) = _$ModelFormDefinitionImpl;

  factory _ModelFormDefinition.fromJson(Map<String, dynamic> json) =
      _$ModelFormDefinitionImpl.fromJson;

  @override
  List<ModelFieldDefinition> get fields;
  @override
  Map<String, List<String>> get fieldsets;
  @override
  @JsonKey(name: 'readonly_fields')
  List<String> get readonlyFields;

  /// Create a copy of ModelFormDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModelFormDefinitionImplCopyWith<_$ModelFormDefinitionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AdminApiError _$AdminApiErrorFromJson(Map<String, dynamic> json) {
  return _AdminApiError.fromJson(json);
}

/// @nodoc
mixin _$AdminApiError {
  String get message => throw _privateConstructorUsedError;
  int get statusCode => throw _privateConstructorUsedError;
  String? get code => throw _privateConstructorUsedError;
  Map<String, dynamic>? get details => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AdminApiError value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AdminApiError value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AdminApiError value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this AdminApiError to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdminApiError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdminApiErrorCopyWith<AdminApiError> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminApiErrorCopyWith<$Res> {
  factory $AdminApiErrorCopyWith(
          AdminApiError value, $Res Function(AdminApiError) then) =
      _$AdminApiErrorCopyWithImpl<$Res, AdminApiError>;
  @useResult
  $Res call(
      {String message,
      int statusCode,
      String? code,
      Map<String, dynamic>? details});
}

/// @nodoc
class _$AdminApiErrorCopyWithImpl<$Res, $Val extends AdminApiError>
    implements $AdminApiErrorCopyWith<$Res> {
  _$AdminApiErrorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdminApiError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? statusCode = null,
    Object? code = freezed,
    Object? details = freezed,
  }) {
    return _then(_value.copyWith(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      statusCode: null == statusCode
          ? _value.statusCode
          : statusCode // ignore: cast_nullable_to_non_nullable
              as int,
      code: freezed == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String?,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdminApiErrorImplCopyWith<$Res>
    implements $AdminApiErrorCopyWith<$Res> {
  factory _$$AdminApiErrorImplCopyWith(
          _$AdminApiErrorImpl value, $Res Function(_$AdminApiErrorImpl) then) =
      __$$AdminApiErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String message,
      int statusCode,
      String? code,
      Map<String, dynamic>? details});
}

/// @nodoc
class __$$AdminApiErrorImplCopyWithImpl<$Res>
    extends _$AdminApiErrorCopyWithImpl<$Res, _$AdminApiErrorImpl>
    implements _$$AdminApiErrorImplCopyWith<$Res> {
  __$$AdminApiErrorImplCopyWithImpl(
      _$AdminApiErrorImpl _value, $Res Function(_$AdminApiErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdminApiError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? statusCode = null,
    Object? code = freezed,
    Object? details = freezed,
  }) {
    return _then(_$AdminApiErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      statusCode: null == statusCode
          ? _value.statusCode
          : statusCode // ignore: cast_nullable_to_non_nullable
              as int,
      code: freezed == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String?,
      details: freezed == details
          ? _value._details
          : details // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminApiErrorImpl implements _AdminApiError {
  const _$AdminApiErrorImpl(
      {required this.message,
      this.statusCode = 500,
      this.code,
      final Map<String, dynamic>? details})
      : _details = details;

  factory _$AdminApiErrorImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminApiErrorImplFromJson(json);

  @override
  final String message;
  @override
  @JsonKey()
  final int statusCode;
  @override
  final String? code;
  final Map<String, dynamic>? _details;
  @override
  Map<String, dynamic>? get details {
    final value = _details;
    if (value == null) return null;
    if (_details is EqualUnmodifiableMapView) return _details;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'AdminApiError(message: $message, statusCode: $statusCode, code: $code, details: $details)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminApiErrorImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.statusCode, statusCode) ||
                other.statusCode == statusCode) &&
            (identical(other.code, code) || other.code == code) &&
            const DeepCollectionEquality().equals(other._details, _details));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, message, statusCode, code,
      const DeepCollectionEquality().hash(_details));

  /// Create a copy of AdminApiError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminApiErrorImplCopyWith<_$AdminApiErrorImpl> get copyWith =>
      __$$AdminApiErrorImplCopyWithImpl<_$AdminApiErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AdminApiError value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AdminApiError value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AdminApiError value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminApiErrorImplToJson(
      this,
    );
  }
}

abstract class _AdminApiError implements AdminApiError {
  const factory _AdminApiError(
      {required final String message,
      final int statusCode,
      final String? code,
      final Map<String, dynamic>? details}) = _$AdminApiErrorImpl;

  factory _AdminApiError.fromJson(Map<String, dynamic> json) =
      _$AdminApiErrorImpl.fromJson;

  @override
  String get message;
  @override
  int get statusCode;
  @override
  String? get code;
  @override
  Map<String, dynamic>? get details;

  /// Create a copy of AdminApiError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdminApiErrorImplCopyWith<_$AdminApiErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
