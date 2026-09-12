import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  String? id;
  String userId;
  String? userEmail;
  String? userName;
  String message;
  String status;
  String? adminReply;
  Timestamp? createdAt;
  Timestamp? repliedAt;

  FeedbackModel({
    this.id,
    required this.userId,
    this.userEmail,
    this.userName,
    required this.message,
    this.status = 'pending',
    this.adminReply,
    this.createdAt,
    this.repliedAt,
  });

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'],
      userName: map['userName'],
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',
      adminReply: map['adminReply'],
      createdAt: map['createdAt'],
      repliedAt: map['repliedAt'],
    );
  }

  factory FeedbackModel.fromSnapshot(DocumentSnapshot doc) =>
      FeedbackModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'message': message,
        'status': status,
        'adminReply': adminReply,
      };
}
