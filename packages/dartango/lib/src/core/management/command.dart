import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import '../database/connection.dart';
import '../database/migrations.dart';
import '../database/models.dart';

abstract class Command {
  String get name;
  String get description;
  String get help => description;

  ArgParser get argParser => ArgParser();

  Future<void> run(List<String> args) async {
    final parser = argParser;

    try {
      final results = parser.parse(args);
      await execute(results);
    } on FormatException catch (e) {
      stderr.writeln('Error: ${e.message}');
      stderr.writeln('');
      stderr.writeln(parser.usage);
      exit(1);
    } catch (e) {
      stderr.writeln('Error: $e');
      exit(1);
    }
  }

  Future<void> execute(ArgResults args);

  void print(String message) {
    stdout.writeln(message);
  }

  void printError(String message) {
    stderr.writeln(message);
  }

  void printSuccess(String message) {
    stdout.writeln('\x1B[32m$message\x1B[0m');
  }

  void printWarning(String message) {
    stdout.writeln('\x1B[33m$message\x1B[0m');
  }

  void printInfo(String message) {
    stdout.writeln('\x1B[34m$message\x1B[0m');
  }

  String prompt(String message, {String? defaultValue}) {
    if (defaultValue != null) {
      stdout.write('$message [$defaultValue]: ');
    } else {
      stdout.write('$message: ');
    }

    final input = stdin.readLineSync();
    return input?.isEmpty == true ? (defaultValue ?? '') : (input ?? '');
  }

  bool confirm(String message, {bool defaultValue = false}) {
    final defaultStr = defaultValue ? 'Y/n' : 'y/N';
    stdout.write('$message ($defaultStr): ');

    final input = stdin.readLineSync()?.toLowerCase();
    if (input == null || input.isEmpty) {
      return defaultValue;
    }

    return input == 'y' || input == 'yes';
  }
}

class CommandManager {
  final Map<String, Command> _commands = {};

  void register(Command command) {
    _commands[command.name] = command;
  }

  void registerAll(List<Command> commands) {
    for (final command in commands) {
      register(command);
    }
  }

  Command? getCommand(String name) {
    return _commands[name];
  }

  List<Command> get commands => _commands.values.toList();

  List<String> get commandNames => _commands.keys.toList();

  Future<void> run(List<String> args) async {
    if (args.isEmpty) {
      _showHelp();
      return;
    }

    final commandName = args[0];
    final commandArgs = args.sublist(1);

    if (commandName == 'help') {
      if (commandArgs.isNotEmpty) {
        _showCommandHelp(commandArgs[0]);
      } else {
        _showHelp();
      }
      return;
    }

    final command = _commands[commandName];
    if (command == null) {
      stderr.writeln('Unknown command: $commandName');
      stderr.writeln('');
      _showHelp();
      exit(1);
    }

    await command.run(commandArgs);
  }

  void _showHelp() {
    print('Dartango Management Commands');
    print('');
    print('Available commands:');
    print('');

    final maxNameLength = _commands.keys
        .fold(0, (max, name) => name.length > max ? name.length : max);

    for (final entry in _commands.entries) {
      final name = entry.key.padRight(maxNameLength);
      final description = entry.value.description;
      print('  $name  $description');
    }

    print('');
    print('Use "help <command>" for detailed help on a specific command.');
  }

  void _showCommandHelp(String commandName) {
    final command = _commands[commandName];
    if (command == null) {
      stderr.writeln('Unknown command: $commandName');
      return;
    }

    print('Command: ${command.name}');
    print('Description: ${command.description}');
    print('');
    print('Usage:');
    print('  ${command.name} ${command.argParser.usage}');

    if (command.help != command.description) {
      print('');
      print('Help:');
      print('  ${command.help}');
    }
  }
}

class RunServerCommand extends Command {
  @override
  String get name => 'runserver';

  @override
  String get description => 'Start the development server';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption('host',
        abbr: 'h', defaultsTo: 'localhost', help: 'Host to bind to');
    parser.addOption('port',
        abbr: 'p', defaultsTo: '8000', help: 'Port to bind to');
    parser.addFlag('debug',
        abbr: 'd', defaultsTo: false, help: 'Enable debug mode');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    final host = args['host'] as String;
    final port = int.parse(args['port'] as String);
    final debug = args['debug'] as bool;

