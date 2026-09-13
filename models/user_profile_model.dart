import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel {
  String uid;
  String name;
  String? email;
  String role;
  bool blocked;

  String? blockedBy;
  bool notificationsEnabled;
  bool accountVerified;
  String country;
  Timestamp? createdAt;

  UserProfileModel({
    required this.uid,
    required this.name,
    this.email,
    required this.role,
    this.blocked = false,
    this.blockedBy,
    this.notificationsEnabled = true,
    this.accountVerified = false,
    this.country = '',
    this.createdAt,
  });

  static String _normalizeRole(dynamic rawRole) {
    final role = (rawRole ?? 'mother').toString();
    if (role == 'father/husband') return 'father';
    return role;
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfileModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'],
      role: _normalizeRole(map['role']),
      blocked: map['blocked'] ?? false,
      blockedBy: map['blockedBy'] as String?,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      accountVerified: map['accountVerified'] ?? false,
      country: (map['country'] ?? '').toString(),
      createdAt: map['createdAt'],
    );
  }

  factory UserProfileModel.fromSnapshot(DocumentSnapshot doc) =>
      UserProfileModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role,
        'blocked': blocked,
        'blockedBy': blockedBy,
        'notificationsEnabled': notificationsEnabled,
        'accountVerified': accountVerified,
        'country': country,
      };
}
