import 'dart:async';
import '../auth/models.dart' as auth;
import '../database/connection.dart';
import '../database/models.dart';
import '../forms/forms.dart';
import '../http/request.dart';
import '../http/response.dart';

abstract class ModelAdmin<T extends Model> {
  final Type modelType;
  final AdminSite adminSite;

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

  ModelAdmin({
    required this.modelType,
    required this.adminSite,
  }) {
    actions.add(AdminAction(
      name: 'delete_selected',
      description: 'Delete selected objects',
      function: (List<Model> objects) => deleteSelected(objects.cast<T>()),
    ));
  }

  // Model instance methods
  String getObjectName(T instance) {
    return instance.toString();
  }

  String getObjectUrl(T instance, String action) {
    final modelName = modelType.toString().toLowerCase();
    final appLabel = getAppLabel();
    return '/admin/$appLabel/$modelName/${instance.pk}/$action/';
  }

  String getAppLabel() {
    // Extract app label from model type or use default
    return 'admin';
  }

  // CRUD operations
  Future<List<T>> getQueryset({
    String? search,
    Map<String, dynamic> filters = const {},
    String? ordering,
    int? limit,
    int? offset,
  }) async {
    // Default implementation - override in subclasses for custom behavior
    return [];
  }

  Future<T?> getObject(dynamic pk) async {
    // Default implementation - override in subclasses for custom behavior
    return null;
  }

  Future<T> createObject(Map<String, dynamic> data) async {
    final connection = await DatabaseRouter.getConnection();
    try {
      final instance = await _createModelInstance(data);
      await instance.save();
      return instance;
    } catch (e) {
      throw Exception('Failed to create object: $e');
    } finally {
      await DatabaseRouter.releaseConnection(connection);
    }
  }

  Future<T> updateObject(T instance, Map<String, dynamic> data) async {
    try {
      _updateModelFields(instance, data);
      await instance.save();
      return instance;
    } catch (e) {
      throw Exception('Failed to update object: $e');
    }
  }

  Future<void> deleteObject(T instance) async {
    try {
      await instance.delete();
    } catch (e) {
      throw Exception('Failed to delete object: $e');
    }
  }

  Future<T> _createModelInstance(Map<String, dynamic> data) async {
    throw UnimplementedError(
        'Subclasses must override createObject() or _createModelInstance() for model $modelType. '
        'Implement a factory method that creates an instance from the provided data map.');
  }

  void _updateModelFields(T instance, Map<String, dynamic> data) {
    for (final entry in data.entries) {
      final fieldName = _snakeToCamel(entry.key);
      try {
        instance.setField(fieldName, entry.value);
      } catch (e) {
        continue;
      }
    }
  }

  String _snakeToCamel(String snakeCase) {
    final parts = snakeCase.split('_');
    if (parts.isEmpty) return snakeCase;
    return parts.first +
        parts.skip(1).map((part) => part[0].toUpperCase() + part.substring(1)).join();
  }

  Future<void> deleteSelected(List<T> objects) async {
    for (final obj in objects) {
      await deleteObject(obj);
    }
  }

  // Form handling
  Form getForm({T? instance, Map<String, dynamic> data = const {}}) {
    return AdminModelForm<T>(
      modelType: modelType,
      instance: instance,
      data: data,
      fieldsToInclude: fieldsToShow.isNotEmpty ? fieldsToShow : null,
      exclude: excludeFields.isNotEmpty ? excludeFields : null,
    );
  }

  Future<bool> saveModel(T instance, Form form, bool isNew) async {
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
    final modelName = modelType.toString().toLowerCase();
    final permissionName = '$appLabel.${permission}_$modelName';

    return await user.hasPermission(permissionName);
  }

  auth.User? _getUserFromRequest(HttpRequest request) {
    // Get user from request context/session
    // This would typically be set by authentication middleware
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
      'objects': objects,
      'opts': getModelOptions(),
      'has_add_permission': await hasAddPermissionCheck(request),
      'has_change_permission': await hasChangePermissionCheck(request),
      'has_delete_permission': await hasDeletePermissionCheck(request),
      'list_display': listDisplay,
      'list_filter': listFilter,
      'search_fields': searchFields,
      'actions': actions,
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
      'model_name': modelType.toString().toLowerCase(),
      'verbose_name': getVerboseName(),
      'verbose_name_plural': getVerboseNamePlural(),
      'app_label': getAppLabel(),
    };
  }

  String getVerboseName() {
    return modelType.toString();
  }

  String getVerboseNamePlural() {
    final name = getVerboseName();
    return name.endsWith('s') ? name : '${name}s';
  }

  String getChangelistUrl() {
    final modelName = modelType.toString().toLowerCase();
    final appLabel = getAppLabel();
    return '/admin/$appLabel/$modelName/';
  }

  Map<String, dynamic> getObjectData(T instance) {
    // Convert model instance to JSON for API
    return {
      'pk': instance.pk,
      'str': getObjectName(instance),
      'fields': instance.toJson(),
    };
  }
}

class AdminSite {
  final String name;
  final String adminUrl;
  final Map<Type, ModelAdmin> _registry = {};

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
  void register<T extends Model>(Type modelType, ModelAdmin<T> adminClass) {
    _registry[modelType] = adminClass;
  }

  void unregister(Type modelType) {
    _registry.remove(modelType);
  }

  bool isRegistered(Type modelType) {
    return _registry.containsKey(modelType);
  }

