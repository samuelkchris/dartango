import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import 'cache.dart';

class FileCache extends CacheBackend {
  final String _cachePath;
  final Duration _defaultTimeout;

  FileCache({
    required String cachePath,
    Duration? defaultTimeout,
  })  : _cachePath = cachePath,
        _defaultTimeout = defaultTimeout ?? const Duration(minutes: 5) {
    _ensureCacheDirectory();
  }

  void _ensureCacheDirectory() {
    final dir = Directory(_cachePath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  String _getFilePath(String key) {
    final hashedKey = md5.convert(utf8.encode(key)).toString();
    return path.join(_cachePath, hashedKey);
  }

  @override
  Future<T?> get<T>(String key) async {
    final filePath = _getFilePath(makeKey(key));
    final file = File(filePath);

    if (!file.existsSync()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;

      final expiry = DateTime.fromMillisecondsSinceEpoch(data['expiry'] as int);
      if (DateTime.now().isAfter(expiry)) {
        await file.delete();
        return null;
      }

      return deserialize<T>(data['value'] as String);
    } catch (e) {
      await file.delete();
      return null;
    }
  }

  @override
  Future<void> set<T>(String key, T value, {Duration? timeout}) async {
    final filePath = _getFilePath(makeKey(key));
    final file = File(filePath);

    final expiry = DateTime.now().add(timeout ?? _defaultTimeout);
    final data = {
      'value': serialize(value),
      'expiry': expiry.millisecondsSinceEpoch,
    };

    await file.writeAsString(json.encode(data));
  }

  @override
  Future<void> delete(String key) async {
    final filePath = _getFilePath(makeKey(key));
    final file = File(filePath);

    if (file.existsSync()) {
      await file.delete();
    }
  }

  @override
  Future<void> clear() async {
    final dir = Directory(_cachePath);
    if (dir.existsSync()) {
      await for (final entity in dir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }
  }

  @override
  Future<bool> exists(String key) async {
    return await get(key) != null;
  }

  @override
  Future<int> size() async {
    final dir = Directory(_cachePath);
    if (!dir.existsSync()) {
      return 0;
    }

    int count = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        count++;
      }
    }

    return count;
  }

  @override
  Future<List<String>> keys() async {
    final dir = Directory(_cachePath);
    if (!dir.existsSync()) {
      return [];
    }

    final keys = <String>[];
    await for (final entity in dir.list()) {
      if (entity is File) {
        keys.add(path.basename(entity.path));
      }
    }

    return keys;
  }

  @override
  Future<Map<String, T>> getMany<T>(List<String> keys) async {
    final result = <String, T>{};
    for (final key in keys) {
      final value = await get<T>(key);
      if (value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  @override
  Future<void> setMany<T>(Map<String, T> values, {Duration? timeout}) async {
    for (final entry in values.entries) {
      await set(entry.key, entry.value, timeout: timeout);
    }
  }

  @override
  Future<void> deleteMany(List<String> keys) async {
    for (final key in keys) {
      await delete(key);
    }
  }

  @override
  Future<T?> getOrSet<T>(String key, Future<T> Function() factory,
      {Duration? timeout}) async {
    final existing = await get<T>(key);
    if (existing != null) {
      return existing;
    }

    final value = await factory();
    await set(key, value, timeout: timeout);
    return value;
  }

  @override
  Future<void> touch(String key, {Duration? timeout}) async {
    final value = await get(key);
    if (value != null) {
      await set(key, value, timeout: timeout);
    }
  }

  @override
  Future<int> increment(String key, {int delta = 1}) async {
    final current = await get<int>(key) ?? 0;
    final newValue = current + delta;
    await set(key, newValue);
    return newValue;
  }

  @override
  Future<int> decrement(String key, {int delta = 1}) async {
    return await increment(key, delta: -delta);
  }

  @override
  Future<void> expire(String key, Duration timeout) async {
    final value = await get(key);
    if (value != null) {
      await set(key, value, timeout: timeout);
    }
  }

  @override
  Future<Duration?> ttl(String key) async {
    final filePath = _getFilePath(makeKey(key));
    final file = File(filePath);

    if (!file.existsSync()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;

      final expiry = DateTime.fromMillisecondsSinceEpoch(data['expiry'] as int);
      final now = DateTime.now();

      if (now.isAfter(expiry)) {
        await file.delete();
        return null;
      }

      return expiry.difference(now);
    } catch (e) {
      await file.delete();
      return null;
    }
  }

  Future<void> cleanup() async {
    final dir = Directory(_cachePath);
    if (!dir.existsSync()) {
      return;
    }

    final now = DateTime.now();
    await for (final entity in dir.list()) {
      if (entity is File) {
        try {
          final content = await entity.readAsString();
          final data = json.decode(content) as Map<String, dynamic>;

          final expiry =
              DateTime.fromMillisecondsSinceEpoch(data['expiry'] as int);
          if (now.isAfter(expiry)) {
            await entity.delete();
          }
        } catch (e) {
          await entity.delete();
        }
      }
    }
  }
}

class TieredCache extends CacheBackend {
  final List<Cache> _tiers;

  TieredCache({
    required List<Cache> tiers,
    Duration? defaultTimeout,
  }) : _tiers = tiers {
    if (tiers.isEmpty) {
      throw ArgumentError('At least one cache tier is required');
    }
  }

  @override
  Future<T?> get<T>(String key) async {
    for (int i = 0; i < _tiers.length; i++) {
      final value = await _tiers[i].get<T>(key);
      if (value != null) {
        // Promote to higher tiers
        for (int j = 0; j < i; j++) {
          await _tiers[j].set(key, value);
        }
        return value;
      }
    }
    return null;
  }

  @override
  Future<void> set<T>(String key, T value, {Duration? timeout}) async {
    // Set in all tiers
    for (final tier in _tiers) {
      await tier.set(key, value, timeout: timeout);
    }
  }

  @override
  Future<void> delete(String key) async {
    // Delete from all tiers
    for (final tier in _tiers) {
      await tier.delete(key);
    }
  }

  @override
  Future<void> clear() async {
    // Clear all tiers
    for (final tier in _tiers) {
      await tier.clear();
    }
  }

  @override
  Future<bool> exists(String key) async {
    for (final tier in _tiers) {
      if (await tier.exists(key)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<int> size() async {
    // Return size of first tier
    return await _tiers.first.size();
  }

  @override
  Future<List<String>> keys() async {
    // Return keys from first tier
    return await _tiers.first.keys();
  }

  @override
  Future<Map<String, T>> getMany<T>(List<String> keys) async {
    final result = <String, T>{};
    for (final key in keys) {
      final value = await get<T>(key);
      if (value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  @override
  Future<void> setMany<T>(Map<String, T> values, {Duration? timeout}) async {
    for (final entry in values.entries) {
      await set(entry.key, entry.value, timeout: timeout);
    }
  }

  @override
  Future<void> deleteMany(List<String> keys) async {
    for (final key in keys) {
      await delete(key);
    }
  }

  @override
  Future<T?> getOrSet<T>(String key, Future<T> Function() factory,
      {Duration? timeout}) async {
    final existing = await get<T>(key);
    if (existing != null) {
      return existing;
    }

    final value = await factory();
    await set(key, value, timeout: timeout);
    return value;
  }

  @override
  Future<void> touch(String key, {Duration? timeout}) async {
    final value = await get(key);
    if (value != null) {
      await set(key, value, timeout: timeout);
    }
  }

  @override
  Future<int> increment(String key, {int delta = 1}) async {
    final current = await get<int>(key) ?? 0;
    final newValue = current + delta;
    await set(key, newValue);
    return newValue;
  }

  @override
  Future<int> decrement(String key, {int delta = 1}) async {
    return await increment(key, delta: -delta);
  }

  @override
  Future<void> expire(String key, Duration timeout) async {
    final value = await get(key);
    if (value != null) {
      await set(key, value, timeout: timeout);
    }
  }

  @override
  Future<Duration?> ttl(String key) async {
    // Check TTL in first tier that has the key
    for (final tier in _tiers) {
      final ttl = await tier.ttl(key);
      if (ttl != null) {
        return ttl;
      }
    }
    return null;
  }
}
