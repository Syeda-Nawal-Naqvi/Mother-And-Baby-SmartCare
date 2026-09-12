import 'package:shared_preferences/shared_preferences.dart';

class FeedbackReminderService {
  FeedbackReminderService._();

  static const _prefsKey = 'feedback_reminder_last_shown_at';
  static const Duration _interval = Duration(days: 7);

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMillis = prefs.getInt(_prefsKey);
    if (lastMillis == null) return true;
    final last = DateTime.fromMillisecondsSinceEpoch(lastMillis);
    return DateTime.now().difference(last) >= _interval;
  }

  static Future<void> markShownNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, DateTime.now().millisecondsSinceEpoch);
  }
}
