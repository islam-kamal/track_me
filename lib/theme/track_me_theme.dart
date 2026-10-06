import 'package:flutter/material.dart';

const Color trackSlate = Color(0xFF0B1220);
const Color trackCard = Color(0xFF162032);
const Color trackTeal = Color(0xFF2DD4BF);
const Color trackInk = Color(0xFF042F2E);

ThemeData buildTrackMeTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: trackTeal,
    brightness: Brightness.dark,
  ).copyWith(
    primary: trackTeal,
    onPrimary: trackInk,
    surface: trackCard,
    onSurface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: trackSlate,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      labelStyle: const TextStyle(color: Color(0xFFCBD5E1)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: trackTeal,
        foregroundColor: trackInk,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: Color(0xFF334155)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: trackTeal),
    ),
  );
}
