import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class XRayStorageService {
  static const String _embeddedPrefix = 'embedded_xray|';

  static bool isEmbedded(String? value) {
    return value != null && value.startsWith(_embeddedPrefix);
  }

  static String? normalizeLegacyPath(String? value) {
    if (value == null || value.isEmpty || isEmbedded(value)) {
      return value;
    }

    final trimmed = value.trim();
    final directFile = File(trimmed);
    if (directFile.existsSync()) {
      return directFile.path;
    }

    String normalized = trimmed;
    if (normalized.startsWith('/user/')) {
      normalized = normalized.replaceFirst('/user/', '/Users/');
    }
    normalized = normalized.replaceAll('/downloads/', '/Downloads/');
    normalized = normalized.replaceAll('/desktop/', '/Desktop/');
    normalized = normalized.replaceAll('/documents/', '/Documents/');
    normalized = normalized.replaceAll('/pictures/', '/Pictures/');

    return normalized;
  }

  static Future<String?> importImage(String? sourcePath) async {
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      return null;
    }

    final normalizedPath = normalizeLegacyPath(sourcePath);
    if (normalizedPath == null) {
      return null;
    }

    final file = File(normalizedPath);
    if (!await file.exists()) {
      throw Exception('Selected x-ray image file was not found.');
    }

    final bytes = await file.readAsBytes();
    final extension = _sanitizeExtension(path.extension(file.path));
    return '$_embeddedPrefix$extension|${base64Encode(bytes)}';
  }

  static Uint8List? decodeEmbeddedBytes(String? value) {
    if (!isEmbedded(value)) {
      return null;
    }

    try {
      final parts = value!.split('|');
      if (parts.length < 3) {
        return null;
      }
      return Uint8List.fromList(base64Decode(parts.sublist(2).join('|')));
    } catch (_) {
      return null;
    }
  }

  static String _extractExtension(String value) {
    if (!isEmbedded(value)) {
      return _sanitizeExtension(path.extension(value));
    }

    final parts = value.split('|');
    if (parts.length < 3) {
      return '.jpg';
    }

    return _sanitizeExtension(parts[1]);
  }

  static Future<String?> resolveImagePath(String? storedValue) async {
    if (storedValue == null || storedValue.isEmpty) {
      return null;
    }

    if (!isEmbedded(storedValue)) {
      final normalizedPath = normalizeLegacyPath(storedValue);
      if (normalizedPath == null) {
        return null;
      }
      return await File(normalizedPath).exists() ? normalizedPath : null;
    }

    final bytes = decodeEmbeddedBytes(storedValue);
    if (bytes == null) {
      return null;
    }

    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory(path.join(tempDir.path, 'xray_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    final hash = crypto.sha1.convert(bytes).toString();
    final extension = _extractExtension(storedValue);
    final tempFile = File(path.join(cacheDir.path, '$hash$extension'));
    if (!await tempFile.exists()) {
      await tempFile.writeAsBytes(bytes, flush: true);
    }

    return tempFile.path;
  }

  static String _sanitizeExtension(String extension) {
    if (extension.isEmpty) {
      return '.jpg';
    }
    return extension.startsWith('.') ? extension : '.$extension';
  }
}
