import 'dart:io';
import 'package:test/test.dart';

import '../../../lib/src/core/sessions/cleanup.dart';
import '../../../lib/src/core/database/connection.dart';
import '../../../lib/src/core/database/query.dart';

void main() {
  group('SessionCleaner', () {
    late SessionCleaner cleaner;
    
    setUp(() {
      cleaner = SessionCleaner(
        dryRun: false,
        batchSize: 10,
        verbose: false,
      );
    });
    
    test('cleanDatabaseSessions with no expired sessions', () async {
      final mockConnection = MockDatabaseConnection();
      mockConnection.queryResults = [{'count': 0}];
      
      DatabaseRouter.registerDatabase('default', DatabaseConfig(
        host: 'localhost',
        port: 5432,
        database: 'test',
        username: 'test',
        password: 'test',
        backend: DatabaseBackend.postgresql,
      ));
      
      final deleted = await cleaner.cleanDatabaseSessions();
      expect(deleted, equals(0));
    });
    
    test('cleanDatabaseSessions with expired sessions', () async {
      final mockConnection = MockDatabaseConnection();
      mockConnection.queryResults = [
        {'count': 5},
        [
          {'session_key': 'key1'},
          {'session_key': 'key2'},
          {'session_key': 'key3'},
          {'session_key': 'key4'},
          {'session_key': 'key5'},
        ]
      ];
      
      DatabaseRouter.registerDatabase('default', DatabaseConfig(
        host: 'localhost',
        port: 5432,
        database: 'test',
        username: 'test',
        password: 'test',
        backend: DatabaseBackend.postgresql,
      ));
      
      final deleted = await cleaner.cleanDatabaseSessions();
      expect(deleted, equals(5));
      expect(mockConnection.executeCalls.length, greaterThan(0));
    });
    
    test('cleanDatabaseSessions with dry run', () async {
      final dryRunCleaner = SessionCleaner(
        dryRun: true,
        batchSize: 10,
        verbose: false,
      );
      
      final mockConnection = MockDatabaseConnection();
      mockConnection.queryResults = [{'count': 3}];
      
      DatabaseRouter.registerDatabase('default', DatabaseConfig(
        host: 'localhost',
        port: 5432,
        database: 'test',
        username: 'test',
        password: 'test',
        backend: DatabaseBackend.postgresql,
      ));
      
      final wouldDelete = await dryRunCleaner.cleanDatabaseSessions();
      expect(wouldDelete, equals(3));
      expect(mockConnection.executeCalls, isEmpty);
    });
    
    test('cleanFileSessions with expired files', () async {
      final tempDir = await Directory.systemTemp.createTemp('session_cleanup_test_');
      
      try {
        final oldFile = File('${tempDir.path}/session_old_key.session');
        await oldFile.create();
        await oldFile.setLastModified(DateTime.now().subtract(const Duration(days: 15)));
        
        final recentFile = File('${tempDir.path}/session_recent_key.session');
        await recentFile.create();
        await recentFile.setLastModified(DateTime.now().subtract(const Duration(hours: 1)));
        
        final customCleaner = SessionCleaner(
          dryRun: false,
          batchSize: 10,
          verbose: false,
        );
        
        final deleted = await customCleaner.cleanFileSessions();
        
        expect(deleted, greaterThan(0));
        expect(await oldFile.exists(), isFalse);
        expect(await recentFile.exists(), isTrue);
        
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
    
    test('cleanFileSessions with no session directory', () async {
      final deleted = await cleaner.cleanFileSessions();
      expect(deleted, equals(0));
    });
    
    test('cleanCacheSessions returns zero', () async {
      final deleted = await cleaner.cleanCacheSessions();
      expect(deleted, equals(0));
    });
  });
  
  group('SessionAnalyzer', () {
    late SessionAnalyzer analyzer;
    
    setUp(() {
      analyzer = SessionAnalyzer();
    });
    
    test('analyzeAll returns comprehensive stats', () async {
      final stats = await analyzer.analyzeAll();
      
      expect(stats, isA<SessionStats>());
      expect(stats.database, isA<BackendStats>());
      expect(stats.file, isA<BackendStats>());
      expect(stats.cache, isA<BackendStats>());
      expect(stats.timestamp, isA<DateTime>());
    });
    
    test('analyzes database sessions', () async {
      final mockConnection = MockDatabaseConnection();
      mockConnection.queryResults = [
        {'count': 10},
        {'count': 7},
        {'size': 1024},
      ];
      
      DatabaseRouter.registerDatabase('default', DatabaseConfig(
        host: 'localhost',
        port: 5432,
        database: 'test',
        username: 'test',
        password: 'test',
        backend: DatabaseBackend.postgresql,
      ));
      
      final stats = await analyzer.analyzeAll();
      
      expect(stats.database.total, equals(10));
      expect(stats.database.active, equals(7));
      expect(stats.database.expired, equals(3));
      expect(stats.database.storageSize, equals(1024));
    });
    
    test('analyzes file sessions', () async {
      final tempDir = await Directory.systemTemp.createTemp('session_analyzer_test_');
      
      try {
        final activeFile = File('${tempDir.path}/active_session.session');
        await activeFile.create();
        await activeFile.writeAsString('{"key": "value"}');
        await activeFile.setLastModified(DateTime.now().subtract(const Duration(hours: 1)));
        
        final expiredFile = File('${tempDir.path}/expired_session.session');
        await expiredFile.create();
        await expiredFile.writeAsString('{"old": "data"}');
        await expiredFile.setLastModified(DateTime.now().subtract(const Duration(days: 15)));
        
        final stats = await analyzer.analyzeAll();
        
        expect(stats.file.total, equals(2));
        expect(stats.file.active, equals(1));
        expect(stats.file.expired, equals(1));
        expect(stats.file.storageSize, greaterThan(0));
        
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
  
  group('SessionStats', () {
    late SessionStats stats;
    
    setUp(() {
      stats = SessionStats(
        database: BackendStats(total: 100, active: 80, expired: 20, storageSize: 1024),
        file: BackendStats(total: 50, active: 40, expired: 10, storageSize: 512),
        cache: BackendStats(total: 25, active: 25, expired: 0, storageSize: 256),
        timestamp: DateTime.now(),
      );
    });
    
    test('calculates total statistics', () {
      expect(stats.totalSessions, equals(175));
      expect(stats.totalActive, equals(145));
      expect(stats.totalExpired, equals(30));
      expect(stats.totalStorageSize, equals(1792));
    });
    
    test('generates JSON output', () {
      final json = stats.toJson();
      
      expect(json, contains('"total":'));
      expect(json, contains('"sessions": 175'));
      expect(json, contains('"active": 145'));
      expect(json, contains('"expired": 30'));
      expect(json, contains('"backends":'));
      expect(json, contains('"database":'));
      expect(json, contains('"file":'));
      expect(json, contains('"cache":'));
    });
    
    test('generates CSV output', () {
      final csv = stats.toCsv();
      
      expect(csv, contains('Backend,Total,Active,Expired,Storage (bytes)'));
      expect(csv, contains('Database,100,80,20,1024'));
      expect(csv, contains('File,50,40,10,512'));
      expect(csv, contains('Cache,25,25,0,256'));
      expect(csv, contains('Total,175,145,30,1792'));
    });
    
    test('generates table output', () {
      final table = stats.toTable();
      
      expect(table, contains('Session Statistics'));
      expect(table, contains('Database'));
      expect(table, contains('File'));
      expect(table, contains('Cache'));
      expect(table, contains('Total'));
      expect(table, contains('100'));
      expect(table, contains('80'));
      expect(table, contains('20'));
      expect(table, contains('1.0KB'));
    });
    
    test('generates detailed table output', () {
      final detailedTable = stats.toTable(detailed: true);
      
      expect(detailedTable, contains('Detailed Information:'));
      expect(detailedTable, contains('Active sessions:'));
      expect(detailedTable, contains('Expired sessions:'));
      expect(detailedTable, contains('Storage:'));
    });
    
    test('formats bytes correctly', () {
      final smallStats = SessionStats(
        database: BackendStats(total: 1, active: 1, expired: 0, storageSize: 500),
        file: BackendStats(total: 1, active: 1, expired: 0, storageSize: 1536),
        cache: BackendStats(total: 1, active: 1, expired: 0, storageSize: 2097152),
        timestamp: DateTime.now(),
      );
      
      final table = smallStats.toTable();
      expect(table, contains('500B'));
      expect(table, contains('1.5KB'));
      expect(table, contains('2.0MB'));
    });
  });
  
  group('BackendStats', () {
    test('creates backend statistics', () {
      final stats = BackendStats(
        total: 100,
        active: 75,
        expired: 25,
        storageSize: 2048,
      );
      
      expect(stats.total, equals(100));
      expect(stats.active, equals(75));
      expect(stats.expired, equals(25));
      expect(stats.storageSize, equals(2048));
    });
    
    test('generates JSON output', () {
      final stats = BackendStats(
        total: 50,
        active: 40,
        expired: 10,
        storageSize: 1024,
      );
      
      final json = stats.toJson();
      expect(json, contains('"total": 50'));
      expect(json, contains('"active": 40'));
      expect(json, contains('"expired": 10'));
      expect(json, contains('"storage_bytes": 1024'));
    });
  });
  
  group('SessionCleanupCommand', () {
    late SessionCleanupCommand command;
    
    setUp(() {
      command = SessionCleanupCommand();
      command.configureParser();
    });
    
    test('configures parser with correct options', () {
      expect(command.name, equals('clearsessions'));
      expect(command.description, contains('Remove expired sessions'));
      expect(command.help, contains('Usage:'));
      
      expect(command.parser.options, containsValue(hasProperty('name', 'backend')));
      expect(command.parser.options, containsValue(hasProperty('name', 'dry-run')));
      expect(command.parser.options, containsValue(hasProperty('name', 'batch-size')));
      expect(command.parser.options, containsValue(hasProperty('name', 'verbose')));
    });
    
    test('validates backend option values', () {
      final backendOption = command.parser.options.values
          .firstWhere((option) => option.name == 'backend');
      
      expect(backendOption.allowed, containsAll(['database', 'file', 'cache', 'all']));
      expect(backendOption.defaultsTo, equals('all'));
    });
    
    test('validates batch-size default', () {
      final batchSizeOption = command.parser.options.values
          .firstWhere((option) => option.name == 'batch-size');
      
      expect(batchSizeOption.defaultsTo, equals('1000'));
    });
    
    test('validates dry-run default', () {
      final dryRunOption = command.parser.options.values
          .firstWhere((option) => option.name == 'dry-run');
      
      expect(dryRunOption.defaultsTo, isFalse);
    });
  });
  
  group('SessionStatsCommand', () {
    late SessionStatsCommand command;
    
    setUp(() {
      command = SessionStatsCommand();
      command.configureParser();
    });
    
    test('configures parser with correct options', () {
      expect(command.name, equals('sessionstats'));
      expect(command.description, contains('Display statistics'));
      expect(command.help, contains('Usage:'));
      
      expect(command.parser.options, containsValue(hasProperty('name', 'backend')));
      expect(command.parser.options, containsValue(hasProperty('name', 'format')));
      expect(command.parser.options, containsValue(hasProperty('name', 'detailed')));
    });
    
    test('validates format option values', () {
      final formatOption = command.parser.options.values
          .firstWhere((option) => option.name == 'format');
      
      expect(formatOption.allowed, containsAll(['table', 'json', 'csv']));
      expect(formatOption.defaultsTo, equals('table'));
    });
  });
}

class MockDatabaseConnection implements DatabaseConnection {
  List<Map<String, dynamic>> queryResults = [];
  List<String> executeCalls = [];
  int queryCallCount = 0;
  
  @override
  Future<QueryResult> execute(String sql, [List<dynamic>? parameters]) async {
    executeCalls.add(sql);
    return QueryResult(
      affectedRows: 5,
      insertId: null,
      columns: [],
      rows: [],
    );
  }
  
  @override
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? parameters]) async {
    if (queryCallCount < queryResults.length) {
      final result = queryResults[queryCallCount];
      queryCallCount++;
      
      if (result is List<Map<String, dynamic>>) {
        return result;
      } else {
        return [result];
      }
    }
    return [];
  }
  
  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseConnection) callback) async {
    return await callback(this);
  }
  
  @override
  Future<void> close() async {}
  
  @override
  bool get isOpen => true;
  
  @override
  String get databaseName => 'test';
  
  @override
  DatabaseBackend get backend => DatabaseBackend.postgresql;
  
  @override
  Future<void> ping() async {}
  
  @override
  Future<Map<String, dynamic>> getServerInfo() async => {};
  
  @override
  Future<List<String>> getTableNames() async => [];
  
  @override
  Future<List<Map<String, dynamic>>> getTableSchema(String tableName) async => [];
  
  @override
  Future<List<Map<String, dynamic>>> getIndexes(String tableName) async => [];
  
  @override
  Future<void> beginTransaction() async {}
  
  @override
  Future<void> commitTransaction() async {}
  
  @override
  Future<void> rollbackTransaction() async {}
  
  @override
  Future<void> setSavepoint(String name) async {}
  
  @override
  Future<void> releaseSavepoint(String name) async {}
  
  @override
  Future<void> rollbackToSavepoint(String name) async {}
}