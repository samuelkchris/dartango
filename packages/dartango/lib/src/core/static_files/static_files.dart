import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import '../http/request.dart';
import '../http/response.dart';
import '../settings/global.dart';

/// Static files handling for Dartango
/// Based on Django's static files framework

/// Main static files handler
class StaticFilesHandler {
  static final StaticFilesHandler _instance = StaticFilesHandler._internal();
  static StaticFilesHandler get instance => _instance;
  StaticFilesHandler._internal();

  final List<StaticFilesFinder> _finders = [];
  final Map<String, String> _fileCache = {};
  final Map<String, DateTime> _lastModified = {};
  final Map<String, String> _etags = {};

  bool _debug = false;
  bool _initialized = false;

  /// Initialize static files handler
  void initialize({
    bool debug = false,
    List<String>? staticDirs,
    List<String>? staticUrls,
    String? staticRoot,
    String? staticUrl,
  }) {
    _debug = debug;
    _finders.clear();

    // Add default finders
    _finders.add(FileSystemFinder(
      staticDirs: staticDirs ?? ['static'],
      staticUrls: staticUrls ?? ['/static/'],
    ));

    if (staticRoot != null) {
      _finders.add(AppDirectoriesFinder(
        staticRoot: staticRoot,
        staticUrl: staticUrl ?? '/static/',
      ));
    }

    // Add CDN finder if configured
    try {
      final cdnUrl =
          GlobalSettings.instance.getSetting<String>('STATIC_CDN_URL');
      _finders.add(CdnFinder(cdnUrl: cdnUrl));
        } catch (e) {
      // CDN URL not configured, skip
    }

    _initialized = true;
  }

  /// Find a static file
  Future<StaticFile?> findFile(String relativePath) async {
    if (!_initialized) {
      initialize();
    }

    // Check cache first
    if (_fileCache.containsKey(relativePath)) {
      final filePath = _fileCache[relativePath]!;
      final file = File(filePath);
      if (await file.exists()) {
        return StaticFile(
          path: filePath,
          url: _buildUrl(relativePath),
          relativePath: relativePath,
          lastModified: _lastModified[relativePath],
          etag: _etags[relativePath],
        );
      } else {
        // File was deleted, remove from cache
        _fileCache.remove(relativePath);
        _lastModified.remove(relativePath);
        _etags.remove(relativePath);
      }
    }

    // Search through finders
    for (final finder in _finders) {
      final file = await finder.find(relativePath);
      if (file != null) {
        // Cache the result
        _fileCache[relativePath] = file.path;
        if (file.lastModified != null) {
          _lastModified[relativePath] = file.lastModified!;
        }
        if (file.etag != null) {
          _etags[relativePath] = file.etag!;
        }
        return file;
      }
    }

    return null;
  }

  /// Get URL for a static file
  String getStaticUrl(String relativePath) {
    if (!_initialized) {
      initialize();
    }

    return _buildUrl(relativePath);
  }

  /// Serve static file
  Future<HttpResponse> serveStaticFile(
      HttpRequest request, String relativePath) async {
    final file = await findFile(relativePath);
    if (file == null) {
      return HttpResponse.notFound('Static file not found: $relativePath');
    }

    final fileObj = File(file.path);
    if (!await fileObj.exists()) {
      return HttpResponse.notFound('Static file not found: $relativePath');
    }

    // Check if file was modified
    final ifModifiedSince = request.headers['if-modified-since'];
    final ifNoneMatch = request.headers['if-none-match'];

    if (ifModifiedSince != null && file.lastModified != null) {
      final clientDate = HttpDate.parse(ifModifiedSince);
      if (file.lastModified!.isBefore(clientDate.add(Duration(seconds: 1)))) {
        return HttpResponse(
          null,
          statusCode: 304,
          headers: {
            'Last-Modified': HttpDate.format(file.lastModified!),
            'ETag': file.etag ?? '',
          },
        );
      }
    }

    if (ifNoneMatch != null && file.etag != null && ifNoneMatch == file.etag) {
      return HttpResponse(
        null,
        statusCode: 304,
        headers: {
          'Last-Modified': HttpDate.format(file.lastModified!),
          'ETag': file.etag!,
        },
      );
    }

    // Determine content type
    final contentType = _getContentType(file.path);

    // Set caching headers
    final headers = <String, String>{
      'Content-Type': contentType,
      'Content-Length': (await fileObj.length()).toString(),
    };

    if (file.lastModified != null) {
      headers['Last-Modified'] = HttpDate.format(file.lastModified!);
    }

    if (file.etag != null) {
      headers['ETag'] = file.etag!;
    }

    // Set cache control
    if (_debug) {
      headers['Cache-Control'] = 'no-cache';
    } else {
      headers['Cache-Control'] = 'public, max-age=31536000'; // 1 year
    }

    // Handle range requests
    final rangeHeader = request.headers['range'];
    if (rangeHeader != null) {
      return await _handleRangeRequest(fileObj, rangeHeader, headers);
    }

    return HttpResponse.file(
      fileObj,
      headers: headers,
      contentType: contentType,
    );
  }

