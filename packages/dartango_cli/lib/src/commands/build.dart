import 'dart:io';
import 'package:args/args.dart';
import 'package:dartango/src/core/management/command.dart';

class BuildCommand extends Command {
  @override
  String get name => 'build';

  @override
  String get description => 'Build the project for production';

  @override
  String get help => '''
Build the Dartango project for production deployment.

This command compiles the project and optimizes it for production use.
It creates a build directory with all necessary files for deployment.

Examples:
  dartango build
  dartango build --output=dist
  dartango build --mode=release
  dartango build --verbose
''';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption('output',
        abbr: 'o',
        defaultsTo: 'build',
        help: 'Output directory for build files');
    parser.addOption('mode',
        abbr: 'm',
        defaultsTo: 'release',
        allowed: ['debug', 'release'],
        help: 'Build mode');
    parser.addFlag('verbose',
        abbr: 'v', defaultsTo: false, help: 'Enable verbose output');
    parser.addFlag('clean',
        abbr: 'c',
        defaultsTo: false,
        help: 'Clean build directory before building');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    if (!_isInDartangoProject()) {
      printError('This command must be run from within a Dartango project');
      return;
    }

    final output = args['output'] as String;
    final mode = args['mode'] as String;
    final verbose = args['verbose'] as bool;
    final clean = args['clean'] as bool;

    final buildDir = Directory(output);

    if (clean && await buildDir.exists()) {
      printInfo('Cleaning build directory...');
      await buildDir.delete(recursive: true);
    }

    if (!await buildDir.exists()) {
      await buildDir.create(recursive: true);
    }

    printInfo('Building Dartango project...');
    printInfo('Output directory: $output');
    printInfo('Build mode: $mode');
    print('');

    try {
      // Run dart compile
      final compileArgs = [
        'compile',
        'exe',
        'bin/main.dart',
        '-o',
        '$output/app',
      ];

      if (mode == 'release') {
        compileArgs.add('--optimize');
      }

      final compileProcess = await Process.start(
        'dart',
        compileArgs,
        mode: verbose ? ProcessStartMode.inheritStdio : ProcessStartMode.normal,
      );

      final compileExitCode = await compileProcess.exitCode;

      if (compileExitCode != 0) {
        printError('Compilation failed with exit code $compileExitCode');
        return;
      }

      // Copy static assets
      await _copyStaticAssets(output);

      // Generate deployment configuration
      await _generateDeploymentConfig(output, mode);

      printSuccess('Build completed successfully!');
      print('');
      print('Build artifacts:');
      print('  Executable: $output/app');
      print('  Static files: $output/static/');
      print('  Configuration: $output/config.yaml');
      print('');
      print('To deploy, copy the $output directory to your server.');
    } catch (e) {
      printError('Build failed: $e');
    }
  }

  Future<void> _copyStaticAssets(String outputDir) async {
    final staticDir = Directory('static');
    if (!await staticDir.exists()) return;

    final outputStaticDir = Directory('$outputDir/static');
    if (!await outputStaticDir.exists()) {
      await outputStaticDir.create(recursive: true);
    }

    await for (final entity in staticDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = entity.path.replaceFirst('static/', '');
        final outputPath = '$outputDir/static/$relativePath';
        final outputFile = File(outputPath);

        await outputFile.create(recursive: true);
        await entity.copy(outputPath);
      }
    }
  }

  Future<void> _generateDeploymentConfig(String outputDir, String mode) async {
    final configFile = File('$outputDir/config.yaml');
    final config = '''
# Dartango Deployment Configuration
mode: $mode
server:
  host: 0.0.0.0
  port: 8000
database:
  # Configure your database connection here
  type: sqlite
  path: data/app.db
logging:
  level: ${mode == 'debug' ? 'debug' : 'info'}
  file: logs/app.log
''';

    await configFile.writeAsString(config);
  }

  bool _isInDartangoProject() {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) return false;

    final content = pubspecFile.readAsStringSync();
    return content.contains('dartango');
  }
}
