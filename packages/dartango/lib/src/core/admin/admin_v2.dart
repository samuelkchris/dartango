import 'dart:async';

import '../auth/models_v2.dart' as auth;
import '../database/connection.dart';
import '../forms/fields.dart';
import '../http/request.dart';
import '../http/response.dart';

// Generic admin interface that doesn't depend on Model base class
abstract class BaseAdmin<T> {
  final String modelName;
  final AdminSite adminSite;
  final String? database;

  // Configuration options
  List<String> listDisplay = ['__str__'];
  List<String> listFilter = [];
  List<String> searchFields = [];
  List<String> orderingFields = [];
  List<String> readonlyFields = [];
  List<String> excludeFields = [];
  List<String> fieldsToShow = [];
  Map<String, List<String>> fieldsets = {};

  // Pagination
  int listPerPage = 100;
  int listMaxShowAll = 200;

  // Permissions
  bool hasAddPermission = true;
  bool hasChangePermission = true;
  bool hasDeletePermission = true;
  bool hasViewPermission = true;

  // Actions
  List<AdminAction> actions = [];
  List<String> actionsOnTop = [];
  List<String> actionsOnBottom = [];
  bool actionsSelectionCounter = true;

  BaseAdmin({
    required this.modelName,
    required this.adminSite,
    this.database,
  }) {
    actions.add(AdminAction(
      name: 'delete_selected',
      description: 'Delete selected objects',
      function: deleteSelected,
    ));
  }

  // Abstract methods that must be implemented by subclasses
  Future<List<T>> getQueryset({
    String? search,
    Map<String, dynamic> filters = const {},
    String? ordering,
    int? limit,
    int? offset,
  });

  Future<T?> getObject(dynamic pk);
  Future<T> createObject(Map<String, dynamic> data);
  Future<T> updateObject(T instance, Map<String, dynamic> data);
  Future<void> deleteObject(T instance);

  // Model instance methods
  String getObjectName(T instance) {
    return instance.toString();
  }

  String getObjectUrl(T instance, String action) {
    final appLabel = getAppLabel();
    final pk = _getPrimaryKey(instance);
    return '/admin/$appLabel/$modelName/$pk/$action/';
  }

  String getAppLabel() {
    return 'admin';
  }

  dynamic _getPrimaryKey(T instance) {
    if (instance is auth.User) {
      return (instance as auth.User).id;
    } else if (instance is auth.Group) {
      return (instance as auth.Group).id;
    }
    return 'unknown';
  }

  Future<void> deleteSelected(List<dynamic> objects) async {
    for (final obj in objects) {
      if (obj is T) {
        await deleteObject(obj);
      }
    }
  }

  // Form handling
  AdminModelForm<T> getForm(
      {T? instance, Map<String, dynamic> data = const {}}) {
    return AdminModelForm<T>(
      modelName: modelName,
      instance: instance,
      data: data,
      fieldsToInclude: fieldsToShow.isNotEmpty ? fieldsToShow : null,
      exclude: excludeFields.isNotEmpty ? excludeFields : null,
    );
  }

  Future<bool> saveModel(T instance, AdminModelForm<T> form, bool isNew) async {
    if (await form.isValidAsync()) {
      if (isNew) {
        await createObject(form.cleanedData);
      } else {
        await updateObject(instance, form.cleanedData);
      }
      return true;
    }
    return false;
  }

  // Permission checking
  Future<bool> hasPermission(HttpRequest request, String permission) async {
    final user = _getUserFromRequest(request);
    if (user == null || !user.isAuthenticated) return false;

    final appLabel = getAppLabel();
    final permissionName = '$appLabel.${permission}_$modelName';

    return await user.hasPermission(permissionName);
  }

  auth.User? _getUserFromRequest(HttpRequest request) {
    return request.middlewareState['user'] as auth.User?;
  }

  Future<bool> hasAddPermissionCheck(HttpRequest request) async {
    return hasAddPermission && await hasPermission(request, 'add');
  }

  Future<bool> hasChangePermissionCheck(HttpRequest request) async {
    return hasChangePermission && await hasPermission(request, 'change');
  }

