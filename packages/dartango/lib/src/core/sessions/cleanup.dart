import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import '../database/connection.dart';
import '../database/query.dart';
import '../management/command.dart';
import '../cache/cache.dart';
import 'backends.dart';

class SessionCleanupCommand extends Command {
  @override
  String get name => 'clearsessions';

  @override
  String get description => 'Remove expired sessions from the session store';

  @override
  String get help => '''
Remove expired sessions from the session store.

This command cleans up sessions that have expired based on their expiry date.
It supports multiple session backends including database, cache, and file storage.

Usage:
  dartango clearsessions [options]

Options:
  --backend=<backend>    Specify the session backend to clean (database, file, cache)
  --dry-run             Show what would be deleted without actually deleting
  --batch-size=<size>   Number of sessions to process in each batch (default: 1000)
  --verbose             Show detailed progress information

Examples:
  dartango clearsessions
  dartango clearsessions --backend=database --verbose
  dartango clearsessions --dry-run --batch-size=500
''';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption(
      'backend',
      help: 'Session backend to clean (database, file, cache, all)',
      defaultsTo: 'all',
      allowed: ['database', 'file', 'cache', 'all'],
    );

    parser.addFlag(
      'dry-run',
      help: 'Show what would be deleted without actually deleting',
      defaultsTo: false,
    );

    parser.addOption(
      'batch-size',
      help: 'Number of sessions to process in each batch',
      defaultsTo: '1000',
    );

    parser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Show detailed progress information',
      defaultsTo: false,
    );
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    final backend = args['backend'] as String;
    final dryRun = args['dry-run'] as bool;
    final batchSize = int.parse(args['batch-size'] as String);
    final verbose = args['verbose'] as bool;
    
    if (verbose) {
      print('Starting session cleanup...');
      print('Backend: $backend');
      print('Dry run: $dryRun');
      print('Batch size: $batchSize');
      print('');
    }
    
    final cleaner = SessionCleaner(
      dryRun: dryRun,
      batchSize: batchSize,
      verbose: verbose,
    );
    
    try {
      int totalCleaned = 0;
      
      if (backend == 'all' || backend == 'database') {
        final cleaned = await cleaner.cleanDatabaseSessions();
        totalCleaned += cleaned;
        if (verbose) print('Database sessions cleaned: $cleaned');
      }
      
      if (backend == 'all' || backend == 'file') {
        final cleaned = await cleaner.cleanFileSessions();
        totalCleaned += cleaned;
        if (verbose) print('File sessions cleaned: $cleaned');
      }
      
      if (backend == 'all' || backend == 'cache') {
        final cleaned = await cleaner.cleanCacheSessions();
        totalCleaned += cleaned;
        if (verbose) print('Cache sessions cleaned: $cleaned');
      }
      
      if (dryRun) {
        print('Dry run completed. Would have cleaned $totalCleaned expired sessions.');
      } else {
        print('Session cleanup completed. Cleaned $totalCleaned expired sessions.');
      }
      
    } catch (e) {
      print('Error during session cleanup: $e');
      exitCode = 1;
    }
  }
}

class SessionStatsCommand extends Command {
  @override
  String get name => 'sessionstats';

  @override
  String get description => 'Display statistics about sessions in the session store';

  @override
  String get help => '''
Display detailed statistics about sessions in the session store.

This command provides information about active sessions, expired sessions,
and storage usage across different session backends.

Usage:
  dartango sessionstats [options]

Options:
  --backend=<backend>    Specify the session backend to analyze
  --format=<format>      Output format (table, json, csv)
  --detailed             Show detailed breakdown by backend

Examples:
  dartango sessionstats
  dartango sessionstats --backend=database --format=json
  dartango sessionstats --detailed
''';

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    parser.addOption(
      'backend',
      help: 'Session backend to analyze',
      defaultsTo: 'all',
      allowed: ['database', 'file', 'cache', 'all'],
    );

    parser.addOption(
      'format',
      help: 'Output format',
      defaultsTo: 'table',
      allowed: ['table', 'json', 'csv'],
    );

