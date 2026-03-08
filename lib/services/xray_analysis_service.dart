import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

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
  // Adjust this path based on where you deploy your Python script
  // For development, assume it's in the project root relative to the Flutter app
  // For flutter run testing, use direct paths
  static String get _pythonExecutable {
    if (kDebugMode) {
      // Use the current project directory instead of a hardcoded D:\ path
      return path.join(Directory.current.path, 'python_module', 'python.exe');
    }
    final exePath = Platform.resolvedExecutable;
    final exeDir = path.dirname(exePath);
    return path.join(exeDir, 'python_module', 'python.exe');
  }

  static String get _pythonScriptPath {
    if (kDebugMode) {
      // Use the current project directory instead of a hardcoded D:\ path
      return path.join(
          Directory.current.path, 'python_module', 'xray_analyzer.py');
    }
    final exePath = Platform.resolvedExecutable;
    final exeDir = path.dirname(exePath);
    return path.join(exeDir, 'python_module', 'xray_analyzer.py');
  }

  Future<XRayAnalysisResult> analyzeXRayImage(
      String imagePath, String patientName, String locale) async {
    if (!File(_pythonScriptPath).existsSync()) {
      debugPrint('Python script not found at: $_pythonScriptPath');
      return XRayAnalysisResult.error('Python analysis script not found.');
    }

    try {
      final result = await Process.run(
        _pythonExecutable,
        [_pythonScriptPath, imagePath, patientName, locale],
      );

      if (result.exitCode == 0) {
        String rawStdout = result.stdout as String;
        print('Raw Python stdout: $rawStdout'); // Added for debugging
        // Find the start of the JSON output (first '{' character)
        final jsonStartIndex = rawStdout.indexOf('{');
        if (jsonStartIndex == -1) {
          print('Error: No JSON output found in Python script stdout.');
          return XRayAnalysisResult.error('No JSON output from Python script.');
        }
        final jsonString = rawStdout.substring(jsonStartIndex);
        print('Extracted JSON string: $jsonString'); // Added for debugging

        final jsonOutput = jsonDecode(jsonString);
        return XRayAnalysisResult.fromJson(jsonOutput);
      } else {
        print('Python script error (exit code: ${result.exitCode}):');
        print('Stdout: ${result.stdout}');
        print('Stderr: ${result.stderr}');
        // Attempt to parse error message if Python script returned one
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
      print('Error running Python script: $e');
      return XRayAnalysisResult.error('Failed to run Python script: $e');
    }
  }
}
