import 'dart:io';
import 'package:path/path.dart' as path;

class AppGenerator {
  final String appName;
  final String template;
  final String outputPath;

  AppGenerator({
    required this.appName,
    required this.template,
    required this.outputPath,
  });

  Future<void> generate() async {
    final appDir = Directory(outputPath);
    await appDir.create(recursive: true);

    // Generate core app files
    await _generateModelsFile();
    await _generateViewsFile();
    await _generateUrlsFile();
    await _generateAppsFile();
    await _generateTestFiles();

    // Generate template-specific files
    switch (template) {
      case 'api-only':
        await _generateApiOnlyFiles();
        break;
      case 'minimal':
        await _generateMinimalFiles();
        break;
      case 'default':
      default:
        await _generateDefaultFiles();
        break;
    }
  }

  Future<void> _generateModelsFile() async {
    final modelsDir = Directory(path.join(outputPath, 'models'));
    await modelsDir.create(recursive: true);

    final modelsContent = '''
import 'package:dartango/dartango.dart';

// Add your models here
// Example:
// class ${_toPascalCase(appName)}Model extends Model {
//   static const String tableName = '${appName}_model';
//   
//   final CharField name = CharField(maxLength: 100);
//   final TextField description = TextField();
//   final DateTimeField createdAt = DateTimeField(autoNow: true);
//   
//   @override
//   String toString() => name.value ?? 'Unnamed ${_toPascalCase(appName)}Model';
// }
''';

    await File(path.join(modelsDir.path, '${appName}_model.dart'))
        .writeAsString(modelsContent);
  }

  Future<void> _generateViewsFile() async {
    final viewsDir = Directory(path.join(outputPath, 'views'));
    await viewsDir.create(recursive: true);

    final viewsContent = '''
import 'package:dartango/dartango.dart';

class ${_toPascalCase(appName)}ListView extends ListView {
  @override
  String get templateName => '$appName/${appName}_list.html';
  
  @override
  Future<QuerySet> getQuerySet() async {
    // Return your model queryset here
    // Example: return ${_toPascalCase(appName)}Model.objects.all();
    return Future.value(QuerySet([]));
  }
  
  @override
  Map<String, dynamic> getContextData() {
    return {
      'title': '${_toTitleCase(appName)} List',
      'app_name': '$appName',
    };
  }
}

class ${_toPascalCase(appName)}DetailView extends DetailView {
  @override
  String get templateName => '$appName/${appName}_detail.html';
  
  @override
  Map<String, dynamic> getContextData() {
    return {
      'title': '${_toTitleCase(appName)} Detail',
      'app_name': '$appName',
    };
  }
}

class ${_toPascalCase(appName)}CreateView extends CreateView {
  @override
  String get templateName => '$appName/${appName}_form.html';
  
  @override
  String get successUrl => '/$appName/';
  
  @override
  Map<String, dynamic> getContextData() {
    return {
      'title': 'Create ${_toTitleCase(appName)}',
      'app_name': '$appName',
    };
  }
}
''';

    await File(path.join(viewsDir.path, '${appName}_views.dart'))
        .writeAsString(viewsContent);
  }

  Future<void> _generateUrlsFile() async {
    final urlsContent = '''
import 'package:dartango/dartango.dart';
import 'views/${appName}_views.dart';

final urlPatterns = [
  path('', ${_toPascalCase(appName)}ListView.asView(), name: '${appName}_list'),
  path('<int:id>/', ${_toPascalCase(appName)}DetailView.asView(), name: '${appName}_detail'),
  path('create/', ${_toPascalCase(appName)}CreateView.asView(), name: '${appName}_create'),
];
''';

    await File(path.join(outputPath, 'urls.dart')).writeAsString(urlsContent);
  }

  Future<void> _generateAppsFile() async {
    final appsContent = '''
import 'package:dartango/dartango.dart';

class ${_toPascalCase(appName)}Config extends AppConfig {
  @override
  String get name => '$appName';
  
  @override
  String get label => '${_toTitleCase(appName)}';
  
  @override
  String get verbose_name => '${_toTitleCase(appName)} Application';
  
  @override
  void ready() {
    // Perform any app initialization here
    super.ready();
  }
}
''';

    await File(path.join(outputPath, 'apps.dart')).writeAsString(appsContent);
  }

  Future<void> _generateTestFiles() async {
    final testDir = Directory(path.join(outputPath, 'test'));
    await testDir.create(recursive: true);

    final testContent = '''
import 'package:test/test.dart';
import 'package:dartango/dartango.dart';
import '../views/${appName}_views.dart';

void main() {
  group('${_toPascalCase(appName)} Views', () {
    late TestClient client;

    setUp(() {
      client = TestClient();
    });

    test('${appName} list view should return 200', () async {
      final response = await client.get('/$appName/');
      expect(response.statusCode, equals(200));
    });

    test('${appName} detail view should return 200', () async {
      final response = await client.get('/$appName/1/');
      expect(response.statusCode, equals(200));
    });

    test('${appName} create view should return 200', () async {
      final response = await client.get('/$appName/create/');
      expect(response.statusCode, equals(200));
    });
  });
}
''';

    await File(path.join(testDir.path, 'test_${appName}_views.dart'))
        .writeAsString(testContent);
  }

