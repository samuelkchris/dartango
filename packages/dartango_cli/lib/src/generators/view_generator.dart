import 'dart:io';
import 'package:path/path.dart' as path;

class ViewGenerator {
  final String name;
  final String app;
  final String outputPath;
  final bool force;

  ViewGenerator({
    required this.name,
    required this.app,
    required this.outputPath,
    this.force = false,
  });

  Future<void> generate() async {
    final viewsDir = Directory(outputPath);
    await viewsDir.create(recursive: true);

    final viewFileName = '${_toSnakeCase(name)}.dart';
    final viewFile = File(path.join(viewsDir.path, viewFileName));

    if (await viewFile.exists() && !force) {
      throw Exception('View file already exists: ${viewFile.path}');
    }

    final viewContent = _generateViewContent();
    await viewFile.writeAsString(viewContent);

    // Generate corresponding template
    await _generateTemplate();
  }

  String _generateViewContent() {
    final className = _toPascalCase(name);
    final templateName = '${app}/${_toSnakeCase(name)}.html';

    return '''
import 'package:dartango/dartango.dart';

// Function-based view
Future<HttpResponse> ${_toCamelCase(name)}(HttpRequest request) async {
  final context = {
    'title': '${_toTitleCase(name)}',
    'app_name': '$app',
    'timestamp': DateTime.now().toIso8601String(),
  };
  
  return TemplateResponse(request, '$templateName', context);
}

// Class-based view
class $className extends TemplateView {
  @override
  String get templateName => '$templateName';
  
  @override
  Future<HttpResponse> get(HttpRequest request) async {
    final context = await getContextData();
    return TemplateResponse(request, templateName, context);
  }
  
  @override
  Map<String, dynamic> getContextData() {
    return {
      'title': '${_toTitleCase(name)}',
      'app_name': '$app',
      'view_name': '$name',
      'timestamp': DateTime.now().toIso8601String(),
      ...super.getContextData(),
    };
  }
}

// API view variant
class ${className}ApiView extends View {
  @override
  Future<HttpResponse> get(HttpRequest request) async {
    final data = {
      'message': 'Hello from ${_toTitleCase(name)} API',
      'app': '$app',
      'view': '$name',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    return JsonResponse(data);
  }
  
  @override
  Future<HttpResponse> post(HttpRequest request) async {
    final body = await request.json();
    
    // Process the request data
    final result = await _processData(body);
    
    return JsonResponse({
      'success': true,
      'data': result,
      'message': 'Data processed successfully',
    });
  }
  
  Future<Map<String, dynamic>> _processData(Map<String, dynamic> data) async {
    // Implement your data processing logic here
    return {
      'processed_at': DateTime.now().toIso8601String(),
      'input': data,
    };
  }
}

// List view for displaying multiple items
class ${className}ListView extends ListView {
  @override
  String get templateName => '${app}/${_toSnakeCase(name)}_list.html';
  
  @override
  Future<QuerySet> getQuerySet() async {
    // Return your model queryset here
    // Example: return YourModel.objects.all();
    return Future.value(QuerySet([]));
  }
  
  @override
  Map<String, dynamic> getContextData() {
    return {
      'title': '${_toTitleCase(name)} List',
      'app_name': '$app',
      ...super.getContextData(),
    };
  }
}

// Detail view for displaying single item
class ${className}DetailView extends DetailView {
  @override
  String get templateName => '${app}/${_toSnakeCase(name)}_detail.html';
  
  @override
  Map<String, dynamic> getContextData() {
    return {
      'title': '${_toTitleCase(name)} Detail',
      'app_name': '$app',
      ...super.getContextData(),
    };
  }
}

// Create view for creating new items
class ${className}CreateView extends CreateView {
  @override
  String get templateName => '${app}/${_toSnakeCase(name)}_form.html';
  
  @override
  String get successUrl => '/$app/${_toSnakeCase(name)}/';
  
  @override
  Map<String, dynamic> getContextData() {
    return {
      'title': 'Create ${_toTitleCase(name)}',
      'app_name': '$app',
      'form_action': 'create',
      ...super.getContextData(),
    };
  }
}

// Update view for editing existing items
class ${className}UpdateView extends UpdateView {
  @override
  String get templateName => '${app}/${_toSnakeCase(name)}_form.html';
  
  @override
  String get successUrl => '/$app/${_toSnakeCase(name)}/';
  
  @override
  Map<String, dynamic> getContextData() {
    return {
      'title': 'Update ${_toTitleCase(name)}',
      'app_name': '$app',
      'form_action': 'update',
      ...super.getContextData(),
    };
  }
}

// Delete view for removing items
class ${className}DeleteView extends DeleteView {
  @override
  String get templateName => '${app}/${_toSnakeCase(name)}_confirm_delete.html';
  
  @override
  String get successUrl => '/$app/${_toSnakeCase(name)}/';
  
  @override
  Map<String, dynamic> getContextData() {
    return {
      'title': 'Delete ${_toTitleCase(name)}',
      'app_name': '$app',
      ...super.getContextData(),
    };
  }
}

// Custom mixin for additional functionality
mixin ${className}Mixin {
  Future<bool> hasPermission(HttpRequest request) async {
    // Implement your permission logic here
    return true;
  }
  
  Future<void> logAccess(HttpRequest request) async {
    // Implement your logging logic here
    print('Access to ${_toTitleCase(name)} by \${request.remoteAddr}');
  }
}

// View with custom permissions
class ${className}PermissionView extends TemplateView with ${className}Mixin {
  @override
  String get templateName => '$templateName';
  
  @override
  Future<HttpResponse> dispatch(HttpRequest request) async {
    if (!await hasPermission(request)) {
      return HttpResponse.forbidden('Permission denied');
    }
    
    await logAccess(request);
    return super.dispatch(request);
  }
  
  @override
  Map<String, dynamic> getContextData() {
    return {
      'title': '${_toTitleCase(name)} (Protected)',
      'app_name': '$app',
      ...super.getContextData(),
    };
  }
}
''';
  }