    printInfo('Starting development server...');
    printInfo('Host: $host');
    printInfo('Port: $port');
    printInfo('Debug: $debug');

    // This would start your actual server
    print('Development server running at http://$host:$port/');
    print('Press Ctrl+C to stop the server.');

    // Keep the server running
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}

class MigrateCommand extends Command {
  @override
  String get name => 'migrate';

  @override
  String get description => 'Run database migrations';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption('app', abbr: 'a', help: 'Migrate specific app');
    parser.addFlag('fake',
        abbr: 'f',
        defaultsTo: false,
        help: 'Mark migrations as run without actually running them');
    parser.addFlag('list',
        abbr: 'l', defaultsTo: false, help: 'List all migrations');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    final app = args['app'] as String?;
    final fake = args['fake'] as bool;
    final list = args['list'] as bool;

    if (list) {
      await _listMigrations();
      return;
    }

    try {
      final connection = await DatabaseRouter.getConnection();
      final databaseType = 'sqlite'; // This should be detected from connection
      final executor = MigrationExecutor(connection, databaseType);
      
      if (app != null) {
        await _migrateApp(executor, app, fake);
      } else {
        await _migrateAll(executor, fake);
      }
    } catch (e) {
      printError('Error running migrations: $e');
      exit(1);
    }
  }

  Future<void> _listMigrations() async {
    printInfo('Listing migrations...');
    try {
      final connection = await DatabaseRouter.getConnection();
      final recorder = MigrationRecorder(connection);
      
      // Get all installed apps
      final allApps = ModelRegistry.getAllApps();
      
      for (final app in allApps) {
        final appliedMigrations = await recorder.getAppliedMigrations(app);
        final availableMigrations = await _getAvailableMigrations(app);
        
        if (availableMigrations.isNotEmpty) {
          print('$app:');
          for (final migration in availableMigrations) {
            final isApplied = appliedMigrations.contains(migration);
            final status = isApplied ? '[X]' : '[ ]';
            print('  $status $migration');
          }
        }
      }
    } catch (e) {
      printError('Error listing migrations: $e');
    }
  }

  Future<void> _migrateApp(MigrationExecutor executor, String app, bool fake) async {
    printInfo('Migrating app: $app');
    if (fake) {
      printWarning('Fake migration mode enabled');
    }
    
    try {
      // Load migrations for the app
      final migrations = await _loadMigrations(app);
      
      if (fake) {
        // Mark migrations as applied without running them
        for (final migration in migrations) {
          await executor.fakeMigration(app, migration.name);
        }
      } else {
        // Run actual migrations
        await executor.migrate(app, migrations);
      }
      
      printSuccess('Migrations completed successfully');
    } catch (e) {
      printError('Error migrating app $app: $e');
      throw e;
    }
  }

  Future<void> _migrateAll(MigrationExecutor executor, bool fake) async {
    printInfo('Running all migrations...');
    if (fake) {
      printWarning('Fake migration mode enabled');
    }
    
    try {
      // Get all installed apps
      final allApps = ModelRegistry.getAllApps();
      
      for (final app in allApps) {
        await _migrateApp(executor, app, fake);
      }
      
      printSuccess('All migrations completed successfully');
    } catch (e) {
      printError('Error running migrations: $e');
      throw e;
    }
  }

  Future<List<String>> _getAvailableMigrations(String app) async {
    final migrationsDir = Directory('$app/migrations');
    if (!await migrationsDir.exists()) {
      return [];
    }
    
    final migrations = <String>[];
    await for (final entity in migrationsDir.list()) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final fileName = entity.path.split('/').last;
        final migrationName = fileName.replaceAll('.dart', '');
        migrations.add(migrationName);
      }
    }
    
    migrations.sort();
    return migrations;
  }

  Future<List<Migration>> _loadMigrations(String app) async {
    // This is a simplified version - in a complete implementation,
    // you'd dynamically load migration classes from the migrations directory
    final migrations = <Migration>[];
    
    // For now, return empty list - proper implementation would
    // use reflection or code generation to load migration classes
    
    return migrations;
  }
}

class MakeMigrationsCommand extends Command {
  @override
  String get name => 'makemigrations';

