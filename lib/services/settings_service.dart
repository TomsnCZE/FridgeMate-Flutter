import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _darkModeKey = 'dark_mode';

  static const String _localeKey = 'locale_code';

  static const String _seedKey = 'theme_seed_key';


  static Future<String?> getLocaleCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey);
  }

  static Future<void> setLocaleCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, code);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }
  static Future<String> getThemeSeedKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_seedKey) ?? 'green';
  }

  static Future<void> setThemeSeedKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_seedKey, key);
  }
}
