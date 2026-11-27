import 'package:shared_preferences/shared_preferences.dart';

class AppInitialPreferences {
  final bool isDarkMode;
  final bool isLoggedIn;
  final String? userId;
  final String? userEmail;

  const AppInitialPreferences({
    required this.isDarkMode,
    required this.isLoggedIn,
    this.userId,
    this.userEmail,
  });
}

class PreferencesService {
  PreferencesService._();
  static final PreferencesService instance = PreferencesService._();

  static const String _keyDarkMode = 'pref_dark_mode';
  static const String _keyIsLoggedIn = 'pref_is_logged_in';
  static const String _keyUserId = 'pref_user_id';
  static const String _keyUserEmail = 'pref_user_email';

  /// Menyimpan preferensi mode gelap (dark mode)
  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  /// Membaca preferensi mode gelap (default: false / light mode)
  Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  /// Menyimpan status sesi login terakhir
  Future<void> saveUserSession({
    required bool isLoggedIn,
    String? userId,
    String? userEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, isLoggedIn);

    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_keyUserId, userId);
    } else if (!isLoggedIn) {
      await prefs.remove(_keyUserId);
    }

    if (userEmail != null && userEmail.isNotEmpty) {
      await prefs.setString(_keyUserEmail, userEmail);
    } else if (!isLoggedIn) {
      await prefs.remove(_keyUserEmail);
    }
  }

  /// Membaca apakah sesi login terakhir masih aktif
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Membaca userId tersimpan dari sesi terakhir
  Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  /// Membaca email tersimpan dari sesi terakhir
  Future<String?> getSavedUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  /// Menghapus sesi login saat user logout
  Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserEmail);
  }

  /// Memuat seluruh preferensi awal saat aplikasi pertama kali dijalankan
  Future<AppInitialPreferences> loadInitialPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return AppInitialPreferences(
      isDarkMode: prefs.getBool(_keyDarkMode) ?? false,
      isLoggedIn: prefs.getBool(_keyIsLoggedIn) ?? false,
      userId: prefs.getString(_keyUserId),
      userEmail: prefs.getString(_keyUserEmail),
    );
  }
}