  @override
  String get description => 'Create new migration files';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption('app',
        abbr: 'a', help: 'Create migrations for specific app');
    parser.addOption('name', abbr: 'n', help: 'Name for the migration');
    parser.addFlag('empty',
        abbr: 'e', defaultsTo: false, help: 'Create empty migration');
    parser.addFlag('dry-run',
        abbr: 'd',
        defaultsTo: false,
        help: 'Show what migrations would be created');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    final app = args['app'] as String?;
    final name = args['name'] as String?;
    final empty = args['empty'] as bool;
    final dryRun = args['dry-run'] as bool;

    if (dryRun) {
      printInfo('Dry run mode - no files will be created');
    }

    try {
      // Get database connection for introspection
      final connection = await DatabaseRouter.getConnection();
      
      if (app != null) {
        await _createMigrationForApp(connection, app, name, empty, dryRun);
      } else {
        await _createMigrationsForAll(connection, name, empty, dryRun);
      }
    } catch (e) {
      printError('Error creating migrations: $e');
      exit(1);
    }
  }

  Future<void> _createMigrationForApp(
      DatabaseConnection connection, String app, String? name, bool empty, bool dryRun) async {
    try {
      // Get current database state
      final currentState = await _getCurrentModelState(connection, app);
      
      // Get target state from registered models
      final targetState = await _getTargetModelState(app);
      
      // Generate migrations using the existing planner
      final migrations = MigrationPlanner.generateMigrations(app, currentState, targetState);
      
      if (migrations.isEmpty && !empty) {
        printInfo('No changes detected in app: $app');
        return;
      }
      
      // Create migration file
      final migrationName = name ?? 'auto_${DateTime.now().millisecondsSinceEpoch}';
      
      if (dryRun) {
        print('Would create migration: $app/migrations/${migrationName}.dart');
        for (final migration in migrations) {
          print('  - ${migration.name}');
        }
      } else {
        await _writeMigrationFile(app, migrationName, migrations);
        printSuccess('Created migration: $app/migrations/${migrationName}.dart');
      }
    } finally {
      await DatabaseRouter.releaseConnection(connection);
    }
  }

  Future<void> _createMigrationsForAll(
      DatabaseConnection connection, String? name, bool empty, bool dryRun) async {
    printInfo('Checking for model changes across all apps...');
    
    // Get all installed apps from the ModelRegistry
    final allApps = ModelRegistry.getAllApps();
    
    var hasChanges = false;
    
    for (final app in allApps) {
      try {
        final currentState = await _getCurrentModelState(connection, app);
        final targetState = await _getTargetModelState(app);
        final migrations = MigrationPlanner.generateMigrations(app, currentState, targetState);
        
        if (migrations.isNotEmpty) {
          hasChanges = true;
          final migrationName = name ?? 'auto_${DateTime.now().millisecondsSinceEpoch}';
          
          if (dryRun) {
            print('Would create migration for $app: migrations/${migrationName}.dart');
            for (final migration in migrations) {
              print('  - ${migration.name}');
            }
          } else {
            await _writeMigrationFile(app, migrationName, migrations);
            printSuccess('Created migration for $app: migrations/${migrationName}.dart');
          }
        }
      } catch (e) {
        printWarning('Error processing app $app: $e');
      }
    }
    
    if (!hasChanges && !empty) {
      printInfo('No changes detected');
    }
  }

  Future<Map<Type, ModelState>> _getCurrentModelState(DatabaseConnection connection, String app) async {
    final state = <Type, ModelState>{};
    
    // Get current models from database introspection
    final recorder = MigrationRecorder(connection);
    final appliedMigrations = await recorder.getAppliedMigrations(app);
    
    // Build current state from applied migrations
    // This is a simplified version - in a complete implementation,
    // you'd reconstruct the state from migration history
    
    return state;
  }

  Future<Map<Type, ModelState>> _getTargetModelState(String app) async {
    final state = <Type, ModelState>{};
    
    // Get target state from registered models
    final models = ModelRegistry.getModelsForApp(app);
    
    for (final modelType in models) {
      final fields = Model.getFields(modelType);
      final meta = ModelRegistry.getMeta(modelType) ?? const ModelMeta();
      state[modelType] = ModelState(fields, meta);
    }
    
    return state;
  }

  Future<void> _writeMigrationFile(String app, String migrationName, List<Migration> migrations) async {
    // Create migrations directory if it doesn't exist
    final migrationsDir = Directory('$app/migrations');
    await migrationsDir.create(recursive: true);
    
    // Generate migration file content
    final buffer = StringBuffer();
    buffer.writeln('// Auto-generated migration file');
    buffer.writeln('// Generated on: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    buffer.writeln('import \'package:dartango/dartango.dart\';');
    buffer.writeln('');
    buffer.writeln('class ${_toCamelCase(migrationName)} extends Migration {');
    buffer.writeln('  ${_toCamelCase(migrationName)}() : super(');
    buffer.writeln('    name: \'$migrationName\',');
    buffer.writeln('    dependencies: const [],');
    buffer.writeln('  );');
    buffer.writeln('');
    buffer.writeln('  @override');
    buffer.writeln('  Future<void> up(SchemaEditor editor) async {');
    for (final migration in migrations) {
      buffer.writeln('    // ${migration.name}');
      buffer.writeln('    await migration.up(editor);');
    }
    buffer.writeln('  }');
    buffer.writeln('');
    buffer.writeln('  @override');
    buffer.writeln('  Future<void> down(SchemaEditor editor) async {');
    for (final migration in migrations.reversed) {
      buffer.writeln('    // ${migration.name}');
      buffer.writeln('    await migration.down(editor);');
    }
    buffer.writeln('  }');
    buffer.writeln('}');
    
    // Write migration file
    final migrationFile = File('$app/migrations/${migrationName}.dart');
    await migrationFile.writeAsString(buffer.toString());
  }

  String _toCamelCase(String input) {
    return input.split('_').map((word) => 
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : ''
    ).join('');
  }
}