  /// Handle range requests for large files
  Future<HttpResponse> _handleRangeRequest(
    File file,
    String rangeHeader,
    Map<String, String> headers,
  ) async {
    final fileSize = await file.length();
    final ranges = _parseRangeHeader(rangeHeader, fileSize);

    if (ranges.isEmpty) {
      return HttpResponse(
        null,
        statusCode: 416,
        headers: {
          'Content-Range': 'bytes */$fileSize',
          ...headers,
        },
      );
    }

    final range = ranges.first;
    final start = range.start;
    final end = range.end;
    final length = end - start + 1;

    final stream = file.openRead(start, end + 1);

    return HttpResponse.stream(
      stream,
      statusCode: 206,
      headers: {
        'Content-Range': 'bytes $start-$end/$fileSize',
        'Content-Length': length.toString(),
        'Accept-Ranges': 'bytes',
        ...headers,
      },
    );
  }

  /// Parse Range header
  List<_Range> _parseRangeHeader(String rangeHeader, int fileSize) {
    final ranges = <_Range>[];

    if (!rangeHeader.startsWith('bytes=')) {
      return ranges;
    }

    final rangeSpecs = rangeHeader.substring(6).split(',');

    for (final spec in rangeSpecs) {
      final parts = spec.trim().split('-');
      if (parts.length != 2) continue;

      final startStr = parts[0].trim();
      final endStr = parts[1].trim();

      int start, end;

      if (startStr.isEmpty && endStr.isNotEmpty) {
        // Suffix range: -500
        final suffixLength = int.tryParse(endStr);
        if (suffixLength == null || suffixLength <= 0) continue;
        start = fileSize - suffixLength;
        end = fileSize - 1;
      } else if (startStr.isNotEmpty && endStr.isEmpty) {
        // Start range: 500-
        start = int.tryParse(startStr) ?? 0;
        end = fileSize - 1;
      } else if (startStr.isNotEmpty && endStr.isNotEmpty) {
        // Full range: 500-999
        start = int.tryParse(startStr) ?? 0;
        end = int.tryParse(endStr) ?? fileSize - 1;
      } else {
        continue;
      }

      if (start < 0 || end >= fileSize || start > end) continue;

      ranges.add(_Range(start, end));
    }

    return ranges;
  }

  /// Get content type for file
  String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();

    switch (extension) {
      case '.html':
      case '.htm':
        return 'text/html; charset=utf-8';
      case '.css':
        return 'text/css; charset=utf-8';
      case '.js':
        return 'application/javascript; charset=utf-8';
      case '.json':
        return 'application/json; charset=utf-8';
      case '.xml':
        return 'application/xml; charset=utf-8';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.svg':
        return 'image/svg+xml';
      case '.ico':
        return 'image/x-icon';
      case '.pdf':
        return 'application/pdf';
      case '.zip':
        return 'application/zip';
      case '.gz':
        return 'application/gzip';
      case '.tar':
        return 'application/x-tar';
      case '.mp4':
        return 'video/mp4';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.woff':
        return 'font/woff';
      case '.woff2':
        return 'font/woff2';
      case '.ttf':
        return 'font/ttf';
      case '.otf':
        return 'font/otf';
      case '.txt':
        return 'text/plain; charset=utf-8';
      case '.md':
        return 'text/markdown; charset=utf-8';
      default:
        return 'application/octet-stream';
    }
  }

  /// Build URL for static file
  String _buildUrl(String relativePath) {
    final staticUrl =
        GlobalSettings.instance.getSetting<String>('STATIC_URL') ?? '/static/';
    return '$staticUrl$relativePath';
  }

  /// Collect all static files
  Future<Map<String, String>> collectStatic({
    required String collectRoot,
    bool overwrite = false,
    bool dryRun = false,
  }) async {
    final collectedFiles = <String, String>{};
    final collectDir = Directory(collectRoot);

    if (!dryRun) {
      if (await collectDir.exists() && overwrite) {
        await collectDir.delete(recursive: true);
      }
      await collectDir.create(recursive: true);
    }

    for (final finder in _finders) {
      final files = await finder.listAll();

      for (final file in files) {
        final targetPath = path.join(collectRoot, file.relativePath);

        if (!dryRun) {
          final targetFile = File(targetPath);
          await targetFile.create(recursive: true);

          if (file.path.startsWith('http')) {
            // Download from URL
            final client = HttpClient();
            try {
              final request = await client.getUrl(Uri.parse(file.path));
              final response = await request.close();
              await response.pipe(targetFile.openWrite());
            } finally {
              client.close();
            }
          } else {
            // Copy local file
            await File(file.path).copy(targetPath);
          }
        }

        collectedFiles[file.relativePath] = targetPath;
      }
    }

    return collectedFiles;
  }

  /// Clear cache
  void clearCache() {
    _fileCache.clear();
    _lastModified.clear();
    _etags.clear();
  }
}

