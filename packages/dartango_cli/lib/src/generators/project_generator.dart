import 'dart:io';
import 'package:path/path.dart' as path;

class ProjectGenerator {
  final String projectName;
  final String template;
  final String outputPath;

  ProjectGenerator({
    required this.projectName,
    required this.template,
    required this.outputPath,
  });

  Future<void> generate() async {
    final projectDir = Directory(outputPath);
    await projectDir.create(recursive: true);

    // Generate core project files
    await _generatePubspec();
    await _generateMainFile();
    await _generateLibFiles();
    await _generateTestFiles();
    await _generateConfigFiles();
    await _generateDocumentation();
    await _generateGitIgnore();

    // Generate template-specific files
    switch (template) {
      case 'minimal':
        await _generateMinimalTemplate();
        break;
      case 'api-only':
        await _generateApiOnlyTemplate();
        break;
      case 'default':
      default:
        await _generateDefaultTemplate();
        break;
    }
    
    // Copy Flutter admin package
    await _copyFlutterAdminPackage();
  }

  Future<void> _generatePubspec() async {
    final pubspecContent = '''
name: $projectName
description: A Dartango web application
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  dartango:
    path: ../packages/dartango
  shelf: ^1.4.0
  shelf_router: ^1.1.0
  shelf_static: ^1.1.0
  args: ^2.4.0
  path: ^1.8.0

dev_dependencies:
  test: ^1.24.0
  lints: ^3.0.0
''';

    await File(path.join(outputPath, 'pubspec.yaml'))
        .writeAsString(pubspecContent);
  }

  Future<void> _generateMainFile() async {
    final mainContent = '''
import 'package:$projectName/app.dart';

Future<void> main(List<String> args) async {
  final app = ${_toPascalCase(projectName)}App();
  await app.run(args);
}
''';

    final binDir = Directory(path.join(outputPath, 'bin'));
    await binDir.create(recursive: true);
    await File(path.join(binDir.path, 'main.dart')).writeAsString(mainContent);
  }

