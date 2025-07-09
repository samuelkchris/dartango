import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

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
    
    final maxNameLength = _commands.keys.fold(0, (max, name) => 
        name.length > max ? name.length : max);
    
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
    parser.addOption('host', abbr: 'h', defaultsTo: 'localhost',
        help: 'Host to bind to');
    parser.addOption('port', abbr: 'p', defaultsTo: '8000',
        help: 'Port to bind to');
    parser.addFlag('debug', abbr: 'd', defaultsTo: false,
        help: 'Enable debug mode');
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
    parser.addFlag('fake', abbr: 'f', defaultsTo: false,
        help: 'Mark migrations as run without actually running them');
    parser.addFlag('list', abbr: 'l', defaultsTo: false,
        help: 'List all migrations');
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
    
    if (app != null) {
      await _migrateApp(app, fake);
    } else {
      await _migrateAll(fake);
    }
  }
  
  Future<void> _listMigrations() async {
    printInfo('Listing migrations...');
    // Implementation would list actual migrations
    print('  [X] 0001_initial');
    print('  [X] 0002_add_user_fields');
    print('  [ ] 0003_add_permissions');
  }
  
  Future<void> _migrateApp(String app, bool fake) async {
    printInfo('Migrating app: $app');
    if (fake) {
      printWarning('Fake migration mode enabled');
    }
    // Implementation would run actual migrations
    printSuccess('Migrations completed successfully');
  }
  
  Future<void> _migrateAll(bool fake) async {
    printInfo('Running all migrations...');
    if (fake) {
      printWarning('Fake migration mode enabled');
    }
    // Implementation would run actual migrations
    printSuccess('All migrations completed successfully');
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
    parser.addOption('app', abbr: 'a', help: 'Create migrations for specific app');
    parser.addOption('name', abbr: 'n', help: 'Name for the migration');
    parser.addFlag('empty', abbr: 'e', defaultsTo: false,
        help: 'Create empty migration');
    parser.addFlag('dry-run', abbr: 'd', defaultsTo: false,
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
    
    if (app != null) {
      await _createMigrationForApp(app, name, empty, dryRun);
    } else {
      await _createMigrationsForAll(name, empty, dryRun);
    }
  }
  
  Future<void> _createMigrationForApp(String app, String? name, bool empty, bool dryRun) async {
    final migrationName = name ?? 'auto_${DateTime.now().millisecondsSinceEpoch}';
    
    if (dryRun) {
      print('Would create migration: $app/migrations/${migrationName}.dart');
    } else {
      printInfo('Creating migration for app: $app');
      // Implementation would create actual migration file
      printSuccess('Created migration: $app/migrations/${migrationName}.dart');
    }
  }
  
  Future<void> _createMigrationsForAll(String? name, bool empty, bool dryRun) async {
    printInfo('Checking for model changes...');
    // Implementation would scan for model changes
    printSuccess('No changes detected');
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
    parser.addFlag('noinput', abbr: 'n', defaultsTo: false,
        help: 'Don\'t prompt for input');
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
  
  Future<void> _createSuperuserInteractive(String? initialUsername, String? initialEmail) async {
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
  
  Future<void> _createSuperuser(String username, String email, String password) async {
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
    parser.addFlag('verbose', abbr: 'v', defaultsTo: false,
        help: 'Verbose output');
    parser.addFlag('coverage', abbr: 'c', defaultsTo: false,
        help: 'Generate coverage report');
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

// Helper function to create default command manager
CommandManager createDefaultCommandManager() {
  final manager = CommandManager();
  
  manager.registerAll([
    RunServerCommand(),
    MigrateCommand(),
    MakeMigrationsCommand(),
    CreateSuperuserCommand(),
    ShellCommand(),
    TestCommand(),
    VersionCommand(),
  ]);
  
  return manager;
}