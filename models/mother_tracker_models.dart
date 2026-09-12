import 'package:cloud_firestore/cloud_firestore.dart';

class MotherWeightModel {
  String? id;
  double weight;
  DateTime date;
  Timestamp? createdAt;

  MotherWeightModel({
    this.id,
    required this.weight,
    required this.date,
    this.createdAt,
  });

  factory MotherWeightModel.fromMap(Map<String, dynamic> map, String id) {
    return MotherWeightModel(
      id: id,
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      createdAt: map['createdAt'],
    );
  }

  factory MotherWeightModel.fromSnapshot(DocumentSnapshot doc) =>
      MotherWeightModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
        'weight': weight,
        'date': date.toIso8601String(),
      };
}

class BloodPressureModel {
  String? id;
  int systolic;
  int diastolic;
  Timestamp? createdAt;

  BloodPressureModel({
    this.id,
    required this.systolic,
    required this.diastolic,
    this.createdAt,
  });

  String get category {
    if (systolic >= 140 || diastolic >= 90) return 'High (Stage 2)';
    if (systolic >= 130 || diastolic >= 80) return 'High (Stage 1)';
    if (systolic >= 120) return 'Elevated';
    return 'Normal';
  }

  factory BloodPressureModel.fromMap(Map<String, dynamic> map, String id) {
    return BloodPressureModel(
      id: id,
      systolic: (map['systolic'] as num?)?.toInt() ?? 0,
      diastolic: (map['diastolic'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'],
    );
  }

  factory BloodPressureModel.fromSnapshot(DocumentSnapshot doc) =>
      BloodPressureModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
        'systolic': systolic,
        'diastolic': diastolic,
      };
}

class GlucoseModel {
  String? id;
  double glucoseLevel;
  Timestamp? createdAt;

  GlucoseModel({
    this.id,
    required this.glucoseLevel,
    this.createdAt,
  });

  factory GlucoseModel.fromMap(Map<String, dynamic> map, String id) {
    return GlucoseModel(
      id: id,
      glucoseLevel: (map['glucoseLevel'] as num?)?.toDouble() ?? 0,
      createdAt: map['createdAt'],
    );
  }

  factory GlucoseModel.fromSnapshot(DocumentSnapshot doc) =>
      GlucoseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {'glucoseLevel': glucoseLevel};
}

class MedicalHistoryModel {
  String? id;
  String diseaseName;
  String medicines;
  String doctorNotes;
  DateTime visitDate;
  Timestamp? createdAt;

  MedicalHistoryModel({
    this.id,
    required this.diseaseName,
    required this.medicines,
    required this.doctorNotes,
    required this.visitDate,
    this.createdAt,
  });

  factory MedicalHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return MedicalHistoryModel(
      id: id,
      diseaseName: map['diseaseName'] ?? '',
      medicines: map['medicines'] ?? '',
      doctorNotes: map['doctorNotes'] ?? '',
      visitDate: DateTime.tryParse(map['visitDate']?.toString() ?? '') ??
          DateTime.now(),
      createdAt: map['createdAt'],
    );
  }

  factory MedicalHistoryModel.fromSnapshot(DocumentSnapshot doc) =>
      MedicalHistoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
        'diseaseName': diseaseName,
        'medicines': medicines,
        'doctorNotes': doctorNotes,
        'visitDate': visitDate.toIso8601String(),
      };
}
