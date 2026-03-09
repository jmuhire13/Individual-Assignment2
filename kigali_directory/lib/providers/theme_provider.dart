import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'dark_mode';

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Load theme preference on startup
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  // Toggle theme and save preference
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
  }

  // Set theme directly (for settings screen)
  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode == isDark) return;

    _isDarkMode = isDark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
  }

  // Get light theme
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.grey,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.white,

    // App bar styling
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: const BorderSide(color: Colors.grey),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Input field styling
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    ),

    // Card theme
    cardTheme: const CardThemeData(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),

    // Bottom navigation bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
  );

  // Get dark theme
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.grey,
    primaryColor: Colors.white,
    scaffoldBackgroundColor: Colors.grey.shade900,

    // App bar styling for dark mode
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey.shade900,
      foregroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Button themes for dark mode
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.grey),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Input field styling for dark mode
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade600),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade800,
    ),

    // Card theme for dark mode
    cardTheme: CardThemeData(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.grey.shade800,
    ),

    // Bottom navigation bar for dark mode
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.grey.shade900,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey.shade400,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
  );

  // Get current theme
  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;
}