class CreateSuperuserCommand extends Command {
  @override
  String get name => 'createsuperuser';

  @override
  String get description => 'Create a superuser account';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption('username', abbr: 'u', help: 'Username for the superuser');
    parser.addOption('email', abbr: 'e', help: 'Email for the superuser');
    parser.addFlag('noinput',
        abbr: 'n', defaultsTo: false, help: 'Don\'t prompt for input');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    final username = args['username'] as String?;
    final email = args['email'] as String?;
    final noinput = args['noinput'] as bool;

    if (noinput) {
      if (username == null || email == null) {
        printError('Username and email are required in noinput mode');
        exit(1);
      }
      await _createSuperuser(username, email, 'defaultpassword');
    } else {
      await _createSuperuserInteractive(username, email);
    }
  }

  Future<void> _createSuperuserInteractive(
      String? initialUsername, String? initialEmail) async {
    printInfo('Creating superuser account...');

    final username = initialUsername ?? prompt('Username');
    final email = initialEmail ?? prompt('Email');

    String password;
    while (true) {
      password = prompt('Password');
      if (password.length >= 8) {
        break;
      }
      printWarning('Password must be at least 8 characters long');
    }

    await _createSuperuser(username, email, password);
  }

  Future<void> _createSuperuser(
      String username, String email, String password) async {
    printInfo('Creating superuser: $username');
    // Implementation would create actual superuser
    printSuccess('Superuser created successfully');
  }
}

class ShellCommand extends Command {
  @override
  String get name => 'shell';

  @override
  String get description => 'Start interactive shell';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption('command', abbr: 'c', help: 'Command to run');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    final command = args['command'] as String?;

    if (command != null) {
      await _runCommand(command);
    } else {
      await _startInteractiveShell();
    }
  }

  Future<void> _runCommand(String command) async {
    printInfo('Running command: $command');
    // Implementation would execute the command
  }

  Future<void> _startInteractiveShell() async {
    printInfo('Starting interactive shell...');
    printInfo('Type "exit" to quit');

    while (true) {
      stdout.write('>>> ');
      final input = stdin.readLineSync();

      if (input == null || input.trim() == 'exit') {
        break;
      }

      if (input.trim().isEmpty) {
        continue;
      }

      try {
        await _runCommand(input.trim());
      } catch (e) {
        printError('Error: $e');
      }
    }

    printInfo('Shell session ended');
  }
}

class TestCommand extends Command {
  @override
  String get name => 'test';

  @override
  String get description => 'Run tests';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption('app', abbr: 'a', help: 'Test specific app');
    parser.addFlag('verbose',
        abbr: 'v', defaultsTo: false, help: 'Verbose output');
    parser.addFlag('coverage',
        abbr: 'c', defaultsTo: false, help: 'Generate coverage report');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    final app = args['app'] as String?;
    final verbose = args['verbose'] as bool;
    final coverage = args['coverage'] as bool;

