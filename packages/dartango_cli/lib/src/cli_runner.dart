import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dartango/src/core/management/command.dart';

import 'commands/create_project.dart';
import 'commands/start_app.dart';
import 'commands/generate.dart';
import 'commands/serve.dart';
import 'commands/build.dart';
import 'commands/test.dart' as cli_test;
import 'commands/doctor.dart';

class CliRunner {
  late final CommandManager _commandManager;
  late final ArgParser _argParser;

  CliRunner() {
    _commandManager = CommandManager();
    _setupCommands();
    _setupArgParser();
  }

  void _setupCommands() {
    _commandManager.registerAll([
      CreateProjectCommand(),
      StartAppCommand(),
      GenerateCommand(),
      ServeCommand(),
      BuildCommand(),
      cli_test.TestCommand(),
      DoctorCommand(),
    ]);
  }

  void _setupArgParser() {
    _argParser = ArgParser();
    _argParser.addFlag('help', abbr: 'h', help: 'Show help information');
    _argParser.addFlag('version', abbr: 'v', help: 'Show version information');
    _argParser.addFlag('verbose', help: 'Enable verbose logging');
  }

  Future<int> run(List<String> arguments) async {
    try {
      final results = _argParser.parse(arguments);

      if (results['help'] as bool) {
        _showHelp();
        return 0;
      }

      if (results['version'] as bool) {
        _showVersion();
        return 0;
      }

      if (results.rest.isEmpty) {
        _showHelp();
        return 1;
      }

      final commandName = results.rest[0];
      final commandArgs = results.rest.sublist(1);

      await _commandManager.run([commandName, ...commandArgs]);
      return 0;
    } on FormatException catch (e) {
      stderr.writeln('Error: ${e.message}');
      _showHelp();
      return 1;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }

  void _showHelp() {
    print('Dartango CLI - Django-inspired framework for Dart');
    print('');
    print('Usage: dartango <command> [arguments]');
    print('');
    print('Global options:');
    print('  -h, --help       Show this help information');
    print('  -v, --version    Show version information');
    print('  --verbose        Enable verbose logging');
    print('');
    print('Available commands:');
    print('');

    final commands = _commandManager.commands;
    final maxNameLength = commands.fold(
        0, (max, cmd) => cmd.name.length > max ? cmd.name.length : max);

    for (final command in commands) {
      final name = command.name.padRight(maxNameLength);
      print('  $name  ${command.description}');
    }

    print('');
    print(
        'Run "dartango help <command>" for more information about a command.');
  }

  void _showVersion() {
    print('Dartango CLI version 0.0.1');
    print('Dart SDK version: ${Platform.version}');
  }
}
