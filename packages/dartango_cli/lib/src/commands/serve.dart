import 'dart:io';
import 'package:args/args.dart';
import 'package:dartango/src/core/management/command.dart';

class ServeCommand extends Command {
  @override
  String get name => 'serve';

  @override
  String get description => 'Start the development server';

  @override
  String get help => '''
Start the Dartango development server.

This command starts a local development server that serves your Dartango application.
The server includes hot reload capabilities and detailed error reporting.

Examples:
  dartango serve
  dartango serve --port=3000
  dartango serve --host=0.0.0.0 --port=8080
  dartango serve --no-debug
''';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption('host',
        abbr: 'h', defaultsTo: 'localhost', help: 'Host to bind the server to');
    parser.addOption('port',
        abbr: 'p', defaultsTo: '8000', help: 'Port to bind the server to');
    parser.addFlag('debug',
        abbr: 'd', defaultsTo: true, help: 'Enable debug mode');
    parser.addFlag('hot-reload', defaultsTo: true, help: 'Enable hot reload');
    parser.addFlag('open',
        abbr: 'o',
        defaultsTo: false,
        help: 'Open the app in the default browser');
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    if (!_isInDartangoProject()) {
      printError('This command must be run from within a Dartango project');
      return;
    }

    final host = args['host'] as String;
    final portStr = args['port'] as String;
    final debug = args['debug'] as bool;
    final hotReload = args['hot-reload'] as bool;
    final open = args['open'] as bool;

    int port;
    try {
      port = int.parse(portStr);
    } catch (e) {
      printError('Invalid port number: $portStr');
      return;
    }

    if (port < 1 || port > 65535) {
      printError('Port must be between 1 and 65535');
      return;
    }

    printInfo('Starting Dartango development server...');
    printInfo('Host: $host');
    printInfo('Port: $port');
    printInfo('Debug mode: ${debug ? 'enabled' : 'disabled'}');
    printInfo('Hot reload: ${hotReload ? 'enabled' : 'disabled'}');
    print('');

    try {
      final process = await Process.start(
        'dart',
        ['run', 'bin/main.dart', '--host=$host', '--port=$port'],
        mode: ProcessStartMode.inheritStdio,
      );

      if (open) {
        await _openBrowser('http://$host:$port');
      }

      printSuccess('Development server running at http://$host:$port/');
      printInfo('Press Ctrl+C to stop the server');
      print('');

      // Wait for the process to complete
      final exitCode = await process.exitCode;

      if (exitCode != 0) {
        printError('Server exited with code $exitCode');
      }
    } catch (e) {
      printError('Failed to start server: $e');
      printInfo('Make sure you have a bin/main.dart file in your project');
    }
  }

  Future<void> _openBrowser(String url) async {
    try {
      if (Platform.isWindows) {
        await Process.run('start', [url], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      printWarning('Failed to open browser: $e');
    }
  }

  bool _isInDartangoProject() {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) return false;

    final content = pubspecFile.readAsStringSync();
    return content.contains('dartango');
  }
}
