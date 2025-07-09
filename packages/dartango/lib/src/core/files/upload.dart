import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

class UploadedFile {
  final String name;
  final String? originalName;
  final int size;
  final String contentType;
  final DateTime uploadedAt;
  final Uint8List bytes;
  final String? hash;

  UploadedFile({
    required this.name,
    this.originalName,
    required this.size,
    required this.contentType,
    required this.uploadedAt,
    required this.bytes,
    this.hash,
  });

  String get extension => path.extension(originalName ?? name);
  String get baseName => path.basenameWithoutExtension(originalName ?? name);
  
  bool get isImage => contentType.startsWith('image/');
  bool get isVideo => contentType.startsWith('video/');
  bool get isAudio => contentType.startsWith('audio/');
  bool get isText => contentType.startsWith('text/');
  bool get isPdf => contentType == 'application/pdf';
  bool get isDocument => [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  ].contains(contentType);

  String get humanReadableSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String generateHash() {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> saveTo(String filePath) async {
    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'original_name': originalName,
      'size': size,
      'content_type': contentType,
      'uploaded_at': uploadedAt.toIso8601String(),
      'extension': extension,
      'is_image': isImage,
      'is_video': isVideo,
      'is_audio': isAudio,
      'is_document': isDocument,
      'human_readable_size': humanReadableSize,
      'hash': hash ?? generateHash(),
    };
  }
}

class FileUploadConfig {
  final int maxFileSize;
  final List<String> allowedExtensions;
  final List<String> allowedMimeTypes;
  final String uploadDirectory;
  final bool generateUniqueNames;
  final bool preserveOriginalName;
  final bool calculateHash;

  const FileUploadConfig({
    this.maxFileSize = 10 * 1024 * 1024, // 10MB
    this.allowedExtensions = const [],
    this.allowedMimeTypes = const [],
    this.uploadDirectory = 'uploads',
    this.generateUniqueNames = true,
    this.preserveOriginalName = true,
    this.calculateHash = true,
  });

  bool isExtensionAllowed(String extension) {
    if (allowedExtensions.isEmpty) return true;
    return allowedExtensions.contains(extension.toLowerCase());
  }

  bool isMimeTypeAllowed(String mimeType) {
    if (allowedMimeTypes.isEmpty) return true;
    return allowedMimeTypes.contains(mimeType.toLowerCase());
  }

  bool isSizeAllowed(int size) {
    return size <= maxFileSize;
  }
}

class FileUploadResult {
  final bool success;
  final UploadedFile? file;
  final String? error;
  final String? filePath;

  FileUploadResult({
    required this.success,
    this.file,
    this.error,
    this.filePath,
  });

  factory FileUploadResult.success(UploadedFile file, String filePath) {
    return FileUploadResult(
      success: true,
      file: file,
      filePath: filePath,
    );
  }

  factory FileUploadResult.error(String error) {
    return FileUploadResult(
      success: false,
      error: error,
    );
  }
}

class FileUploadHandler {
  final FileUploadConfig config;

  FileUploadHandler({FileUploadConfig? config})
      : config = config ?? const FileUploadConfig();

  Future<FileUploadResult> handleUpload(
    String fieldName,
    String fileName,
    String contentType,
    Uint8List bytes,
  ) async {
    try {
      // Validate file size
      if (!config.isSizeAllowed(bytes.length)) {
        return FileUploadResult.error(
          'File size exceeds maximum allowed size of ${config.maxFileSize} bytes',
        );
      }

      // Validate file extension
      final extension = path.extension(fileName).toLowerCase();
      if (!config.isExtensionAllowed(extension)) {
        return FileUploadResult.error(
          'File extension "$extension" is not allowed',
        );
      }

      // Validate MIME type
      if (!config.isMimeTypeAllowed(contentType)) {
        return FileUploadResult.error(
          'File type "$contentType" is not allowed',
        );
      }

      // Generate file name
      final finalFileName = config.generateUniqueNames
          ? _generateUniqueFileName(fileName)
          : fileName;

      // Create uploaded file object
      final uploadedFile = UploadedFile(
        name: finalFileName,
        originalName: config.preserveOriginalName ? fileName : null,
        size: bytes.length,
        contentType: contentType,
        uploadedAt: DateTime.now(),
        bytes: bytes,
        hash: config.calculateHash ? sha256.convert(bytes).toString() : null,
      );

      // Save file to disk
      final filePath = path.join(config.uploadDirectory, finalFileName);
      await uploadedFile.saveTo(filePath);

      return FileUploadResult.success(uploadedFile, filePath);
    } catch (e) {
      return FileUploadResult.error('Upload failed: ${e.toString()}');
    }
  }

