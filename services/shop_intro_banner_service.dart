import 'package:shared_preferences/shared_preferences.dart';

class ShopIntroBannerService {
  ShopIntroBannerService._();

  static const _prefsKey = 'shop_intro_banner_dismissed';

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_prefsKey) ?? false);
  }

  static Future<void> markDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }
}