  Future<void> _generateDefaultFiles() async {
    // Generate templates for default template
    final templatesDir = Directory(path.join(outputPath, 'templates', appName));
    await templatesDir.create(recursive: true);

    final listTemplate = '''
{% extends "base.html" %}

{% block title %}{{ title }}{% endblock %}

{% block content %}
<div class="container">
    <h1>{{ title }}</h1>
    
    <div class="actions">
        <a href="{% url '${appName}_create' %}" class="btn btn-primary">
            Create New ${_toTitleCase(appName)}
        </a>
    </div>
    
    <div class="list-container">
        {% for item in object_list %}
        <div class="item">
            <h3>
                <a href="{% url '${appName}_detail' item.id %}">
                    {{ item.name }}
                </a>
            </h3>
            <p>{{ item.description }}</p>
            <small>Created: {{ item.created_at }}</small>
        </div>
        {% empty %}
        <p>No ${appName} items found.</p>
        {% endfor %}
    </div>
</div>
{% endblock %}
''';

    await File(path.join(templatesDir.path, '${appName}_list.html'))
        .writeAsString(listTemplate);

    final detailTemplate = '''
{% extends "base.html" %}

{% block title %}{{ title }}{% endblock %}

{% block content %}
<div class="container">
    <h1>{{ object.name }}</h1>
    
    <div class="actions">
        <a href="{% url '${appName}_list' %}" class="btn btn-secondary">
            Back to List
        </a>
        <a href="{% url '${appName}_edit' object.id %}" class="btn btn-primary">
            Edit
        </a>
    </div>
    
    <div class="detail-container">
        <p><strong>Description:</strong> {{ object.description }}</p>
        <p><strong>Created:</strong> {{ object.created_at }}</p>
        <p><strong>Modified:</strong> {{ object.modified_at }}</p>
    </div>
</div>
{% endblock %}
''';

    await File(path.join(templatesDir.path, '${appName}_detail.html'))
        .writeAsString(detailTemplate);

    final formTemplate = '''
{% extends "base.html" %}

{% block title %}{{ title }}{% endblock %}

{% block content %}
<div class="container">
    <h1>{{ title }}</h1>
    
    <form method="post">
        {% csrf_token %}
        
        <div class="form-group">
            <label for="name">Name:</label>
            <input type="text" id="name" name="name" value="{{ form.name.value }}" required>
            {% if form.name.errors %}
                <div class="error">{{ form.name.errors }}</div>
            {% endif %}
        </div>
        
        <div class="form-group">
            <label for="description">Description:</label>
            <textarea id="description" name="description">{{ form.description.value }}</textarea>
            {% if form.description.errors %}
                <div class="error">{{ form.description.errors }}</div>
            {% endif %}
        </div>
        
        <div class="form-actions">
            <button type="submit" class="btn btn-primary">Save</button>
            <a href="{% url '${appName}_list' %}" class="btn btn-secondary">Cancel</a>
        </div>
    </form>
</div>
{% endblock %}
''';

    await File(path.join(templatesDir.path, '${appName}_form.html'))
        .writeAsString(formTemplate);
  }

  Future<void> _generateApiOnlyFiles() async {
    // Override views for API-only template
    final viewsDir = Directory(path.join(outputPath, 'views'));

    final apiViewsContent = '''
import 'package:dartango/dartango.dart';

class ${_toPascalCase(appName)}ApiView extends View {
  @override
  Future<HttpResponse> get(HttpRequest request) async {
    // List all items
    final items = []; // Replace with actual queryset
    
    return JsonResponse({
      'results': items,
      'count': items.length,
    });
  }
  
  @override
  Future<HttpResponse> post(HttpRequest request) async {
    // Create new item
    final data = await request.json();
    
    // Validate and save data here
    
    return JsonResponse({
      'id': 1,
      'message': '${_toTitleCase(appName)} created successfully',
    }, statusCode: 201);
  }
}

class ${_toPascalCase(appName)}DetailApiView extends View {
  @override
  Future<HttpResponse> get(HttpRequest request) async {
    final id = request.pathParams['id'];
    
    // Fetch item by ID
    final item = {}; // Replace with actual item fetch
    
    if (item.isEmpty) {
      return JsonResponse({
        'error': '${_toTitleCase(appName)} not found',
      }, statusCode: 404);
    }
    
    return JsonResponse(item);
  }
  
  @override
  Future<HttpResponse> put(HttpRequest request) async {
    final id = request.pathParams['id'];
    final data = await request.json();
    
    // Update item
    
    return JsonResponse({
      'id': id,
      'message': '${_toTitleCase(appName)} updated successfully',
    });
  }
  
  @override
  Future<HttpResponse> delete(HttpRequest request) async {
    final id = request.pathParams['id'];
    
    // Delete item
    
    return JsonResponse({
      'message': '${_toTitleCase(appName)} deleted successfully',
    });
  }
}
''';

    await File(path.join(viewsDir.path, '${appName}_api_views.dart'))
        .writeAsString(apiViewsContent);

    // Override URLs for API
    final apiUrlsContent = '''
import 'package:dartango/dartango.dart';
import 'views/${appName}_api_views.dart';

final urlPatterns = [
  path('', ${_toPascalCase(appName)}ApiView.asView(), name: '${appName}_api'),
  path('<int:id>/', ${_toPascalCase(appName)}DetailApiView.asView(), name: '${appName}_detail_api'),
];
''';

    await File(path.join(outputPath, 'urls.dart'))
        .writeAsString(apiUrlsContent);
  }

  Future<void> _generateMinimalFiles() async {
    // Generate minimal template files
    final templatesDir = Directory(path.join(outputPath, 'templates', appName));
    await templatesDir.create(recursive: true);

    final minimalTemplate = '''
<h1>${_toTitleCase(appName)}</h1>
<p>Welcome to the $appName app!</p>
''';

    await File(path.join(templatesDir.path, '${appName}_simple.html'))
        .writeAsString(minimalTemplate);
  }

  String _toPascalCase(String input) {
    return input
        .split('_')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join('');
  }

  String _toTitleCase(String input) {
    return input
        .split('_')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }
}
