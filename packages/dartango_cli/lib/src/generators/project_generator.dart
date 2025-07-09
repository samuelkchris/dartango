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
    path: ../dartango
  shelf: ^1.4.0
  args: ^2.4.0
  path: ^1.8.0

dev_dependencies:
  test: ^1.24.0
  lints: ^3.0.0
''';

    await File(path.join(outputPath, 'pubspec.yaml')).writeAsString(pubspecContent);
  }

  Future<void> _generateMainFile() async {
    final mainContent = '''
import 'package:dartango/dartango.dart';
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

class ${_toPascalCase(projectName)}App extends DartangoApp {
  @override
  void configure() {
    // Configure your application here
    super.configure();
  }
  
  @override
  List<String> get installedApps => [
    // Add your apps here
  ];
  
  @override
  Map<String, dynamic> get settings => {
    'DEBUG': true,
    'SECRET_KEY': 'your-secret-key-here',
    'ALLOWED_HOSTS': ['localhost', '127.0.0.1'],
  };
}
''';

    await File(path.join(libDir.path, 'app.dart')).writeAsString(appContent);

    // Generate URLs file
    final urlsContent = '''
import 'package:dartango/dartango.dart';

final urlPatterns = [
  path('/', HomeView.asView(), name: 'home'),
  // Add more URL patterns here
];
''';

    await File(path.join(libDir.path, 'urls.dart')).writeAsString(urlsContent);

    // Generate basic view
    final viewsContent = '''
import 'package:dartango/dartango.dart';

class HomeView extends TemplateView {
  @override
  String get templateName => 'home.html';
  
  @override
  Map<String, dynamic> getContextData() {
    return {
      'title': 'Welcome to $projectName',
      'message': 'Your Dartango application is running!',
    };
  }
}
''';

    await File(path.join(libDir.path, 'views.dart')).writeAsString(viewsContent);
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

    await File(path.join(testDir.path, 'app_test.dart')).writeAsString(testContent);
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

    await File(path.join(outputPath, 'analysis_options.yaml')).writeAsString(analysisContent);
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

    await File(path.join(outputPath, 'CHANGELOG.md')).writeAsString(changelogContent);
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

    await File(path.join(outputPath, '.gitignore')).writeAsString(gitignoreContent);
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
            max-width: 600px;
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
        .features {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin-top: 2rem;
        }
        .feature {
            background: rgba(255, 255, 255, 0.1);
            padding: 1rem;
            border-radius: 8px;
            backdrop-filter: blur(10px);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>{{ title }}</h1>
        <p>{{ message }}</p>
        
        <div class="features">
            <div class="feature">
                <h3>🚀 Fast Development</h3>
                <p>Get started quickly with Django-inspired patterns</p>
            </div>
            <div class="feature">
                <h3>🎯 Type Safe</h3>
                <p>Built with Dart for compile-time safety</p>
            </div>
            <div class="feature">
                <h3>🔧 Flexible</h3>
                <p>Customize every aspect of your application</p>
            </div>
        </div>
    </div>
</body>
</html>
''';

    await File(path.join(templatesDir.path, 'home.html')).writeAsString(homeTemplate);

    // Generate static directory
    final staticDir = Directory(path.join(outputPath, 'static'));
    await staticDir.create(recursive: true);
    
    final cssDir = Directory(path.join(staticDir.path, 'css'));
    await cssDir.create(recursive: true);
    
    final jsDir = Directory(path.join(staticDir.path, 'js'));
    await jsDir.create(recursive: true);
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

    await File(path.join(templatesDir.path, 'home.html')).writeAsString(minimalTemplate);
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

    await File(path.join(libDir.path, 'views.dart')).writeAsString(apiViewsContent);

    // Override URLs for API
    final apiUrlsContent = '''
import 'package:dartango/dartango.dart';

final urlPatterns = [
  path('/', ApiView.asView(), name: 'api_root'),
  path('/health', HealthView.asView(), name: 'health'),
  // Add more API endpoints here
];
''';

    await File(path.join(libDir.path, 'urls.dart')).writeAsString(apiUrlsContent);
  }

  String _toPascalCase(String input) {
    return input
        .split('_')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join('');
  }
}