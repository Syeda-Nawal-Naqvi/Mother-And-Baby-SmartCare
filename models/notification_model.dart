import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  String? id;
  String recipientId;
  String title;
  String body;
  String type;
  String? relatedId;
  String? senderName;
  String? senderId;

  bool read;
  Timestamp? createdAt;

  NotificationModel({
    this.id,
    required this.recipientId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.senderName,
    this.senderId,
    this.read = false,
    this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      recipientId: map['recipientId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? '',
      relatedId: map['relatedId'],
      senderName: map['senderName'],
      senderId: map['senderId'],
      read: map['read'] ?? false,
      createdAt: map['createdAt'],
    );
  }

  factory NotificationModel.fromSnapshot(DocumentSnapshot doc) =>
      NotificationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'recipientId': recipientId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'read': read,
    };
    if (senderName != null) map['senderName'] = senderName;
    if (senderId != null) map['senderId'] = senderId;
    return map;
  }
}