  Future<bool> hasDeletePermissionCheck(HttpRequest request) async {
    return hasDeletePermission && await hasPermission(request, 'delete');
  }

  Future<bool> hasViewPermissionCheck(HttpRequest request) async {
    return hasViewPermission && await hasPermission(request, 'view');
  }

  // View responses
  Future<HttpResponse> changelistView(HttpRequest request) async {
    if (!await hasViewPermissionCheck(request)) {
      return HttpResponse.forbidden('Permission denied');
    }

    final search = request.getQueryParam('q');
    final page = int.tryParse(request.getQueryParam('p') ?? '1') ?? 1;
    final ordering = request.getQueryParam('o');

    // Build filters from request
    final filters = <String, dynamic>{};
    for (final field in listFilter) {
      final value = request.getQueryParam(field);
      if (value != null && value.isNotEmpty) {
        filters[field] = value;
      }
    }

    final offset = (page - 1) * listPerPage;
    final objects = await getQueryset(
      search: search,
      filters: filters,
      ordering: ordering,
      limit: listPerPage,
      offset: offset,
    );

    final context = {
      'objects': objects.map((obj) => getObjectData(obj)).toList(),
      'opts': getModelOptions(),
      'has_add_permission': await hasAddPermissionCheck(request),
      'has_change_permission': await hasChangePermissionCheck(request),
      'has_delete_permission': await hasDeletePermissionCheck(request),
      'list_display': listDisplay,
      'list_filter': listFilter,
      'search_fields': searchFields,
      'actions': actions
          .map((a) => {'name': a.name, 'description': a.description})
          .toList(),
      'page': page,
      'per_page': listPerPage,
    };

    return HttpResponse.json(context);
  }

  Future<HttpResponse> addView(HttpRequest request) async {
    if (!await hasAddPermissionCheck(request)) {
      return HttpResponse.forbidden('Permission denied');
    }

    if (request.method == 'POST') {
      final postData = await request.parsedBody;
      final form = getForm(data: postData);
      if (await form.isValidAsync()) {
        final instance = await createObject(form.cleanedData);
        return HttpResponse.json({
          'success': true,
          'object': getObjectData(instance),
          'redirect': getObjectUrl(instance, 'change'),
        });
      } else {
        return HttpResponse.json({
          'success': false,
          'errors': form.errors,
          'form': form.toJson(),
        });
      }
    }

    final form = getForm();
    return HttpResponse.json({
      'form': form.toJson(),
      'opts': getModelOptions(),
    });
  }

  Future<HttpResponse> changeView(HttpRequest request, dynamic objectId) async {
    if (!await hasChangePermissionCheck(request)) {
      return HttpResponse.forbidden('Permission denied');
    }

    final instance = await getObject(objectId);
    if (instance == null) {
      return HttpResponse.notFound('Object not found');
    }

    if (request.method == 'POST') {
      final postData = await request.parsedBody;
      final form = getForm(instance: instance, data: postData);
      if (await saveModel(instance, form, false)) {
        return HttpResponse.json({
          'success': true,
          'object': getObjectData(instance),
        });
      } else {
        return HttpResponse.json({
          'success': false,
          'errors': form.errors,
          'form': form.toJson(),
        });
      }
    }

    final form = getForm(instance: instance);
    return HttpResponse.json({
      'form': form.toJson(),
      'object': getObjectData(instance),
      'opts': getModelOptions(),
    });
  }

  Future<HttpResponse> deleteView(HttpRequest request, dynamic objectId) async {
    if (!await hasDeletePermissionCheck(request)) {
      return HttpResponse.forbidden('Permission denied');
    }

    final instance = await getObject(objectId);
    if (instance == null) {
      return HttpResponse.notFound('Object not found');
    }

    if (request.method == 'POST') {
      await deleteObject(instance);
      return HttpResponse.json({
        'success': true,
        'redirect': getChangelistUrl(),
      });
    }

    return HttpResponse.json({
      'object': getObjectData(instance),
      'opts': getModelOptions(),
    });
  }

