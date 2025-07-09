import 'dart:io';
import 'dart:convert';

import 'exceptions.dart';

abstract class TemplateLoader {
  TemplateSource loadTemplate(String name);
  bool exists(String name);
  List<String> listTemplates();
}

class TemplateSource {
  final String source;
  final String name;
  final String? origin;
  final DateTime? lastModified;
  
  TemplateSource(this.source, this.name, {this.origin, this.lastModified});
}

class FileSystemLoader extends TemplateLoader {
  final List<String> templateDirs;
  final String encoding;
  final bool followLinks;
  
  FileSystemLoader(this.templateDirs, {
    this.encoding = 'utf-8',
    this.followLinks = false,
  });
  
  @override
  TemplateSource loadTemplate(String name) {
    for (final templateDir in templateDirs) {
      final filePath = _buildPath(templateDir, name);
      final file = File(filePath);
      
      if (file.existsSync()) {
        if (!followLinks && _isSymlink(file)) {
          continue;
        }
        
        final content = file.readAsStringSync(encoding: Encoding.getByName(encoding)!);
        final lastModified = file.lastModifiedSync();
        
        return TemplateSource(
          content,
          name,
          origin: filePath,
          lastModified: lastModified,
        );
      }
    }
    
    throw TemplateNotFoundException('Template "$name" not found in any of the template directories');
  }
  
  @override
  bool exists(String name) {
    for (final templateDir in templateDirs) {
      final filePath = _buildPath(templateDir, name);
      final file = File(filePath);
      
      if (file.existsSync()) {
        if (!followLinks && _isSymlink(file)) {
          continue;
        }
        return true;
      }
    }
    
    return false;
  }
  
  @override
  List<String> listTemplates() {
    final templates = <String>[];
    
    for (final templateDir in templateDirs) {
      final dir = Directory(templateDir);
      if (dir.existsSync()) {
        final files = dir.listSync(recursive: true, followLinks: followLinks);
        
        for (final file in files) {
          if (file is File && file.path.endsWith('.html')) {
            final relativePath = file.path.substring(templateDir.length + 1);
            templates.add(relativePath);
          }
        }
      }
    }
    
    return templates;
  }
  
  String _buildPath(String templateDir, String name) {
    final parts = name.split('/');
    return [templateDir, ...parts].join(Platform.pathSeparator);
  }
  
  bool _isSymlink(File file) {
    try {
      final stat = file.statSync();
      return stat.type == FileSystemEntityType.link;
    } catch (e) {
      return false;
    }
  }
}

class StringLoader extends TemplateLoader {
  final Map<String, String> templates;
  
  StringLoader(this.templates);
  
  @override
  TemplateSource loadTemplate(String name) {
    if (!templates.containsKey(name)) {
      throw TemplateNotFoundException('Template "$name" not found in StringLoader');
    }
    
    return TemplateSource(
      templates[name]!,
      name,
      origin: 'string:$name',
    );
  }
  
  @override
  bool exists(String name) {
    return templates.containsKey(name);
  }
  
  @override
  List<String> listTemplates() {
    return templates.keys.toList();
  }
  
  void addTemplate(String name, String content) {
    templates[name] = content;
  }
  
  void removeTemplate(String name) {
    templates.remove(name);
  }
}

class CachedLoader extends TemplateLoader {
  final TemplateLoader loader;
  final Map<String, TemplateSource> _cache = {};
  final Map<String, DateTime> _lastChecked = {};
  final Duration cacheTimeout;
  
  CachedLoader(this.loader, {this.cacheTimeout = const Duration(minutes: 5)});
  
  @override
  TemplateSource loadTemplate(String name) {
    final now = DateTime.now();
    
    if (_cache.containsKey(name)) {
      final lastChecked = _lastChecked[name];
      if (lastChecked != null && now.difference(lastChecked) < cacheTimeout) {
        return _cache[name]!;
      }
    }
    
    final source = loader.loadTemplate(name);
    _cache[name] = source;
    _lastChecked[name] = now;
    
    return source;
  }
  
  @override
  bool exists(String name) {
    return loader.exists(name);
  }
  
  @override
  List<String> listTemplates() {
    return loader.listTemplates();
  }
  
  void clearCache() {
    _cache.clear();
    _lastChecked.clear();
  }
  
  void removeCached(String name) {
    _cache.remove(name);
    _lastChecked.remove(name);
  }
}

class ChainLoader extends TemplateLoader {
  final List<TemplateLoader> loaders;
  
  ChainLoader(this.loaders);
  
