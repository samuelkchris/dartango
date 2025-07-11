import 'dart:io';
import 'package:args/args.dart';
import 'package:dartango/src/core/management/command.dart';
import 'package:path/path.dart' as path;

import '../generators/model_generator.dart';
import '../generators/view_generator.dart';
import '../generators/middleware_generator.dart';
import '../generators/command_generator.dart';

class GenerateCommand extends Command {
  @override
  String get name => 'generate';

  @override
  String get description => 'Generate code scaffolding';

  @override
  String get help => '''
Generate various types of code scaffolding for your Dartango project.

Available generators:
  model       Generate a model class
  view        Generate a view class
  middleware  Generate middleware
  command     Generate a management command

Examples:
  dartango generate model User
  dartango generate view UserView --app=users
  dartango generate middleware AuthMiddleware
  dartango generate command backup_database
''';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption('app', abbr: 'a', help: 'App to generate code in');
    parser.addOption('output', abbr: 'o', help: 'Output directory');
    parser.addFlag('force',
        abbr: 'f', defaultsTo: false, help: 'Overwrite existing files');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    if (args.rest.length < 2) {
      printError('Generator type and name are required');
      printInfo('Usage: dartango generate <type> <name>');
      printInfo('');
      printInfo('Available types: model, view, middleware, command');
      return;
    }

    final generatorType = args.rest[0];
    final name = args.rest[1];
    final app = args['app'] as String?;
    final output = args['output'] as String?;
    final force = args['force'] as bool;

    if (!_isInDartangoProject()) {
      printError('This command must be run from within a Dartango project');
      return;
    }

    try {
      switch (generatorType) {
        case 'model':
          await _generateModel(name, app, output, force);
          break;
        case 'view':
          await _generateView(name, app, output, force);
          break;
        case 'middleware':
          await _generateMiddleware(name, output, force);
          break;
        case 'command':
          await _generateCommand(name, output, force);
          break;
        default:
          printError('Unknown generator type: $generatorType');
          printInfo('Available types: model, view, middleware, command');
      }
    } catch (e) {
      printError('Failed to generate $generatorType: $e');
    }
  }

  Future<void> _generateModel(
      String name, String? app, String? output, bool force) async {
    if (app == null) {
      printError('App name is required for model generation');
      printInfo('Use --app=<app_name> to specify the app');
      return;
    }

    final appPath = path.join('lib', 'apps', app);
    if (!Directory(appPath).existsSync()) {
      printError('App "$app" does not exist');
      printInfo('Run "dartango startapp $app" to create the app first');
      return;
    }

    final outputPath = output ?? path.join(appPath, 'models');
    final generator = ModelGenerator(
      name: name,
      app: app,
      outputPath: outputPath,
      force: force,
    );

    await generator.generate();
    printSuccess('Model "$name" generated successfully!');
  }

  Future<void> _generateView(
      String name, String? app, String? output, bool force) async {
    if (app == null) {
      printError('App name is required for view generation');
      printInfo('Use --app=<app_name> to specify the app');
      return;
    }

    final appPath = path.join('lib', 'apps', app);
    if (!Directory(appPath).existsSync()) {
      printError('App "$app" does not exist');
      printInfo('Run "dartango startapp $app" to create the app first');
      return;
    }

    final outputPath = output ?? path.join(appPath, 'views');
    final generator = ViewGenerator(
      name: name,
      app: app,
      outputPath: outputPath,
      force: force,
    );

    await generator.generate();
    printSuccess('View "$name" generated successfully!');
  }

  Future<void> _generateMiddleware(
      String name, String? output, bool force) async {
    final outputPath = output ?? path.join('lib', 'middleware');
    final generator = MiddlewareGenerator(
      name: name,
      outputPath: outputPath,
      force: force,
    );

    await generator.generate();
    printSuccess('Middleware "$name" generated successfully!');
  }

  Future<void> _generateCommand(String name, String? output, bool force) async {
    final outputPath = output ?? path.join('lib', 'commands');
    final generator = CommandGenerator(
      name: name,
      outputPath: outputPath,
      force: force,
    );

    await generator.generate();
    printSuccess('Command "$name" generated successfully!');
  }

  bool _isInDartangoProject() {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) return false;

    final content = pubspecFile.readAsStringSync();
    return content.contains('dartango');
  }
}
