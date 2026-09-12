import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_notification_service.dart';
import '../models/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppNotificationService _notifications = AppNotificationService();

  CollectionReference get _col => _firestore.collection('feedback');

  Future<String?> submitFeedback(String message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';

      String? userName;
      try {
        final profileDoc =
            await _firestore.collection('users').doc(user.uid).get();
        userName = (profileDoc.data()?['name'] as String?)?.trim();
        if (userName == null || userName.isEmpty) userName = null;
      } catch (_) {}
      userName ??= user.displayName;

      await _col.add({
        ...FeedbackModel(
          userId: user.uid,
          userEmail: user.email,
          userName: userName,
          message: message.trim(),
        ).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'repliedAt': null,
      });

      return null;
    } catch (e) {
      return 'Failed to send feedback. Please try again.';
    }
  }

  Stream<QuerySnapshot> getMyFeedback() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _col
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<List<QueryDocumentSnapshot>> getAllFeedback() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs);
  }

  Stream<List<QueryDocumentSnapshot>> getPendingFeedback() {
    return _col.where('status', isEqualTo: 'pending').snapshots().map((snap) {
      DateTime resolve(dynamic value) =>
          value is Timestamp ? value.toDate() : DateTime.now();
      final docs = snap.docs.toList()
        ..sort((a, b) =>
            resolve((b.data() as Map<String, dynamic>)['createdAt']).compareTo(
                resolve((a.data() as Map<String, dynamic>)['createdAt'])));
      return docs;
    });
  }

  Future<String?> replyToFeedback({
    required String feedbackId,
    required String userId,
    required String originalMessage,
    required String reply,
  }) async {
    try {
      await _col.doc(feedbackId).update({
        'status': 'replied',
        'adminReply': reply.trim(),
        'repliedAt': FieldValue.serverTimestamp(),
      });
      await _notifications.sendToUser(
        userId: userId,
        title: '💬 Admin replied to your feedback',
        body: reply.trim(),
        type: 'feedback_reply',
        relatedId: feedbackId,
        senderName: 'Admin',
      );
      return null;
    } catch (e) {
      return 'Failed to send reply. Please try again.';
    }
  }

  Future<void> deleteFeedback(String feedbackId) async {
    await _col.doc(feedbackId).delete();
  }
}
