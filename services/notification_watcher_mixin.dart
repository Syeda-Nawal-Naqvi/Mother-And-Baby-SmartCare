import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'app_notification_service.dart';
import 'local_notification_service.dart';
import 'notification_sound_service.dart';

mixin NotificationWatcherMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notifSub;
  final Set<String> _seenIds = {};
  bool _isFirstSnapshot = true;

  void startWatchingNotifications() {
    final service = AppNotificationService();
    service.enforceRetention();

    _notifSub = service.streamMyNotifications().listen((snapshot) async {
      if (_isFirstSnapshot) {
        _isFirstSnapshot = false;
        var hasUnreadBacklog = false;
        for (final doc in snapshot.docs) {
          _seenIds.add(doc.id);
          if (doc.data()['read'] != true) hasUnreadBacklog = true;
        }
        if (hasUnreadBacklog) {
          NotificationSoundService().playPopIfEnabled();
        }
        return;
      }

      final newUnread = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        if (_seenIds.contains(doc.id)) continue;
        _seenIds.add(doc.id);
        final data = doc.data();
        if (data['read'] == true) continue;
        newUnread.add(data);
      }

      if (newUnread.isEmpty) return;

      final appPrefEnabled = await service.isNotificationsEnabled();
      final osPermissionGranted =
          await LocalNotificationService().isPermissionGranted();
      final canShowTray = appPrefEnabled && osPermissionGranted;

      if (!appPrefEnabled) {
        debugPrint(
            'NotificationWatcherMixin: OS tray notification skipped — app-level notificationsEnabled preference is off');
      } else if (!osPermissionGranted) {
        debugPrint(
            'NotificationWatcherMixin: OS tray notification skipped — OS runtime permission not granted (see SessionGuardService for the re-prompt flow)');
      }

      for (final data in newUnread) {
        await NotificationSoundService().playPopIfEnabled();
        if (canShowTray) {
          await LocalNotificationService().show(
            title: (data['title'] as String?) ?? 'New notification',
            body: (data['body'] as String?) ?? '',
          );
        }
      }

      service.enforceRetention();
    });
  }

  void stopWatchingNotifications() {
    _notifSub?.cancel();
  }
}