  Future<void> _generateTemplate() async {
    final templatesDir =
        Directory(path.join(outputPath, '..', 'templates', app));
    await templatesDir.create(recursive: true);

    final templateFileName = '${_toSnakeCase(name)}.html';
    final templateFile = File(path.join(templatesDir.path, templateFileName));

    if (await templateFile.exists() && !force) {
      return; // Don't overwrite existing templates
    }

    final templateContent = _generateTemplateContent();
    await templateFile.writeAsString(templateContent);

    // Generate additional template variants
    await _generateListTemplate(templatesDir);
    await _generateDetailTemplate(templatesDir);
    await _generateFormTemplate(templatesDir);
    await _generateDeleteTemplate(templatesDir);
  }

  String _generateTemplateContent() {
    return '''
{% extends "base.html" %}

{% block title %}{{ title }}{% endblock %}

{% block content %}
<div class="container">
    <div class="header">
        <h1>{{ title }}</h1>
        <p class="subtitle">Welcome to the ${_toTitleCase(name)} view</p>
    </div>
    
    <div class="content">
        <div class="info-card">
            <h3>View Information</h3>
            <ul>
                <li><strong>App:</strong> {{ app_name }}</li>
                <li><strong>View:</strong> {{ view_name }}</li>
                <li><strong>Generated:</strong> {{ timestamp }}</li>
            </ul>
        </div>
        
        <div class="actions">
            <a href="/" class="btn btn-secondary">Home</a>
            <a href="/{{ app_name }}/" class="btn btn-primary">{{ app_name|title }} Home</a>
        </div>
    </div>
</div>

<style>
    .container {
        max-width: 800px;
        margin: 0 auto;
        padding: 2rem;
    }
    
    .header {
        text-align: center;
        margin-bottom: 2rem;
    }
    
    .header h1 {
        color: #333;
        margin-bottom: 0.5rem;
    }
    
    .subtitle {
        color: #666;
        font-size: 1.1rem;
    }
    
    .info-card {
        background: #f8f9fa;
        padding: 1.5rem;
        border-radius: 8px;
        margin-bottom: 2rem;
    }
    
    .info-card h3 {
        margin-top: 0;
        color: #495057;
    }
    
    .info-card ul {
        list-style: none;
        padding: 0;
    }
    
    .info-card li {
        padding: 0.25rem 0;
    }
    
    .actions {
        text-align: center;
    }
    
    .btn {
        display: inline-block;
        padding: 0.5rem 1rem;
        margin: 0 0.5rem;
        text-decoration: none;
        border-radius: 4px;
        font-weight: 500;
    }
    
    .btn-primary {
        background: #007bff;
        color: white;
    }
    
    .btn-secondary {
        background: #6c757d;
        color: white;
    }
    
    .btn:hover {
        opacity: 0.9;
    }
</style>
{% endblock %}
''';
  }

  Future<void> _generateListTemplate(Directory templatesDir) async {
    final listTemplate = '''
{% extends "base.html" %}

{% block title %}{{ title }}{% endblock %}

{% block content %}
<div class="container">
    <div class="header">
        <h1>{{ title }}</h1>
        <div class="actions">
            <a href="create/" class="btn btn-primary">Create New</a>
        </div>
    </div>
    
    <div class="list-container">
        {% for item in object_list %}
        <div class="list-item">
            <h3>
                <a href="{{ item.id }}/">{{ item.name }}</a>
            </h3>
            <p>{{ item.description }}</p>
            <div class="item-meta">
                <span>Created: {{ item.created_at }}</span>
                <span>Status: {{ item.is_active|yesno:"Active,Inactive" }}</span>
            </div>
        </div>
        {% empty %}
        <div class="empty-state">
            <p>No items found.</p>
            <a href="create/" class="btn btn-primary">Create the first one</a>
        </div>
        {% endfor %}
    </div>
</div>
{% endblock %}
''';

    await File(path.join(templatesDir.path, '${_toSnakeCase(name)}_list.html'))
        .writeAsString(listTemplate);
  }

