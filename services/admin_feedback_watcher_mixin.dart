import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app_notification_service.dart';
import 'local_notification_service.dart';
import 'notification_sound_service.dart';

mixin AdminFeedbackWatcherMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _feedbackSub;
  bool _isFirstFeedbackSnapshot = true;

  void startWatchingFeedback() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _watchFrom(uid);
  }

  Future<void> _watchFrom(String uid) async {
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);

    Timestamp since = Timestamp.fromMillisecondsSinceEpoch(0);
    try {
      final userDoc = await userDocRef.get();
      final stored = userDoc.data()?['lastFeedbackSyncAt'];
      if (stored is Timestamp) since = stored;
    } catch (e) {
      debugPrint(
          'AdminFeedbackWatcherMixin: could not read lastFeedbackSyncAt: $e');
    }

    _feedbackSub = FirebaseFirestore.instance
        .collection('feedback')
        .where('createdAt', isGreaterThan: since)
        .orderBy('createdAt')
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isEmpty) return;

      final isBacklog = _isFirstFeedbackSnapshot;
      _isFirstFeedbackSnapshot = false;

      Timestamp? latest;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'];
        if (createdAt is Timestamp &&
            (latest == null || createdAt.compareTo(latest) > 0)) {
          latest = createdAt;
        }
        await _ensureNotification(
          adminUid: uid,
          feedbackId: doc.id,
          data: data,
          alert: !isBacklog,
        );
      }

      if (latest != null) {
        try {
          await userDocRef
              .set({'lastFeedbackSyncAt': latest}, SetOptions(merge: true));
        } catch (e) {
          debugPrint(
              'AdminFeedbackWatcherMixin: could not save lastFeedbackSyncAt: $e');
        }
      }
    }, onError: (e) {
      debugPrint('AdminFeedbackWatcherMixin: feedback watch error: $e');
    });
  }

  Future<void> _ensureNotification({
    required String adminUid,
    required String feedbackId,
    required Map<String, dynamic> data,
    required bool alert,
  }) async {
    final notifRef = FirebaseFirestore.instance
        .collection('notifications')
        .doc('fb_${feedbackId}_$adminUid');

    final message = (data['message'] ?? '').toString();
    final senderName =
        (data['userName'] ?? data['userEmail'] ?? 'A user').toString();

    final senderId = data['userId'] as String?;

    try {
      final existing = await notifRef.get();
      if (existing.exists) return;
      await notifRef.set({
        'recipientId': adminUid,
        'title': '📝 New feedback received',
        'body': message,
        'type': 'feedback_submitted',
        'relatedId': feedbackId,
        'senderName': senderName,
        if (senderId != null) 'senderId': senderId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
          'AdminFeedbackWatcherMixin: could not write notification for $feedbackId: $e');
      return;
    }

    if (alert) {
      await NotificationSoundService().playPopIfEnabled();
      if (await AppNotificationService().isNotificationsEnabled()) {
        await LocalNotificationService().show(
          title: '📝 New feedback received',
          body: message,
        );
      }
    }
  }

  void stopWatchingFeedback() {
    _feedbackSub?.cancel();
  }
}