  String _generateUniqueFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(originalName);
    final baseName = path.basenameWithoutExtension(originalName);
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    
    return '${baseName}_${timestamp}_$random$extension';
  }

  Future<List<FileUploadResult>> handleMultipleUploads(
    List<Map<String, dynamic>> files,
  ) async {
    final results = <FileUploadResult>[];
    
    for (final fileData in files) {
      final result = await handleUpload(
        fileData['field_name'] as String,
        fileData['file_name'] as String,
        fileData['content_type'] as String,
        fileData['bytes'] as Uint8List,
      );
      results.add(result);
    }
    
    return results;
  }
}

class ImageUploadHandler extends FileUploadHandler {
  ImageUploadHandler({FileUploadConfig? config})
      : super(
          config: config ??
              const FileUploadConfig(
                allowedExtensions: ['.jpg', '.jpeg', '.png', '.gif', '.webp'],
                allowedMimeTypes: [
                  'image/jpeg',
                  'image/png',
                  'image/gif',
                  'image/webp',
                ],
                maxFileSize: 5 * 1024 * 1024, // 5MB
              ),
        );
}

class DocumentUploadHandler extends FileUploadHandler {
  DocumentUploadHandler({FileUploadConfig? config})
      : super(
          config: config ??
              const FileUploadConfig(
                allowedExtensions: [
                  '.pdf',
                  '.doc',
                  '.docx',
                  '.xls',
                  '.xlsx',
                  '.ppt',
                  '.pptx',
                  '.txt',
                ],
                allowedMimeTypes: [
                  'application/pdf',
                  'application/msword',
                  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                  'application/vnd.ms-excel',
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                  'application/vnd.ms-powerpoint',
                  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
                  'text/plain',
                ],
                maxFileSize: 20 * 1024 * 1024, // 20MB
              ),
        );
}

class FileStorage {
  static Future<String> store(UploadedFile file, String directory) async {
    final filePath = path.join(directory, file.name);
    await file.saveTo(filePath);
    return filePath;
  }

  static Future<bool> exists(String filePath) async {
    return await File(filePath).exists();
  }

  static Future<void> delete(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<Uint8List> read(String filePath) async {
    final file = File(filePath);
    return await file.readAsBytes();
  }

  static Future<String> move(String sourcePath, String destinationPath) async {
    final sourceFile = File(sourcePath);
    final destinationFile = File(destinationPath);
    
    await destinationFile.create(recursive: true);
    await sourceFile.copy(destinationPath);
    await sourceFile.delete();
    
    return destinationPath;
  }

  static Future<List<String>> listFiles(String directory) async {
    final dir = Directory(directory);
    if (!await dir.exists()) return [];
    
    final files = <String>[];
    await for (final entity in dir.list()) {
      if (entity is File) {
        files.add(entity.path);
      }
    }
    
    return files;
  }

  static Future<int> getDirectorySize(String directory) async {
    final dir = Directory(directory);
    if (!await dir.exists()) return 0;
    
    int totalSize = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    
    return totalSize;
  }
}

class FileUploadMiddleware {
  final FileUploadHandler handler;
  final String tempDirectory;

  FileUploadMiddleware({
    FileUploadHandler? handler,
    this.tempDirectory = 'temp/uploads',
  }) : handler = handler ?? FileUploadHandler();

  Future<Map<String, FileUploadResult>> processMultipartData(
    Map<String, dynamic> multipartData,
  ) async {
    final results = <String, FileUploadResult>{};
    
    for (final entry in multipartData.entries) {
      if (entry.value is Map<String, dynamic>) {
        final fileData = entry.value as Map<String, dynamic>;
        if (fileData.containsKey('bytes') && fileData.containsKey('filename')) {
          final result = await handler.handleUpload(
            entry.key,
            fileData['filename'] as String,
            fileData['content_type'] as String? ?? 'application/octet-stream',
            fileData['bytes'] as Uint8List,
          );
          results[entry.key] = result;
        }
      }
    }
    
    return results;
  }
}

extension FileUploadExtensions on Map<String, dynamic> {
  bool get hasFiles {
    return values.any((value) => 
      value is Map<String, dynamic> && 
      value.containsKey('bytes') && 
      value.containsKey('filename')
    );
  }
  
  List<String> get fileFields {
    return entries
        .where((entry) => 
          entry.value is Map<String, dynamic> && 
          (entry.value as Map<String, dynamic>).containsKey('bytes'))
        .map((entry) => entry.key)
        .toList();
  }
}