import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const String askDeleteConfirmationKey = 'askDeleteConfirmation';

  static Future<void> setAskDeleteConfirmation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(askDeleteConfirmationKey, value);
  }

  static Future<bool> getAskDeleteConfirmation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(askDeleteConfirmationKey) ?? true; // Default to true
  }
}