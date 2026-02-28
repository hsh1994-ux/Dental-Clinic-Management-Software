import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;

/// Singleton service that holds the SQLCipher encryption key in RAM.
/// The key is SHA-256(password) as a hex string — never persisted to disk.
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._();
  static EncryptionService get instance => _instance;
  EncryptionService._();

  List<int>? _keyBytes;

  /// Whether the encryption key is currently loaded in RAM.
  bool get hasKey => _keyBytes != null;

  /// Returns the key as a hex string for SQLCipher PRAGMA key.
  String? get keyHex {
    if (_keyBytes == null) return null;
    return _keyBytes!.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Derives the AES-256 key from password: key = SHA-256(password).
  /// Stored in RAM only — never written to disk.
  void setKey(String password) {
    final hash = crypto.sha256.convert(utf8.encode(password));
    _keyBytes = List<int>.from(hash.bytes); // 32 bytes = 256 bits
  }

  /// Securely wipes the key from RAM by overwriting with zeros.
  void clearKey() {
    if (_keyBytes != null) {
      for (var i = 0; i < _keyBytes!.length; i++) {
        _keyBytes![i] = 0;
      }
      _keyBytes = null;
    }
  }
}
