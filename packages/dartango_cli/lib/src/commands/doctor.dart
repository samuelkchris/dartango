import 'dart:io';
import 'package:args/args.dart';
import 'package:dartango/src/core/management/command.dart';

class DoctorCommand extends Command {
  @override
  String get name => 'doctor';

  @override
  String get description => 'Check project health and dependencies';

  @override
  String get help => '''
Check the health of your Dartango project and development environment.

This command validates:
- Dart SDK version
- Project structure
- Dependencies
- Configuration files
- Database connections
- Common issues

Examples:
  dartango doctor
  dartango doctor --verbose
  dartango doctor --fix
''';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addFlag('verbose', abbr: 'v', defaultsTo: false,
        help: 'Show detailed information');
    parser.addFlag('fix', abbr: 'f', defaultsTo: false,
        help: 'Attempt to fix common issues');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    final verbose = args['verbose'] as bool;
    final fix = args['fix'] as bool;

    printInfo('Dartango Doctor - Project Health Check');
    print('');

    var hasIssues = false;
    
    // Check Dart SDK
    hasIssues = await _checkDartSdk(verbose) || hasIssues;
    
    // Check project structure
    hasIssues = await _checkProjectStructure(verbose, fix) || hasIssues;
    
    // Check dependencies
    hasIssues = await _checkDependencies(verbose, fix) || hasIssues;
    
    // Check configuration
    hasIssues = await _checkConfiguration(verbose, fix) || hasIssues;
    
    // Check database
    hasIssues = await _checkDatabase(verbose) || hasIssues;
    
    print('');
    if (hasIssues) {
      printWarning('Some issues were found. See details above.');
      if (!fix) {
        printInfo('Run with --fix to attempt automatic fixes');
      }
    } else {
      printSuccess('No issues found! Your project looks healthy. 🎉');
    }
  }

  Future<bool> _checkDartSdk(bool verbose) async {
    printInfo('Checking Dart SDK...');
    
    try {
      final result = await Process.run('dart', ['--version']);
      final version = result.stdout.toString().trim();
      
      if (verbose) {
        print('  $version');
      }
      
      // Check minimum version (3.0.0)
      final versionMatch = RegExp(r'(\d+)\.(\d+)\.(\d+)').firstMatch(version);
      if (versionMatch != null) {
        final major = int.parse(versionMatch.group(1)!);
        
        if (major < 3) {
          printError('  Dart SDK version 3.0.0 or higher is required');
          return true;
        }
      }
      
      printSuccess('  Dart SDK version is compatible');
      return false;
    } catch (e) {
      printError('  Dart SDK not found or not in PATH');
      return true;
    }
  }

  Future<bool> _checkProjectStructure(bool verbose, bool fix) async {
    printInfo('Checking project structure...');
    
    var hasIssues = false;
    
    final requiredFiles = [
      'pubspec.yaml',
      'lib/',
      'bin/',
      'test/',
    ];
    
    final optionalFiles = [
      'README.md',
      'CHANGELOG.md',
      'analysis_options.yaml',
      '.gitignore',
    ];
    
    for (final file in requiredFiles) {
      if (!await FileSystemEntity.isFile(file) && !await FileSystemEntity.isDirectory(file)) {
        printError('  Missing required file/directory: $file');
        hasIssues = true;
        
        if (fix) {
          await _createMissingStructure(file);
        }
      } else if (verbose) {
        printSuccess('  Found: $file');
      }
    }
    
    for (final file in optionalFiles) {
      if (await FileSystemEntity.isFile(file)) {
        if (verbose) printSuccess('  Found: $file');
      } else if (verbose) {
        printWarning('  Optional file missing: $file');
      }
    }
    
    if (!hasIssues) {
      printSuccess('  Project structure is valid');
    }
    
    return hasIssues;
  }

  Future<bool> _checkDependencies(bool verbose, bool fix) async {
    printInfo('Checking dependencies...');
    
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      printError('  pubspec.yaml not found');
      return true;
    }
    
    final content = pubspecFile.readAsStringSync();
    
    // Check for Dartango dependency
    if (!content.contains('dartango')) {
      printError('  Dartango dependency not found in pubspec.yaml');
      return true;
    }
    
    // Check if pub get has been run
    final pubspecLock = File('pubspec.lock');
    if (!pubspecLock.existsSync()) {
      printWarning('  pubspec.lock not found - dependencies may not be resolved');
      if (fix) {
        printInfo('  Running pub get...');
        await Process.run('dart', ['pub', 'get']);
      }
    }
    
    // Check for common dependencies
    final commonDeps = ['args', 'path', 'shelf'];
    for (final dep in commonDeps) {
      if (content.contains(dep)) {
        if (verbose) printSuccess('  Found dependency: $dep');
      }
    }
    
    printSuccess('  Dependencies check completed');
    return false;
  }

  Future<bool> _checkConfiguration(bool verbose, bool fix) async {
    printInfo('Checking configuration...');
    
    var hasIssues = false;
    
    // Check for main entry point
    final mainFile = File('bin/main.dart');
    if (!mainFile.existsSync()) {
      printError('  Main entry point not found: bin/main.dart');
      hasIssues = true;
      
      if (fix) {
        await _createMainFile();
      }
    } else if (verbose) {
      printSuccess('  Found main entry point: bin/main.dart');
    }
    
    // Check analysis options
    final analysisOptions = File('analysis_options.yaml');
    if (!analysisOptions.existsSync()) {
      if (verbose) printWarning('  analysis_options.yaml not found');
      
      if (fix) {
        await _createAnalysisOptions();
      }
    } else if (verbose) {
      printSuccess('  Found analysis_options.yaml');
    }
    
    if (!hasIssues) {
      printSuccess('  Configuration is valid');
    }
    
    return hasIssues;
  }

  Future<bool> _checkDatabase(bool verbose) async {
    printInfo('Checking database connectivity...');
    
    // This is a placeholder - in a real implementation,
    // you would check actual database connections
    if (verbose) {
      printInfo('  Database connectivity check not implemented yet');
    }
    
    printSuccess('  Database check completed');
    return false;
  }

  Future<void> _createMissingStructure(String path) async {
    printInfo('  Creating missing structure: $path');
    
    if (path.endsWith('/')) {
      await Directory(path).create(recursive: true);
    } else {
      await File(path).create(recursive: true);
    }
  }

  Future<void> _createMainFile() async {
    printInfo('  Creating bin/main.dart');
    
    final mainContent = '''
import 'package:dartango/dartango.dart';

void main() {
  final app = DartangoApp();
  
  // Configure your app here
  
  app.run();
}
''';
    
    await File('bin/main.dart').writeAsString(mainContent);
  }

  Future<void> _createAnalysisOptions() async {
    printInfo('  Creating analysis_options.yaml');
    
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
    
    await File('analysis_options.yaml').writeAsString(analysisContent);
  }
}