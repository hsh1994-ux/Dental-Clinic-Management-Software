import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import 'xray_storage_service.dart';

// Data model for the X-ray analysis result
class XRayAnalysisResult {
  final String analysisId;
  final DateTime? timestamp; // Made nullable
  final String imagePath;
  final String? annotatedImagePath;
  final String analysisStatus;
  final String? imageQuality;
  final List<XRayFinding> findings;
  final String? medicalAdviceSummary;
  final String? errorMessage;

  XRayAnalysisResult({
    required this.analysisId,
    this.timestamp, // No longer required
    required this.imagePath,
    this.annotatedImagePath,
    required this.analysisStatus,
    this.imageQuality,
    required this.findings,
    this.medicalAdviceSummary,
    this.errorMessage,
  });

  factory XRayAnalysisResult.fromJson(Map<String, dynamic> json) {
    return XRayAnalysisResult(
      analysisId: json['analysis_id'] ?? 'N/A',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null, // Handle nullable timestamp
      imagePath: json['image_path'] ?? 'N/A',
      annotatedImagePath: json['annotated_image_path'],
      analysisStatus: json['analysis_status'] ?? 'error',
      imageQuality: json['image_quality'],
      findings: (json['findings'] as List<dynamic>?)
              ?.map((f) => XRayFinding.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      medicalAdviceSummary: json['medical_advice_summary'],
      errorMessage: json['message'],
    );
  }

  // Factory for error cases where Python script might return a simple error JSON
  factory XRayAnalysisResult.error(String message) {
    return XRayAnalysisResult(
      analysisId: 'error',
      timestamp: DateTime.now(),
      imagePath: 'N/A',
      analysisStatus: 'error',
      findings: [],
      errorMessage: message,
    );
  }
}

class XRayFinding {
  final String area;
  final String issue;
  final double confidence;
  final String? severity;
  final String? recommendation;

  XRayFinding({
    required this.area,
    required this.issue,
    required this.confidence,
    this.severity,
    this.recommendation,
  });

  factory XRayFinding.fromJson(Map<String, dynamic> json) {
    return XRayFinding(
      area: json['area'] ?? 'N/A',
      issue: json['issue'] ?? 'N/A',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      severity: json['severity'],
      recommendation: json['recommendation'],
    );
  }
}

class XRayAnalysisService {
  static Iterable<Directory> _candidateBaseDirectories() sync* {
    final seen = <String>{};

    Iterable<Directory> parentsOf(Directory start) sync* {
      Directory current = start;
      while (true) {
        final normalized = path.normalize(current.path);
        if (!seen.add(normalized)) {
          break;
        }
        yield current;

        final parent = current.parent;
        if (parent.path == current.path) {
          break;
        }
        current = parent;
      }
    }

    yield* parentsOf(Directory.current.absolute);

    final exeDir = File(Platform.resolvedExecutable).parent.absolute;
    yield* parentsOf(exeDir);

    final scriptDir = File(Platform.script.toFilePath()).parent.absolute;
    yield* parentsOf(scriptDir);
  }

  static String? _findPythonScriptPath() {
    const relativeCandidates = [
      'python_module/xray_analyzer.py',
      'Resources/python_module/xray_analyzer.py',
      'Frameworks/App.framework/Resources/flutter_assets/python_module/xray_analyzer.py',
    ];

    for (final baseDir in _candidateBaseDirectories()) {
      for (final relativePath in relativeCandidates) {
        final candidate = path.join(baseDir.path, relativePath);
        if (File(candidate).existsSync()) {
          return candidate;
        }
      }
    }

    return null;
  }