  @override
  TemplateSource loadTemplate(String name) {
    for (final loader in loaders) {
      try {
        return loader.loadTemplate(name);
      } catch (e) {
        continue;
      }
    }
    
    throw TemplateNotFoundException('Template "$name" not found in any loader');
  }
  
  @override
  bool exists(String name) {
    for (final loader in loaders) {
      if (loader.exists(name)) {
        return true;
      }
    }
    
    return false;
  }
  
  @override
  List<String> listTemplates() {
    final templates = <String>[];
    
    for (final loader in loaders) {
      templates.addAll(loader.listTemplates());
    }
    
    return templates.toSet().toList();
  }
}

class AssetLoader extends TemplateLoader {
  final String assetPath;
  final String package;
  
  AssetLoader(this.assetPath, {this.package = ''});
  
  @override
  TemplateSource loadTemplate(String name) {
    final fullPath = package.isEmpty ? '$assetPath/$name' : 'packages/$package/$assetPath/$name';
    
    try {
      final content = _loadAssetString(fullPath);
      return TemplateSource(
        content,
        name,
        origin: 'asset:$fullPath',
      );
    } catch (e) {
      throw TemplateNotFoundException('Template "$name" not found in assets');
    }
  }
  
  @override
  bool exists(String name) {
    try {
      loadTemplate(name);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  List<String> listTemplates() {
    return [];
  }
  
  String _loadAssetString(String path) {
    final file = File(path);
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
    
    throw FileSystemException('Asset not found', path);
  }
}

class MemoryLoader extends TemplateLoader {
  final Map<String, TemplateSource> _templates = {};
  
  @override
  TemplateSource loadTemplate(String name) {
    if (!_templates.containsKey(name)) {
      throw TemplateNotFoundException('Template "$name" not found in MemoryLoader');
    }
    
    return _templates[name]!;
  }
  
  @override
  bool exists(String name) {
    return _templates.containsKey(name);
  }
  
  @override
  List<String> listTemplates() {
    return _templates.keys.toList();
  }
  
  void addTemplate(String name, String content, {String? origin}) {
    _templates[name] = TemplateSource(
      content,
      name,
      origin: origin ?? 'memory:$name',
    );
  }
  
  void removeTemplate(String name) {
    _templates.remove(name);
  }
  
  void clear() {
    _templates.clear();
  }
}

class DatabaseLoader extends TemplateLoader {
  final String tableName;
  final String nameColumn;
  final String contentColumn;
  final String? originColumn;
  final String? lastModifiedColumn;
  
  DatabaseLoader({
    this.tableName = 'templates',
    this.nameColumn = 'name',
    this.contentColumn = 'content',
    this.originColumn = 'origin',
    this.lastModifiedColumn = 'last_modified',
  });
  
  @override
  TemplateSource loadTemplate(String name) {
    final template = _queryTemplate(name);
    
    if (template == null) {
      throw TemplateNotFoundException('Template "$name" not found in database');
    }
    
    return TemplateSource(
      template['content'],
      name,
      origin: template['origin'],
      lastModified: template['last_modified'],
    );
  }
  
  @override
  bool exists(String name) {
    return _queryTemplate(name) != null;
  }
  
  @override
  List<String> listTemplates() {
    final templates = _queryAllTemplates();
    return templates.map((t) => t['name'] as String).toList();
  }
  
  Map<String, dynamic>? _queryTemplate(String name) {
    return null;
  }
  
  List<Map<String, dynamic>> _queryAllTemplates() {
    return [];
  }
}

class CompoundLoader extends TemplateLoader {
  final Map<String, TemplateLoader> loaders;
  
  CompoundLoader(this.loaders);
  
  @override
  TemplateSource loadTemplate(String name) {
    for (final entry in loaders.entries) {
      final prefix = entry.key;
      final loader = entry.value;
      
      if (name.startsWith('$prefix:')) {
        final templateName = name.substring(prefix.length + 1);
        return loader.loadTemplate(templateName);
      }
    }
    
    throw TemplateNotFoundException('Template "$name" not found in any compound loader');
  }
  
  @override
  bool exists(String name) {
    for (final entry in loaders.entries) {
      final prefix = entry.key;
      final loader = entry.value;
      
      if (name.startsWith('$prefix:')) {
        final templateName = name.substring(prefix.length + 1);
        return loader.exists(templateName);
      }
    }
    
    return false;
  }
  
  @override
  List<String> listTemplates() {
    final templates = <String>[];
    
    for (final entry in loaders.entries) {
      final prefix = entry.key;
      final loader = entry.value;
      
      final loaderTemplates = loader.listTemplates();
      templates.addAll(loaderTemplates.map((t) => '$prefix:$t'));
    }
    
    return templates;
  }
}