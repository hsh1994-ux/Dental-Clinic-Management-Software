import 'dart:io';
import 'package:path/path.dart' as p;

/// Provides paths for all persistent app data.
///
/// Data is stored in a "ClinC Data" folder that sits next to the app:
///   macOS:   {folder_containing_clinc.app}/ClinC Data/
///   Windows: {Release_folder}/ClinC Data/
///   Linux:   {bundle_folder}/ClinC Data/
///
/// This keeps everything together for easy migration while avoiding
/// macOS restrictions on writing inside an app bundle.
class AppStorage {
  AppStorage._();

  static String get dataDir {
    if (Platform.isMacOS) {
      // Executable is at clinc.app/Contents/MacOS/clinc — go up 3 levels
      // to reach the folder that contains clinc.app.
      final appBundleParent =
          File(Platform.resolvedExecutable).parent.parent.parent.parent;
      return p.join(appBundleParent.path, 'ClinC Data');
    }
    // Windows / Linux: sibling to the executable directory.
    return p.join(File(Platform.resolvedExecutable).parent.path, 'ClinC Data');
  }

  static String get dbPath => p.join(dataDir, 'clinc_database.db');

  static String get settingsPath => p.join(dataDir, 'settings.json');

  static Future<void> ensureDataDirExists() async {
    await Directory(dataDir).create(recursive: true);
  }
}