  static bool _commandExists(String command) {
    try {
      final result = Process.runSync(command, const ['--version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static String? _findPythonExecutable() {
    final localCandidates = <String>[
      // Unix-style venv paths (macOS, Linux)
      path.join(Directory.current.path, '.venv', 'bin', 'python'),
      path.join(Directory.current.path, '.venv', 'bin', 'python3'),
      path.join(Directory.current.path, 'venv', 'bin', 'python'),
      path.join(Directory.current.path, 'venv', 'bin', 'python3'),
      // Windows-style venv paths
      path.join(Directory.current.path, '.venv', 'Scripts', 'python.exe'),
      path.join(Directory.current.path, 'venv', 'Scripts', 'python.exe'),
    ];

    for (final baseDir in _candidateBaseDirectories()) {
      localCandidates.addAll([
        // Unix-style venv paths
        path.join(baseDir.path, '.venv', 'bin', 'python'),
        path.join(baseDir.path, '.venv', 'bin', 'python3'),
        path.join(baseDir.path, 'venv', 'bin', 'python'),
        path.join(baseDir.path, 'venv', 'bin', 'python3'),
        // Windows-style venv paths
        path.join(baseDir.path, '.venv', 'Scripts', 'python.exe'),
        path.join(baseDir.path, 'venv', 'Scripts', 'python.exe'),
        // Bundled python
        path.join(baseDir.path, 'python_module', 'python.exe'),
        path.join(baseDir.path, 'python_module', 'python'),
      ]);
    }

    localCandidates.addAll([
      '/opt/homebrew/bin/python3',
      '/opt/homebrew/bin/python',
      '/usr/local/bin/python3',
      '/usr/local/bin/python',
      '/usr/bin/python3',
      '/Library/Frameworks/Python.framework/Versions/Current/bin/python3',
    ]);

    for (final candidate in localCandidates) {
      if (File(candidate).existsSync()) {
        return candidate;
      }
    }

    if (_commandExists('python3')) return 'python3';
    if (_commandExists('python')) return 'python';

    return null;
  }

  Future<XRayAnalysisResult> analyzeXRayImage(
      String imagePath, String patientName, String locale) async {
    final resolvedImagePath = await XRayStorageService.resolveImagePath(imagePath);
    if (resolvedImagePath == null) {
      debugPrint('Unable to resolve x-ray image for analysis.');
      return XRayAnalysisResult.error(
          'X-ray image file could not be prepared for analysis.');
    }

    final pythonScriptPath = _findPythonScriptPath();
    if (pythonScriptPath == null) {
      debugPrint(
          'Python script not found. Checked from current dir: ${Directory.current.path}, executable: ${Platform.resolvedExecutable}');
      return XRayAnalysisResult.error('Python analysis script not found.');
    }

    final pythonExecutable = _findPythonExecutable();
    if (pythonExecutable == null) {
      debugPrint('No Python executable found for x-ray analysis.');
      return XRayAnalysisResult.error(
          'Python runtime not found. Install Python 3 to enable x-ray analysis.');
    }

    try {
      final result = await Process.run(
        pythonExecutable,
        [pythonScriptPath, resolvedImagePath, patientName, locale],
      );

      if (result.exitCode == 0) {
        final rawStdout = result.stdout as String;
        final jsonStartIndex = rawStdout.indexOf('{');
        if (jsonStartIndex == -1) {
          debugPrint('No JSON output found in Python script stdout.');
          return XRayAnalysisResult.error('No JSON output from Python script.');
        }
        final jsonString = rawStdout.substring(jsonStartIndex);
        final jsonOutput = jsonDecode(jsonString);
        return XRayAnalysisResult.fromJson(jsonOutput);
      } else {
        debugPrint('Python script error (exit code: ${result.exitCode}): ${result.stderr}');
        try {
          final jsonError = jsonDecode(result.stdout as String);
          return XRayAnalysisResult.error(
              jsonError['message'] ?? 'Unknown Python script error.');
        } catch (_) {
          return XRayAnalysisResult.error(
              'Python script failed: ${result.stderr}');
        }
      }
    } catch (e) {
      debugPrint('Error running Python script: $e');
      return XRayAnalysisResult.error('Failed to run Python script: $e');
    }
  }
}
