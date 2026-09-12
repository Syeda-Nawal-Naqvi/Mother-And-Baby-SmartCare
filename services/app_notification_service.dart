import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class AppNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('notifications');

  CollectionReference<Map<String, dynamic>> get _adminUidsCol =>
      _firestore.collection('admin_uids');

  String? get _uid => _auth.currentUser?.uid;

  Future<bool> isNotificationsEnabled() async {
    final uid = _uid;
    if (uid == null) return true;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return (doc.data()?['notificationsEnabled'] as bool?) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .set({'notificationsEnabled': enabled}, SetOptions(merge: true));
  }

  static const int _maxReadNotifications = 20;
  static const int _maxUnreadNotifications = 30;

  Future<void> enforceRetention() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final snap = await _col.where('recipientId', isEqualTo: uid).get();
      if (snap.docs.isEmpty) return;

      DateTime resolve(dynamic value) =>
          value is Timestamp ? value.toDate() : DateTime.now();

      final docs = snap.docs.toList()
        ..sort((a, b) => resolve(b.data()['createdAt'])
            .compareTo(resolve(a.data()['createdAt'])));

      final unread = docs.where((d) => d.data()['read'] != true).toList();
      final read = docs.where((d) => d.data()['read'] == true).toList();

      final keepUnread = unread.length > _maxUnreadNotifications
          ? unread.sublist(0, _maxUnreadNotifications)
          : unread;
      final keepRead = read.length > _maxReadNotifications
          ? read.sublist(0, _maxReadNotifications)
          : read;

      final keepIds = <String>{
        ...keepUnread.map((d) => d.id),
        ...keepRead.map((d) => d.id),
      };
      final toDelete =
          docs.where((d) => !keepIds.contains(d.id)).map((d) => d.reference);

      if (toDelete.isEmpty) return;
      final batch = _firestore.batch();
      for (final ref in toDelete) {
        batch.delete(ref);
      }
      await batch.commit();
      debugPrint('AppNotificationService: retention cleanup applied');
    } catch (e) {
      debugPrint('AppNotificationService: enforceRetention error: $e');
    }
  }

  Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
    String? senderName,
  }) async {
    final data = <String, dynamic>{
      ...NotificationModel(
        recipientId: userId,
        title: title,
        body: body,
        type: type,
        relatedId: relatedId,
        senderName: senderName,
      ).toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    final online = !result.contains(ConnectivityResult.none);

    if (online) {
      try {
        await _col.add(data);
      } catch (e) {
        debugPrint('AppNotificationService: send failed: $e');
        await _queueOfflineNotification(data);
      }
    } else {
      await _queueOfflineNotification(data);
    }
  }

  Future<void> sendToAdmins({
    required String title,
    required String body,
    required String type,
    String? relatedId,
    String? senderName,
  }) async {
    QuerySnapshot<Map<String, dynamic>> adminSnap;
    try {
      adminSnap =
          await _adminUidsCol.get(const GetOptions(source: Source.server));
    } catch (e) {
      debugPrint(
          'AppNotificationService: server read of admin_uids failed ($e), falling back to cache');
      adminSnap = await _adminUidsCol.get();
    }

    if (adminSnap.docs.isEmpty) {
      throw StateError(
          'admin_uids directory is empty — no admin account has been '
          'registered as a notification recipient yet. Open the Admin '
          'Panel once on the admin account (it self-heals this on load), '
          'then try again.');
    }
    final batch = _firestore.batch();
    for (final doc in adminSnap.docs) {
      final ref = _col.doc();
      final data = <String, dynamic>{
        ...NotificationModel(
          recipientId: doc.id,
          title: title,
          body: body,
          type: type,
          relatedId: relatedId,
          senderName: senderName,
        ).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      batch.set(ref, data);
    }
    await batch.commit();
  }

  Future<void> _queueOfflineNotification(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('_pending_notifications').add({
        ...data,
        '_queuedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('AppNotificationService: failed to queue notification: $e');
    }
  }

  Future<void> flushPendingNotifications() async {
    try {
      final pendingSnap =
          await _firestore.collection('_pending_notifications').get();

      if (pendingSnap.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in pendingSnap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data.remove('_queuedAt');
        final newRef = _col.doc();
        batch.set(newRef, data);
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('AppNotificationService: flush error: $e');
    }
  }

  Future<int> sendToAllUsers({
    required String title,
    required String body,
    String? senderName,
  }) async {
    final usersSnap = await _firestore
        .collection('users')
        .where('blocked', isEqualTo: false)
        .get();

    if (usersSnap.docs.isEmpty) return 0;

    const chunkSize = 450;
    int sent = 0;
    for (var i = 0; i < usersSnap.docs.length; i += chunkSize) {
      final chunk = usersSnap.docs.skip(i).take(chunkSize);
      final batch = _firestore.batch();
      for (final userDoc in chunk) {
        final ref = _col.doc();
        batch.set(ref, {
          ...NotificationModel(
            recipientId: userDoc.id,
            title: title,
            body: body,
            type: 'admin_message',
            senderName: senderName ?? 'Admin',
          ).toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        sent++;
      }
      await batch.commit();
    }
    return sent;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMyNotifications() {
    if (_uid == null) return const Stream.empty();
    return _col.where('recipientId', isEqualTo: _uid).snapshots();
  }

  Stream<int> streamUnreadCount() {
    if (_uid == null) return Stream.value(0);
    return _col
        .where('recipientId', isEqualTo: _uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    await _col.doc(notificationId).update({'read': true});
  }

  Future<bool> hasUnreadNotifications() async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final snap = await _col
          .where('recipientId', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .limit(1)
          .get(const GetOptions(source: Source.server));
      return snap.docs.isNotEmpty;
    } catch (e) {
      debugPrint(
          'AppNotificationService: hasUnreadNotifications server read failed ($e), falling back to cache');
      try {
        final snap = await _col
            .where('recipientId', isEqualTo: uid)
            .where('read', isEqualTo: false)
            .limit(1)
            .get();
        return snap.docs.isNotEmpty;
      } catch (e2) {
        debugPrint(
            'AppNotificationService: hasUnreadNotifications failed: $e2');
        return false;
      }
    }
  }

  Future<void> markAllAsRead() async {
    if (_uid == null) return;
    final snap = await _col
        .where('recipientId', isEqualTo: _uid)
        .where('read', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _col.doc(notificationId).delete();
  }
}
