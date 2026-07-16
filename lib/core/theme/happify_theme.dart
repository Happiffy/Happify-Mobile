import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'happify_colors.dart';

ThemeData buildHappifyTheme({bool highContrast = false}) {
  final ink = highContrast ? Colors.black : HappifyColors.ink;
  final inkSoft = highContrast
      ? const Color(0xFF28231F)
      : HappifyColors.inkSoft;
  final background = highContrast ? Colors.white : HappifyColors.background;
  final surface = highContrast ? Colors.white : HappifyColors.surface;
  final line = highContrast ? Colors.black : HappifyColors.line;
  final base = GoogleFonts.nunitoTextTheme().apply(
    bodyColor: ink,
    displayColor: ink,
  );
  final display = GoogleFonts.nunito(
    color: ink,
    fontWeight: FontWeight.w900,
    height: 1.05,
    letterSpacing: -0.5,
  );

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    dividerColor: line,
    colorScheme: ColorScheme.fromSeed(
      seedColor: HappifyColors.green,
      primary: highContrast ? Colors.black : HappifyColors.green,
      onPrimary: Colors.white,
      secondary: HappifyColors.blue,
      onSecondary: Colors.white,
      surface: surface,
      error: highContrast ? const Color(0xFFA60000) : HappifyColors.red,
    ),
    textTheme: base.copyWith(
      displayLarge: display.copyWith(fontSize: 40),
      headlineLarge: display.copyWith(fontSize: 32),
      headlineMedium: display.copyWith(fontSize: 27),
      headlineSmall: display.copyWith(fontSize: 22),
      titleLarge: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: ink,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: inkSoft,
        height: 1.55,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: inkSoft,
        height: 1.5,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: highContrast ? Colors.black : HappifyColors.green,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      labelStyle: TextStyle(color: inkSoft, fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: highContrast ? Colors.black : HappifyColors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: highContrast ? Colors.black : HappifyColors.blueDark,
        minimumSize: const Size.fromHeight(54),
        side: BorderSide(
          color: highContrast ? Colors.black : HappifyColors.line,
          width: 2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: highContrast ? Colors.black : const Color(0xFFD7FFBF),
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: ink),
      ),
    ),
  );
}
