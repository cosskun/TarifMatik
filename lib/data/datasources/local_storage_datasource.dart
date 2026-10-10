import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageDatasource {
  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  Future<String?> getString(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  Future<bool> setString(String key, String value) async {
    final prefs = await _prefs;
    return prefs.setString(key, value);
  }

  Future<int?> getInt(String key) async {
    final prefs = await _prefs;
    return prefs.getInt(key);
  }

  Future<bool> setInt(String key, int value) async {
    final prefs = await _prefs;
    return prefs.setInt(key, value);
  }

  Future<double?> getDouble(String key) async {
    final prefs = await _prefs;
    return prefs.getDouble(key);
  }

  Future<bool> setDouble(String key, double value) async {
    final prefs = await _prefs;
    return prefs.setDouble(key, value);
  }

  Future<List<String>?> getStringList(String key) async {
    final prefs = await _prefs;
    return prefs.getStringList(key);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    final prefs = await _prefs;
    return prefs.setStringList(key, value);
  }

  Future<bool> remove(String key) async {
    final prefs = await _prefs;
    return prefs.remove(key);
  }

  Future<dynamic> getJson(String key) async {
    final str = await getString(key);
    if (str == null) return null;
    try {
      return jsonDecode(str);
    } catch (_) {
      return null;
    }
  }

  Future<bool> setJson(String key, dynamic value) async {
    final str = jsonEncode(value);
    return setString(key, str);
  }
}
