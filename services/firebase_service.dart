import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Set<String> _autoCleanCollections = {
    'mother_weight',
    'glucose',
    'blood_pressure',
    'baby_weight',
  };
  static const int _keepCount = 30;
  static const int _keepDays = 30;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
  static StreamSubscription<List<ConnectivityResult>>? _connSub;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      _db.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      debugPrint(
          'FirestoreService: skipping settings (already initialized): $e');
    }

    final connectivity = Connectivity();
    final initial = await connectivity.checkConnectivity();
    isOnline.value = !initial.contains(ConnectivityResult.none);

    _connSub = connectivity.onConnectivityChanged.listen((results) {
      isOnline.value = !results.contains(ConnectivityResult.none);
    });
  }

  static void dispose() => _connSub?.cancel();

  static CollectionReference<Map<String, dynamic>> collection(String name) {
    final uid = _uid;
    if (uid == null) {
      throw StateError('No authenticated user — cannot access "$name"');
    }
    return _db.collection('users').doc(uid).collection(name);
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> stream(
    String name, {
    String orderBy = 'createdAt',
    bool descending = true,
  }) {
    return collection(name)
        .orderBy(orderBy, descending: descending)
        .snapshots(includeMetadataChanges: true);
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamByBaby(
    String name,
    String babyId,
  ) {
    return collection(name)
        .where('babyId', isEqualTo: babyId)
        .snapshots(includeMetadataChanges: true);
  }

  static List<QueryDocumentSnapshot<Map<String, dynamic>>> sortByField(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String field,
    bool descending,
  ) {
    DateTime resolve(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    final sorted = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);
    sorted.sort((a, b) {
      final da = resolve(a.data()[field]);
      final db_ = resolve(b.data()[field]);
      return descending ? db_.compareTo(da) : da.compareTo(db_);
    });
    return sorted;
  }

  static Future<DocumentReference<Map<String, dynamic>>> add(
    String name,
    Map<String, dynamic> data,
  ) async {
    final ref = await collection(name).add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (_autoCleanCollections.contains(name)) {
      unawaited(_autoClean(name));
    }

    return ref;
  }

  static Future<void> _autoClean(String name) async {
    try {
      final snap =
          await collection(name).orderBy('createdAt', descending: true).get();
      if (snap.docs.length <= _keepCount) return;

      final cutoff = DateTime.now().subtract(const Duration(days: _keepDays));

      final groups =
          <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
      for (final doc in snap.docs) {
        final key = (doc.data()['babyId'] ?? '').toString();
        groups.putIfAbsent(key, () => []).add(doc);
      }

      final toDelete = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final docs in groups.values) {
        if (docs.length <= _keepCount) continue;
        for (final doc in docs.sublist(_keepCount)) {
          final created = doc.data()['createdAt'];
          if (created is Timestamp && created.toDate().isBefore(cutoff)) {
            toDelete.add(doc);
          }
        }
      }

      if (toDelete.isEmpty) return;

      final batch = _db.batch();
      for (final doc in toDelete) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('FirestoreService: auto clean skipped for '
          '"$name" (will retry on next add): $e');
    }
  }

  static Future<void> update(
      String name, String docId, Map<String, dynamic> data) {
    return collection(name).doc(docId).update(data);
  }

  static Future<void> delete(String name, String docId) {
    return collection(name).doc(docId).delete();
  }

  static bool isPendingWrite(DocumentSnapshot doc) =>
      doc.metadata.hasPendingWrites;
}
