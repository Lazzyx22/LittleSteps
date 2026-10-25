import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class PreferencesStore implements LocalStore {
  PreferencesStore(this.preferences);
  final SharedPreferences preferences;
  @override
  Future<String?> read(String key) async => preferences.getString(key);
  @override
  Future<void> write(String key, String value) async {
    if (!await preferences.setString(key, value))
      throw StateError('Could not save local learning data');
  }
}

class MemoryStore implements LocalStore {
  final Map<String, String> values = {};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