/// Abstract base class for static file finders
abstract class StaticFilesFinder {
  Future<StaticFile?> find(String relativePath);
  Future<List<StaticFile>> listAll();
}

/// File system finder for static files
class FileSystemFinder extends StaticFilesFinder {
  final List<String> staticDirs;
  final List<String> staticUrls;

  FileSystemFinder({
    required this.staticDirs,
    required this.staticUrls,
  });

  @override
  Future<StaticFile?> find(String relativePath) async {
    for (final dir in staticDirs) {
      final fullPath = path.join(dir, relativePath);
      final file = File(fullPath);

      if (await file.exists()) {
        final stats = await file.stat();
        final etag = await _generateETag(file);

        return StaticFile(
          path: fullPath,
          url: _buildUrl(relativePath),
          relativePath: relativePath,
          lastModified: stats.modified,
          etag: etag,
        );
      }
    }

    return null;
  }

  @override
  Future<List<StaticFile>> listAll() async {
    final files = <StaticFile>[];

    for (final dir in staticDirs) {
      final directory = Directory(dir);
      if (!await directory.exists()) continue;

      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final relativePath = path.relative(entity.path, from: dir);
          final stats = await entity.stat();
          final etag = await _generateETag(entity);

          files.add(StaticFile(
            path: entity.path,
            url: _buildUrl(relativePath),
            relativePath: relativePath,
            lastModified: stats.modified,
            etag: etag,
          ));
        }
      }
    }

    return files;
  }

  String _buildUrl(String relativePath) {
    final staticUrl = staticUrls.isNotEmpty ? staticUrls.first : '/static/';
    return '$staticUrl$relativePath';
  }

  Future<String> _generateETag(File file) async {
    final stats = await file.stat();
    final content = '${stats.modified.millisecondsSinceEpoch}-${stats.size}';
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return '"${digest.toString()}"';
  }
}

/// App directories finder
class AppDirectoriesFinder extends StaticFilesFinder {
  final String staticRoot;
  final String staticUrl;

  AppDirectoriesFinder({
    required this.staticRoot,
    required this.staticUrl,
  });

  @override
  Future<StaticFile?> find(String relativePath) async {
    final fullPath = path.join(staticRoot, relativePath);
    final file = File(fullPath);

    if (await file.exists()) {
      final stats = await file.stat();
      final etag = await _generateETag(file);

      return StaticFile(
        path: fullPath,
        url: '$staticUrl$relativePath',
        relativePath: relativePath,
        lastModified: stats.modified,
        etag: etag,
      );
    }

    return null;
  }

  @override
  Future<List<StaticFile>> listAll() async {
    final files = <StaticFile>[];
    final directory = Directory(staticRoot);

    if (!await directory.exists()) return files;

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: staticRoot);
        final stats = await entity.stat();
        final etag = await _generateETag(entity);

        files.add(StaticFile(
          path: entity.path,
          url: '$staticUrl$relativePath',
          relativePath: relativePath,
          lastModified: stats.modified,
          etag: etag,
        ));
      }
    }

    return files;
  }

  Future<String> _generateETag(File file) async {
    final stats = await file.stat();
    final content = '${stats.modified.millisecondsSinceEpoch}-${stats.size}';
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return '"${digest.toString()}"';
  }
}

/// CDN finder for static files
class CdnFinder extends StaticFilesFinder {
  final String cdnUrl;

  CdnFinder({required this.cdnUrl});

  @override
  Future<StaticFile?> find(String relativePath) async {
    final fullUrl = '$cdnUrl$relativePath';

    return StaticFile(
      path: fullUrl,
      url: fullUrl,
      relativePath: relativePath,
      lastModified: DateTime.now(),
      etag: null,
    );
  }

  @override
  Future<List<StaticFile>> listAll() async {
    // CDN finder doesn't support listing all files
    return [];
  }
}

/// Represents a static file
class StaticFile {
  final String path;
  final String url;
  final String relativePath;
  final DateTime? lastModified;
  final String? etag;

  StaticFile({
    required this.path,
    required this.url,
    required this.relativePath,
    this.lastModified,
    this.etag,
  });

  @override
  String toString() => 'StaticFile(path: $path, url: $url)';
}

/// Range for HTTP range requests
class _Range {
  final int start;
  final int end;

  _Range(this.start, this.end);
}

/// Middleware for serving static files
class StaticFilesMiddleware {
  final StaticFilesHandler handler;
  final bool autoServe;

