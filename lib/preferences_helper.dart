import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const String askDeleteConfirmationKey = 'askDeleteConfirmation';
  static const String darkModeKey = 'darkMode';

  static Future<void> setAskDeleteConfirmation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(askDeleteConfirmationKey, value);
  }

  static Future<bool> getAskDeleteConfirmation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(askDeleteConfirmationKey) ?? true;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(darkModeKey, value);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(darkModeKey) ?? true;
  }
}