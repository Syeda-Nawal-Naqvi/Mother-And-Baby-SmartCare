import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'account_cleanup_service.dart';
import 'app_notification_service.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppNotificationService _notifications = AppNotificationService();

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _adminUidsCol =>
      _firestore.collection('admin_uids');

  static const String _babiesSubcollection = 'babies';
  static const String _motherProfileSubcollection = 'mother_profile';

  static const List<String> knownRoles = [
    'mother',
    'father',
    'caretaker',
    'admin',
  ];

  String? get currentUid => _auth.currentUser?.uid;

  static String normalizeRole(dynamic rawRole) {
    final role = (rawRole ?? 'mother').toString();
    if (role == 'father/husband') return 'father';
    return role;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _freshGet(
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      return await query.get(const GetOptions(source: Source.server));
    } catch (_) {
      return await query.get(const GetOptions(source: Source.cache));
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllUsers() {
    return _usersCol.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamUsersByRole(String role) {
    return _usersCol.where('role', isEqualTo: role).snapshots();
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _orphanSafeCollectionGroupStream(String subcollection) {
    return _firestore
        .collectionGroup(subcollection)
        .snapshots()
        .asyncMap((snap) async {
      if (snap.docs.isEmpty) {
        return <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      }
      Set<String> validUids;
      try {
        final usersSnap =
            await _usersCol.get(const GetOptions(source: Source.server));
        validUids = usersSnap.docs.map((d) => d.id).toSet();
      } catch (_) {
        return snap.docs;
      }
      return snap.docs.where((d) {
        final parentUid = d.reference.parent.parent?.id;
        return parentUid != null && validUids.contains(parentUid);
      }).toList();
    });
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      streamAllMothers() =>
          _orphanSafeCollectionGroupStream(_motherProfileSubcollection);

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamAllBabies() =>
      _orphanSafeCollectionGroupStream(_babiesSubcollection);

  Future<void> deleteMotherProfile(DocumentReference ref) async {
    await ref.delete();
  }

  Future<void> deleteBabyProfile(DocumentReference ref) async {
    await ref.delete();
  }

  final ValueNotifier<Map<String, int>> liveAnalytics =
      ValueNotifier<Map<String, int>>({
    'totalUsers': 0,
    'admins': 0,
    'mothers': 0,
    'fathers': 0,
    'caretakers': 0,
    'blockedUsers': 0,
    'activeUsers': 0,
    'totalFeedback': 0,
    'pendingFeedback': 0,
    'totalMothers': 0,
    'totalBabies': 0,
    'unreadAdminNotifications': 0,
  });

  StreamSubscription? _usersSub;
  StreamSubscription? _feedbackSub;
  StreamSubscription? _mothersSub;
  StreamSubscription? _babiesSub;
  StreamSubscription? _adminNotifsSub;
  bool _analyticsStarted = false;
  Timer? _analyticsDebounce;

  void startLiveAnalytics() {
    if (_analyticsStarted) return;
    _analyticsStarted = true;

    void refresh() {
      _analyticsDebounce?.cancel();
      _analyticsDebounce = Timer(const Duration(milliseconds: 300), () {
        _computeLiveAnalytics();
      });
    }

    _usersSub = _usersCol.snapshots().listen((_) => refresh());
    _feedbackSub =
        _firestore.collection('feedback').snapshots().listen((_) => refresh());
    _mothersSub = _firestore
        .collectionGroup(_motherProfileSubcollection)
        .snapshots()
        .listen((_) => refresh());
    _babiesSub = _firestore
        .collectionGroup(_babiesSubcollection)
        .snapshots()
        .listen((_) => refresh());
    final myUid = currentUid;
    if (myUid != null) {
      _adminNotifsSub = _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: myUid)
          .where('read', isEqualTo: false)
          .snapshots()
          .listen((_) => refresh());
    }

    _computeLiveAnalytics();
  }

  void stopLiveAnalytics() {
    _usersSub?.cancel();
    _feedbackSub?.cancel();
    _mothersSub?.cancel();
    _babiesSub?.cancel();
    _adminNotifsSub?.cancel();
    _analyticsDebounce?.cancel();
    _analyticsStarted = false;
  }

  Map<String, int> _tally(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> userDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> feedbackDocs,
    int mothersProfileCount,
    int babiesCount,
    int adminNotifCount,
  ) {
    int totalUsers = 0;
    int admins = 0;
    int mothers = 0;
    int fathers = 0;
    int caretakers = 0;
    int blocked = 0;

    for (final doc in userDocs) {
      final data = doc.data();
      totalUsers++;
      final role = normalizeRole(data['role']);
      switch (role) {
        case 'admin':
          admins++;
          break;
        case 'father':
          fathers++;
          break;
        case 'caretaker':
          caretakers++;
          break;
        default:
          mothers++;
      }
      if (data['blocked'] == true) blocked++;
    }

    int pendingFeedback = 0;
    for (final doc in feedbackDocs) {
      if (doc.data()['status'] == 'pending') pendingFeedback++;
    }

    return {
      'totalUsers': totalUsers,
      'admins': admins,
      'mothers': mothers,
      'fathers': fathers,
      'caretakers': caretakers,
      'blockedUsers': blocked,
      'activeUsers': totalUsers - blocked,
      'totalFeedback': feedbackDocs.length,
      'pendingFeedback': pendingFeedback,
      'totalMothers': mothersProfileCount,
      'totalBabies': babiesCount,
      'unreadAdminNotifications': adminNotifCount,
    };
  }

  int _orphanSafeCount(
    QuerySnapshot<Map<String, dynamic>> snap,
    Set<String> validUids,
  ) {
    return snap.docs.where((d) {
      final parentUid = d.reference.parent.parent?.id;
      return parentUid != null && validUids.contains(parentUid);
    }).length;
  }

  Future<void> _computeLiveAnalytics() async {
    try {
      final usersSnap = await _freshGet(_usersCol);
      final validUids = usersSnap.docs.map((d) => d.id).toSet();
      final feedbackSnap = await _freshGet(_firestore.collection('feedback'));
      final mothersSnap = await _freshGet(
          _firestore.collectionGroup(_motherProfileSubcollection));
      final babiesSnap =
          await _freshGet(_firestore.collectionGroup(_babiesSubcollection));
      final myUid = currentUid;
      final adminNotifsSnap = myUid == null
          ? null
          : await _freshGet(_firestore
              .collection('notifications')
              .where('recipientId', isEqualTo: myUid)
              .where('read', isEqualTo: false));

      liveAnalytics.value = _tally(
        usersSnap.docs,
        feedbackSnap.docs,
        _orphanSafeCount(mothersSnap, validUids),
        _orphanSafeCount(babiesSnap, validUids),
        adminNotifsSnap?.docs.length ?? 0,
      );
    } catch (e) {
      debugPrint('AdminService: live analytics error: $e');
    }
  }

  Future<Map<String, int>> getAnalytics() async {
    final usersSnap = await _freshGet(_usersCol);
    final validUids = usersSnap.docs.map((d) => d.id).toSet();
    final feedbackSnap = await _freshGet(_firestore.collection('feedback'));
    final mothersSnap = await _freshGet(
        _firestore.collectionGroup(_motherProfileSubcollection));
    final babiesSnap =
        await _freshGet(_firestore.collectionGroup(_babiesSubcollection));

    return _tally(
      usersSnap.docs,
      feedbackSnap.docs,
      _orphanSafeCount(mothersSnap, validUids),
      _orphanSafeCount(babiesSnap, validUids),
      0,
    );
  }

  void _assertNotSelf(String uid, String action) {
    if (uid == currentUid) {
      throw StateError('You cannot $action your own admin account.');
    }
  }

  Future<void> setUserBlocked(String uid, bool blocked) async {
    if (blocked) _assertNotSelf(uid, 'block');
    await _usersCol.doc(uid).update({'blocked': blocked});
    if (blocked) {
      await AccountCleanupService.revokeAllSessions(uid);
    }
  }

  Future<void> ensureAdminDirectoryEntry() async {
    final uid = currentUid;
    if (uid == null) return;
    try {
      await _adminUidsCol.doc(uid).set(
          {'addedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('AdminService: ensureAdminDirectoryEntry failed: $e');
    }
  }

  Future<void> promoteToAdmin(String uid) async {
    await _usersCol.doc(uid).update({'role': 'admin'});
    await _adminUidsCol.doc(uid).set(
        {'addedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    await _notifications.sendToUser(
      userId: uid,
      title: '🎉 You are now an admin',
      body: 'An administrator has granted you admin access.',
      type: 'admin_message',
      senderName: 'System',
    );
  }

  Future<void> deleteUserAccount(String uid) async {
    _assertNotSelf(uid, 'remove');
    await _usersCol.doc(uid).update({'blocked': true});
    try {
      await _adminUidsCol.doc(uid).delete();
    } catch (_) {}
    await AccountCleanupService.wipeAllUserData(uid);
  }

  Future<int> cleanupOrphans() => AccountCleanupService.cleanupOrphans();

  Future<bool> hasAnotherActiveAdmin(String excludeUid) async {
    final snap = await _usersCol
        .where('role', isEqualTo: 'admin')
        .where('blocked', isEqualTo: false)
        .get();
    return snap.docs.any((doc) => doc.id != excludeUid);
  }

  Future<String> getUserRole(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists) return 'mother';
    return normalizeRole(doc.data()?['role']);
  }
}