  // Utility methods
  Map<String, dynamic> getModelOptions() {
    return {
      'model_name': modelName,
      'verbose_name': getVerboseName(),
      'verbose_name_plural': getVerboseNamePlural(),
      'app_label': getAppLabel(),
    };
  }

  String getVerboseName() {
    return modelName.substring(0, 1).toUpperCase() + modelName.substring(1);
  }

  String getVerboseNamePlural() {
    final name = getVerboseName();
    return name.endsWith('s') ? name : '${name}s';
  }

  String getChangelistUrl() {
    final appLabel = getAppLabel();
    return '/admin/$appLabel/$modelName/';
  }

  Map<String, dynamic> getObjectData(T instance) {
    final Map<String, dynamic> data = {};

    data['pk'] = _getPrimaryKey(instance);
    data['str'] = getObjectName(instance);

    // Try to get JSON representation
    try {
      if (instance is auth.User) {
        data['fields'] = (instance as auth.User).toJson();
      } else if (instance is auth.Group) {
        data['fields'] = {
          'id': (instance as auth.Group).id,
          'name': (instance as auth.Group).name
        };
      } else {
        data['fields'] = {};
      }
    } catch (e) {
      data['fields'] = {};
    }

    return data;
  }
}

class AdminSite {
  final String name;
  final String adminUrl;
  final Map<String, BaseAdmin> _registry = {};

  // Site-wide configuration
  String siteHeader = 'Dartango Administration';
  String siteTitle = 'Dartango Admin';
  String indexTitle = 'Site Administration';
  bool enableNavSidebar = true;

  AdminSite({
    this.name = 'admin',
    this.adminUrl = '/admin/',
  });

  // Model registration
  void register<T>(String modelName, BaseAdmin<T> adminClass) {
    _registry[modelName] = adminClass;
  }

  void unregister(String modelName) {
    _registry.remove(modelName);
  }

  bool isRegistered(String modelName) {
    return _registry.containsKey(modelName);
  }

  BaseAdmin? getModelAdmin(String modelName) {
    return _registry[modelName];
  }

  List<BaseAdmin> getAllModelAdmins() {
    return _registry.values.toList();
  }

  // Permission checking
  Future<bool> hasPermission(HttpRequest request) async {
    final user = _getUserFromRequest(request);
    return user != null && user.isAuthenticated && user.isStaff;
  }

  auth.User? _getUserFromRequest(HttpRequest request) {
    return request.middlewareState['user'] as auth.User?;
  }

  // Views
  Future<HttpResponse> indexView(HttpRequest request) async {
    if (!await hasPermission(request)) {
      return HttpResponse.redirect('/admin/login/');
    }

    final appList = await getAppList(request);
    return HttpResponse.json({
      'title': indexTitle,
      'app_list': appList,
      'site_header': siteHeader,
      'site_title': siteTitle,
    });
  }

  Future<HttpResponse> loginView(HttpRequest request) async {
    if (request.method == 'POST') {
      final postData = await request.parsedBody;
      final username = postData['username'];
      final password = postData['password'];

      if (username != null && password != null) {
        final user = await auth.User.getUserByUsername(username);
        if (user != null && user.checkPassword(password) && user.isStaff) {
          await user.updateLastLogin();
          return HttpResponse.json({
            'success': true,
            'redirect': adminUrl,
          });
        }
      }

      return HttpResponse.json({
        'success': false,
        'error': 'Invalid username or password',
      });
    }

    return HttpResponse.json({
      'title': 'Log in',
      'site_header': siteHeader,
    });
  }

  Future<HttpResponse> logoutView(HttpRequest request) async {
    return HttpResponse.json({
      'success': true,
      'redirect': '/admin/login/',
    });
  }

