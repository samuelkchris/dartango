import 'dart:io';
import 'package:args/args.dart';
import 'package:dartango/src/core/management/command.dart';

class TestCommand extends Command {
  @override
  String get name => 'test';

  @override
  String get description => 'Run tests';

  @override
  String get help => '''
Run tests for the Dartango project.

This command runs all tests or specific test files/patterns.
It supports various test runners and reporting options.

Examples:
  dartango test
  dartango test --app=users
  dartango test --file=test/models/user_test.dart
  dartango test --coverage
  dartango test --watch
''';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption('app', abbr: 'a', help: 'Run tests for specific app');
    parser.addOption('file', abbr: 'f', help: 'Run specific test file');
    parser.addOption('pattern', abbr: 'p', help: 'Run tests matching pattern');
    parser.addFlag('coverage', abbr: 'c', defaultsTo: false,
        help: 'Generate code coverage report');
    parser.addFlag('watch', abbr: 'w', defaultsTo: false,
        help: 'Watch for changes and re-run tests');
    parser.addFlag('verbose', abbr: 'v', defaultsTo: false,
        help: 'Enable verbose output');
    parser.addOption('reporter', abbr: 'r', defaultsTo: 'compact',
        allowed: ['compact', 'expanded', 'json'],
        help: 'Test reporter format');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    if (!_isInDartangoProject()) {
      printError('This command must be run from within a Dartango project');
      return;
    }

    final app = args['app'] as String?;
    final file = args['file'] as String?;
    final pattern = args['pattern'] as String?;
    final coverage = args['coverage'] as bool;
    final watch = args['watch'] as bool;
    final verbose = args['verbose'] as bool;
    final reporter = args['reporter'] as String;

    if (!Directory('test').existsSync()) {
      printError('No test directory found');
      printInfo('Create a test directory and add some tests first');
      return;
    }

    final testArgs = <String>['test'];

    // Add specific test file or pattern
    if (file != null) {
      if (!File(file).existsSync()) {
        printError('Test file not found: $file');
        return;
      }
      testArgs.add(file);
    } else if (app != null) {
      final appTestDir = 'test/apps/$app';
      if (!Directory(appTestDir).existsSync()) {
        printError('No tests found for app: $app');
        return;
      }
      testArgs.add(appTestDir);
    } else if (pattern != null) {
      testArgs.addAll(['--name', pattern]);
    }

    // Add reporter
    testArgs.addAll(['--reporter', reporter]);

    // Add coverage
    if (coverage) {
      testArgs.add('--coverage=coverage');
    }

    // Add verbose
    if (verbose) {
      testArgs.add('--verbose');
    }

    printInfo('Running tests...');
    if (app != null) printInfo('App: $app');
    if (file != null) printInfo('File: $file');
    if (pattern != null) printInfo('Pattern: $pattern');
    if (coverage) printInfo('Coverage: enabled');
    print('');

    try {
      if (watch) {
        await _runTestsWithWatch(testArgs);
      } else {
        await _runTests(testArgs, coverage);
      }
    } catch (e) {
      printError('Test execution failed: $e');
    }
  }

  Future<void> _runTests(List<String> testArgs, bool coverage) async {
    final process = await Process.start(
      'dart',
      testArgs,
      mode: ProcessStartMode.inheritStdio,
    );

    final exitCode = await process.exitCode;

    if (exitCode == 0) {
      printSuccess('All tests passed!');
      
      if (coverage) {
        print('');
        printInfo('Generating coverage report...');
        await _generateCoverageReport();
      }
    } else {
      printError('Some tests failed (exit code: $exitCode)');
    }
  }

  Future<void> _runTestsWithWatch(List<String> testArgs) async {
    printInfo('Running tests in watch mode...');
    printInfo('Press Ctrl+C to stop watching');
    print('');

    // Remove any existing watch flags
    testArgs.removeWhere((arg) => arg.startsWith('--watch'));

    while (true) {
      final process = await Process.start(
        'dart',
        testArgs,
        mode: ProcessStartMode.inheritStdio,
      );

      await process.exitCode;

      print('');
      printInfo('Waiting for file changes...');
      
      // Simple file watching - in a real implementation, you'd use a proper file watcher
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> _generateCoverageReport() async {
    try {
      // Generate HTML coverage report
      final formatProcess = await Process.start(
        'dart',
        ['run', 'coverage:format_coverage', '--lcov', '--in=coverage', '--out=coverage/lcov.info'],
        mode: ProcessStartMode.normal,
      );

      await formatProcess.exitCode;

      // Generate HTML report
      final htmlProcess = await Process.start(
        'genhtml',
        ['coverage/lcov.info', '-o', 'coverage/html'],
        mode: ProcessStartMode.normal,
      );

      final htmlExitCode = await htmlProcess.exitCode;

      if (htmlExitCode == 0) {
        printSuccess('Coverage report generated: coverage/html/index.html');
      } else {
        printWarning('HTML coverage report generation failed. Install genhtml for HTML reports.');
        printInfo('Coverage data available at: coverage/lcov.info');
      }
    } catch (e) {
      printWarning('Coverage report generation failed: $e');
    }
  }

  bool _isInDartangoProject() {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) return false;
    
    final content = pubspecFile.readAsStringSync();
    return content.contains('dartango');
  }
}