import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'app_notification_service.dart';

class NotificationSoundService {
  static final NotificationSoundService _instance =
      NotificationSoundService._internal();
  factory NotificationSoundService() => _instance;
  NotificationSoundService._internal();

  static const String _assetPath = 'sounds/notification_pop.mp3';

  final AudioPlayer _player = AudioPlayer(playerId: 'notification_pop');
  final AppNotificationService _notificationService = AppNotificationService();

  bool _initialized = false;
  Future<void>? _initFuture;

  Future<bool> isSoundEnabled() =>
      _notificationService.isNotificationsEnabled();

  Future<void> _ensureInit() {
    if (_initialized) return Future.value();

    return _initFuture ??= () async {
      try {
        await _player.setPlayerMode(PlayerMode.lowLatency);
        await _player.setReleaseMode(ReleaseMode.stop);
        await _player.setSourceAsset(_assetPath);
        _initialized = true;
      } catch (e) {
        debugPrint('NotificationSoundService: init failed: $e');

        _initFuture = null;
      }
    }();
  }

  Future<void> playPopIfEnabled() async {
    try {
      if (!await isSoundEnabled()) {
        debugPrint(
            'NotificationSoundService: skipped — notificationsEnabled is false for this account');
        return;
      }
      await _ensureInit();

      await _player.seek(Duration.zero);
      await _player.resume();
    } catch (e) {
      debugPrint('NotificationSoundService: playPopIfEnabled failed: $e');

      try {
        await _player.play(AssetSource(_assetPath));
      } catch (e2) {
        debugPrint('NotificationSoundService: fallback play failed: $e2');
      }
    }
  }
}