  // App and model listing
  Future<List<Map<String, dynamic>>> getAppList(HttpRequest request) async {
    final appDict = <String, Map<String, dynamic>>{};

    for (final entry in _registry.entries) {
      final modelName = entry.key;
      final modelAdmin = entry.value;

      final appLabel = modelAdmin.getAppLabel();
      if (!appDict.containsKey(appLabel)) {
        appDict[appLabel] = {
          'name': appLabel,
          'app_label': appLabel,
          'models': <Map<String, dynamic>>[],
        };
      }

      final hasViewPerm = await modelAdmin.hasViewPermissionCheck(request);
      final hasAddPerm = await modelAdmin.hasAddPermissionCheck(request);
      final hasChangePerm = await modelAdmin.hasChangePermissionCheck(request);
      final hasDeletePerm = await modelAdmin.hasDeletePermissionCheck(request);

      if (hasViewPerm) {
        final modelDict = {
          'name': modelAdmin.getVerboseName(),
          'object_name': modelName,
          'perms': {
            'add': hasAddPerm,
            'change': hasChangePerm,
            'delete': hasDeletePerm,
            'view': hasViewPerm,
          },
          'admin_url': modelAdmin.getChangelistUrl(),
          'add_url': '${modelAdmin.getChangelistUrl()}add/',
        };

        appDict[appLabel]!['models'].add(modelDict);
      }
    }

    return appDict.values.toList();
  }

  // URL routing
  Future<HttpResponse> handleRequest(HttpRequest request) async {
    final path = request.path;

    if (path == adminUrl || path == '${adminUrl}index/') {
      return await indexView(request);
    }

    if (path == '${adminUrl}login/') {
      return await loginView(request);
    }

    if (path == '${adminUrl}logout/') {
      return await logoutView(request);
    }

    // Handle model-specific URLs
    final modelUrlPattern = RegExp(r'^/admin/(\\w+)/(\\w+)/(.*)$');
    final match = modelUrlPattern.firstMatch(path);

    if (match != null) {
      final appLabel = match.group(1)!;
      final modelName = match.group(2)!;
      final action = match.group(3)!;

      final modelAdmin = getModelAdmin(modelName);
      if (modelAdmin != null) {
        return await _handleModelRequest(modelAdmin, request, action);
      }
    }

    return HttpResponse.notFound('Page not found');
  }

  Future<HttpResponse> _handleModelRequest(
    BaseAdmin modelAdmin,
    HttpRequest request,
    String action,
  ) async {
    if (action.isEmpty || action == 'changelist/') {
      return await modelAdmin.changelistView(request);
    }

    if (action == 'add/') {
      return await modelAdmin.addView(request);
    }

    // Pattern for change/delete views with object ID
    final objectActionPattern = RegExp(r'^(\\d+)/(change|delete)/?$');
    final match = objectActionPattern.firstMatch(action);

    if (match != null) {
      final objectId = int.parse(match.group(1)!);
      final actionType = match.group(2)!;

      if (actionType == 'change') {
        return await modelAdmin.changeView(request, objectId);
      } else if (actionType == 'delete') {
        return await modelAdmin.deleteView(request, objectId);
      }
    }

    return HttpResponse.notFound('Action not found');
  }
}

class AdminAction {
  final String name;
  final String description;
  final Future<void> Function(List<dynamic>) function;
  final bool requiresConfirmation;

  AdminAction({
    required this.name,
    required this.description,
    required this.function,
    this.requiresConfirmation = true,
  });
}

class AdminModelForm<T> {
  final String modelName;
  final T? instance;
  final List<String>? fieldsToInclude;
  final List<String>? exclude;
  final Map<String, dynamic> data;
  final Map<String, dynamic> initial;
  final String? prefix;

  final Map<String, FormField> fields = {};
  final Map<String, List<String>> errors = {};
  final Map<String, dynamic> cleanedData = {};

  AdminModelForm({
    required this.modelName,
    this.instance,
    this.fieldsToInclude,
    this.exclude,
    this.data = const {},
    this.initial = const {},
    this.prefix,
  }) {
    _initializeFields();
  }

