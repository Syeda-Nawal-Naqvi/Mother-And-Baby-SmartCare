import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

  static const String _shareSubDir = 'smartcare_reports';

  static const Duration _minFileAge = Duration(hours: 6);

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

    final file = await _writeUniqueTempPdf(pdfBytes, fileName);

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
      unawaited(_cleanupOldSharedFiles());
    }
  }

  static Future<ShareResult> sharePdf({
    required Uint8List pdfBytes,
    required String fileName,
    required String subject,
    required String bodyText,
    String? recipientHint,
  }) async {
    final file = await _writeUniqueTempPdf(pdfBytes, fileName);
    final text = recipientHint != null && recipientHint.isNotEmpty
        ? '$bodyText\n\n(Intended for: $recipientHint)'
        : bodyText;

    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path, mimeType: 'application/pdf', name: fileName)
          ],
          subject: subject,
          text: text,
        ),
      );
      return result;
    } catch (e) {
      throw Exception('Could not open the share sheet. $e');
    } finally {
      unawaited(_cleanupOldSharedFiles());
    }
  }

  static Future<Directory> _shareDir() async {
    Directory base;
    try {
      base = await getTemporaryDirectory();
    } on MissingPluginException {
      throw Exception(
        'PDF storage plugin not registered on this build. Run "flutter '
        'clean", "flutter pub get", then fully stop and re-run the app '
        '(not hot reload/hot restart) — new native plugins are only '
        'registered on a full app restart.',
      );
    } catch (_) {
      try {
        base = await getApplicationDocumentsDirectory();
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

    final dir = Directory('${base.path}/$_shareSubDir');
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } catch (e) {
      throw Exception('Could not prepare a folder for the PDF. $e');
    }
    return dir;
  }

  static Future<File> _writeUniqueTempPdf(
      Uint8List pdfBytes, String fileName) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final dir = await _shareDir();
        final stamp = DateTime.now().microsecondsSinceEpoch;
        final safeName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
        final uniqueName = '${stamp}_$safeName';
        final file = File('${dir.path}/$uniqueName');

        await file.writeAsBytes(pdfBytes, flush: true);

        final writtenLength = await file.length();
        if (writtenLength != pdfBytes.length) {
          throw Exception(
              'PDF file was written incompletely ($writtenLength/${pdfBytes.length} bytes).');
        }

        return file;
      } catch (e) {
        lastError = e;
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }
    throw Exception('Could not prepare the PDF file. $lastError');
  }

  static Future<void> _cleanupOldSharedFiles() async {
    try {
      final dir = await _shareDir();
      if (!await dir.exists()) return;
      final now = DateTime.now();
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        try {
          final stat = await entity.stat();
          if (now.difference(stat.modified) >= _minFileAge) {
            await entity.delete();
          }
        } catch (_) {}
      }
    } catch (_) {}
  }
}
