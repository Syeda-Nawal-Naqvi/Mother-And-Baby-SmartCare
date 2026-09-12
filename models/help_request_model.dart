import 'package:cloud_firestore/cloud_firestore.dart';

class HelpRequestModel {
  String? id;
  String name;
  String email;
  String message;
  String status;
  Timestamp? createdAt;
  Timestamp? resolvedAt;

  HelpRequestModel({
    this.id,
    required this.name,
    required this.email,
    required this.message,
    this.status = 'pending',
    this.createdAt,
    this.resolvedAt,
  });

  factory HelpRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return HelpRequestModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'],
      resolvedAt: map['resolvedAt'],
    );
  }

  factory HelpRequestModel.fromSnapshot(DocumentSnapshot doc) =>
      HelpRequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'message': message,
        'status': status,
      };
}
