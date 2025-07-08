import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static late SharedPreferences _prefs;

  static const String _appVersionKey = 'app_version';
  static const String _firstLaunchKey = 'first_launch';
  static const String _voiceAssistantKey = 'voice_assistant_enabled';

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      // Retry once
      await Future.delayed(const Duration(milliseconds: 500));
      _prefs = await SharedPreferences.getInstance();
    }
  }

  // String methods
  static Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  // Bool methods
  static Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  // Int methods
  static Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  static int getInt(String key, {int defaultValue = 0}) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  // Double methods
  static Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  static double getDouble(String key, {double defaultValue = 0.0}) {
    return _prefs.getDouble(key) ?? defaultValue;
  }

  // StringList methods
  static Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  static List<String> getStringList(String key) {
    return _prefs.getStringList(key) ?? [];
  }

  // Remove method
  static Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  // Clear all
  static Future<void> clear() async {
    await _prefs.clear();
  }

  // Check if key exists
  static bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  static Future<bool?> isFirstLaunch() async {
    return _prefs.getBool(_firstLaunchKey);
  }

  static Future<void> setFirstLaunch(bool value) async {
    await _prefs.setBool(_firstLaunchKey, value);
  }

  static Future<void> setAppVersion(String version) async {
    await _prefs.setString(_appVersionKey, version);
  }

  static String? getAppVersion() {
    return _prefs.getString(_appVersionKey);
  }

  static Future<bool> isVoiceAssistantEnabled() async {
    return _prefs.getBool(_voiceAssistantKey) ?? false;
  }

  static Future<void> setVoiceAssistantEnabled(bool value) async {
    await _prefs.setBool(_voiceAssistantKey, value);
  }
} 