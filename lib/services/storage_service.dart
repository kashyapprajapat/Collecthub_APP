import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class StorageService {
  // Save user data to local storage
  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userIdKey, user.id);
    await prefs.setString(AppConstants.userNameKey, user.name);
    await prefs.setString(AppConstants.userEmailKey, user.email);
  }

  // Get user data from local storage
  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(AppConstants.userIdKey);
    final name = prefs.getString(AppConstants.userNameKey);
    final email = prefs.getString(AppConstants.userEmailKey);

    if (id != null && name != null && email != null) {
      return User(id: id, name: name, email: email);
    }
    return null;
  }

  // Clear user data from local storage (logout)
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userNameKey);
    await prefs.remove(AppConstants.userEmailKey);
  }

  // Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    final user = await getUser();
    return user != null;
  }

  // Get individual user data
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userIdKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userNameKey);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userEmailKey);
  }
}