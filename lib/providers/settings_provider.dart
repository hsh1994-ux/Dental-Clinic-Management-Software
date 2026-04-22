import 'package:flutter/material.dart';
import '../services/file_preferences.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en');
  String? _backupLocation;
  DateTime? _lastBackupTime;
  int _backupRetentionDays = 7;
  int _autoBackupIntervalHours = 24;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  String? get backupLocation => _backupLocation;
  DateTime? get lastBackupTime => _lastBackupTime;
  int get backupRetentionDays => _backupRetentionDays;
  int get autoBackupIntervalHours => _autoBackupIntervalHours;

  bool get shouldAutoBackup {
    if (_lastBackupTime == null) return true;
    return DateTime.now().difference(_lastBackupTime!) >
        Duration(hours: _autoBackupIntervalHours);
  }

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await FilePreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 0;
    _themeMode = ThemeMode.values[themeIndex];

    final languageCode = prefs.getString('languageCode') ?? 'en';
    _locale = Locale(languageCode);

    _backupLocation = prefs.getString('backupLocation');
    _backupRetentionDays = prefs.getInt('backupRetentionDays') ?? 7;
    _autoBackupIntervalHours = prefs.getInt('autoBackupIntervalHours') ?? 24;

    final lastBackupMs = prefs.getInt('lastBackupTimestamp');
    if (lastBackupMs != null) {
      _lastBackupTime = DateTime.fromMillisecondsSinceEpoch(lastBackupMs);
    }

    notifyListeners();
  }

  Future<void> updateLastBackupTime() async {
    _lastBackupTime = DateTime.now();
    final prefs = await FilePreferences.getInstance();
    await prefs.setInt(
        'lastBackupTimestamp', _lastBackupTime!.millisecondsSinceEpoch);
    notifyListeners();
  }

  Future<void> setBackupRetentionDays(int days) async {
    _backupRetentionDays = days;
    final prefs = await FilePreferences.getInstance();
    await prefs.setInt('backupRetentionDays', days);
    notifyListeners();
  }

  Future<void> setAutoBackupIntervalHours(int hours) async {
    _autoBackupIntervalHours = hours;
    final prefs = await FilePreferences.getInstance();
    await prefs.setInt('autoBackupIntervalHours', hours);
    notifyListeners();
  }

  Future<void> setBackupLocation(String? path) async {
    _backupLocation = path;
    final prefs = await FilePreferences.getInstance();
    if (path != null) {
      await prefs.setString('backupLocation', path);
    } else {
      await prefs.remove('backupLocation');
    }
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDarkMode) async {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    final prefs = await FilePreferences.getInstance();
    await prefs.setInt('themeMode', _themeMode.index);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    final prefs = await FilePreferences.getInstance();
    await prefs.setString('languageCode', languageCode);
    notifyListeners();
  }
}
