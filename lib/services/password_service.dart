import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'file_preferences.dart';

class PasswordService {
  static const _doubleHashKey = 'password_double_hash';

  static String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  static String hashPassword(String password) => _sha256(password);

  static String doubleHashPassword(String password) =>
      _sha256(_sha256(password));

  static Future<bool> isPasswordSet() async {
    final prefs = await FilePreferences.getInstance();
    return prefs.containsKey(_doubleHashKey) &&
        (prefs.getString(_doubleHashKey)?.isNotEmpty ?? false);
  }

  static Future<void> savePassword(String password) async {
    final prefs = await FilePreferences.getInstance();
    await prefs.setString(_doubleHashKey, doubleHashPassword(password));
  }

  static Future<bool> verifyPassword(String password) async {
    final prefs = await FilePreferences.getInstance();
    final stored = prefs.getString(_doubleHashKey);
    if (stored == null || stored.isEmpty) return false;
    return doubleHashPassword(password) == stored;
  }

  static Future<void> clearPassword() async {
    final prefs = await FilePreferences.getInstance();
    await prefs.remove(_doubleHashKey);
  }
}
