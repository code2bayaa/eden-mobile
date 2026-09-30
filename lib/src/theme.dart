/// Eden's palette and type, lifted from the web app's `src/styless.css`: earth backgrounds, clay
/// accents, sand text; Fraunces for headings, Inter for everything else.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class EdenColors {
  static const earth950 = Color(0xFF0F0F0E);
  static const earth900 = Color(0xFF1A1A17);
  static const earth800 = Color(0xFF262622);
  static const clay500 = Color(0xFFB35A3D);
  static const clay400 = Color(0xFFD97D5A);
  static const clay300 = Color(0xFFE89977);
  static const sand100 = Color(0xFFF4F2ED);
  static const sand200 = Color(0xFFE8E4D9);
  static const muted = Color(0xFF9A968C);
  static const good = Color(0xFF7FB77E);
  static const bad = Color(0xFFE0645A);
}

TextStyle fraunces(double size, {FontWeight weight = FontWeight.w600, Color? color}) =>
    GoogleFonts.fraunces(fontSize: size, fontWeight: weight, color: color ?? EdenColors.sand100);

ThemeData edenTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: EdenColors.earth950,
    colorScheme: const ColorScheme.dark(
      primary: EdenColors.clay400,
      onPrimary: EdenColors.earth950,
      secondary: EdenColors.clay300,
      surface: EdenColors.earth900,
      onSurface: EdenColors.sand100,
      error: EdenColors.bad,
    ),
  );
  final text = GoogleFonts.interTextTheme(base.textTheme)
      .apply(bodyColor: EdenColors.sand100, displayColor: EdenColors.sand100);
  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: EdenColors.earth950,
      foregroundColor: EdenColors.sand100,
      elevation: 0,
      titleTextStyle: fraunces(20),
    ),
    cardTheme: const CardThemeData(
      color: EdenColors.earth900,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: EdenColors.earth900,
      indicatorColor: EdenColors.earth800,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: EdenColors.earth900,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: EdenColors.earth800),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: EdenColors.earth800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: EdenColors.clay400),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: EdenColors.clay500,
        foregroundColor: EdenColors.sand100,
        minimumSize: const Size.fromHeight(50),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
    ),
  );
}