  void _initializeFields() {
    // Add basic fields for User model
    if (modelName == 'user') {
      fields['username'] =
          CharField(name: 'username', label: 'Username', maxLength: 150);
      fields['email'] = EmailField(name: 'email', label: 'Email');
      fields['first_name'] = CharField(
          name: 'first_name',
          label: 'First name',
          required: false,
          maxLength: 150);
      fields['last_name'] = CharField(
          name: 'last_name',
          label: 'Last name',
          required: false,
          maxLength: 150);
      fields['password'] = PasswordField(name: 'password', label: 'Password');
      fields['is_active'] =
          BooleanField(name: 'is_active', label: 'Active', initialValue: true);
      fields['is_staff'] = BooleanField(
          name: 'is_staff', label: 'Staff status', initialValue: false);
      fields['is_superuser'] = BooleanField(
          name: 'is_superuser', label: 'Superuser status', initialValue: false);
    } else if (modelName == 'group') {
      fields['name'] = CharField(name: 'name', label: 'Name', maxLength: 150);
    }
  }

  Future<bool> isValidAsync() async {
    errors.clear();
    cleanedData.clear();

    bool isValid = true;

    // Clean and validate each field
    for (final entry in fields.entries) {
      final fieldName = entry.key;
      final field = entry.value;

      try {
        final rawValue = data[fieldName];
        final cleanedValue = field.clean(rawValue);

        // Validate cleaned value
        await field.validate(cleanedValue);

        cleanedData[fieldName] = cleanedValue;
      } catch (e) {
        final errorMessage = e is ValidationError ? e.message : e.toString();
        errors.putIfAbsent(fieldName, () => []).add(errorMessage);
        isValid = false;
      }
    }

    return isValid;
  }

  Map<String, dynamic> toJson() {
    return {
      'fields': fields.map((key, value) => MapEntry(key, value.toJson())),
      'errors': errors,
      'data': data,
    };
  }
}

// Built-in admin classes
class UserAdmin extends BaseAdmin<auth.User> {
  UserAdmin({required super.adminSite, super.database})
      : super(modelName: 'user') {
    listDisplay = [
      'username',
      'email',
      'first_name',
      'last_name',
      'is_staff',
      'is_active'
    ];
    listFilter = ['is_staff', 'is_superuser', 'is_active'];
    searchFields = ['username', 'first_name', 'last_name', 'email'];
    orderingFields = ['username', 'email', 'first_name', 'last_name'];

    fieldsets = {
      'Personal info': ['first_name', 'last_name', 'email'],
      'Permissions': ['is_active', 'is_staff', 'is_superuser'],
      'Important dates': ['last_login', 'date_joined'],
    };
  }

  @override
  Future<List<auth.User>> getQueryset({
    String? search,
    Map<String, dynamic> filters = const {},
    String? ordering,
    int? limit,
    int? offset,
  }) async {
    final connection = await DatabaseRouter.getConnection(database);
    try {
      var sql = 'SELECT * FROM auth_users';
      final whereConditions = <String>[];
      final parameters = <dynamic>[];

      // Add search functionality
      if (search != null && search.isNotEmpty) {
        whereConditions.add(
            '(username LIKE ? OR email LIKE ? OR first_name LIKE ? OR last_name LIKE ?)');
        final searchTerm = '%$search%';
        parameters.addAll([searchTerm, searchTerm, searchTerm, searchTerm]);
      }

      // Add filters
      for (final entry in filters.entries) {
        whereConditions.add('${entry.key} = ?');
        parameters.add(entry.value);
      }

      if (whereConditions.isNotEmpty) {
        sql += ' WHERE ${whereConditions.join(' AND ')}';
      }

      // Add ordering
      if (ordering != null) {
        sql += ' ORDER BY $ordering';
      }

      // Add pagination
      if (limit != null) {
        sql += ' LIMIT $limit';
        if (offset != null) {
          sql += ' OFFSET $offset';
        }
      }

      final result = await connection.query(sql, parameters);
      return result
          .map((row) => auth.User.fromMap(row, database: database))
          .toList();
    } finally {
      await DatabaseRouter.releaseConnection(connection, database);
    }
  }

  @override
  Future<auth.User?> getObject(dynamic pk) async {
    return await auth.User.getUserById(pk as int, database: database);
  }

  @override
  Future<auth.User> createObject(Map<String, dynamic> data) async {
    return await auth.User.createUser(
      username: data['username'],
      email: data['email'],
      password: data['password'],
      firstName: data['first_name'],
      lastName: data['last_name'],
      isActive: data['is_active'] ?? true,
      isStaff: data['is_staff'] ?? false,
      isSuperuser: data['is_superuser'] ?? false,
      database: database,
    );
  }