  Future<void> _generateLibFiles() async {
    final libDir = Directory(path.join(outputPath, 'lib'));
    await libDir.create(recursive: true);

    // Generate main app file
    final appContent = '''
import 'package:dartango/dartango.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import 'models/blog_post.dart';
import 'admin/blog_post_admin.dart';

class ${_toPascalCase(projectName)}App extends DartangoApp {
  @override
  Future<void> configure() async {
    // Configure your application here
    await super.configure();
  }
  
  @override
  List<String> get installedApps => [
    'blog',
  ];
  
  @override
  Map<String, dynamic> get settings => {
    'DEBUG': true,
    'SECRET_KEY': 'your-secret-key-here-${DateTime.now().millisecondsSinceEpoch}',
    'ALLOWED_HOSTS': ['localhost', '127.0.0.1'],
    'HOST': 'localhost',
    'PORT': 8000,
    'DATABASE_URL': 'sqlite:///${projectName}.db',
  };
  
  @override
  Future<void> setupAdmin(AdminSite adminSite) async {
    // Register your models with the admin
    adminSite.register<BlogPost>(BlogPost, BlogPostAdmin(adminSite: adminSite));
  }
  
  @override
  Future<void> setupRoutes(Router router) async {
    // Add your custom routes here
    router.get('/api/posts/', _getPostsHandler);
    router.get('/api/posts/<id>/', _getPostHandler);
    router.post('/api/posts/', _createPostHandler);
  }
  
  Future<Response> _getPostsHandler(Request request) async {
    final admin = BlogPostAdmin(adminSite: AdminSite());
    final posts = await admin.getQueryset();
    final jsonData = posts.map((p) => p.toJson()).toList();
    return Response.ok(
      '{"results": \${_jsonEncode(jsonData)}, "count": \${posts.length}}',
      headers: {'Content-Type': 'application/json'},
    );
  }
  
  Future<Response> _getPostHandler(Request request) async {
    final id = request.params['id']!;
    final admin = BlogPostAdmin(adminSite: AdminSite());
    final post = await admin.getObject(id);
    if (post == null) {
      return Response.notFound('{"error": "Post not found"}');
    }
    return Response.ok(
      _jsonEncode(post.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }
  
  Future<Response> _createPostHandler(Request request) async {
    return Response.ok('{"message": "Post creation not implemented yet"}');
  }
  
  String _jsonEncode(dynamic object) {
    if (object is Map) {
      final entries = object.entries.map((e) => '"\${e.key}": \${_jsonEncode(e.value)}');
      return '{\${entries.join(', ')}}';
    } else if (object is List) {
      final items = object.map((item) => _jsonEncode(item));
      return '[\${items.join(', ')}]';
    } else if (object is String) {
      return '"\$object"';
    } else if (object is num || object is bool) {
      return object.toString();
    } else if (object == null) {
      return 'null';
    } else {
      return '"\${object.toString()}"';
    }
  }
}
''';

    await File(path.join(libDir.path, 'app.dart')).writeAsString(appContent);

    // Generate models directory and BlogPost model
    final modelsDir = Directory(path.join(libDir.path, 'models'));
    await modelsDir.create(recursive: true);
    
    final blogPostContent = '''
import 'package:dartango/dartango.dart';

class BlogPost extends Model {
  BlogPost();
  
  @override
  ModelMeta get meta => const ModelMeta(
    tableName: 'blog_posts',
    appLabel: 'blog',
    verboseName: 'Blog Post',
    verboseNamePlural: 'Blog Posts',
  );
  
  String get title => getField<String>('title') ?? '';
  set title(String value) => setField('title', value);
  
  String get content => getField<String>('content') ?? '';
  set content(String value) => setField('content', value);
  
  DateTime get createdAt => getField<DateTime>('createdAt') ?? DateTime.now();
  set createdAt(DateTime value) => setField('createdAt', value);
  
  DateTime get updatedAt => getField<DateTime>('updatedAt') ?? DateTime.now();
  set updatedAt(DateTime value) => setField('updatedAt', value);
  
  bool get published => getField<bool>('published') ?? false;
  set published(bool value) => setField('published', value);
  
  @override
  String toString() => title;
}
''';
    
    await File(path.join(modelsDir.path, 'blog_post.dart')).writeAsString(blogPostContent);
    
    // Generate admin directory and BlogPostAdmin
    final adminDir = Directory(path.join(libDir.path, 'admin'));
    await adminDir.create(recursive: true);
    
    final blogPostAdminContent = '''
import 'package:dartango/dartango.dart';
import '../models/blog_post.dart';

class BlogPostAdmin extends ModelAdmin<BlogPost> {
  BlogPostAdmin({required super.adminSite}) : super(modelType: BlogPost);
  
  @override
  List<String> get listDisplay => ['title', 'published', 'createdAt'];
  
  @override
  List<String> get listFilter => ['published', 'createdAt'];
  
  @override
  List<String> get searchFields => ['title', 'content'];
  
  @override
  String getVerboseName() => 'Blog Post';
  
  @override
  String getVerboseNamePlural() => 'Blog Posts';
  
  @override
  String getAppLabel() => 'blog';
  
  @override
  String getChangelistUrl() => '/admin/blog/blogpost/';
  
  @override
  Future<List<BlogPost>> getQueryset({
    String? search,
    Map<String, dynamic> filters = const {},
    String? ordering,
    int? limit,
    int? offset,
  }) async {
    // Sample data for demo - replace with actual database queries
    final posts = <BlogPost>[];
    
    final post1 = BlogPost()
      ..title = 'Welcome to ${_toPascalCase(projectName)}'
      ..content = 'This is your first blog post created automatically!'
      ..published = true
      ..createdAt = DateTime.now();
    posts.add(post1);
    
    final post2 = BlogPost()
      ..title = 'Getting Started with Dartango'
      ..content = 'Learn how to use the Dartango framework to build amazing web applications.'
      ..published = false
      ..createdAt = DateTime.now().subtract(Duration(days: 1));
    posts.add(post2);
    
    return posts;
  }
  
  @override
  Future<BlogPost?> getObject(dynamic pk) async {
    final posts = await getQueryset();
    final id = int.tryParse(pk.toString()) ?? 0;
    return posts.isNotEmpty && id > 0 && id <= posts.length ? posts[id - 1] : null;
  }
  
  @override
  Future<bool> hasViewPermissionCheck(HttpRequest request) async => true;
  
  @override
  Future<bool> hasAddPermissionCheck(HttpRequest request) async => true;
  
  @override
  Future<bool> hasChangePermissionCheck(HttpRequest request) async => true;
  
  @override
  Future<bool> hasDeletePermissionCheck(HttpRequest request) async => true;
  
  @override
  Future<HttpResponse> changelistView(HttpRequest request) async {
    final posts = await getQueryset();
    final jsonData = posts.map((p) => p.toJson()).toList();
    return HttpResponse.json({
      'results': jsonData,
      'count': posts.length,
      'model': 'BlogPost',
      'app': 'blog',
    });
  }
  
  @override
  Future<HttpResponse> addView(HttpRequest request) async {
    return HttpResponse.json({
      'form': {
        'title': {'type': 'text', 'required': true},
        'content': {'type': 'textarea', 'required': true},
        'published': {'type': 'checkbox', 'required': false},
      },
      'model': 'BlogPost',
      'app': 'blog',
    });
  }
  
  @override
  Future<HttpResponse> changeView(HttpRequest request, dynamic objectId) async {
    final post = await getObject(objectId);
    if (post == null) {
      return HttpResponse.notFound('Post not found');
    }
    return HttpResponse.json({
      'object': post.toJson(),
      'form': {
        'title': {'type': 'text', 'required': true, 'value': post.title},
        'content': {'type': 'textarea', 'required': true, 'value': post.content},
        'published': {'type': 'checkbox', 'required': false, 'value': post.published},
      },
      'model': 'BlogPost',
      'app': 'blog',
    });
  }
  
  @override
  Future<HttpResponse> deleteView(HttpRequest request, dynamic objectId) async {
    final post = await getObject(objectId);
    if (post == null) {
      return HttpResponse.notFound('Post not found');
    }
    return HttpResponse.json({
      'object': post.toJson(),
      'message': 'Are you sure you want to delete this post?',
      'model': 'BlogPost',
      'app': 'blog',
    });
  }
}
''';
    
    await File(path.join(adminDir.path, 'blog_post_admin.dart')).writeAsString(blogPostAdminContent);

    // Generate URLs file
    final urlsContent = '''
import 'package:dartango/dartango.dart';
import 'views/home_view.dart';
import 'views/blog_view.dart';

// Helper function to convert shelf.Handler to ViewFunction
ViewFunction _wrapHandler(Function handler) {
  return (HttpRequest request, Map<String, String> kwargs) async {
    final shelfRequest = request.shelfRequest;
    final shelfResponse = await handler(shelfRequest);
    return HttpResponse(
      await shelfResponse.readAsString(),
      statusCode: shelfResponse.statusCode,
      headers: Map<String, String>.from(shelfResponse.headers),
    );
  };
}

final urlPatterns = [
  path('/', _wrapHandler(HomeView.asView()), name: 'home'),
  path('/blog/', _wrapHandler(BlogView.asView()), name: 'blog'),
  // Add more URL patterns here
];
''';

    await File(path.join(libDir.path, 'urls.dart')).writeAsString(urlsContent);

    // Generate views directory and view files
    final viewsDir = Directory(path.join(libDir.path, 'views'));
    await viewsDir.create(recursive: true);
    
    final homeViewContent = '''
import 'package:dartango/dartango.dart';
import 'package:shelf/shelf.dart' as shelf;

class HomeView extends TemplateView {
  HomeView() : super(templateName: 'home.html');
  
  @override
  Map<String, dynamic> getContextData(HttpRequest request, Map<String, dynamic> kwargs) {
    return {
      'title': 'Welcome to $projectName',
      'message': 'Your Dartango application is running!',
      'project_name': '$projectName',
      'admin_url': '/admin/',
    };
  }
  
  static shelf.Handler asView() {
    return (shelf.Request request) async {
      final view = HomeView();
      final dartangoRequest = HttpRequest.fromShelfRequest(request);
      final response = await view.get(dartangoRequest, {});
      return response.toShelfResponse();
    };
  }
}
''';
    
    await File(path.join(viewsDir.path, 'home_view.dart')).writeAsString(homeViewContent);
    
    final blogViewContent = '''
import 'package:dartango/dartango.dart';
import 'package:shelf/shelf.dart' as shelf;

class BlogView extends TemplateView {
  BlogView() : super(templateName: 'blog.html');
  
  @override
  Map<String, dynamic> getContextData(HttpRequest request, Map<String, dynamic> kwargs) {
    return {
      'title': 'Blog Posts',
      'posts': [
        {
          'title': 'Welcome to $projectName',
          'content': 'This is your first blog post!',
          'published': true,
        },
        {
          'title': 'Getting Started with Dartango',
          'content': 'Learn how to use the Dartango framework.',
          'published': false,
        },
      ],
    };
  }
  
  static shelf.Handler asView() {
    return (shelf.Request request) async {
      final view = BlogView();
      final dartangoRequest = HttpRequest.fromShelfRequest(request);
      final response = await view.get(dartangoRequest, {});
      return response.toShelfResponse();
    };
  }
}
''';
    
    await File(path.join(viewsDir.path, 'blog_view.dart')).writeAsString(blogViewContent);
  }

