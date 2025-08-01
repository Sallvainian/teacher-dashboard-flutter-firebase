/// Theme management provider for application theming.
/// 
/// This module manages the application's theme state, handling dark/light
/// mode switching with persistent storage. Supports system preference
/// detection and manual theme overrides.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider managing application theme state and persistence.
/// 
/// This provider serves as the central theme manager, coordinating
/// theme changes across the application. Key features:
/// - Light, dark, and system theme mode support
/// - Persistent theme preference storage
/// - Real-time theme switching with UI updates
/// - System brightness detection and adaptation
/// - Toggle functionality for quick theme switching
/// 
/// Theme preferences are automatically saved to SharedPreferences
/// and restored on application startup.
class ThemeProvider with ChangeNotifier {
  /// SharedPreferences key for storing theme preference.
  static const String _themeKey = 'theme_mode';
  
  /// Current theme mode (light, dark, or system).
  ThemeMode _themeMode = ThemeMode.system;
  
  /// Current theme mode setting.
  ThemeMode get themeMode => _themeMode;
  
  /// Whether the current effective theme is dark mode.
  /// 
  /// Resolves system theme mode by checking platform brightness.
  /// Returns actual dark mode state regardless of theme setting.
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // This will be determined by the system
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
  
  /// Creates theme provider and loads saved preferences.
  /// 
  /// Automatically restores theme setting from persistent storage.
  ThemeProvider() {
    _loadTheme();
  }
  
  /// Loads theme preference from SharedPreferences.
  /// 
  /// Restores previously saved theme mode or defaults to system.
  /// Called during provider initialization.
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);
    
    if (themeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == themeString,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }
  
  /// Toggles between light and dark theme modes.
  /// 
  /// Cycling behavior:
  /// - Light → Dark
  /// - Dark → Light
  /// - System → Opposite of current effective theme
  /// 
  /// Automatically saves preference and updates UI.
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      // If system, switch to the opposite of current
      _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeMode.toString());
    notifyListeners();
  }
  
  /// Sets specific theme mode.
  /// 
  /// Allows direct setting to light, dark, or system mode.
  /// Automatically saves preference and updates UI.
  /// 
  /// @param mode Theme mode to set (light, dark, or system)
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString());
    notifyListeners();
  }
}