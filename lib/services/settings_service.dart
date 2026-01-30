import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _darkModeKey = 'dark_mode';
  static const String _expirationDaysKey = 'expiration_days';
  static const String _defaultCategoryKey = 'default_category';
  static const String _defaultUnitKey = 'default_unit';
  static const String _hideExpiredKey = 'hide_expired';
  static const String _notificationsKey = 'notifications';
  static const String _viewModeKey = 'view_mode';

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

  static Future<int> getExpirationWarningDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_expirationDaysKey) ?? 3;
  }

  static Future<String> getDefaultCategory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultCategoryKey) ?? 'fridge';
  }

  static Future<String> getDefaultUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultUnitKey) ?? 'ks';
  }

  static Future<bool> getHideExpired() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hideExpiredKey) ?? false;
  }

  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? true;
  }

  static Future<String> getViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_viewModeKey) ?? 'list';
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  static Future<void> setExpirationWarningDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_expirationDaysKey, days);
  }

  static Future<void> setDefaultCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultCategoryKey, category);
  }

  static Future<void> setDefaultUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultUnitKey, unit);
  }

  static Future<void> setHideExpired(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideExpiredKey, value);
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }

  static Future<void> setViewMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_viewModeKey, mode);
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
