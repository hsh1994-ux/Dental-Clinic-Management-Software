class PatientXray {
  final int? xrayId;
  final int patientId;
  final String imagePath;
  final String createdAt;

  PatientXray({
    this.xrayId,
    required this.patientId,
    required this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (xrayId != null) 'xray_id': xrayId,
      'patient_id': patientId,
      'image_path': imagePath,
      'created_at': createdAt,
    };
  }

  factory PatientXray.fromMap(Map<String, dynamic> map) {
    return PatientXray(
      xrayId: map['xray_id'] as int?,
      patientId: map['patient_id'] as int,
      imagePath: map['image_path'] as String,
      createdAt: map['created_at'] as String,
    );
  }
}