  StaticFilesMiddleware({
    StaticFilesHandler? handler,
    this.autoServe = true,
  }) : handler = handler ?? StaticFilesHandler.instance;

  /// Handle static file requests
  Future<HttpResponse?> call(HttpRequest request) async {
    if (!autoServe) return null;

    final path = request.path;
    final staticUrl =
        GlobalSettings.instance.getSetting<String>('STATIC_URL') ?? '/static/';

    if (path.startsWith(staticUrl)) {
      final relativePath = path.substring(staticUrl.length);
      return await handler.serveStaticFile(request, relativePath);
    }

    return null;
  }
}

/// Template tags for static files
class StaticFilesTemplateTags {
  /// Generate static file URL
  static String staticUrl(String relativePath) {
    return StaticFilesHandler.instance.getStaticUrl(relativePath);
  }

  /// Load static file content (for inline CSS/JS)
  static Future<String> loadStatic(String relativePath) async {
    final file = await StaticFilesHandler.instance.findFile(relativePath);
    if (file == null) return '';

    if (file.path.startsWith('http')) {
      // Download from URL
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(file.path));
        final response = await request.close();
        final bytes = await response.expand((data) => data).toList();
        return utf8.decode(bytes);
      } finally {
        client.close();
      }
    } else {
      // Read local file
      final fileObj = File(file.path);
      if (await fileObj.exists()) {
        return await fileObj.readAsString();
      }
    }

    return '';
  }
}

/// Utilities for static files
class StaticFilesUtils {
  /// Generate manifest file for asset versioning
  static Future<Map<String, String>> generateManifest(String staticRoot) async {
    final manifest = <String, String>{};
    final directory = Directory(staticRoot);

    if (!await directory.exists()) return manifest;

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: staticRoot);
        final stats = await entity.stat();
        final content =
            '${stats.modified.millisecondsSinceEpoch}-${stats.size}';
        final bytes = utf8.encode(content);
        final digest = sha256.convert(bytes);
        final hash = digest.toString().substring(0, 8);

        final extension = path.extension(relativePath);
        final baseName = path.basenameWithoutExtension(relativePath);
        final dirName = path.dirname(relativePath);

        final hashedName = '$baseName.$hash$extension';
        final hashedPath = dirName == '.' ? hashedName : '$dirName/$hashedName';

        manifest[relativePath] = hashedPath;
      }
    }

    return manifest;
  }

  /// Compress static files
  static Future<void> compressStaticFiles(String staticRoot) async {
    final directory = Directory(staticRoot);
    if (!await directory.exists()) return;

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        final extension = path.extension(entity.path).toLowerCase();

        if (['.css', '.js', '.html', '.xml', '.json', '.svg']
            .contains(extension)) {
          final content = await entity.readAsBytes();
          final compressed = gzip.encode(content);

          final gzipFile = File('${entity.path}.gz');
          await gzipFile.writeAsBytes(compressed);
        }
      }
    }
  }

  /// Validate static files
  static Future<List<String>> validateStaticFiles(String staticRoot) async {
    final errors = <String>[];
    final directory = Directory(staticRoot);

    if (!await directory.exists()) {
      errors.add('Static root directory does not exist: $staticRoot');
      return errors;
    }

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: staticRoot);

        // Check file size
        final stats = await entity.stat();
        if (stats.size > 50 * 1024 * 1024) {
          // 50MB
          errors.add('File too large: $relativePath (${stats.size} bytes)');
        }

        // Check for common issues
        if (relativePath.contains('..')) {
          errors.add('Path traversal detected: $relativePath');
        }

        if (relativePath.startsWith('.')) {
          errors.add('Hidden file detected: $relativePath');
        }
      }
    }

    return errors;
  }
}

/// Initialize static files system
void initializeStaticFiles({
  bool debug = false,
  List<String>? staticDirs,
  List<String>? staticUrls,
  String? staticRoot,
  String? staticUrl,
}) {
  StaticFilesHandler.instance.initialize(
    debug: debug,
    staticDirs: staticDirs,
    staticUrls: staticUrls,
    staticRoot: staticRoot,
    staticUrl: staticUrl,
  );
}

/// Get static file URL
String staticUrl(String relativePath) {
  return StaticFilesHandler.instance.getStaticUrl(relativePath);
}

/// Serve static file
Future<HttpResponse> serveStaticFile(HttpRequest request, String relativePath) {
  return StaticFilesHandler.instance.serveStaticFile(request, relativePath);
}

/// Collect all static files
Future<Map<String, String>> collectStatic({
  required String collectRoot,
  bool overwrite = false,
  bool dryRun = false,
}) {
  return StaticFilesHandler.instance.collectStatic(
    collectRoot: collectRoot,
    overwrite: overwrite,
    dryRun: dryRun,
  );
}
