import 'dart:convert';
import 'package:flutter/foundation.dart';

class StorageUtils {
  static const String _prefix = 'dartango_admin_';
  final Map<String, String> _storage = {};

  Future<void> saveSecure(String key, String value) async {
    final prefixedKey = '$_prefix$key';
    _storage[prefixedKey] = value;

    if (kDebugMode) {
      print('Saved secure data for key: $key');
    }
  }

  Future<String?> getSecure(String key) async {
    final prefixedKey = '$_prefix$key';
    return _storage[prefixedKey];
  }

  Future<void> deleteSecure(String key) async {
    final prefixedKey = '$_prefix$key';
    _storage.remove(prefixedKey);

    if (kDebugMode) {
      print('Deleted secure data for key: $key');
    }
  }

  Future<void> save(String key, String value) async {
    final prefixedKey = '$_prefix$key';
    _storage[prefixedKey] = value;
  }

  Future<String?> get(String key) async {
    final prefixedKey = '$_prefix$key';
    return _storage[prefixedKey];
  }

  Future<void> delete(String key) async {
    final prefixedKey = '$_prefix$key';
    _storage.remove(prefixedKey);
  }

  Future<void> saveJson(String key, Map<String, dynamic> value) async {
    await save(key, jsonEncode(value));
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final jsonString = await get(key);
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveBool(String key, bool value) async {
    await save(key, value.toString());
  }

  Future<bool?> getBool(String key) async {
    final value = await get(key);
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  Future<void> saveInt(String key, int value) async {
    await save(key, value.toString());
  }

  Future<int?> getInt(String key) async {
    final value = await get(key);
    if (value == null) return null;
    return int.tryParse(value);
  }

  Future<void> saveDouble(String key, double value) async {
    await save(key, value.toString());
  }

  Future<double?> getDouble(String key) async {
    final value = await get(key);
    if (value == null) return null;
    return double.tryParse(value);
  }

  Future<void> saveStringList(String key, List<String> value) async {
    await save(key, jsonEncode(value));
  }

  Future<List<String>?> getStringList(String key) async {
    final jsonString = await get(key);
    if (jsonString == null) return null;

    try {
      final list = jsonDecode(jsonString) as List;
      return list.cast<String>();
    } catch (e) {
      return null;
    }
  }

  Future<void> clear() async {
    _storage.clear();
  }

  Future<void> clearSecure() async {
    final keysToRemove =
        _storage.keys.where((key) => key.startsWith(_prefix)).toList();

    for (final key in keysToRemove) {
      _storage.remove(key);
    }
  }

  Future<bool> containsKey(String key) async {
    final prefixedKey = '$_prefix$key';
    return _storage.containsKey(prefixedKey);
  }

  Future<List<String>> getAllKeys() async {
    return _storage.keys
        .where((key) => key.startsWith(_prefix))
        .map((key) => key.substring(_prefix.length))
        .toList();
  }

  Future<Map<String, String>> getAllData() async {
    final result = <String, String>{};
    for (final entry in _storage.entries) {
      if (entry.key.startsWith(_prefix)) {
        final key = entry.key.substring(_prefix.length);
        result[key] = entry.value;
      }
    }
    return result;
  }

  Future<void> setDefaults(Map<String, String> defaults) async {
    for (final entry in defaults.entries) {
      final exists = await containsKey(entry.key);
      if (!exists) {
        await save(entry.key, entry.value);
      }
    }
  }

  Future<void> backup() async {
    final data = await getAllData();
    final backupData = jsonEncode(data);
    await save('backup_${DateTime.now().millisecondsSinceEpoch}', backupData);
  }

  Future<void> restore(String backupKey) async {
    final backupData = await get(backupKey);
    if (backupData == null) return;

    try {
      final data = jsonDecode(backupData) as Map<String, dynamic>;
      await clear();

      for (final entry in data.entries) {
        await save(entry.key, entry.value.toString());
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to restore backup: $e');
      }
    }
  }

  Future<List<String>> getBackupKeys() async {
    final allKeys = await getAllKeys();
    return allKeys.where((key) => key.startsWith('backup_')).toList();
  }

  Future<void> deleteBackup(String backupKey) async {
    await delete(backupKey);
  }

  Future<void> cleanupOldBackups({int maxBackups = 5}) async {
    final backupKeys = await getBackupKeys();
    if (backupKeys.length <= maxBackups) return;

    backupKeys.sort((a, b) => b.compareTo(a));
    final keysToDelete = backupKeys.skip(maxBackups);

    for (final key in keysToDelete) {
      await deleteBackup(key);
    }
  }
}