  Future<void> _generateTestFiles() async {
    final testDir = Directory(path.join(outputPath, 'test'));
    await testDir.create(recursive: true);

    final testContent = '''
import 'package:test/test.dart';
import 'package:$projectName/app.dart';

void main() {
  group('${_toPascalCase(projectName)}App', () {
    late ${_toPascalCase(projectName)}App app;

    setUp(() {
      app = ${_toPascalCase(projectName)}App();
    });

    test('should create app instance', () {
      expect(app, isNotNull);
    });

    test('should have correct settings', () {
      expect(app.settings['DEBUG'], isTrue);
    });
  });
}
''';

    await File(path.join(testDir.path, 'app_test.dart'))
        .writeAsString(testContent);
  }

  Future<void> _generateConfigFiles() async {
    // Generate analysis options
    final analysisContent = '''
include: package:lints/recommended.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  
linter:
  rules:
    - prefer_single_quotes
    - sort_pub_dependencies
    - avoid_print
''';

    await File(path.join(outputPath, 'analysis_options.yaml'))
        .writeAsString(analysisContent);
  }

  Future<void> _generateDocumentation() async {
    final readmeContent = '''
# $projectName

A Dartango web application.

## Getting Started

This project is built with [Dartango](https://github.com/yourusername/dartango), a Django-inspired web framework for Dart.

### Prerequisites

- Dart SDK 3.0.0 or higher
- Dartango CLI

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   dart pub get
   ```

### Running the Application

To start the development server:

```bash
dartango serve
```

The application will be available at `http://localhost:8000`.

### Building for Production

To build the application for production:

```bash
dartango build
```

### Testing

To run tests:

```bash
dartango test
```

### Project Structure

```
$projectName/
├── bin/
│   └── main.dart          # Application entry point
├── lib/
│   ├── app.dart           # Main application class
│   ├── urls.dart          # URL configuration
│   └── views.dart         # View controllers
├── test/                  # Test files
├── static/                # Static assets
├── templates/             # HTML templates
└── pubspec.yaml          # Project configuration
```

### Commands

- `dartango serve` - Start development server
- `dartango build` - Build for production
- `dartango test` - Run tests
- `dartango generate` - Generate code scaffolding
- `dartango doctor` - Check project health

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License.
''';

    await File(path.join(outputPath, 'README.md')).writeAsString(readmeContent);

    final changelogContent = '''
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- Initial project setup
- Basic Dartango application structure

## [1.0.0] - ${DateTime.now().toIso8601String().split('T')[0]}

### Added
- Initial release
- Basic web application functionality
''';

    await File(path.join(outputPath, 'CHANGELOG.md'))
        .writeAsString(changelogContent);
  }