    parser.addFlag(
      'detailed',
      help: 'Show detailed breakdown by backend',
      defaultsTo: false,
    );
    return parser;
  }

  @override
  Future<void> execute(ArgResults args) async {
    final backend = args['backend'] as String;
    final format = args['format'] as String;
    final detailed = args['detailed'] as bool;
    
    final analyzer = SessionAnalyzer();
    
    try {
      final stats = await analyzer.analyzeAll();
      
      switch (format) {
        case 'json':
          print(stats.toJson());
          break;
        case 'csv':
          print(stats.toCsv());
          break;
        case 'table':
        default:
          print(stats.toTable(detailed: detailed));
          break;
      }
      
    } catch (e) {
      print('Error analyzing sessions: $e');
      exitCode = 1;
    }
  }
}

class SessionCleaner {
  final bool dryRun;
  final int batchSize;
  final bool verbose;
  
  SessionCleaner({
    required this.dryRun,
    required this.batchSize,
    required this.verbose,
  });
  
  Future<int> cleanDatabaseSessions() async {
    try {
      final connection = await DatabaseRouter.getConnection();
      try {
        return await _cleanDatabaseSessionsWithConnection(connection);
      } finally {
        await DatabaseRouter.releaseConnection(connection);
      }
    } catch (e) {
      if (verbose) print('Database session cleanup failed: $e');
      return 0;
    }
  }
  
  Future<int> _cleanDatabaseSessionsWithConnection(DatabaseConnection connection) async {
    const tableName = 'dartango_sessions';
    
    final countBuilder = QueryBuilder()
        .select(['COUNT(*) as count'])
        .from(tableName)
        .where('expire_date < ?', [DateTime.now().toIso8601String()]);
    
    final countResult = await connection.query(countBuilder.toSql(), countBuilder.parameters);
    final expiredCount = countResult.first['count'] as int;
    
    if (expiredCount == 0) {
      if (verbose) print('No expired database sessions found.');
      return 0;
    }
    
    if (verbose) print('Found $expiredCount expired database sessions.');
    
    if (dryRun) {
      return expiredCount;
    }
    
    int totalDeleted = 0;
    int processed = 0;
    
    while (processed < expiredCount) {
      final batchBuilder = QueryBuilder()
          .select(['session_key'])
          .from(tableName)
          .where('expire_date < ?', [DateTime.now().toIso8601String()])
          .limit(batchSize);
      
      final batchResult = await connection.query(batchBuilder.toSql(), batchBuilder.parameters);
      
      if (batchResult.isEmpty) break;
      
      final sessionKeys = batchResult.map((row) => row['session_key'] as String).toList();
      
      final deleteBuilder = DeleteQueryBuilder(tableName)
          .where('session_key IN (${sessionKeys.map((_) => '?').join(', ')})', sessionKeys);
      
      final deleteResult = await connection.execute(deleteBuilder.toSql(), deleteBuilder.parameters);
      final deletedInBatch = deleteResult.affectedRows ?? 0;
      
      totalDeleted += deletedInBatch;
      processed += sessionKeys.length;
      
      if (verbose) {
        print('Processed $processed/$expiredCount sessions (deleted $deletedInBatch in this batch)');
      }
      
      if (sessionKeys.length < batchSize) break;
    }
    
    return totalDeleted;
  }
  