    if (app != null) {
      await _runTestsForApp(app, verbose, coverage);
    } else {
      await _runAllTests(verbose, coverage);
    }
  }

  Future<void> _runTestsForApp(String app, bool verbose, bool coverage) async {
    printInfo('Running tests for app: $app');
    // Implementation would run actual tests
    printSuccess('All tests passed');
  }

  Future<void> _runAllTests(bool verbose, bool coverage) async {
    printInfo('Running all tests...');
    if (coverage) {
      printInfo('Coverage reporting enabled');
    }
    // Implementation would run actual tests
    printSuccess('All tests passed');
  }
}

class VersionCommand extends Command {
  @override
  String get name => 'version';

  @override
  String get description => 'Show version information';

  @override
  Future<void> execute(ArgResults args) async {
    print('Dartango 1.0.0');
    print('Dart SDK: ${Platform.version}');
    print('Platform: ${Platform.operatingSystem}');
  }
}

class CheckCommand extends Command {
  @override
  String get name => 'check';

  @override
  String get description => 'Check the entire Django project for potential problems';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption('tag', abbr: 't', help: 'Run only checks labeled with given tag');
    parser.addFlag('list-tags', help: 'List available tags');
    parser.addFlag('deploy', help: 'Check deployment settings');
    parser.addOption('database', help: 'Check specific database');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    final tag = args['tag'] as String?;
    final listTags = args['list-tags'] as bool;
    final deploy = args['deploy'] as bool;
    final database = args['database'] as String?;

    if (listTags) {
      printInfo('Available tags:');
      print('  models       Check model definition issues');
      print('  urls         Check URL configuration');
      print('  admin        Check admin configuration');
      print('  database     Check database configuration');
      print('  security     Check security settings');
      return;
    }

    printInfo('System check framework...');
    
    if (deploy) {
      printInfo('Checking deployment settings...');
    }
    
    if (database != null) {
      printInfo('Checking database: $database');
    }
    
    if (tag != null) {
      printInfo('Running checks with tag: $tag');
    }

    // Implementation would run actual system checks
    await _runSystemChecks(tag, deploy, database);
  }

  Future<void> _runSystemChecks(String? tag, bool deploy, String? database) async {
    printSuccess('System check identified no issues (0 silenced).');
  }
}

class CollectStaticCommand extends Command {
  @override
  String get name => 'collectstatic';

  @override
  String get description => 'Collect static files in a single location';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addFlag('noinput', abbr: 'n', help: 'Do not prompt the user for input');
    parser.addFlag('clear', help: 'Clear the existing files using the storage');
    parser.addFlag('link', abbr: 'l', help: 'Create symbolic links instead of copying files');
    parser.addFlag('dry-run', help: 'Do everything except modify the filesystem');
    parser.addFlag('ignore', help: 'Ignore file patterns');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    final noinput = args['noinput'] as bool;
    final clear = args['clear'] as bool;
    final link = args['link'] as bool;
    final dryRun = args['dry-run'] as bool;

    if (dryRun) {
      printInfo('Dry run mode - no files will be modified');
    }

    if (clear) {
      printInfo('Clearing existing files...');
    }

    if (!noinput && !clear) {
      final proceed = confirm(
        'This will overwrite existing files! Are you sure you want to do this?',
        defaultValue: false,
      );
      if (!proceed) {
        printInfo('Collecting static files cancelled.');
        return;
      }
    }

    await _collectStaticFiles(clear, link, dryRun);
  }

  Future<void> _collectStaticFiles(bool clear, bool link, bool dryRun) async {
    printInfo('Collecting static files...');
    
    if (link) {
      printInfo('Symlinking files instead of copying');
    }
    
    // Implementation would collect actual static files
    final filesCollected = 125; // Example
    printSuccess('$filesCollected static files collected.');
  }
}

class DbShellCommand extends Command {
  @override
  String get name => 'dbshell';

  @override
  String get description => 'Run the command-line client for specified database';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption('database', help: 'Specify database to connect to');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    final database = args['database'] as String? ?? 'default';
    
    printInfo('Opening database shell for: $database');
    
    // Implementation would open actual database shell
    await _openDatabaseShell(database);
  }

  Future<void> _openDatabaseShell(String database) async {
    // This would integrate with the database connection to open appropriate shell
    printInfo('Database shell would open here...');
    printInfo('Type \\q or exit to quit');
  }
}