  Future<void> _generateDetailTemplate(Directory templatesDir) async {
    final detailTemplate = '''
{% extends "base.html" %}

{% block title %}{{ title }}{% endblock %}

{% block content %}
<div class="container">
    <div class="header">
        <h1>{{ object.name }}</h1>
        <div class="actions">
            <a href="../" class="btn btn-secondary">Back to List</a>
            <a href="edit/" class="btn btn-primary">Edit</a>
            <a href="delete/" class="btn btn-danger">Delete</a>
        </div>
    </div>
    
    <div class="detail-container">
        <div class="detail-card">
            <h3>Details</h3>
            <dl>
                <dt>Name</dt>
                <dd>{{ object.name }}</dd>
                
                <dt>Description</dt>
                <dd>{{ object.description|default:"No description" }}</dd>
                
                <dt>Status</dt>
                <dd>{{ object.is_active|yesno:"Active,Inactive" }}</dd>
                
                <dt>Created</dt>
                <dd>{{ object.created_at }}</dd>
                
                <dt>Last Updated</dt>
                <dd>{{ object.updated_at }}</dd>
            </dl>
        </div>
    </div>
</div>
{% endblock %}
''';

    await File(
            path.join(templatesDir.path, '${_toSnakeCase(name)}_detail.html'))
        .writeAsString(detailTemplate);
  }

  Future<void> _generateFormTemplate(Directory templatesDir) async {
    final formTemplate = '''
{% extends "base.html" %}

{% block title %}{{ title }}{% endblock %}

{% block content %}
<div class="container">
    <div class="header">
        <h1>{{ title }}</h1>
    </div>
    
    <form method="post" class="form-container">
        {% csrf_token %}
        
        <div class="form-group">
            <label for="name">Name:</label>
            <input type="text" id="name" name="name" 
                   value="{{ form.name.value|default:'' }}" 
                   class="form-control" required>
            {% if form.name.errors %}
                <div class="error">{{ form.name.errors }}</div>
            {% endif %}
        </div>
        
        <div class="form-group">
            <label for="description">Description:</label>
            <textarea id="description" name="description" 
                      class="form-control" rows="4">{{ form.description.value|default:'' }}</textarea>
            {% if form.description.errors %}
                <div class="error">{{ form.description.errors }}</div>
            {% endif %}
        </div>
        
        <div class="form-group">
            <label>
                <input type="checkbox" name="is_active" 
                       {% if form.is_active.value %}checked{% endif %}>
                Active
            </label>
            {% if form.is_active.errors %}
                <div class="error">{{ form.is_active.errors }}</div>
            {% endif %}
        </div>
        
        <div class="form-actions">
            <button type="submit" class="btn btn-primary">
                {% if form_action == 'create' %}Create{% else %}Update{% endif %}
            </button>
            <a href="../" class="btn btn-secondary">Cancel</a>
        </div>
    </form>
</div>
{% endblock %}
''';

    await File(path.join(templatesDir.path, '${_toSnakeCase(name)}_form.html'))
        .writeAsString(formTemplate);
  }

  Future<void> _generateDeleteTemplate(Directory templatesDir) async {
    final deleteTemplate = '''
{% extends "base.html" %}

{% block title %}{{ title }}{% endblock %}

{% block content %}
<div class="container">
    <div class="header">
        <h1>{{ title }}</h1>
    </div>
    
    <div class="delete-container">
        <div class="warning-card">
            <h3>⚠️ Are you sure?</h3>
            <p>Are you sure you want to delete "<strong>{{ object.name }}</strong>"?</p>
            <p class="warning">This action cannot be undone.</p>
        </div>
        
        <form method="post" class="delete-form">
            {% csrf_token %}
            <div class="form-actions">
                <button type="submit" class="btn btn-danger">Yes, Delete</button>
                <a href="../" class="btn btn-secondary">Cancel</a>
            </div>
        </form>
    </div>
</div>
{% endblock %}
''';

    await File(path.join(
            templatesDir.path, '${_toSnakeCase(name)}_confirm_delete.html'))
        .writeAsString(deleteTemplate);
  }

  String _toPascalCase(String input) {
    return input
        .split('_')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join('');
  }

  String _toCamelCase(String input) {
    final parts = input.split('_');
    if (parts.isEmpty) return input;

    return parts.first.toLowerCase() +
        parts
            .skip(1)
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1)
                : '')
            .join('');
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
            RegExp(r'([A-Z])'), (match) => '_${match.group(1)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '')
        .toLowerCase();
  }

  String _toTitleCase(String input) {
    return input
        .split('_')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }
}
