import 'dart:io';
import 'package:path/path.dart' as path;

class CommandGenerator {
  final String name;
  final String outputPath;
  final bool force;

  CommandGenerator({
    required this.name,
    required this.outputPath,
    this.force = false,
  });

  Future<void> generate() async {
    final commandsDir = Directory(outputPath);
    await commandsDir.create(recursive: true);

    final commandFileName = '${_toSnakeCase(name)}.dart';
    final commandFile = File(path.join(commandsDir.path, commandFileName));

    if (await commandFile.exists() && !force) {
      throw Exception('Command file already exists: ${commandFile.path}');
    }

    final commandContent = _generateCommandContent();
    await commandFile.writeAsString(commandContent);
  }

  String _generateCommandContent() {
    final className = _toPascalCase(name);
    final commandName = _toSnakeCase(name);

    return '''
import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:dartango/dartango.dart';

/// ${_toTitleCase(name)} management command
/// 
/// This command handles ${_toTitleCase(name).toLowerCase()} operations.
/// Customize the execute method to implement your specific functionality.
class ${className}Command extends Command {
  @override
  String get name => '$commandName';

  @override
  String get description => '${_toTitleCase(name)} management command';

  @override
  String get help => 'Help for ${_toTitleCase(name)} command';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    
    // Common options
    parser.addFlag('verbose', abbr: 'v', defaultsTo: false,
        help: 'Enable verbose output');
    parser.addFlag('dry-run', abbr: 'd', defaultsTo: false,
        help: 'Show what would be done without actually doing it');
    parser.addFlag('force', abbr: 'f', defaultsTo: false,
        help: 'Force execution even if there are warnings');
    
    // Custom options for this command
    parser.addOption('option1', abbr: 'o', defaultsTo: 'default_value',
        help: 'Custom option 1 for ${_toTitleCase(name)}');
    parser.addOption('option2', help: 'Custom option 2 for ${_toTitleCase(name)}');
    parser.addFlag('enable-feature', defaultsTo: false,
        help: 'Enable a specific feature');
    
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    final verbose = args['verbose'] as bool;
    final dryRun = args['dry-run'] as bool;
    final force = args['force'] as bool;
    final option1 = args['option1'] as String;
    final option2 = args['option2'] as String?;
    final enableFeature = args['enable-feature'] as bool;

    if (verbose) {
      printInfo('Starting ${_toTitleCase(name)} command execution');
      printInfo('Options:');
      printInfo('  Verbose: \$verbose');
      printInfo('  Dry run: \$dryRun');
      printInfo('  Force: \$force');
      printInfo('  Option 1: \$option1');
      printInfo('  Option 2: \${option2 ?? 'not set'}');
      printInfo('  Enable feature: \$enableFeature');
    }

    try {
      // Validate prerequisites
      if (!await _validatePrerequisites(verbose)) {
        printError('Prerequisites validation failed');
        return;
      }

      // Check for warnings
      final warnings = await _checkWarnings();
      if (warnings.isNotEmpty && !force) {
        printWarning('Warnings found:');
        for (final warning in warnings) {
          printWarning('  - \$warning');
        }
        printInfo('Use --force to proceed anyway');
        return;
      }

      // Execute the main logic
      await _executeMainLogic(args, verbose, dryRun);

      // Cleanup if needed
      await _cleanup(verbose);

      printSuccess('${_toTitleCase(name)} command completed successfully!');
    } catch (e) {
      printError('${_toTitleCase(name)} command failed: \$e');
      if (verbose) {
        printError('Stack trace: \${StackTrace.current}');
      }
    }
  }

  /// Validate prerequisites before running the command
  Future<bool> _validatePrerequisites(bool verbose) async {
    if (verbose) {
      printInfo('Validating prerequisites...');
    }

    // Example validations
    final validations = [
      _checkDatabaseConnection(),
      _checkRequiredFiles(),
      _checkPermissions(),
    ];

    final results = await Future.wait(validations);
    final allValid = results.every((result) => result);

    if (verbose) {
      printInfo('Prerequisites validation: \${allValid ? 'passed' : 'failed'}');
    }

    return allValid;
  }

  /// Check for warnings that might affect execution
  Future<List<String>> _checkWarnings() async {
    final warnings = <String>[];

    // Example warning checks
    if (!await _isDatabaseEmpty()) {
      warnings.add('Database is not empty, existing data might be affected');
    }

    if (!await _hasBackup()) {
      warnings.add('No recent backup found, consider creating one first');
    }

    return warnings;
  }

  /// Execute the main command logic
  Future<void> _executeMainLogic(ArgResults args, bool verbose, bool dryRun) async {
    if (verbose) {
      printInfo('Executing main logic...');
    }

    // Step 1: Preparation
    await _prepareExecution(verbose, dryRun);

    // Step 2: Process data
    await _processData(args, verbose, dryRun);

    // Step 3: Apply changes
    await _applyChanges(verbose, dryRun);

    // Step 4: Verify results
    await _verifyResults(verbose);
  }

  /// Prepare for execution
  Future<void> _prepareExecution(bool verbose, bool dryRun) async {
    if (verbose) {
      printInfo('Preparing execution...');
    }

    if (dryRun) {
      printInfo('[DRY RUN] Would prepare execution environment');
      return;
    }

    // Implement your preparation logic here
    // Example: Create temporary directories, load configuration, etc.
    await _createTempDirectories();
    await _loadConfiguration();
  }

  /// Process data according to command logic
  Future<void> _processData(ArgResults args, bool verbose, bool dryRun) async {
    if (verbose) {
      printInfo('Processing data...');
    }

    final option1 = args['option1'] as String;
    final option2 = args['option2'] as String?;
    final enableFeature = args['enable-feature'] as bool;

    if (dryRun) {
      printInfo('[DRY RUN] Would process data with options:');
      printInfo('  Option 1: \$option1');
      printInfo('  Option 2: \${option2 ?? 'not set'}');
      printInfo('  Enable feature: \$enableFeature');
      return;
    }

    // Implement your data processing logic here
    // Example: Read files, query database, transform data, etc.
    await _readInputData();
    await _transformData(option1, option2, enableFeature);
  }

  /// Apply changes based on processed data
  Future<void> _applyChanges(bool verbose, bool dryRun) async {
    if (verbose) {
      printInfo('Applying changes...');
    }

    if (dryRun) {
      printInfo('[DRY RUN] Would apply changes to the system');
      return;
    }

    // Implement your change application logic here
    // Example: Update database, write files, send notifications, etc.
    await _updateDatabase();
    await _writeOutputFiles();
    await _sendNotifications();
  }

  /// Verify that the results are correct
  Future<void> _verifyResults(bool verbose) async {
    if (verbose) {
      printInfo('Verifying results...');
    }

    // Implement your verification logic here
    // Example: Check database integrity, validate files, etc.
    final isValid = await _validateResults();
    
    if (isValid) {
      if (verbose) {
        printSuccess('Results verification passed');
      }
    } else {
      throw Exception('Results verification failed');
    }
  }

  /// Cleanup resources and temporary files
  Future<void> _cleanup(bool verbose) async {
    if (verbose) {
      printInfo('Cleaning up...');
    }

    // Implement your cleanup logic here
    await _removeTempDirectories();
    await _closeConnections();
  }

  // Helper methods for validation
  Future<bool> _checkDatabaseConnection() async {
    // Implement database connection check
    return true; // Placeholder
  }

  Future<bool> _checkRequiredFiles() async {
    // Implement required files check
    return true; // Placeholder
  }

  Future<bool> _checkPermissions() async {
    // Implement permissions check
    return true; // Placeholder
  }

  Future<bool> _isDatabaseEmpty() async {
    // Implement database empty check
    return false; // Placeholder
  }

  Future<bool> _hasBackup() async {
    // Implement backup check
    return true; // Placeholder
  }

  // Helper methods for execution
  Future<void> _createTempDirectories() async {
    // Implement temp directory creation
    final tempDir = Directory('.tmp/$commandName');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
  }

  Future<void> _loadConfiguration() async {
    // Implement configuration loading
  }

  Future<void> _readInputData() async {
    // Implement input data reading
  }

  Future<void> _transformData(String option1, String? option2, bool enableFeature) async {
    // Implement data transformation logic
  }

  Future<void> _updateDatabase() async {
    // Implement database update logic
  }

  Future<void> _writeOutputFiles() async {
    // Implement output file writing
  }

  Future<void> _sendNotifications() async {
    // Implement notification sending
  }

  Future<bool> _validateResults() async {
    // Implement results validation
    return true; // Placeholder
  }

  Future<void> _removeTempDirectories() async {
    // Implement temp directory removal
    final tempDir = Directory('.tmp/$commandName');
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }

  Future<void> _closeConnections() async {
    // Implement connection closing
  }
}

// Utility class for command-specific operations
class ${className}Utils {
  static Future<Map<String, dynamic>> readConfig(String configPath) async {
    // Implement config reading
    return {};
  }

  static Future<void> writeConfig(String configPath, Map<String, dynamic> config) async {
    // Implement config writing
  }

  static String formatOutput(dynamic data) {
    // Implement output formatting
    return data.toString();
  }

  static bool validateInput(String input) {
    // Implement input validation
    return input.isNotEmpty;
  }
}

// Custom exception for command-specific errors
class ${className}Exception implements Exception {
  final String message;
  final int? exitCode;

  const ${className}Exception(this.message, [this.exitCode]);

  @override
  String toString() => message;
}

// Usage example in comments:
/*
// Register the command in your command manager:
final commandManager = CommandManager();
commandManager.register(${className}Command());

// Run the command:
await commandManager.run(['$commandName', '--verbose', '--option1=custom_value']);
*/
''';
  }

  String _toPascalCase(String input) {
    return input
        .split('_')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
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