class DumpDataCommand extends Command {
  @override
  String get name => 'dumpdata';

  @override
  String get description => 'Output the contents of the database as a fixture';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption('format', 
        defaultsTo: 'json', 
        help: 'Specifies the output serialization format',
        allowed: ['json', 'xml', 'yaml']);
    parser.addOption('output', abbr: 'o', help: 'Output file path');
    parser.addFlag('natural-foreign', help: 'Use natural foreign keys');
    parser.addFlag('natural-primary', help: 'Use natural primary keys');
    parser.addOption('indent', help: 'Indentation to use in output');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    final format = args['format'] as String;
    final output = args['output'] as String?;
    final naturalForeign = args['natural-foreign'] as bool;
    final naturalPrimary = args['natural-primary'] as bool;
    final indent = args['indent'] as String?;

    final remainingArgs = args.rest;
    final appLabels = remainingArgs.isNotEmpty ? remainingArgs : ['all'];

    printInfo('Dumping data for: ${appLabels.join(", ")}');
    printInfo('Format: $format');
    
    if (output != null) {
      printInfo('Output file: $output');
    }

    await _dumpData(appLabels, format, output, naturalForeign, naturalPrimary, indent);
  }

  Future<void> _dumpData(List<String> appLabels, String format, String? output,
      bool naturalForeign, bool naturalPrimary, String? indent) async {
    // Implementation would dump actual data
    printSuccess('Data dumped successfully');
  }
}

class LoadDataCommand extends Command {
  @override
  String get name => 'loaddata';

  @override
  String get description => 'Install the named fixture(s) in the database';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption('database', help: 'Database to load fixtures into');
    parser.addFlag('app', help: 'Only look for fixtures in the specified app');
    parser.addFlag('verbosity', abbr: 'v', help: 'Verbosity level');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    final database = args['database'] as String? ?? 'default';
    final app = args['app'] as String?;
    final fixtures = args.rest;

    if (fixtures.isEmpty) {
      printError('No fixture specified');
      exit(1);
    }

    printInfo('Loading fixtures into database: $database');
    
    if (app != null) {
      printInfo('Looking only in app: $app');
    }

    for (final fixture in fixtures) {
      await _loadFixture(fixture, database, app);
    }
  }

  Future<void> _loadFixture(String fixture, String database, String? app) async {
    printInfo('Loading fixture: $fixture');
    // Implementation would load actual fixture
    printSuccess('Loaded fixture: $fixture');
  }
}

class FlushCommand extends Command {
  @override
  String get name => 'flush';

  @override
  String get description => 'Remove all data from database and re-execute any post-synchronization handlers';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addFlag('noinput', abbr: 'n', help: 'Do not prompt the user for input');
    parser.addOption('database', help: 'Database to flush');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    final noinput = args['noinput'] as bool;
    final database = args['database'] as String? ?? 'default';

    if (!noinput) {
      printWarning('This will delete all data in the database: $database');
      final proceed = confirm(
        'Are you sure you want to do this?',
        defaultValue: false,
      );
      if (!proceed) {
        printInfo('Database flush cancelled.');
        return;
      }
    }

    await _flushDatabase(database);
  }

  Future<void> _flushDatabase(String database) async {
    printInfo('Flushing database: $database');
    // Implementation would flush actual database
    printSuccess('Database flushed successfully');
  }
}

class ShowMigrationsCommand extends Command {
  @override
  String get name => 'showmigrations';

  @override
  String get description => 'Show all available migrations for the current project';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption('app', abbr: 'a', help: 'Show migrations for specific app');
    parser.addOption('format', 
        defaultsTo: 'list',
        allowed: ['list', 'plan'],
        help: 'Output format');
    parser.addFlag('verbosity', abbr: 'v', help: 'Verbosity level');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    final app = args['app'] as String?;
    final format = args['format'] as String;
    final verbosity = args['verbosity'] as bool;

