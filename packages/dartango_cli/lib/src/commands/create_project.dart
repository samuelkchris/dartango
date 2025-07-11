import 'dart:io';
import 'package:args/args.dart';
import 'package:dartango/src/core/management/command.dart';
import 'package:path/path.dart' as path;

import '../generators/project_generator.dart';

class CreateProjectCommand extends Command {
  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Dartango project';

  @override
  String get help => '''
Create a new Dartango project with the specified name.

This command creates a new project directory with the following structure:
- lib/: Main application code
- bin/: Executable entry point
- test/: Test files
- pubspec.yaml: Dart package configuration
- README.md: Project documentation

Examples:
  dartango create my_project
  dartango create my_project --template=minimal
  dartango create my_project --output=/path/to/projects
''';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption('template',
        abbr: 't',
        defaultsTo: 'default',
        allowed: ['default', 'minimal', 'api-only'],
        help: 'Template to use for the project');
    parser.addOption('output',
        abbr: 'o', defaultsTo: '.', help: 'Output directory for the project');
    parser.addFlag('force',
        abbr: 'f',
        defaultsTo: false,
        help: 'Overwrite existing project directory');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    if (args.rest.isEmpty) {
      printError('Project name is required');
      printInfo('Usage: dartango create <project_name>');
      return;
    }

    final projectName = args.rest[0];
    final template = args['template'] as String;
    final outputDir = args['output'] as String;
    final force = args['force'] as bool;

    if (!_isValidProjectName(projectName)) {
      printError('Invalid project name: $projectName');
      printInfo(
          'Project name must contain only letters, numbers, and underscores');
      return;
    }

    final projectPath = path.join(outputDir, projectName);
    final projectDir = Directory(projectPath);

    if (await projectDir.exists()) {
      if (!force) {
        printError('Project directory already exists: $projectPath');
        printInfo('Use --force to overwrite existing directory');
        return;
      }

      if (!confirm('Directory "$projectPath" already exists. Overwrite?')) {
        printInfo('Project creation cancelled');
        return;
      }

      await projectDir.delete(recursive: true);
    }

    printInfo('Creating Dartango project: $projectName');
    printInfo('Template: $template');
    printInfo('Output directory: $projectPath');

    try {
      final generator = ProjectGenerator(
        projectName: projectName,
        template: template,
        outputPath: projectPath,
      );

      await generator.generate();

      printSuccess('Project created successfully!');
      print('');
      print('Next steps:');
      print('  cd $projectName');
      print('  dart pub get');
      print('  dartango serve');
      print('');
      print('Happy coding! 🚀');
    } catch (e) {
      printError('Failed to create project: $e');
    }
  }

  bool _isValidProjectName(String name) {
    final regex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');
    return regex.hasMatch(name);
  }
}
