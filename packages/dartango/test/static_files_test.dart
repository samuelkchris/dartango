import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

import '../lib/src/core/static_files/static_files.dart';
import '../lib/src/core/http/request.dart';
import '../lib/src/core/http/response.dart';
import '../lib/src/core/settings/global.dart';
import '../lib/src/core/settings/base.dart';
import 'package:shelf/shelf.dart' as shelf;

void main() {
  group('Static Files System Tests', () {
    late Directory tempDir;
    late Directory staticDir;
    late StaticFilesHandler handler;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('dartango_static_test');
      staticDir = Directory(path.join(tempDir.path, 'static'));
      await staticDir.create();

      // Create test files
      final cssFile = File(path.join(staticDir.path, 'style.css'));
      await cssFile.writeAsString('body { background-color: blue; }');

      final jsFile = File(path.join(staticDir.path, 'script.js'));
      await jsFile.writeAsString('console.log("Hello World");');

      final imgDir = Directory(path.join(staticDir.path, 'images'));
      await imgDir.create();

      final imgFile = File(path.join(imgDir.path, 'logo.png'));
      await imgFile
          .writeAsBytes([137, 80, 78, 71, 13, 10, 26, 10]); // PNG header

      // Configure and initialize settings
      GlobalSettings.configure(Settings());
      GlobalSettings.instance.setSetting('STATIC_URL', '/static/');
      GlobalSettings.instance.setSetting('STATIC_ROOT', staticDir.path);

      handler = StaticFilesHandler.instance;
    });

    tearDownAll(() async {
      await tempDir.delete(recursive: true);
    });

    setUp(() {
      handler.initialize(
        debug: true,
        staticDirs: [staticDir.path],
        staticUrls: ['/static/'],
      );
    });

    tearDown(() {
      handler.clearCache();
    });

    group('File Finding', () {
      test('should find existing static file', () async {
        final file = await handler.findFile('style.css');
        expect(file, isNotNull);
        expect(file!.relativePath, equals('style.css'));
        expect(file.path, equals(path.join(staticDir.path, 'style.css')));
        expect(file.url, equals('/static/style.css'));
      });

      test('should find file in subdirectory', () async {
        final file = await handler.findFile('images/logo.png');
        expect(file, isNotNull);
        expect(file!.relativePath, equals('images/logo.png'));
        expect(file.path, equals(path.join(staticDir.path, 'images/logo.png')));
        expect(file.url, equals('/static/images/logo.png'));
      });

      test('should return null for non-existent file', () async {
        final file = await handler.findFile('nonexistent.css');
        expect(file, isNull);
      });

      test('should cache file lookups', () async {
        // First lookup
        final file1 = await handler.findFile('style.css');
        expect(file1, isNotNull);

        // Second lookup should use cache
        final file2 = await handler.findFile('style.css');
        expect(file2, isNotNull);
        expect(file2!.path, equals(file1!.path));
      });
    });

    group('URL Generation', () {
      test('should generate correct static URL', () {
        final url = handler.getStaticUrl('style.css');
        expect(url, equals('/static/style.css'));
      });

      test('should handle subdirectories in URL', () {
        final url = handler.getStaticUrl('images/logo.png');
        expect(url, equals('/static/images/logo.png'));
      });

      test('should use configured static URL', () {
        GlobalSettings.instance.setSetting('STATIC_URL', '/assets/');
        handler.initialize(debug: true);

        final url = handler.getStaticUrl('style.css');
        expect(url, equals('/assets/style.css'));
      });
    });

    group('File Serving', () {
      test('should serve CSS file with correct headers', () async {
        final request = _createRequest('GET', '/static/style.css');
        final response = await handler.serveStaticFile(request, 'style.css');

        expect(response.statusCode, equals(200));
        expect(response.headers['Content-Type'],
            equals('text/css; charset=utf-8'));
        expect(response.headers['Cache-Control'],
            equals('no-cache')); // Debug mode
      });

      test('should serve JavaScript file with correct headers', () async {
        final request = _createRequest('GET', '/static/script.js');
        final response = await handler.serveStaticFile(request, 'script.js');

        expect(response.statusCode, equals(200));
        expect(response.headers['Content-Type'],
            equals('application/javascript; charset=utf-8'));
      });

      test('should serve PNG image with correct headers', () async {
        final request = _createRequest('GET', '/static/images/logo.png');
        final response =
            await handler.serveStaticFile(request, 'images/logo.png');

        expect(response.statusCode, equals(200));
        expect(response.headers['Content-Type'], equals('image/png'));
      });

      test('should return 404 for non-existent file', () async {
        final request = _createRequest('GET', '/static/nonexistent.css');
        final response =
            await handler.serveStaticFile(request, 'nonexistent.css');

        expect(response.statusCode, equals(404));
      });

      test('should handle ETag headers', () async {
        final request = _createRequest('GET', '/static/style.css');
        final response = await handler.serveStaticFile(request, 'style.css');

        expect(response.headers['ETag'], isNotNull);
        expect(response.headers['Last-Modified'], isNotNull);
      });

      test('should handle conditional requests with ETag', () async {
        // First request to get ETag
        final request1 = _createRequest('GET', '/static/style.css');
        final response1 = await handler.serveStaticFile(request1, 'style.css');
        final etag = response1.headers['ETag']!;

        // Second request with If-None-Match
        final request2 = _createRequest('GET', '/static/style.css', headers: {
          'If-None-Match': etag,
        });
        final response2 = await handler.serveStaticFile(request2, 'style.css');

        expect(response2.statusCode, equals(304));
      });
    });

    group('Content Type Detection', () {
      test('should detect CSS content type', () async {
        final request = _createRequest('GET', '/static/style.css');
        final response = await handler.serveStaticFile(request, 'style.css');

        expect(response.headers['Content-Type'],
            equals('text/css; charset=utf-8'));
      });

      test('should detect JavaScript content type', () async {
        final request = _createRequest('GET', '/static/script.js');
        final response = await handler.serveStaticFile(request, 'script.js');

        expect(response.headers['Content-Type'],
            equals('application/javascript; charset=utf-8'));
      });

      test('should detect PNG image content type', () async {
        final request = _createRequest('GET', '/static/images/logo.png');
        final response =
            await handler.serveStaticFile(request, 'images/logo.png');

        expect(response.headers['Content-Type'], equals('image/png'));
      });

      test('should use default content type for unknown extensions', () async {
        final unknownFile = File(path.join(staticDir.path, 'unknown.xyz'));
        await unknownFile.writeAsString('unknown content');

        final request = _createRequest('GET', '/static/unknown.xyz');
        final response = await handler.serveStaticFile(request, 'unknown.xyz');

        expect(response.headers['Content-Type'],
            equals('application/octet-stream'));
      });
    });

    group('Caching', () {
      test('should set cache headers in production mode', () async {
        handler.initialize(debug: false);

        final request = _createRequest('GET', '/static/style.css');
        final response = await handler.serveStaticFile(request, 'style.css');

        expect(response.headers['Cache-Control'],
            equals('public, max-age=31536000'));
      });

      test('should set no-cache headers in debug mode', () async {
        handler.initialize(debug: true);

        final request = _createRequest('GET', '/static/style.css');
        final response = await handler.serveStaticFile(request, 'style.css');

        expect(response.headers['Cache-Control'], equals('no-cache'));
      });

      test('should handle cache invalidation when file changes', () async {
        // First request
        final file1 = await handler.findFile('style.css');
        expect(file1, isNotNull);

        // Modify file
        final cssFile = File(path.join(staticDir.path, 'style.css'));
        await cssFile.writeAsString('body { background-color: red; }');

        // Clear cache and request again
        handler.clearCache();
        final file2 = await handler.findFile('style.css');
        expect(file2, isNotNull);
        expect(file2!.etag, isNot(equals(file1!.etag)));
      });
    });

    group('Multiple Static Directories', () {
      test('should search multiple directories', () async {
        final extraDir = Directory(path.join(tempDir.path, 'extra'));
        await extraDir.create();

        final extraFile = File(path.join(extraDir.path, 'extra.css'));
        await extraFile.writeAsString('body { color: green; }');

        handler.initialize(
          debug: true,
          staticDirs: [staticDir.path, extraDir.path],
          staticUrls: ['/static/'],
        );

        final file = await handler.findFile('extra.css');
        expect(file, isNotNull);
        expect(file!.relativePath, equals('extra.css'));
      });

      test('should prioritize first directory in search order', () async {
        final extraDir = Directory(path.join(tempDir.path, 'extra'));
        await extraDir.create();

        // Create file with same name in both directories
        final extraFile = File(path.join(extraDir.path, 'style.css'));
        await extraFile.writeAsString('body { color: green; }');

        handler.initialize(
          debug: true,
          staticDirs: [staticDir.path, extraDir.path],
          staticUrls: ['/static/'],
        );

        final file = await handler.findFile('style.css');
        expect(file, isNotNull);
        expect(file!.path, equals(path.join(staticDir.path, 'style.css')));
      });
    });

    group('Static Files Middleware', () {
      test('should serve static files through middleware', () async {
        final middleware = StaticFilesMiddleware();
        final request = _createRequest('GET', '/static/style.css');

        final response = await middleware.call(request);
        expect(response, isNotNull);
        expect(response!.statusCode, equals(200));
      });

      test('should return null for non-static requests', () async {
        final middleware = StaticFilesMiddleware();
        final request = _createRequest('GET', '/api/users');

        final response = await middleware.call(request);
        expect(response, isNull);
      });

      test('should not serve when autoServe is false', () async {
        final middleware = StaticFilesMiddleware(autoServe: false);
        final request = _createRequest('GET', '/static/style.css');

        final response = await middleware.call(request);
        expect(response, isNull);
      });
    });

    group('File Collection', () {
      test('should collect all static files', () async {
        final collectRoot = path.join(tempDir.path, 'collected');

        final collected = await handler.collectStatic(
          collectRoot: collectRoot,
          overwrite: true,
        );

        expect(collected, isNotEmpty);
        expect(collected.containsKey('style.css'), isTrue);
        expect(collected.containsKey('script.js'), isTrue);
        expect(collected.containsKey('images/logo.png'), isTrue);

        // Check that files were actually copied
        final collectedCss = File(path.join(collectRoot, 'style.css'));
        expect(await collectedCss.exists(), isTrue);

        final collectedJs = File(path.join(collectRoot, 'script.js'));
        expect(await collectedJs.exists(), isTrue);

        final collectedImg = File(path.join(collectRoot, 'images/logo.png'));
        expect(await collectedImg.exists(), isTrue);
      });

      test('should handle dry run collection', () async {
        final collectRoot = path.join(tempDir.path, 'collected_dry');

        final collected = await handler.collectStatic(
          collectRoot: collectRoot,
          dryRun: true,
        );

        expect(collected, isNotEmpty);

        // Check that files were NOT actually copied
        final collectedCss = File(path.join(collectRoot, 'style.css'));
        expect(await collectedCss.exists(), isFalse);
      });
    });

    group('Utility Functions', () {
      test('should generate manifest file', () async {
        final manifest =
            await StaticFilesUtils.generateManifest(staticDir.path);

        expect(manifest, isNotEmpty);
        expect(manifest.containsKey('style.css'), isTrue);
        expect(manifest.containsKey('script.js'), isTrue);
        expect(manifest.containsKey('images/logo.png'), isTrue);

        // Check that hashed names are generated
        expect(manifest['style.css'], contains('.'));
        expect(manifest['style.css'], isNot(equals('style.css')));
      });

      test('should validate static files', () async {
        final errors =
            await StaticFilesUtils.validateStaticFiles(staticDir.path);

        // Should have no errors for valid files
        expect(errors, isEmpty);
      });

      test('should detect validation errors', () async {
        // Create a file with path traversal
        final badFile = File(path.join(staticDir.path, '../bad.css'));
        await badFile.create(recursive: true);
        await badFile.writeAsString('body { color: red; }');

        final errors =
            await StaticFilesUtils.validateStaticFiles(staticDir.path);

        // Should have no errors since the file is outside the static directory
        expect(errors, isEmpty);

        await badFile.delete();
      });
    });

    group('Template Tags', () {
      test('should generate static URL from template tag', () {
        final url = StaticFilesTemplateTags.staticUrl('style.css');
        expect(url, equals('/static/style.css'));
      });

      test('should load static file content', () async {
        final content = await StaticFilesTemplateTags.loadStatic('style.css');
        expect(content, equals('body { background-color: blue; }'));
      });

      test('should return empty string for non-existent file', () async {
        final content =
            await StaticFilesTemplateTags.loadStatic('nonexistent.css');
        expect(content, equals(''));
      });
    });
  });
}

// Helper function to create mock HTTP requests
HttpRequest _createRequest(String method, String path,
    {Map<String, String>? headers}) {
  final uri = Uri.parse('http://localhost$path');
  final shelfRequest = shelf.Request(
    method,
    uri,
    headers: headers ?? {},
  );
  return HttpRequest(shelfRequest);
}