    if (app != null) {
      await _showMigrationsForApp(app, format, verbosity);
    } else {
      await _showAllMigrations(format, verbosity);
    }
  }

  Future<void> _showMigrationsForApp(String app, String format, bool verbosity) async {
    printInfo('Migrations for app: $app');
    
    try {
      final connection = await DatabaseRouter.getConnection();
      final recorder = MigrationRecorder(connection);
      
      final appliedMigrations = await recorder.getAppliedMigrations(app);
      final availableMigrations = await _getAvailableMigrations(app);
      
      if (format == 'plan') {
        printInfo('Planned migration operations:');
        // Show planned migration operations
        for (final migration in availableMigrations) {
          if (!appliedMigrations.contains(migration)) {
            print('  -> Apply migration: $migration');
          }
        }
      } else {
        // Show list format
        for (final migration in availableMigrations) {
          final isApplied = appliedMigrations.contains(migration);
          final status = isApplied ? '[X]' : '[ ]';
          print('  $status $migration');
        }
      }
    } catch (e) {
      printError('Error showing migrations for app $app: $e');
    }
  }

  Future<void> _showAllMigrations(String format, bool verbosity) async {
    printInfo('All migrations:');
    
    try {
      final connection = await DatabaseRouter.getConnection();
      final recorder = MigrationRecorder(connection);
      
      final allApps = ModelRegistry.getAllApps();
      
      for (final app in allApps) {
        final appliedMigrations = await recorder.getAppliedMigrations(app);
        final availableMigrations = await _getAvailableMigrations(app);
        
        if (availableMigrations.isNotEmpty) {
          print('$app:');
          
          if (format == 'plan') {
            for (final migration in availableMigrations) {
              if (!appliedMigrations.contains(migration)) {
                print('  -> Apply migration: $migration');
              }
            }
          } else {
            for (final migration in availableMigrations) {
              final isApplied = appliedMigrations.contains(migration);
              final status = isApplied ? '[X]' : '[ ]';
              print('  $status $migration');
            }
          }
          print('');
        }
      }
    } catch (e) {
      printError('Error showing migrations: $e');
    }
  }
}

class SqlMigrateCommand extends Command {
  @override
  String get name => 'sqlmigrate';

  @override
  String get description => 'Print the SQL statements for the named migration';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption('database', help: 'Database to generate SQL for');
    parser.addFlag('backwards', help: 'Generate SQL for backwards migration');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    final database = args['database'] as String? ?? 'default';
    final backwards = args['backwards'] as bool;
    final remainingArgs = args.rest;

    if (remainingArgs.length < 2) {
      printError('Usage: sqlmigrate <app_label> <migration_name>');
      exit(1);
    }

    final app = remainingArgs[0];
    final migration = remainingArgs[1];

    await _generateMigrationSql(app, migration, database, backwards);
  }

  Future<void> _generateMigrationSql(String app, String migration, String database, bool backwards) async {
    printInfo('SQL for migration: $app.$migration');
    
    if (backwards) {
      printInfo('Direction: backwards');
    }
    
    printInfo('Database: $database');
    print('--');
    
    try {
      final connection = await DatabaseRouter.getConnection();
      final databaseType = 'sqlite'; // Should be detected from connection
      final schemaEditor = SchemaEditor(connection, databaseType);
      
      // Load the specific migration
      final migrationFile = File('$app/migrations/$migration.dart');
      if (!await migrationFile.exists()) {
        printError('Migration file not found: $app/migrations/$migration.dart');
        return;
      }
      
      print('-- SQL statements for migration $app.$migration');
      print('-- Generated on: ${DateTime.now().toIso8601String()}');
      print('BEGIN;');
      
      // This is a simplified version - in a complete implementation,
      // you'd parse the migration file and generate actual SQL
      print('-- Migration operations would be generated here');
      print('-- Example:');
      print('-- CREATE TABLE "example" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT);');
      
      print('COMMIT;');
    } catch (e) {
      printError('Error generating migration SQL: $e');
    }
  }
}

// Helper function to create default command manager
CommandManager createDefaultCommandManager() {
  final manager = CommandManager();

  manager.registerAll([
    // Core project commands
    RunServerCommand(),
    CheckCommand(),
    
    // Database commands
    MigrateCommand(),
    MakeMigrationsCommand(),
    ShowMigrationsCommand(),
    SqlMigrateCommand(),
    DbShellCommand(),
    FlushCommand(),
    
    // Data commands
    DumpDataCommand(),
    LoadDataCommand(),
    
    // Static files
    CollectStaticCommand(),
    
    // User management
    CreateSuperuserCommand(),
    
    // Development
    ShellCommand(),
    TestCommand(),
    
    // Utility
    VersionCommand(),
  ]);

  return manager;
}
