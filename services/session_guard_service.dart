import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'session_service.dart';
import 'app_notification_service.dart';
import 'local_notification_service.dart';
import '../main.dart';

class SessionGuardService {
  static final SessionGuardService _instance = SessionGuardService._internal();
  factory SessionGuardService() => _instance;
  SessionGuardService._internal();

  final AuthService _authService = AuthService();
  final SessionService _sessionService = SessionService();
  final AppNotificationService _notificationService = AppNotificationService();

  static const String _shownAlertsPrefsKey = 'shown_login_alert_ids';
  static const int _maxPersistedShownIds = 200;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<bool>? _revokeSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _alertSub;

  final Set<String> _shownAlertIds = {};
  bool _loadedPersistedShown = false;

  void start() {
    _authSub ??= FirebaseAuth.instance.authStateChanges().listen(
          _onAuthChanged,
        );
  }

  Future<void> _loadPersistedShownIds() async {
    if (_loadedPersistedShown) return;
    _loadedPersistedShown = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_shownAlertsPrefsKey) ?? const [];
      _shownAlertIds.addAll(saved);
    } catch (e) {
      debugPrint('SessionGuardService: loading persisted alert ids failed: $e');
    }
  }

  Future<void> _persistShownIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var list = _shownAlertIds.toList();
      if (list.length > _maxPersistedShownIds) {
        list = list.sublist(list.length - _maxPersistedShownIds);
      }
      await prefs.setStringList(_shownAlertsPrefsKey, list);
    } catch (e) {
      debugPrint('SessionGuardService: persisting alert ids failed: $e');
    }
  }

  Future<void> _onAuthChanged(User? user) async {
    await _revokeSub?.cancel();
    await _alertSub?.cancel();
    _revokeSub = null;
    _alertSub = null;

    if (user == null) return;

    final ctx = navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      unawaited(LocalNotificationService().checkAndRequestPermission(ctx));
    } else {
      debugPrint(
        'SessionGuardService: no navigator context yet, skipping permission check for this auth event',
      );
    }

    await _loadPersistedShownIds();

    final mySessionId = await _sessionService.getLocalSessionId();

    if (mySessionId != null) {
      _revokeSub = _sessionService
          .watchSessionRevoked(user.uid, mySessionId)
          .listen((revoked) async {
        if (!revoked) return;
        await _handleForcedLogout();
      });
    }

    _alertSub = _notificationService.streamMyNotifications().listen(
      (snap) {
        for (final doc in snap.docs) {
          final data = doc.data();
          if (data['type'] != 'new_login') continue;
          if (data['read'] == true) continue;

          final newDeviceSessionId = data['relatedId'] as String?;

          if (mySessionId != null && newDeviceSessionId == mySessionId) {
            continue;
          }

          if (_shownAlertIds.contains(doc.id)) continue;
          _shownAlertIds.add(doc.id);
          unawaited(_persistShownIds());

          LocalNotificationService().show(
            title: data['title'] ?? 'New login detected',
            body: data['body'] ??
                'Was this you? Tap "Yes, it was me" to confirm, or '
                    '"No, block it" to secure your account.',
            payload: jsonEncode({
              'type': 'new_login',
              'notificationId': doc.id,
              'sessionId': newDeviceSessionId,
            }),
            actions: const [
              AndroidNotificationAction(
                LocalNotificationService.actionConfirmLogin,
                'Yes, it was me',
                showsUserInterface: false,
              ),
              AndroidNotificationAction(
                LocalNotificationService.actionBlockLogin,
                "No, block it",
                showsUserInterface: false,
              ),
            ],
          );
        }
      },
      onError: (e) {
        debugPrint('SessionGuardService: alert stream error: $e');
      },
    );
  }

  Future<void> _handleForcedLogout() async {
    try {
      await _sessionService.clearLocalSessionId();
      await _authService.logout();
    } catch (e) {
      debugPrint('SessionGuardService: forced logout failed: $e');
    }
    final navState = navigatorKey.currentState;
    if (navState == null) return;
    navState.pushNamedAndRemoveUntil('/login', (route) => false);
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(
        content: Text(
          'You were signed out on this device for security reasons.',
        ),
      ),
    );
  }
}