  ModelAdmin? getModelAdmin(Type modelType) {
    return _registry[modelType];
  }

  List<ModelAdmin> getAllModelAdmins() {
    return _registry.values.toList();
  }

  Map<Type, ModelAdmin> get registry => _registry;

  // Permission checking
  Future<bool> hasPermission(HttpRequest request) async {
    final user = _getUserFromRequest(request);
    return user != null && user.isAuthenticated && user.isStaff;
  }

  auth.User? _getUserFromRequest(HttpRequest request) {
    // Get user from request context/session
    // This would typically be set by authentication middleware
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
          // Set user session
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
    // Clear user session
    return HttpResponse.json({
      'success': true,
      'redirect': '/admin/login/',
    });
  }

  // App and model listing
  Future<List<Map<String, dynamic>>> getAppList(HttpRequest request) async {
    final appDict = <String, Map<String, dynamic>>{};

    for (final entry in _registry.entries) {
      final modelType = entry.key;
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
          'object_name': modelType.toString(),
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
    final modelUrlPattern = RegExp(r'^/admin/(\w+)/(\w+)/(.*)$');
    final match = modelUrlPattern.firstMatch(path);

    if (match != null) {
      final appLabel = match.group(1)!;
      final modelName = match.group(2)!;
      final action = match.group(3)!;
      
      return await handleModelRequest(request, appLabel, modelName, action);
    }

    return HttpResponse.notFound('Page not found');
  }
  
  Future<HttpResponse> handleModelRequest(HttpRequest request, String appLabel, String modelName, String action) async {
    final modelAdmin = getModelAdminByName(appLabel, modelName);
    if (modelAdmin == null) {
      return HttpResponse.notFound('Model not found');
    }
    
    // Handle different actions
    switch (action) {
      case '':
      case 'changelist/':
        return await modelAdmin.changelistView(request);
      case 'add/':
        return await modelAdmin.addView(request);
      default:
        if (action.endsWith('/change/')) {
          final pk = action.split('/').first;
          return await modelAdmin.changeView(request, pk);
        } else if (action.endsWith('/delete/')) {
          final pk = action.split('/').first;
          return await modelAdmin.deleteView(request, pk);
        }
        return HttpResponse.notFound('Action not found');
    }
  }
  
  ModelAdmin? getModelAdminByName(String appLabel, String modelName) {
    for (final entry in _registry.entries) {
      final modelAdmin = entry.value;
      if (modelAdmin.getAppLabel() == appLabel && 
          entry.key.toString().toLowerCase() == modelName.toLowerCase()) {
        return modelAdmin;
      }
    }
    return null;
  }
}

class AdminAction {
  final String name;
  final String description;
  final Future<void> Function(List<Model>) function;
  final bool requiresConfirmation;

  AdminAction({
    required this.name,
    required this.description,
    required this.function,
    this.requiresConfirmation = true,
  });
}

class AdminModelForm<T> extends ModelForm<T> {
  AdminModelForm({
    required super.modelType,
    super.instance,
    super.fieldsToInclude,
    super.exclude,
    super.data,
    super.initial,
    super.prefix,
  });

}

// Default admin site instance
final AdminSite adminSite = AdminSite();

// Built-in admin classes
class UserAdmin extends ModelAdmin<auth.User> {
  final String? _database;

  UserAdmin({required super.adminSite, String? database})
      : _database = database,
        super(modelType: auth.User) {
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
    // Get database connection
    final connection = await DatabaseRouter.getConnection(_database);
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
          .map((row) => auth.User.fromMap(row, database: _database))
          .toList();
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  @override
  Future<auth.User?> getObject(dynamic pk) async {
    return await auth.User.getUserById(pk as int);
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

class GroupAdmin extends ModelAdmin<auth.Group> {
  final String? _database;

  GroupAdmin({required super.adminSite, String? database})
      : _database = database,
        super(modelType: auth.Group) {
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
    // Get database connection
    final connection = await DatabaseRouter.getConnection(_database);
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
          .map((row) => auth.Group.fromMap(row))
          .toList();
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }

  @override
  Future<auth.Group?> getObject(dynamic pk) async {
    if (pk is int) {
      // Get by ID
      final connection = await DatabaseRouter.getConnection(_database);
      try {
        final result = await connection
            .query('SELECT * FROM auth_groups WHERE id = ?', [pk]);
        if (result.isEmpty) return null;
        return auth.Group.fromMap(result.first);
      } finally {
        await DatabaseRouter.releaseConnection(connection, _database);
      }
    } else {
      // Get by name (legacy support)
      return await auth.Group.getGroupByName(pk.toString());
    }
  }

  @override
  Future<auth.Group> createObject(Map<String, dynamic> data) async {
    return await auth.Group.createGroup(data['name']);
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
    // Delete group from database
    final connection = await DatabaseRouter.getConnection(_database);
    try {
      await connection
          .execute('DELETE FROM auth_groups WHERE id = ?', [instance.id]);
    } finally {
      await DatabaseRouter.releaseConnection(connection, _database);
    }
  }
}

// Auto-register built-in models
void setupDefaultAdmin({String? database}) {
  adminSite.register<auth.User>(
      auth.User, UserAdmin(adminSite: adminSite, database: database));
  adminSite.register<auth.Group>(
      auth.Group, GroupAdmin(adminSite: adminSite, database: database));
}
