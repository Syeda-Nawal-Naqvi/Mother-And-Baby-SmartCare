import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path_provider/path_provider.dart';

import 'firebase_service.dart';

class NoInternetException implements Exception {
  final String message;
  NoInternetException([this.message = 'No internet connection']);
  @override
  String toString() => message;
}

class NoEmailAppException implements Exception {
  final String message;
  NoEmailAppException([
    this.message = 'No email app is set up on this device.',
  ]);
  @override
  String toString() => message;
}

class EmailShareService {
  EmailShareService._();

  static Future<void> sendReportEmail({
    required String recipientEmail,
    required String subject,
    required String bodyText,
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    if (!FirestoreService.isOnline.value) {
      throw NoInternetException();
    }

    final EmailCapabilities capabilities;
    try {
      capabilities = await FlutterEmailSender.getCapabilities();
    } on MissingPluginException {
      throw Exception(
        'Email plugin not registered on this build. Run "flutter clean", '
        '"flutter pub get", then fully stop and re-run the app '
        '(not hot reload/hot restart).',
      );
    }
    if (!capabilities.canSend) {
      throw NoEmailAppException();
    }

    final file = await _writeTempPdf(pdfBytes, fileName);

    final email = Email(
      recipients: [recipientEmail],
      subject: subject,
      body: bodyText,
      attachmentPaths: capabilities.supportsAttachments ? [file.path] : null,
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
    } on FlutterEmailSenderNotAvailableException {
      throw NoEmailAppException();
    } on FlutterEmailSenderUnsupportedFeatureException catch (e) {
      throw Exception(
          'Your mail app does not support: ${e.unsupportedFeatures.join(', ')}.');
    } on FlutterEmailSenderPlatformException catch (e) {
      throw Exception('Could not open the email app. ${e.message}');
    } catch (e) {
      throw Exception('Could not open the email app. $e');
    } finally {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  static Future<File> _writeTempPdf(Uint8List pdfBytes, String fileName) async {
    Directory dir;
    try {
      dir = await getTemporaryDirectory();
    } on MissingPluginException {
      throw Exception(
        'PDF storage plugin not registered on this build. Run "flutter '
        'clean", "flutter pub get", then fully stop and re-run the app '
        '(not hot reload/hot restart) — new native plugins are only '
        'registered on a full app restart.',
      );
    } catch (_) {
      try {
        dir = await getApplicationDocumentsDirectory();
      } on MissingPluginException {
        throw Exception(
          'PDF storage plugin not registered on this build. Run "flutter '
          'clean", "flutter pub get", then fully stop and re-run the app '
          '(not hot reload/hot restart).',
        );
      } catch (e) {
        throw Exception(
            'Could not access device storage to prepare the PDF. $e');
      }
    }

    try {
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes, flush: true);
      return file;
    } catch (e) {
      throw Exception('Could not prepare the PDF file. $e');
    }
  }
}
