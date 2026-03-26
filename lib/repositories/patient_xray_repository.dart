import '../models/patient_xray.dart';
import '../services/database_service.dart';

class PatientXrayRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<int> insertPatientXray(PatientXray xray) async {
    final db = await _databaseService.database;
    return await db.insert('PatientXrayImages', xray.toMap());
  }

  Future<List<PatientXray>> getXraysForPatient(int patientId) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'PatientXrayImages',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => PatientXray.fromMap(m)).toList();
  }

  Future<void> deleteXraysForPatient(int patientId) async {
    final db = await _databaseService.database;
    await db.delete(
      'PatientXrayImages',
      where: 'patient_id = ?',
      whereArgs: [patientId],
    );
  }

  Future<void> deleteXray(int xrayId) async {
    final db = await _databaseService.database;
    await db.delete(
      'PatientXrayImages',
      where: 'xray_id = ?',
      whereArgs: [xrayId],
    );
  }
}
