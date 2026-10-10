import '../../core/constants/storage_keys.dart';
import '../../models/user.dart';
import '../datasources/local_storage_datasource.dart';

class AuthRepository {
  final LocalStorageDatasource _storage;

  AuthRepository({LocalStorageDatasource? storage})
      : _storage = storage ?? LocalStorageDatasource();

  List<AppUser> getDefaultUsers() {
    return [
      AppUser(username: 'admin', password: 'admin', role: 'admin'),
      AppUser(username: 'manager', password: 'manager', role: 'content_manager'),
      AppUser(username: 'uye', password: 'uye', role: 'member'),
    ];
  }

  Future<List<AppUser>> loadUsers() async {
    final dynamic decoded = await _storage.getJson(StorageKeys.usersData);
    if (decoded != null && decoded is List) {
      try {
        return decoded.map((item) => AppUser.fromJson(item as Map<String, dynamic>)).toList();
      } catch (_) {
        return getDefaultUsers();
      }
    }
    final defaultUsers = getDefaultUsers();
    await saveUsers(defaultUsers);
    return defaultUsers;
  }

  Future<void> saveUsers(List<AppUser> users) async {
    final list = users.map((u) => u.toJson()).toList();
    await _storage.setJson(StorageKeys.usersData, list);
  }

  Future<String?> getLoggedInUsername() async {
    return _storage.getString(StorageKeys.loggedInUsername);
  }

  Future<void> setLoggedInUsername(String? username) async {
    if (username == null) {
      await _storage.remove(StorageKeys.loggedInUsername);
    } else {
      await _storage.setString(StorageKeys.loggedInUsername, username);
    }
  }
}