  Future<void> _generateGitIgnore() async {
    final gitignoreContent = '''
# Dart
.dart_tool/
.packages
pubspec.lock
build/
.pub-cache/
.pub/

# IDE
.vscode/
.idea/
*.iml
*.ipr
*.iws

# OS
.DS_Store
Thumbs.db

# Application specific
logs/
data/
uploads/
coverage/
.env
config/local.yaml
''';

    await File(path.join(outputPath, '.gitignore'))
        .writeAsString(gitignoreContent);
  }

  Future<void> _generateDefaultTemplate() async {
    // Generate templates directory
    final templatesDir = Directory(path.join(outputPath, 'templates'));
    await templatesDir.create(recursive: true);

    final homeTemplate = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ title }}</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            text-align: center;
            color: white;
            max-width: 800px;
            padding: 2rem;
        }
        h1 {
            font-size: 3rem;
            margin-bottom: 1rem;
        }
        p {
            font-size: 1.2rem;
            margin-bottom: 2rem;
        }
        .actions {
            margin: 2rem 0;
        }
        .action-btn {
            display: inline-block;
            padding: 15px 30px;
            background: rgba(255, 255, 255, 0.2);
            color: white;
            text-decoration: none;
            border-radius: 8px;
            margin: 10px;
            backdrop-filter: blur(10px);
            transition: all 0.3s ease;
        }
        .action-btn:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: translateY(-2px);
        }
        .features {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1rem;
            margin-top: 2rem;
        }
        .feature {
            background: rgba(255, 255, 255, 0.1);
            padding: 1.5rem;
            border-radius: 8px;
            backdrop-filter: blur(10px);
        }
        .feature h3 {
            margin-top: 0;
            font-size: 1.3rem;
        }
        .status {
            background: rgba(255, 255, 255, 0.15);
            padding: 1rem;
            border-radius: 8px;
            margin: 2rem 0;
            backdrop-filter: blur(10px);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 {{ title }}</h1>
        <p>{{ message }}</p>
        
        <div class="status">
            <h3>✅ {{ project_name }} is Running Successfully!</h3>
            <p>Your Dartango application is ready with Django-style admin interface and REST API.</p>
        </div>
        
        <div class="actions">
            <a href="{{ admin_url }}" class="action-btn">🛠️ Admin Interface</a>
            <a href="/api/posts/" class="action-btn">📝 Blog API</a>
            <a href="/blog/" class="action-btn">📰 Blog Posts</a>
        </div>
        
        <div class="features">
            <div class="feature">
                <h3>🎯 Django-Compatible</h3>
                <p>Familiar patterns with Django-style admin, models, and views</p>
            </div>
            <div class="feature">
                <h3>⚡ Production-Ready</h3>
                <p>Built with Dart for performance and type safety</p>
            </div>
            <div class="feature">
                <h3>🔧 Auto-Generated Admin</h3>
                <p>Complete admin interface with CRUD operations</p>
            </div>
            <div class="feature">
                <h3>🔗 REST API</h3>
                <p>Automatic API endpoints for all registered models</p>
            </div>
        </div>
        
        <div style="margin-top: 3rem; padding: 1rem; background: rgba(255, 255, 255, 0.1); border-radius: 8px;">
            <h3>🎉 Next Steps:</h3>
            <ul style="text-align: left; max-width: 500px; margin: 0 auto;">
                <li>Visit the <strong>Admin Interface</strong> to manage your blog posts</li>
                <li>Check out the <strong>API endpoints</strong> for integration</li>
                <li>Customize your models in <code>lib/models/</code></li>
                <li>Add more views in <code>lib/views/</code></li>
                <li>Create templates in <code>templates/</code></li>
            </ul>
        </div>
    </div>
</body>
</html>
''';

    await File(path.join(templatesDir.path, 'home.html'))
        .writeAsString(homeTemplate);
    
    // Generate blog template
    final blogTemplate = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ title }}</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 0;
            background: #f8f9fa;
            line-height: 1.6;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            padding: 2rem;
        }
        .header {
            background: white;
            padding: 2rem;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 2rem;
            text-align: center;
        }
        .header h1 {
            color: #2c3e50;
            margin-bottom: 0.5rem;
        }
        .nav {
            margin-top: 1rem;
        }
        .nav a {
            color: #3498db;
            text-decoration: none;
            margin: 0 1rem;
            padding: 0.5rem 1rem;
            border-radius: 4px;
            transition: background 0.3s;
        }
        .nav a:hover {
            background: #ecf0f1;
        }
        .post {
            background: white;
            padding: 2rem;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 2rem;
        }
        .post h2 {
            color: #2c3e50;
            margin-top: 0;
            margin-bottom: 1rem;
        }
        .post-meta {
            color: #7f8c8d;
            font-size: 0.9rem;
            margin-bottom: 1rem;
        }
        .post-content {
            color: #34495e;
            line-height: 1.8;
        }
        .status {
            padding: 1rem;
            border-radius: 4px;
            margin: 1rem 0;
        }
        .status.published {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .status.draft {
            background: #fff3cd;
            color: #856404;
            border: 1px solid #ffeaa7;
        }
        .empty-state {
            text-align: center;
            padding: 3rem;
            color: #7f8c8d;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>{{ title }}</h1>
            <p>Welcome to your blog powered by Dartango</p>
            <div class="nav">
                <a href="/">🏠 Home</a>
                <a href="/admin/">🛠️ Admin</a>
                <a href="/api/posts/">📝 API</a>
            </div>
        </div>
        
        {% if posts %}
            {% for post in posts %}
            <div class="post">
                <h2>{{ post.title }}</h2>
                <div class="post-meta">
                    <span class="status {% if post.published %}published{% else %}draft{% endif %}">
                        {% if post.published %}✅ Published{% else %}📝 Draft{% endif %}
                    </span>
                </div>
                <div class="post-content">
                    {{ post.content }}
                </div>
            </div>
            {% endfor %}
        {% else %}
            <div class="empty-state">
                <h2>No blog posts yet</h2>
                <p>Visit the <a href="/admin/">admin interface</a> to create your first blog post!</p>
            </div>
        {% endif %}
    </div>
</body>
</html>
''';
    
    await File(path.join(templatesDir.path, 'blog.html'))
        .writeAsString(blogTemplate);

    // Note: No static files needed - admin interface is built with Flutter
  }

  Future<void> _generateMinimalTemplate() async {
    // Minimal template with just basic structure
    final templatesDir = Directory(path.join(outputPath, 'templates'));
    await templatesDir.create(recursive: true);

    final minimalTemplate = '''
<!DOCTYPE html>
<html>
<head>
    <title>{{ title }}</title>
</head>
<body>
    <h1>{{ title }}</h1>
    <p>{{ message }}</p>
</body>
</html>
''';

    await File(path.join(templatesDir.path, 'home.html'))
        .writeAsString(minimalTemplate);
  }

  Future<void> _generateApiOnlyTemplate() async {
    // Generate API-specific files
    final libDir = Directory(path.join(outputPath, 'lib'));

    // Override the views file for API
    final apiViewsContent = '''
import 'package:dartango/dartango.dart';

class ApiView extends View {
  @override
  Future<HttpResponse> get(HttpRequest request) async {
    return JsonResponse({
      'message': 'Welcome to $projectName API',
      'version': '1.0.0',
      'endpoints': [
        '/api/v1/health',
        '/api/v1/status',
      ],
    });
  }
}

class HealthView extends View {
  @override
  Future<HttpResponse> get(HttpRequest request) async {
    return JsonResponse({
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
''';

    await File(path.join(libDir.path, 'views.dart'))
        .writeAsString(apiViewsContent);

    // Override URLs for API
    final apiUrlsContent = '''
import 'package:dartango/dartango.dart';

final urlPatterns = [
  path('/', ApiView.asView(), name: 'api_root'),
  path('/health', HealthView.asView(), name: 'health'),
  // Add more API endpoints here
];
''';

    await File(path.join(libDir.path, 'urls.dart'))
        .writeAsString(apiUrlsContent);
  }

  Future<void> _copyFlutterAdminPackage() async {
    // Copy the existing dartango_admin package instead of generating from scratch
    final adminSourceDir = Directory(path.join(
      outputPath, 
      '../packages/dartango_admin'
    ));
    
    if (!adminSourceDir.existsSync()) {
      print('Warning: dartango_admin package not found. Creating basic admin structure.');
      await _generateBasicAdmin();
      return;
    }
    
    final adminDestDir = Directory(path.join(outputPath, 'admin'));
    
    // Copy the entire dartango_admin package
    await _copyDirectory(adminSourceDir, adminDestDir);
    
    // Update the pubspec.yaml to reference the correct project name
    final adminPubspec = File(path.join(adminDestDir.path, 'pubspec.yaml'));
    if (adminPubspec.existsSync()) {
      var content = await adminPubspec.readAsString();
      content = content.replaceAll('dartango_admin', '${projectName}_admin');
      content = content.replaceAll('Flutter admin interface for Dartango', 
          'Flutter admin interface for $projectName');
      await adminPubspec.writeAsString(content);
    }
    
    return;
  }
  
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    
    await for (var entity in source.list(recursive: false)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: source.path);
        final destFile = File(path.join(destination.path, relativePath));
        await destFile.parent.create(recursive: true);
        await entity.copy(destFile.path);
      } else if (entity is Directory) {
        final relativePath = path.relative(entity.path, from: source.path);
        final destDir = Directory(path.join(destination.path, relativePath));
        await _copyDirectory(entity, destDir);
      }
    }
  }
  
  Future<void> _generateBasicAdmin() async {
    // Create admin directory in the project
    final adminDir = Directory(path.join(outputPath, 'admin'));
    await adminDir.create(recursive: true);
    
    // Generate admin pubspec.yaml
    final adminPubspecContent = '''
name: ${projectName}_admin
description: Flutter admin interface for $projectName
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.10.0'

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  http: ^1.1.0
  shared_preferences: ^2.2.0
  fl_chart: ^0.63.0
  data_table_2: ^2.5.0
  intl: ^0.18.0
  go_router: ^10.0.0
  web_socket_channel: ^2.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true
''';
    
    await File(path.join(adminDir.path, 'pubspec.yaml'))
        .writeAsString(adminPubspecContent);
    
    // Create lib directory
    final adminLibDir = Directory(path.join(adminDir.path, 'lib'));
    await adminLibDir.create(recursive: true);
    
    // Generate main.dart for admin
    final adminMainContent = '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/app.dart';
import 'src/providers/auth_provider.dart';
import 'src/services/auth_service.dart';
import 'src/services/websocket_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => WebSocketService()),
      ],
      child: AdminApp(),
    ),
  );
}
''';
    
    await File(path.join(adminLibDir.path, 'main.dart'))
        .writeAsString(adminMainContent);
    
    // Create src directory structure
    final srcDir = Directory(path.join(adminLibDir.path, 'src'));
    await srcDir.create(recursive: true);
    
    // Generate app.dart
    final appContent = '''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/users/users_screen.dart';