  Future<int> cleanFileSessions() async {
    try {
      const sessionDir = '/tmp/dartango_sessions';
      final directory = Directory(sessionDir);
      
      if (!await directory.exists()) {
        if (verbose) print('Session directory does not exist: $sessionDir');
        return 0;
      }
      
      final files = await directory.list().where((entity) => entity is File && entity.path.endsWith('.session')).cast<File>().toList();
      
      if (files.isEmpty) {
        if (verbose) print('No session files found.');
        return 0;
      }
      
      int expiredCount = 0;
      int totalDeleted = 0;
      final now = DateTime.now();
      
      for (final file in files) {
        try {
          final stat = await file.stat();
          final expireTime = stat.modified.add(const Duration(days: 14));
          
          if (now.isAfter(expireTime)) {
            expiredCount++;
            
            if (!dryRun) {
              await file.delete();
              totalDeleted++;
            }
          }
        } catch (e) {
          if (verbose) print('Error processing file ${file.path}: $e');
        }
      }
      
      if (verbose) {
        print('Found $expiredCount expired file sessions.');
        if (!dryRun) print('Deleted $totalDeleted file sessions.');
      }
      
      return dryRun ? expiredCount : totalDeleted;
      
    } catch (e) {
      if (verbose) print('File session cleanup failed: $e');
      return 0;
    }
  }
  
  Future<int> cleanCacheSessions() async {
    if (verbose) print('Cache session cleanup: automatic expiry handled by cache backend.');
    return 0;
  }
}

class SessionAnalyzer {
  Future<SessionStats> analyzeAll() async {
    final databaseStats = await _analyzeDatabaseSessions();
    final fileStats = await _analyzeFileSessions();
    final cacheStats = await _analyzeCacheSessions();
    
    return SessionStats(
      database: databaseStats,
      file: fileStats,
      cache: cacheStats,
      timestamp: DateTime.now(),
    );
  }
  
  Future<BackendStats> _analyzeDatabaseSessions() async {
    try {
      final connection = await DatabaseRouter.getConnection();
      try {
        const tableName = 'dartango_sessions';
        
        final totalBuilder = QueryBuilder()
            .select(['COUNT(*) as count'])
            .from(tableName);
        
        final totalResult = await connection.query(totalBuilder.toSql(), totalBuilder.parameters);
        final total = totalResult.first['count'] as int;
        
        final activeBuilder = QueryBuilder()
            .select(['COUNT(*) as count'])
            .from(tableName)
            .where('expire_date > ?', [DateTime.now().toIso8601String()]);
        
        final activeResult = await connection.query(activeBuilder.toSql(), activeBuilder.parameters);
        final active = activeResult.first['count'] as int;
        
        final expired = total - active;
        
        final sizeBuilder = QueryBuilder()
            .select(['SUM(LENGTH(session_data)) as size'])
            .from(tableName);
        
        final sizeResult = await connection.query(sizeBuilder.toSql(), sizeBuilder.parameters);
        final size = sizeResult.first['size'] as int? ?? 0;
        
        return BackendStats(
          total: total,
          active: active,
          expired: expired,
          storageSize: size,
        );
        
      } finally {
        await DatabaseRouter.releaseConnection(connection);
      }
    } catch (e) {
      return BackendStats(total: 0, active: 0, expired: 0, storageSize: 0);
    }
  }
  
  Future<BackendStats> _analyzeFileSessions() async {
    try {
      const sessionDir = '/tmp/dartango_sessions';
      final directory = Directory(sessionDir);
      
      if (!await directory.exists()) {
        return BackendStats(total: 0, active: 0, expired: 0, storageSize: 0);
      }
      
      final files = await directory.list().where((entity) => entity is File && entity.path.endsWith('.session')).cast<File>().toList();
      
      int active = 0;
      int expired = 0;
      int totalSize = 0;
      final now = DateTime.now();
      
      for (final file in files) {
        try {
          final stat = await file.stat();
          final expireTime = stat.modified.add(const Duration(days: 14));
          
          if (now.isAfter(expireTime)) {
            expired++;
          } else {
            active++;
          }
          
          totalSize += stat.size;
        } catch (e) {
          expired++;
        }
      }
      
      return BackendStats(
        total: active + expired,
        active: active,
        expired: expired,
        storageSize: totalSize,
      );
      
    } catch (e) {
      return BackendStats(total: 0, active: 0, expired: 0, storageSize: 0);
    }
  }
  
  Future<BackendStats> _analyzeCacheSessions() async {
    return BackendStats(
      total: 0,
      active: 0,
      expired: 0,
      storageSize: 0,
    );
  }
}

