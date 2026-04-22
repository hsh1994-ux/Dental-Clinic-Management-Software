import 'dart:convert';
import 'dart:io';
import 'app_storage.dart';

/// File-based key-value store that replaces SharedPreferences.
/// Persists data as JSON at AppStorage.settingsPath (inside the app bundle).
class FilePreferences {
  static FilePreferences? _instance;
  static Future<FilePreferences>? _initFuture;
  Map<String, dynamic> _data = {};

  FilePreferences._();

  static Future<FilePreferences> getInstance() {
    _initFuture ??= _create();
    return _initFuture!;
  }

  static Future<FilePreferences> _create() async {
    final instance = FilePreferences._();
    await instance._load();
    _instance = instance;
    return instance;
  }

  /// Call after app reset so the next getInstance() re-reads from disk.
  static void clearInstance() {
    _instance = null;
    _initFuture = null;
  }

  Future<void> _load() async {
    await AppStorage.ensureDataDirExists();
    final file = File(AppStorage.settingsPath);
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        _data = json.decode(content) as Map<String, dynamic>;
      } catch (_) {
        _data = {};
      }
    }
  }

  Future<void> _save() async {
    await AppStorage.ensureDataDirExists();
    await File(AppStorage.settingsPath).writeAsString(json.encode(_data));
  }

  bool containsKey(String key) => _data.containsKey(key);

  String? getString(String key) => _data[key] as String?;
  int? getInt(String key) => (_data[key] as num?)?.toInt();
  bool? getBool(String key) => _data[key] as bool?;
  List<String>? getStringList(String key) =>
      (_data[key] as List?)?.cast<String>();

  Future<void> setString(String key, String value) async {
    _data[key] = value;
    await _save();
  }

  Future<void> setInt(String key, int value) async {
    _data[key] = value;
    await _save();
  }

  Future<void> setBool(String key, bool value) async {
    _data[key] = value;
    await _save();
  }

  Future<void> setStringList(String key, List<String> value) async {
    _data[key] = value;
    await _save();
  }

  Future<void> remove(String key) async {
    _data.remove(key);
    await _save();
  }
}
