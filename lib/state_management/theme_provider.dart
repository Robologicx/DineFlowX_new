import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys
const _colorKey = "selectedColor";
const _modeKey = "themeMode";

/// Immutable state
class ThemeState {
  final Color primaryColor;
  final ThemeMode themeMode;

  const ThemeState({required this.primaryColor, required this.themeMode});

  ThemeState copyWith({Color? primaryColor, ThemeMode? themeMode}) {
    return ThemeState(
      primaryColor: primaryColor ?? this.primaryColor,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  /// Light theme
  ThemeData get lightTheme {
    return ThemeData(
      textTheme: TextTheme(
        bodyLarge: GoogleFonts.poppins(
          fontSize: 14,

          fontWeight: FontWeight.bold,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,

          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  /// Dark theme
  ThemeData get darkTheme {
    return ThemeData(
      inputDecorationTheme: InputDecorationThemeData(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: TextTheme(
        bodyLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}

/// Notifier
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier()
    : super(
        const ThemeState(primaryColor: Colors.blue, themeMode: ThemeMode.light),
      );

  /// Load saved color + mode
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_colorKey);
    final modeIndex = prefs.getInt(_modeKey);
    state = state.copyWith(
      primaryColor: colorValue != null ? Color(colorValue) : state.primaryColor,
      themeMode: modeIndex != null
          ? ThemeMode.values[modeIndex]
          : state.themeMode,
    );
  }

  /// Update and persist color
  Future<void> updateColor(Color color) async {
    state = state.copyWith(primaryColor: color);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorKey, color.value);
  }

  /// Update and persist theme mode
  Future<void> updateMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_modeKey, mode.index);
  }
}

/// Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);
