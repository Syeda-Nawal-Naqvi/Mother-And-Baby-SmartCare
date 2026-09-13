import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_email_sender/flutter_email_sender.dart';

import '../models/help_request_model.dart';

class NoEmailAppException implements Exception {
  final String message;
  NoEmailAppException([
    this.message = 'No email app is set up on this device.',
  ]);
  @override
  String toString() => message;
}

class HelpRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('help_requests');

  Future<String?> submitHelpRequest({
    required String name,
    required String email,
    required String message,
  }) async {
    try {
      await _col.add({
        ...HelpRequestModel(
          name: name.trim(),
          email: email.trim(),
          message: message.trim(),
        ).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'resolvedAt': null,
      });
      return null;
    } catch (e) {
      return 'Could not send your request. Please check your internet '
          'connection and try again.';
    }
  }

  Stream<List<QueryDocumentSnapshot>> streamAll() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs);
  }

  Stream<List<QueryDocumentSnapshot>> streamPending() {
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

  Future<void> markResolved(String id) async {
    await _col.doc(id).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteHelpRequest(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> replyViaEmail({
    required String requestId,
    required String recipientEmail,
    required String recipientName,
  }) async {
    final EmailCapabilities capabilities;
    try {
      capabilities = await FlutterEmailSender.getCapabilities();
    } on MissingPluginException {
      throw Exception(
        'Email plugin not registered on this build. Run "flutter clean", '
        '"flutter pub get", then fully stop and re-run the app.',
      );
    }
    if (!capabilities.canSend) {
      throw NoEmailAppException();
    }

    final email = Email(
      recipients: [recipientEmail],
      subject: 'Re: Your help request — Mother & Baby SmartCare',
      body: 'Hi $recipientName,\n\n'
          'Thanks for reaching out to Mother & Baby SmartCare support.\n\n'
          '\n\n'
          '— Mother & Baby SmartCare Team',
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
    } on FlutterEmailSenderNotAvailableException {
      throw NoEmailAppException();
    } on FlutterEmailSenderPlatformException catch (e) {
      throw Exception('Could not open the email app. ${e.message}');
    } catch (e) {
      throw Exception('Could not open the email app. $e');
    }

    await markResolved(requestId);
  }
}