import 'screens/groups/groups_screen.dart';
import 'theme/app_theme.dart';

class AdminApp extends StatelessWidget {
  AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '$projectName Admin',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }

  final GoRouter _router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final authProvider = context.read<AuthProvider>();
          if (!authProvider.isAuthenticated) {
            return '/login';
          }
          return null;
        },
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const UsersScreen(),
      ),
      GoRoute(
        path: '/groups',
        builder: (context, state) => const GroupsScreen(),
      ),
    ],
  );
}
''';
    
    await File(path.join(srcDir.path, 'app.dart')).writeAsString(appContent);
    
    // Create necessary subdirectories
    final dirs = [
      'models',
      'providers',
      'screens/auth',
      'screens/dashboard',
      'screens/users',
      'screens/groups',
      'services',
      'theme',
      'utils',
      'widgets/common',
      'widgets/dashboard',
      'widgets/layout',
    ];
    
    for (final dir in dirs) {
      await Directory(path.join(srcDir.path, dir)).create(recursive: true);
    }
    
    // Generate a basic theme file
    final themeContent = '''
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.dark,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
''';
    
    await File(path.join(srcDir.path, 'theme/app_theme.dart'))
        .writeAsString(themeContent);
    
    // Generate basic providers and screens
    await _generateAdminProviders(srcDir.path);
    await _generateAdminScreens(srcDir.path);
    await _generateAdminServices(srcDir.path);
    
    // Create web directory for Flutter web
    final webDir = Directory(path.join(adminDir.path, 'web'));
    await webDir.create(recursive: true);
    
    // Generate index.html for Flutter web
    final indexHtmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <base href="/">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="$projectName Admin Interface">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="$projectName Admin">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  <link rel="icon" type="image/png" href="favicon.png"/>
  <title>$projectName Admin</title>
  <link rel="manifest" href="manifest.json">
  <script>
    var serviceWorkerVersion = null;
  </script>
</head>
<body>
  <script src="flutter.js" defer></script>
  <script>
    window.addEventListener('load', function(ev) {
      _flutter.loader.loadEntrypoint({
        serviceWorker: {
          serviceWorkerVersion: serviceWorkerVersion,
        }
      }).then(function(engineInitializer) {
        return engineInitializer.initializeEngine();
      }).then(function(appRunner) {
        return appRunner.runApp();
      });
    });
  </script>
</body>
</html>
''';
    
    await File(path.join(webDir.path, 'index.html'))
        .writeAsString(indexHtmlContent);
    
    // Create a README for the admin
    final adminReadmeContent = '''
# $projectName Admin Interface

This is the Flutter-based admin interface for your Dartango application.

## Getting Started

1. Navigate to the admin directory:
   ```bash
   cd admin
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the admin interface:
   ```bash
   flutter run -d chrome
   ```

## Building for Production

To build the admin interface for production:

```bash
flutter build web
```

The built files will be in `build/web/` directory.

## Features

- Material Design UI
- Responsive layout
- Real-time updates via WebSocket
- CRUD operations for all models
- User authentication
- Dashboard with analytics

## Configuration

The admin interface connects to your Dartango backend at `http://localhost:8000` by default.
You can change this in the service files under `lib/src/services/`.
''';
    
    await File(path.join(adminDir.path, 'README.md'))
        .writeAsString(adminReadmeContent);
  }
  
  Future<void> _generateAdminProviders(String srcPath) async {
    // Generate AuthProvider
    final authProviderContent = '''
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  Map<String, dynamic>? _user;
  
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  
  void login(String token, Map<String, dynamic> user) {
    _isAuthenticated = true;
    _token = token;
    _user = user;
    notifyListeners();
  }
  
  void logout() {
    _isAuthenticated = false;
    _token = null;
    _user = null;
    notifyListeners();
  }
}
''';
    
    await File(path.join(srcPath, 'providers/auth_provider.dart'))
        .writeAsString(authProviderContent);
  }
  
  Future<void> _generateAdminScreens(String srcPath) async {
    // Generate Login Screen
    final loginScreenContent = '''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'admin123');
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(40),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$projectName Admin',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    // Simulate login - in production, call your auth service
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    // Mock successful login
    context.read<AuthProvider>().login(
      'dummy-token',
      {'username': _usernameController.text, 'email': 'admin@example.com'},
    );
    
    context.go('/');
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
''';
    
    await File(path.join(srcPath, 'screens/auth/login_screen.dart'))
        .writeAsString(loginScreenContent);
    
    // Generate Dashboard Screen
    final dashboardScreenContent = '''
import 'package:flutter/material.dart';
import '../../widgets/layout/admin_layout.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Dashboard',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to $projectName Admin',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard('Total Users', '150', Icons.people, Colors.blue),
        _buildStatCard('Active Sessions', '45', Icons.timer, Colors.green),
        _buildStatCard('Blog Posts', '23', Icons.article, Colors.orange),
        _buildStatCard('API Calls', '1.2K', Icons.api, Colors.purple),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text('User \${index + 1} performed an action'),
                  subtitle: Text('\${5 - index} minutes ago'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
''';
    
    await File(path.join(srcPath, 'screens/dashboard/dashboard_screen.dart'))
        .writeAsString(dashboardScreenContent);
    
    // Generate Users Screen
    final usersScreenContent = '''
import 'package:flutter/material.dart';
import '../../widgets/layout/admin_layout.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Users',
      body: const Center(
        child: Text('Users management interface coming soon'),
      ),
    );
  }
}
''';
    
    await File(path.join(srcPath, 'screens/users/users_screen.dart'))
        .writeAsString(usersScreenContent);
    
    // Generate Groups Screen
    final groupsScreenContent = '''
import 'package:flutter/material.dart';
import '../../widgets/layout/admin_layout.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Groups',
      body: const Center(
        child: Text('Groups management interface coming soon'),
      ),
    );
  }
}
''';
    
    await File(path.join(srcPath, 'screens/groups/groups_screen.dart'))
        .writeAsString(groupsScreenContent);
  }
  
  Future<void> _generateAdminServices(String srcPath) async {
    // Generate AuthService
    final authServiceContent = '''
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://localhost:8000';
  
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('\$baseUrl/api/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login');
    }
  }
  
  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    final response = await http.get(
      Uri.parse('\$baseUrl/api/auth/user/'),
      headers: {
        'Authorization': 'Token \$token',
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user');
    }
  }
}
''';
    
    await File(path.join(srcPath, 'services/auth_service.dart'))
        .writeAsString(authServiceContent);
    
    // Generate WebSocketService
    final websocketServiceContent = '''
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static const String wsUrl = 'ws://localhost:8000/ws';
  WebSocketChannel? _channel;
  
  void connect() {
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
  }
  
  void disconnect() {
    _channel?.sink.close();
  }
  
  Stream<dynamic>? get stream => _channel?.stream;
  
  void send(Map<String, dynamic> message) {
    _channel?.sink.add(message);
  }
}
''';
    
    await File(path.join(srcPath, 'services/websocket_service.dart'))
        .writeAsString(websocketServiceContent);
    
    // Generate admin layout widget
    final adminLayoutContent = '''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AdminLayout extends StatelessWidget {
  final String title;
  final Widget body;
  
  const AdminLayout({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                '$projectName Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                context.go('/');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Users'),
              onTap: () {
                Navigator.pop(context);
                context.go('/users');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Groups'),
              onTap: () {
                Navigator.pop(context);
                context.go('/groups');
              },
            ),
          ],
        ),
      ),
      body: body,
    );
  }
}
''';
    
    await File(path.join(srcPath, 'widgets/layout/admin_layout.dart'))
        .writeAsString(adminLayoutContent);
  }

  String _toPascalCase(String input) {
    return input
        .split('_')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join('');
  }
}
