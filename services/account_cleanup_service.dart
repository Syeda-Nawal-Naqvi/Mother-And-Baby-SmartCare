import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AccountCleanupService {
  AccountCleanupService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const List<String> perUserSubcollections = [
    'babies',
    'mother_profile',
    'baby_medical_history',
    'baby_weight',
    'blood_pressure',
    'glucose',
    'medical_history',
    'milestones',
    'mother_weight',
    'allergies',
    'vaccinations',
    'reminders',
  ];

  static const int _batchLimit = 400;

  static Future<void> _deleteInChunks(
    List<DocumentReference> refs,
  ) async {
    for (var i = 0; i < refs.length; i += _batchLimit) {
      final chunk = refs.sublist(
        i,
        i + _batchLimit > refs.length ? refs.length : i + _batchLimit,
      );
      final batch = _db.batch();
      for (final ref in chunk) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  static Future<void> revokeAllSessions(String uid) async {
    try {
      final snap =
          await _db.collection('users').doc(uid).collection('sessions').get();
      if (snap.docs.isEmpty) return;
      await _deleteInChunks(snap.docs.map((d) => d.reference).toList());
    } catch (e) {
      debugPrint(
          'AccountCleanupService: failed revoking sessions for $uid: $e');
    }
  }

  static Future<void> wipeAllUserData(String uid) async {
    await revokeAllSessions(uid);

    for (final name in perUserSubcollections) {
      try {
        final snap =
            await _db.collection('users').doc(uid).collection(name).get();
        if (snap.docs.isEmpty) continue;
        await _deleteInChunks(snap.docs.map((d) => d.reference).toList());
      } catch (e) {
        debugPrint(
            'AccountCleanupService: failed clearing "$name" for $uid: $e');
      }
    }

    try {
      final notifSnap = await _db
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .get();
      if (notifSnap.docs.isNotEmpty) {
        await _deleteInChunks(notifSnap.docs.map((d) => d.reference).toList());
      }
    } catch (e) {
      debugPrint(
          'AccountCleanupService: failed clearing notifications for $uid: $e');
    }

    try {
      final senderNotifSnap = await _db
          .collection('notifications')
          .where('senderId', isEqualTo: uid)
          .get();
      if (senderNotifSnap.docs.isNotEmpty) {
        await _deleteInChunks(
            senderNotifSnap.docs.map((d) => d.reference).toList());
      }
    } catch (e) {
      debugPrint('AccountCleanupService: failed clearing sender-attributed '
          'notifications for $uid: $e');
    }

    try {
      final feedbackSnap = await _db
          .collection('feedback')
          .where('userId', isEqualTo: uid)
          .get();
      if (feedbackSnap.docs.isNotEmpty) {
        await _deleteInChunks(
            feedbackSnap.docs.map((d) => d.reference).toList());
      }
    } catch (e) {
      debugPrint(
          'AccountCleanupService: failed clearing feedback for $uid: $e');
    }

    try {
      await _db.collection('users').doc(uid).delete();
    } catch (e) {
      debugPrint('AccountCleanupService: failed deleting users/$uid doc: $e');
      rethrow;
    }
  }

  static Future<int> cleanupOrphans() async {
    final usersSnap = await _db.collection('users').get();
    final validUids = usersSnap.docs.map((d) => d.id).toSet();

    int deleted = 0;

    for (final name in perUserSubcollections) {
      try {
        final snap = await _db.collectionGroup(name).get();
        final orphanRefs = snap.docs
            .where((d) {
              final parentUid = d.reference.parent.parent?.id;
              return parentUid == null || !validUids.contains(parentUid);
            })
            .map((d) => d.reference)
            .toList();
        if (orphanRefs.isNotEmpty) {
          await _deleteInChunks(orphanRefs);
          deleted += orphanRefs.length;
        }
      } catch (e) {
        debugPrint('AccountCleanupService: orphan sweep failed for '
            '"$name": $e');
      }
    }

    try {
      final notifSnap = await _db.collection('notifications').get();
      final orphanRefs = notifSnap.docs
          .where((d) {
            final data = d.data();
            final recipientId = data['recipientId'] as String?;
            final senderId = data['senderId'] as String?;
            final recipientOrphaned =
                recipientId != null && !validUids.contains(recipientId);
            final senderOrphaned =
                senderId != null && !validUids.contains(senderId);
            return recipientOrphaned || senderOrphaned;
          })
          .map((d) => d.reference)
          .toList();
      if (orphanRefs.isNotEmpty) {
        await _deleteInChunks(orphanRefs);
        deleted += orphanRefs.length;
      }
    } catch (e) {
      debugPrint('AccountCleanupService: orphan sweep failed for '
          'notifications: $e');
    }

    try {
      final feedbackSnap = await _db.collection('feedback').get();
      final orphanRefs = feedbackSnap.docs
          .where((d) {
            final userId = d.data()['userId'] as String?;
            return userId != null && !validUids.contains(userId);
          })
          .map((d) => d.reference)
          .toList();
      if (orphanRefs.isNotEmpty) {
        await _deleteInChunks(orphanRefs);
        deleted += orphanRefs.length;
      }
    } catch (e) {
      debugPrint('AccountCleanupService: orphan sweep failed for feedback: $e');
    }

    try {
      final adminUidsSnap = await _db.collection('admin_uids').get();
      final orphanRefs = adminUidsSnap.docs
          .where((d) => !validUids.contains(d.id))
          .map((d) => d.reference)
          .toList();
      if (orphanRefs.isNotEmpty) {
        await _deleteInChunks(orphanRefs);
        deleted += orphanRefs.length;
      }
    } catch (e) {
      debugPrint(
          'AccountCleanupService: orphan sweep failed for admin_uids: $e');
    }

    return deleted;
  }
}