  @override
  Future<auth.User> updateObject(
      auth.User instance, Map<String, dynamic> data) async {
    instance.username = data['username'] ?? instance.username;
    instance.email = data['email'] ?? instance.email;
    instance.firstName = data['first_name'] ?? instance.firstName;
    instance.lastName = data['last_name'] ?? instance.lastName;
    instance.isActive = data['is_active'] ?? instance.isActive;
    instance.isStaff = data['is_staff'] ?? instance.isStaff;
    instance.isSuperuser = data['is_superuser'] ?? instance.isSuperuser;

    if (data['password'] != null && (data['password'] as String).isNotEmpty) {
      instance.setPassword(data['password']);
    }

    await instance.save();
    return instance;
  }

  @override
  Future<void> deleteObject(auth.User instance) async {
    await instance.delete();
  }
}

class GroupAdmin extends BaseAdmin<auth.Group> {
  GroupAdmin({required super.adminSite, super.database})
      : super(modelName: 'group') {
    listDisplay = ['name'];
    searchFields = ['name'];
    orderingFields = ['name'];
  }

  @override
  Future<List<auth.Group>> getQueryset({
    String? search,
    Map<String, dynamic> filters = const {},
    String? ordering,
    int? limit,
    int? offset,
  }) async {
    final connection = await DatabaseRouter.getConnection(database);
    try {
      var sql = 'SELECT * FROM auth_groups';
      final whereConditions = <String>[];
      final parameters = <dynamic>[];

      // Add search functionality
      if (search != null && search.isNotEmpty) {
        whereConditions.add('name LIKE ?');
        parameters.add('%$search%');
      }

      // Add filters
      for (final entry in filters.entries) {
        whereConditions.add('${entry.key} = ?');
        parameters.add(entry.value);
      }

      if (whereConditions.isNotEmpty) {
        sql += ' WHERE ${whereConditions.join(' AND ')}';
      }

      // Add ordering
      if (ordering != null) {
        sql += ' ORDER BY $ordering';
      }

      // Add pagination
      if (limit != null) {
        sql += ' LIMIT $limit';
        if (offset != null) {
          sql += ' OFFSET $offset';
        }
      }

      final result = await connection.query(sql, parameters);
      return result
          .map((row) => auth.Group.fromMap(row, database: database))
          .toList();
    } finally {
      await DatabaseRouter.releaseConnection(connection, database);
    }
  }

  @override
  Future<auth.Group?> getObject(dynamic pk) async {
    if (pk is int) {
      final connection = await DatabaseRouter.getConnection(database);
      try {
        final result = await connection
            .query('SELECT * FROM auth_groups WHERE id = ?', [pk]);
        if (result.isEmpty) return null;
        return auth.Group.fromMap(result.first, database: database);
      } finally {
        await DatabaseRouter.releaseConnection(connection, database);
      }
    } else {
      return await auth.Group.getGroupByName(pk.toString(), database: database);
    }
  }

  @override
  Future<auth.Group> createObject(Map<String, dynamic> data) async {
    return await auth.Group.createGroup(data['name'], database: database);
  }

  @override
  Future<auth.Group> updateObject(
      auth.Group instance, Map<String, dynamic> data) async {
    instance.name = data['name'] ?? instance.name;
    await instance.save();
    return instance;
  }

  @override
  Future<void> deleteObject(auth.Group instance) async {
    final connection = await DatabaseRouter.getConnection(database);
    try {
      await connection
          .execute('DELETE FROM auth_groups WHERE id = ?', [instance.id]);
    } finally {
      await DatabaseRouter.releaseConnection(connection, database);
    }
  }
}

// Default admin site instance
final AdminSite adminSite = AdminSite();

// Auto-register built-in models
void setupDefaultAdmin({String? database}) {
  adminSite.register<auth.User>(
      'user', UserAdmin(adminSite: adminSite, database: database));
  adminSite.register<auth.Group>(
      'group', GroupAdmin(adminSite: adminSite, database: database));
}
