import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryRecord {
  String label;
  String date;

  DeliveryRecord({required this.label, required this.date});

  factory DeliveryRecord.fromMap(Map<String, dynamic> map) {
    return DeliveryRecord(
      label: map['label'] ?? '',
      date: map['date'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'label': label, 'date': date};
}

class MotherProfileModel {
  String? id;
  String name;
  DateTime dob;
  String bloodGroup;
  List<DeliveryRecord> deliveries;
  Timestamp? createdAt;
  Timestamp? updatedAt;

  MotherProfileModel({
    this.id,
    required this.name,
    required this.dob,
    required this.bloodGroup,
    List<DeliveryRecord>? deliveries,
    this.createdAt,
    this.updatedAt,
  }) : deliveries = deliveries ?? [];

  int get age {
    final now = DateTime.now();
    int years = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years -= 1;
    }
    return years < 0 ? 0 : years;
  }

  factory MotherProfileModel.fromMap(Map<String, dynamic> map, String id) {
    final rawList = map['deliveries'] as List<dynamic>? ?? [];
    final list = rawList
        .map((e) => DeliveryRecord.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    DateTime dob;
    final rawDob = map['dob']?.toString();
    if (rawDob != null && rawDob.isNotEmpty) {
      dob = DateTime.tryParse(rawDob) ?? DateTime.now();
    } else {
      final legacyAge = map['age'] is int ? map['age'] as int : 0;
      final now = DateTime.now();
      dob = DateTime(now.year - legacyAge, now.month, now.day);
    }

    return MotherProfileModel(
      id: id,
      name: map['name'] ?? '',
      dob: dob,
      bloodGroup: map['bloodGroup'] ?? '',
      deliveries: list,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  factory MotherProfileModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MotherProfileModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dob': dob.toIso8601String(),
      'bloodGroup': bloodGroup,
      'deliveries': deliveries.map((d) => d.toMap()).toList(),
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