class SessionStats {
  final BackendStats database;
  final BackendStats file;
  final BackendStats cache;
  final DateTime timestamp;
  
  SessionStats({
    required this.database,
    required this.file,
    required this.cache,
    required this.timestamp,
  });
  
  int get totalSessions => database.total + file.total + cache.total;
  int get totalActive => database.active + file.active + cache.active;
  int get totalExpired => database.expired + file.expired + cache.expired;
  int get totalStorageSize => database.storageSize + file.storageSize + cache.storageSize;
  
  String toJson() {
    return '''
{
  "timestamp": "${timestamp.toIso8601String()}",
  "total": {
    "sessions": $totalSessions,
    "active": $totalActive,
    "expired": $totalExpired,
    "storage_bytes": $totalStorageSize
  },
  "backends": {
    "database": ${database.toJson()},
    "file": ${file.toJson()},
    "cache": ${cache.toJson()}
  }
}''';
  }
  
  String toCsv() {
    return '''Backend,Total,Active,Expired,Storage (bytes)
Database,${database.total},${database.active},${database.expired},${database.storageSize}
File,${file.total},${file.active},${file.expired},${file.storageSize}
Cache,${cache.total},${cache.active},${cache.expired},${cache.storageSize}
Total,$totalSessions,$totalActive,$totalExpired,$totalStorageSize''';
  }
  
  String toTable({bool detailed = false}) {
    final buffer = StringBuffer();
    
    buffer.writeln('Session Statistics');
    buffer.writeln('Generated: ${timestamp.toIso8601String()}');
    buffer.writeln('');
    
    buffer.writeln('═' * 60);
    buffer.writeln('│ Backend    │ Total  │ Active │ Expired │ Storage   │');
    buffer.writeln('├' + '─' * 10 + '┼' + '─' * 6 + '┼' + '─' * 6 + '┼' + '─' * 7 + '┼' + '─' * 9 + '┤');
    
    buffer.writeln('│ Database   │ ${database.total.toString().padLeft(6)} │ ${database.active.toString().padLeft(6)} │ ${database.expired.toString().padLeft(7)} │ ${_formatBytes(database.storageSize).padLeft(9)} │');
    buffer.writeln('│ File       │ ${file.total.toString().padLeft(6)} │ ${file.active.toString().padLeft(6)} │ ${file.expired.toString().padLeft(7)} │ ${_formatBytes(file.storageSize).padLeft(9)} │');
    buffer.writeln('│ Cache      │ ${cache.total.toString().padLeft(6)} │ ${cache.active.toString().padLeft(6)} │ ${cache.expired.toString().padLeft(7)} │ ${_formatBytes(cache.storageSize).padLeft(9)} │');
    
    buffer.writeln('├' + '─' * 10 + '┼' + '─' * 6 + '┼' + '─' * 6 + '┼' + '─' * 7 + '┼' + '─' * 9 + '┤');
    buffer.writeln('│ Total      │ ${totalSessions.toString().padLeft(6)} │ ${totalActive.toString().padLeft(6)} │ ${totalExpired.toString().padLeft(7)} │ ${_formatBytes(totalStorageSize).padLeft(9)} │');
    buffer.writeln('═' * 60);
    
    if (detailed) {
      buffer.writeln('');
      buffer.writeln('Detailed Information:');
      buffer.writeln('• Active sessions: Sessions that have not yet expired');
      buffer.writeln('• Expired sessions: Sessions that are past their expiry date');
      buffer.writeln('• Storage: Approximate storage space used by session data');
      buffer.writeln('• Cache sessions may not show accurate counts due to automatic expiry');
    }
    
    return buffer.toString();
  }
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

class BackendStats {
  final int total;
  final int active;
  final int expired;
  final int storageSize;
  
  BackendStats({
    required this.total,
    required this.active,
    required this.expired,
    required this.storageSize,
  });
  
  String toJson() {
    return '''
{
  "total": $total,
  "active": $active,
  "expired": $expired,
  "storage_bytes": $storageSize
}''';
  }
}