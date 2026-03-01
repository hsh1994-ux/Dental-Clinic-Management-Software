import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart' as crypto;
import 'dart:typed_data';
import 'encryption_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static bool _updaterStarted = false;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    if (!_updaterStarted) {
      _instance.startAppointmentStatusUpdater();
      _updaterStarted = true;
    }
    return _database!;
  }

  void startAppointmentStatusUpdater() {
    // Run the check once at startup, then every 2 hours.
    updatePastAppointmentsStatus();
    Timer.periodic(const Duration(hours: 2), (timer) {
      updatePastAppointmentsStatus();
    });
  }

  Future<void> updatePastAppointmentsStatus() async {
    final db = await database;
    final now = DateTime.now();
    // Assuming appointment_date is stored in a format like 'YYYY-MM-DD HH:MM:SS'
    final formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    try {
      int count = await db.rawUpdate('''
        UPDATE Appointments
        SET status = ?
        WHERE status = ? AND appointment_date <= ?
      ''', ['منجز', 'محجوز', formattedDateTime]);
      if (count > 0) {
        print('Updated $count appointments to "منجز"');
      }
    } catch (e) {
      print('Error updating appointment statuses: $e');
    }
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'clinc_database.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Patients (
        patient_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        birth_date TEXT,
        gender TEXT,
        address TEXT,
        phone TEXT,
        marital_status TEXT,
        file_number TEXT UNIQUE NOT NULL,
        first_visit_date TEXT,
        xray_image TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE Treatments (
        treatment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        diagnosis TEXT,
        treatment TEXT,
        tooth_number TEXT,
        agreed_amount REAL,
        agreed_amount_paid REAL DEFAULT 0.0,
        treatment_date TEXT,
        status TEXT DEFAULT 'قيد التنفيذ',
        expenses REAL DEFAULT 0.0,
        laboratory_name TEXT,
        FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE Invoices (
        invoice_id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        invoice_date TEXT NOT NULL,
        total_amount REAL,
        status TEXT DEFAULT 'مسودة',
        FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE Invoice_Treatments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        treatment_id INTEGER NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES Invoices(invoice_id) ON DELETE CASCADE,
        FOREIGN KEY (treatment_id) REFERENCES Treatments(treatment_id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE Payments (
        payment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        method TEXT DEFAULT 'نقدي',
        FOREIGN KEY (invoice_id) REFERENCES Invoices(invoice_id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE Expenses (
        expense_id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT,
        amount REAL NOT NULL,
        expense_date TEXT NOT NULL,
        category TEXT DEFAULT 'أخرى'
      )
    ''');
    await db.execute('''
      CREATE TABLE Appointments (
        appointment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        appointment_date TEXT NOT NULL,
        notes TEXT,
        doctor_notes TEXT,
        status TEXT DEFAULT 'محجوز',
        FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE Treatments ADD COLUMN agreed_amount_paid REAL DEFAULT 0.0;');
    }
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE Treatments ADD COLUMN expenses REAL DEFAULT 0.0;');
      await db
          .execute('ALTER TABLE Treatments ADD COLUMN laboratory_name TEXT;');
    }
    if (oldVersion < 4) {
      await db.transaction((txn) async {
        await txn.execute('''
          CREATE TABLE Patients_new (
            patient_id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            birth_date TEXT,
            gender TEXT,
            address TEXT,
            phone TEXT,
            marital_status TEXT,
            file_number TEXT UNIQUE NOT NULL,
            first_visit_date TEXT,
            xray_image TEXT
          )
        ''');

        await txn.execute('''
          INSERT INTO Patients_new (patient_id, name, gender, address, phone, marital_status, file_number, first_visit_date, xray_image, birth_date)
          SELECT patient_id, name, gender, address, phone, marital_status, file_number, first_visit_date, xray_image,
                 CASE WHEN age IS NOT NULL THEN (CAST(strftime('%Y', 'now') AS INTEGER) - age) || '-01-01' ELSE NULL END
          FROM Patients
        ''');

        await txn.execute('DROP TABLE Patients');
        await txn.execute('ALTER TABLE Patients_new RENAME TO Patients');
      });
    }
  }

  Future _onConfigure(Database db) async {
    // Set SQLCipher encryption key — must be the FIRST statement
    final keyHex = EncryptionService.instance.keyHex;
    if (keyHex != null) {
      await db.execute("PRAGMA key = \"x'$keyHex'\"");
    }
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> clearDatabase() async {
    final db = await database;
    final tables = [
      'Payments',
      'Invoice_Treatments',
      'Appointments',
      'Expenses',
      'Invoices',
      'Treatments',
      'Patients'
    ];
    await db.execute('PRAGMA foreign_keys = OFF');
    for (var table in tables) {
      await db.delete(table);
    }
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ─── SQLCipher lifecycle methods ───

  Future<String> get _databasePath async {
    return join(await getDatabasesPath(), 'clinc_database.db');
  }

  Future<String> get _encryptedDatabasePath async {
    return join(await getDatabasesPath(), 'clinc_database.db.enc');
  }

  /// Closes the database and nulls the singleton reference.
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Returns true if the file starts with the SQLite plaintext header.
  Future<bool> _isPlaintextDatabase(String path) async {
    final file = File(path);
    if (!await file.exists()) return false;
    final length = await file.length();
    if (length < 16) return false;
    RandomAccessFile? raf;
    try {
      raf = await file.open();
      final header = await raf.read(16);
      return String.fromCharCodes(header).startsWith('SQLite format 3');
    } catch (_) {
      return false;
    } finally {
      await raf?.close();
    }
  }

  /// One-time migration from old AES-GCM .enc file to SQLCipher .db.
  Future<void> _migrateFromAesGcmIfNeeded() async {
    final encPath = await _encryptedDatabasePath;
    final encFile = File(encPath);
    if (!await encFile.exists()) return;

    // The old .enc format was AES-GCM(nonce+mac+ciphertext).
    // We can't decrypt it anymore (cryptography package removed).
    // Just delete the stale .enc file — the plaintext .db or a fresh
    // SQLCipher DB will be used instead.
    await encFile.delete();
  }

  /// Called after authentication. Handles migration and opens the DB.
  /// The DB file on disk is always encrypted (SQLCipher).
  Future<void> openDatabaseWithKey() async {
    // Close any auto-opened DB (from provider constructors)
    await closeDatabase();

    // Clean up old AES-GCM .enc file if present
    await _migrateFromAesGcmIfNeeded();

    final dbPath = await _databasePath;

    // If a plaintext (unencrypted) DB exists from before SQLCipher was
    // added, delete it. SQLCipher can't open a plaintext file with a key.
    // A fresh encrypted DB will be created and sample data re-inserted
    // by checkAndInsertInitialData().
    if (await _isPlaintextDatabase(dbPath)) {
      try {
        await deleteDatabase(dbPath);
      } catch (e) {
        print('Error deleting plaintext database: $e');
      }
    }

    // Open (or create) the SQLCipher-encrypted database
    _database = await _initDatabase();
    if (!_updaterStarted) {
      startAppointmentStatusUpdater();
      _updaterStarted = true;
    }
  }

  /// Re-encrypts the database with the current key (after password change).
  /// Must be called while the DB is open with the OLD key, and
  /// EncryptionService already holds the NEW key.
  Future<void> rekeyDatabase() async {
    final keyHex = EncryptionService.instance.keyHex;
    if (keyHex == null) throw StateError('New encryption key not set');
    final db = await database;
    await db.execute("PRAGMA rekey = \"x'$keyHex'\"");
  }

  /// Deletes the database file entirely (used during app reset).
  Future<void> deleteDatabaseFile() async {
    await closeDatabase();
    final dbPath = await _databasePath;
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    // Also clean up old .enc if it exists
    final encPath = await _encryptedDatabasePath;
    final encFile = File(encPath);
    if (await encFile.exists()) {
      await encFile.delete();
    }
  }

  Future<void> _insertInitialData(Database db) async {
    try {
      String jsonString =
          await rootBundle.loadString('assets/data/sample_data.json');
      if (jsonString.trim().isEmpty) return;
      final data = json.decode(jsonString);

      // Insert Patients
      if (data['patients'] != null) {
        for (var patient in data['patients']) {
          await db.insert('Patients', patient,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Insert Appointments
      if (data['appointments'] != null) {
        for (var appointment in data['appointments']) {
          await db.insert('Appointments', appointment,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Insert Treatments
      if (data['treatments'] != null) {
        for (var treatment in data['treatments']) {
          await db.insert('Treatments', treatment,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Insert Invoices
      if (data['invoices'] != null) {
        for (var invoice in data['invoices']) {
          await db.insert('Invoices', invoice,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Insert Invoice_Treatments
      if (data['invoice_treatments'] != null) {
        for (var invoiceTreatment in data['invoice_treatments']) {
          await db.insert('Invoice_Treatments', invoiceTreatment,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Insert Payments
      if (data['payments'] != null) {
        for (var payment in data['payments']) {
          await db.insert('Payments', payment,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Insert Expenses
      if (data['expenses'] != null) {
        for (var expense in data['expenses']) {
          await db.insert('Expenses', expense,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  Future<void> checkAndInsertInitialData() async {
    final db = await database;
    // Check if patients table is empty, assuming if patients table is empty, then no data has been loaded
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM Patients'));
    if (count == 0) {
      await _insertInitialData(db);
    }
  }
}

class BackupService {
  final DatabaseService _databaseService = DatabaseService();

  /// Pick a backup file (.clinc encrypted or .zip legacy). Returns path or null.
  Future<String?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['clinc', 'zip'],
    );
    if (result == null) return null;
    return result.files.single.path;
  }

  /// Whether the backup file is an encrypted .clinc file.
  bool isBackupEncrypted(String filePath) {
    return filePath.toLowerCase().endsWith('.clinc');
  }

  /// Export all data as an AES-256-encrypted .clinc backup file.
  /// The file is encrypted with the current app password's derived key.
  Future<String?> exportData() async {
    try {
      final db = await _databaseService.database;
      final tables = [
        'Patients',
        'Appointments',
        'Treatments',
        'Invoices',
        'Invoice_Treatments',
        'Payments',
        'Expenses'
      ];
      final Map<String, List<Map<String, dynamic>>> allData = {};

      for (var table in tables) {
        final List<Map<String, dynamic>> tableData = await db.query(table);
        allData[table] = tableData;
      }

      final String jsonData = json.encode(allData);

      final tempDir = await getTemporaryDirectory();
      final backupDir = Directory('${tempDir.path}/backup');
      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
      }
      await backupDir.create();

      final jsonFile = File('${backupDir.path}/backup.json');
      await jsonFile.writeAsString(jsonData);

      final imagesDir = Directory('${backupDir.path}/images');
      await imagesDir.create();

      final patients = allData['Patients'] ?? [];
      for (var patient in patients) {
        final xrayPath = patient['xray_image'];
        if (xrayPath != null && xrayPath.isNotEmpty) {
          final imageFile = File(xrayPath);
          if (await imageFile.exists()) {
            final imageName = basename(imageFile.path);
            await imageFile.copy('${imagesDir.path}/$imageName');
          }
        }
      }

      // Create a plain ZIP in temp first
      final tempZipPath = '${tempDir.path}/temp_backup.zip';
      final encoder = ZipFileEncoder();
      encoder.create(tempZipPath);
      await encoder.addDirectory(backupDir);
      encoder.close();

      // Encrypt the entire ZIP with AES-256-CBC
      final encService = EncryptionService.instance;
      if (!encService.hasKey) throw Exception('Encryption key not available');
      final keyBytes = encService.keyBytes!;
      final zipBytes = await File(tempZipPath).readAsBytes();

      final key = enc.Key(Uint8List.fromList(keyBytes));
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter =
          enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc, padding: 'PKCS7'));
      final encrypted = encrypter.encryptBytes(zipBytes.toList(), iv: iv);

      // HMAC-SHA256 for quick password verification on import
      final hmac = crypto.Hmac(crypto.sha256, keyBytes);
      final hmacDigest = hmac.convert(utf8.encode('clinc-backup-verify'));

      // File format: [16-byte IV] + [32-byte HMAC] + [AES ciphertext]
      final outputBytes = Uint8List(16 + 32 + encrypted.bytes.length);
      outputBytes.setRange(0, 16, iv.bytes);
      outputBytes.setRange(16, 48, hmacDigest.bytes);
      outputBytes.setRange(48, outputBytes.length, encrypted.bytes);

      final outputPath =
          '${tempDir.path}/clinc_backup_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.clinc';
      await File(outputPath).writeAsBytes(outputBytes);

      // Clean up temp files
      await File(tempZipPath).delete();
      await backupDir.delete(recursive: true);

      return outputPath;
    } catch (e) {
      print('Export failed: $e');
      return null;
    }
  }

  /// Import data from a backup file.
  /// [zipFilePath] is the path to the .clinc (encrypted) or .zip (legacy) file.
  /// [password] is required for .clinc files to derive the decryption key.
  Future<bool> importData(
      {required String zipFilePath, String? password}) async {
    try {
      final file = File(zipFilePath);
      List<int> zipBytes;

      if (isBackupEncrypted(zipFilePath)) {
        // --- Encrypted .clinc backup ---
        if (password == null || password.isEmpty) {
          throw WrongPasswordException();
        }

        final fileBytes = await file.readAsBytes();
        if (fileBytes.length < 48) {
          throw Exception('Invalid backup file');
        }

        // Parse: [16 IV] + [32 HMAC] + [ciphertext]
        final iv = enc.IV(Uint8List.fromList(fileBytes.sublist(0, 16)));
        final storedHmac = fileBytes.sublist(16, 48);
        final cipherBytes = fileBytes.sublist(48);

        // Derive key from the provided password
        final keyBytes = EncryptionService.deriveKeyBytes(password);

        // Verify password via HMAC
        final hmac = crypto.Hmac(crypto.sha256, keyBytes);
        final computedHmac = hmac.convert(utf8.encode('clinc-backup-verify'));
        if (!_constantTimeEquals(computedHmac.bytes, storedHmac)) {
          throw WrongPasswordException();
        }

        // Decrypt to get original ZIP bytes
        final key = enc.Key(Uint8List.fromList(keyBytes));
        final encrypter = enc.Encrypter(
            enc.AES(key, mode: enc.AESMode.cbc, padding: 'PKCS7'));
        zipBytes = encrypter.decryptBytes(
            enc.Encrypted(Uint8List.fromList(cipherBytes)),
            iv: iv);
      } else {
        // --- Legacy plain .zip backup ---
        zipBytes = await file.readAsBytes();
      }

      final tempDir = await getTemporaryDirectory();
      final importDir = Directory('${tempDir.path}/import');
      if (await importDir.exists()) {
        await importDir.delete(recursive: true);
      }
      await importDir.create();

      final archive = ZipDecoder().decodeBytes(zipBytes);
      for (final archiveFile in archive) {
        final filename = archiveFile.name;
        final path = '${importDir.path}/$filename';
        if (archiveFile.isFile) {
          final data = archiveFile.content as List<int>;
          File(path)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(path).create(recursive: true);
        }
      }

      final jsonFile = File('${importDir.path}/backup/backup.json');
      if (!await jsonFile.exists()) {
        throw Exception("backup.json not found in archive");
      }
      final jsonData = await jsonFile.readAsString();
      final allData = json.decode(jsonData) as Map<String, dynamic>;

      await _databaseService.clearDatabase();

      final db = await _databaseService.database;
      final tables = [
        'Patients',
        'Treatments',
        'Appointments',
        'Invoices',
        'Invoice_Treatments',
        'Payments',
        'Expenses'
      ];

      final imagesDir = Directory('${importDir.path}/backup/images');
      final appDocsDir = await getApplicationDocumentsDirectory();
      final newImagesDir = Directory('${appDocsDir.path}/xray_images');
      if (!await newImagesDir.exists()) {
        await newImagesDir.create(recursive: true);
      }

      List<Map<String, dynamic>> patients =
          List<Map<String, dynamic>>.from(allData['Patients'] ?? []);
      for (var i = 0; i < patients.length; i++) {
        var patient = patients[i];
        final oldImagePath = patient['xray_image'];
        if (oldImagePath != null && oldImagePath.isNotEmpty) {
          final imageName = basename(oldImagePath);
          final oldImageFile = File('${imagesDir.path}/$imageName');
          if (await oldImageFile.exists()) {
            final newImagePath = '${newImagesDir.path}/$imageName';
            await oldImageFile.copy(newImagePath);
            patients[i]['xray_image'] = newImagePath;
          }
        }
      }
      allData['Patients'] = patients;

      await db.execute('PRAGMA foreign_keys = OFF');
      final batch = db.batch();

      for (var table in tables) {
        List<Map<String, dynamic>> tableData =
            List<Map<String, dynamic>>.from(allData[table] ?? []);
        for (var row in tableData) {
          batch.insert(table, row,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      await batch.commit(noResult: true);
      await db.execute('PRAGMA foreign_keys = ON');

      return true;
    } on WrongPasswordException {
      rethrow;
    } catch (e) {
      print('Import failed: $e');
      return false;
    }
  }

  /// Constant-time comparison to prevent timing attacks on HMAC.
  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

/// Thrown when the wrong password is provided for an encrypted backup.
class WrongPasswordException implements Exception {
  @override
  String toString() => 'Wrong password for encrypted backup';
}
