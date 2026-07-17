import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'happify_colors.dart';

class HappifyShadows {
  static const card = [
    BoxShadow(color: HappifyColors.shadow, offset: Offset(0, 4), blurRadius: 0),
  ];
  static const button = [
    BoxShadow(
      color: HappifyColors.greenDark,
      offset: Offset(0, 5),
      blurRadius: 0,
    ),
  ];
  static const soft = [
    BoxShadow(color: Color(0x18000000), offset: Offset(0, 8), blurRadius: 20),
  ];
  static const primary = [
    BoxShadow(
      color: HappifyColors.greenDark,
      offset: Offset(0, 5),
      blurRadius: 0,
    ),
  ];
  static const blue = [
    BoxShadow(
      color: HappifyColors.blueDark,
      offset: Offset(0, 5),
      blurRadius: 0,
    ),
  ];
  static const purple = [
    BoxShadow(
      color: HappifyColors.purpleDark,
      offset: Offset(0, 5),
      blurRadius: 0,
    ),
  ];
}

class HappifyRadii {
  static const card = 20.0;
  static const field = 16.0;
  static const button = 16.0;
  static const pill = 999.0;
}

ThemeData buildHappifyTheme({bool highContrast = false}) {
  final ink = highContrast ? Colors.black : HappifyColors.ink;
  final inkSoft = highContrast
      ? const Color(0xFF28231F)
      : HappifyColors.inkSoft;
  final line = highContrast ? Colors.black : HappifyColors.line;
  final primary = highContrast ? Colors.black : HappifyColors.green;
  final primaryDark = highContrast ? Colors.black : HappifyColors.greenDark;
  final base = GoogleFonts.nunitoTextTheme().apply(
    bodyColor: ink,
    displayColor: ink,
  );
  final display = base.displayLarge!.copyWith(
    color: ink,
    fontWeight: FontWeight.w900,
    height: 1.05,
    letterSpacing: -0.6,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    scaffoldBackgroundColor: HappifyColors.background,
    canvasColor: HappifyColors.background,
    dividerColor: line,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: highContrast
          ? Colors.white
          : HappifyColors.greenSurface,
      onPrimaryContainer: primaryDark,
      secondary: HappifyColors.blue,
      onSecondary: Colors.white,
      surface: Colors.white,
      surfaceContainer: Colors.white,
      surfaceContainerHighest: HappifyColors.surfaceMuted,
      onSurface: ink,
      onSurfaceVariant: inkSoft,
      error: highContrast ? const Color(0xFFA60000) : HappifyColors.redDark,
      onError: Colors.white,
      outline: line,
    ),
    textTheme: base.copyWith(
      displayLarge: display.copyWith(fontSize: 36),
      headlineLarge: display.copyWith(fontSize: 29),
      headlineMedium: display.copyWith(fontSize: 24),
      headlineSmall: display.copyWith(fontSize: 20),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: ink,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: inkSoft,
        height: 1.45,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: inkSoft,
        height: 1.4,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w900,
        color: ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HappifyRadii.field),
        borderSide: BorderSide(color: line, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HappifyRadii.field),
        borderSide: BorderSide(color: line, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HappifyRadii.field),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HappifyRadii.field),
        borderSide: BorderSide(color: HappifyColors.redDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HappifyRadii.field),
        borderSide: BorderSide(color: HappifyColors.redDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      labelStyle: TextStyle(color: inkSoft, fontWeight: FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 20),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? HappifyColors.surfaceMuted
              : primary,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? HappifyColors.inkMuted
              : Colors.white,
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? primaryDark.withValues(alpha: .18)
              : states.contains(WidgetState.hovered)
              ? Colors.white.withValues(alpha: .12)
              : states.contains(WidgetState.focused)
              ? HappifyColors.focus.withValues(alpha: .55)
              : null,
        ),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HappifyRadii.button),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 20),
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? HappifyColors.inkMuted
              : HappifyColors.blueDark,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? HappifyColors.surfaceMuted
              : Colors.white,
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.disabled) ? line : line,
            width: 2,
          ),
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? HappifyColors.blue.withValues(alpha: .12)
              : states.contains(WidgetState.hovered)
              ? HappifyColors.blueSurface
              : states.contains(WidgetState.focused)
              ? HappifyColors.focus
              : null,
        ),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HappifyRadii.button),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? HappifyColors.inkMuted
              : ink,
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? HappifyColors.lineSubtle
              : states.contains(WidgetState.hovered)
              ? HappifyColors.surfaceMuted
              : states.contains(WidgetState.focused)
              ? HappifyColors.focus
              : null,
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HappifyRadii.button),
          ),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(12)),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? HappifyColors.inkMuted
              : ink,
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? HappifyColors.lineSubtle
              : states.contains(WidgetState.hovered)
              ? HappifyColors.surfaceMuted
              : states.contains(WidgetState.focused)
              ? HappifyColors.focus
              : null,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HappifyRadii.button),
          ),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: HappifyColors.surfaceMuted,
      selectedColor: HappifyColors.greenSurface,
      disabledColor: HappifyColors.surfaceMuted,
      checkmarkColor: HappifyColors.greenDark,
      side: BorderSide(color: line, width: 2),
      labelStyle: TextStyle(color: ink, fontWeight: FontWeight.w800),
      secondaryLabelStyle: TextStyle(color: inkSoft),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HappifyRadii.pill),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : HappifyColors.inkMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? HappifyColors.green
            : HappifyColors.line,
      ),
      trackOutlineColor: WidgetStatePropertyAll(line),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: HappifyColors.green,
      inactiveTrackColor: HappifyColors.greenSurface,
      thumbColor: HappifyColors.greenDark,
      overlayColor: HappifyColors.focus.withValues(alpha: .5),
      valueIndicatorColor: HappifyColors.greenDark,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HappifyRadii.card),
        side: BorderSide(color: line),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HappifyRadii.card),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      showDragHandle: true,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: HappifyColors.red,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HappifyRadii.pill),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: highContrast ? Colors.black : HappifyColors.greenSurface,
      elevation: 0,
      height: 68,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: ink),
      ),
    ),
  );
}
