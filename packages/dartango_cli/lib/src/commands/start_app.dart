import 'dart:io';
import 'package:args/args.dart';
import 'package:dartango/src/core/management/command.dart';
import 'package:path/path.dart' as path;

import '../generators/app_generator.dart';

class StartAppCommand extends Command {
  @override
  String get name => 'startapp';

  @override
  String get description => 'Create a new app within the project';

  @override
  String get help => '''
Create a new app within the current Dartango project.

This command creates a new app directory with the following structure:
- lib/apps/<app_name>/: App module
- lib/apps/<app_name>/models/: Data models
- lib/apps/<app_name>/views/: View controllers
- lib/apps/<app_name>/urls.dart: URL routing
- test/apps/<app_name>/: App tests

Examples:
  dartango startapp blog
  dartango startapp user_management
  dartango startapp api --template=api-only
''';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption('template', abbr: 't', defaultsTo: 'default',
        allowed: ['default', 'api-only', 'minimal'],
        help: 'Template to use for the app');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    if (args.rest.isEmpty) {
      printError('App name is required');
      printInfo('Usage: dartango startapp <app_name>');
      return;
    }

    final appName = args.rest[0];
    final template = args['template'] as String;

    if (!_isValidAppName(appName)) {
      printError('Invalid app name: $appName');
      printInfo('App name must contain only letters, numbers, and underscores');
      return;
    }

    if (!_isInDartangoProject()) {
      printError('This command must be run from within a Dartango project');
      printInfo('Run "dartango create <project_name>" to create a new project first');
      return;
    }

    final appPath = path.join('lib', 'apps', appName);
    final appDir = Directory(appPath);

    if (await appDir.exists()) {
      printError('App directory already exists: $appPath');
      return;
    }

    printInfo('Creating app: $appName');
    printInfo('Template: $template');

    try {
      final generator = AppGenerator(
        appName: appName,
        template: template,
        outputPath: appPath,
      );

      await generator.generate();
      
      printSuccess('App "$appName" created successfully!');
      print('');
      print('Next steps:');
      print('  1. Add your models to lib/apps/$appName/models/');
      print('  2. Create views in lib/apps/$appName/views/');
      print('  3. Configure URLs in lib/apps/$appName/urls.dart');
      print('  4. Include the app in your main urls.dart');
      print('');
      print('Happy coding! 🚀');
    } catch (e) {
      printError('Failed to create app: $e');
    }
  }

  bool _isValidAppName(String name) {
    final regex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');
    return regex.hasMatch(name);
  }

  bool _isInDartangoProject() {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) return false;
    
    final content = pubspecFile.readAsStringSync();
    return content.contains('dartango');
  }
}