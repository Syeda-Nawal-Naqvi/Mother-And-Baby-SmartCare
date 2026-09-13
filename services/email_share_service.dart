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

/// Handles getting the generated PDF report out of the app and into the
/// user's hands (Gmail, WhatsApp, Drive, or the device's mail composer).
///
/// ── Why reports used to fail to attach / "send" but never arrive ──────
/// The old implementation wrote the PDF to a temp file, handed the path
/// to the OS (via share_plus or flutter_email_sender), and then deleted
/// that file *immediately* in a `finally` block as soon as our function
/// call returned. Handing the path to `share()` / the email intent does
/// NOT mean the receiving app (Gmail, WhatsApp, the mail composer, ...)
/// has finished *reading* the file yet:
///   • Gmail/WhatsApp/Drive open the OS share sheet, then read the file
///     off disk and upload it to their own servers in the background —
///     on a slow or unstable connection that upload can take anywhere
///     from a few seconds to a couple of minutes.
///   • The previous fix only kept files alive for 2 minutes before
///     sweeping them, which is exactly why the symptom was
///     *inconsistent*: on fast Wi‑Fi it worked, on a weak mobile signal
///     the attachment got deleted mid‑upload, so the message either
///     failed to send, or "sent" with a broken/empty attachment that
///     never actually downloads on the other end.
///
/// The fix below:
///   1. Every PDF is written with a unique, timestamped file name inside
///      its own subfolder, so two shares fired back-to-back never
///      collide or race each other.
///   2. Right after writing, we read the file back and check its length
///      against the original bytes — if the write was somehow
///      incomplete (e.g. low disk space), we retry once instead of
///      silently handing a corrupt/partial file to the OS.
///   3. We never delete a file synchronously right after handing it off.
///      Stale files are only swept up on the *next* share/send call,
///      and only once they are guaranteed to be well past the point any
///      receiving app could still be reading/uploading them.
class EmailShareService {
  EmailShareService._();

  static const String _shareSubDir = 'smartcare_reports';

  // Deliberately generous: this only controls how long an already-shared
  // PDF is allowed to linger in our own cache subfolder before we sweep
  // it away, not how long the user waits for anything. Keeping it long
  // is what protects slow uploads (weak signal, large PDFs) from having
  // their attachment yanked out from under them mid-transfer.
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
      // Intentionally NOT deleting `file` here — the mail composer keeps
      // reading the attachment off disk (and, for Gmail etc., uploading
      // it) well after control returns to us.
      unawaited(_cleanupOldSharedFiles());
    }
  }

  /// Shares a PDF using the device's native share sheet (share_plus).
  ///
  /// This is the recommended, more reliable way to get the report into
  /// Gmail/WhatsApp/Drive/etc. It hands the file to the OS as a proper
  /// content URI, so it does not suffer from the "attachment missing" /
  /// "opens but Gmail never gets it" issues that direct email-intent
  /// plugins (like flutter_email_sender) can run into on some devices.
  ///
  /// Note: the native share sheet cannot pre-fill the recipient's "To"
  /// field for every app the user might pick (that's an OS-level
  /// limitation, not a bug), so [recipientHint] is folded into the shared
  /// text instead — the user just types/picks the recipient once inside
  /// whichever app they choose.
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
      // Same reasoning as sendReportEmail: never delete right after
      // share() returns — the app the user picked (Gmail, WhatsApp,
      // Drive, ...) may still be reading/uploading the file for a while
      // after the share sheet closes. Stale files get swept on the next
      // call, once they're old enough that this can no longer be true.
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

  /// Writes the PDF under a unique, timestamped file name so that two
  /// reports generated back-to-back (e.g. sharing a mother report right
  /// after a baby report, or double-tapping the share button) never
  /// collide or get deleted out from under each other.
  ///
  /// After writing, the file is read back and its size is compared
  /// against [pdfBytes] — if they don't match (e.g. the device ran low
  /// on storage mid-write), the write is retried once before giving up.
  /// This is what used to cause the "sometimes it shares an empty/broken
  /// PDF that won't open on the other end" symptom.
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
        // Brief pause before retrying, in case the failure was a
        // transient storage hiccup.
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }
    throw Exception('Could not prepare the PDF file. $lastError');
  }

  /// Best-effort cleanup: removes previously shared/emailed PDFs once
  /// they're older than [_minFileAge], instead of deleting the file we
  /// just handed off the instant the share/send call returns. Only ever
  /// touches files inside our own [_shareSubDir], so it can never affect
  /// anything else on the device.
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
        } catch (_) {
          // Ignore individual file errors — best-effort cleanup only.
        }
      }
    } catch (_) {
      // Cleanup must never break the actual share/send flow.
    }
  }
}
