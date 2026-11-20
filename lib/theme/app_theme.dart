import 'package:flutter/material.dart';

class AppTheme {
  // Dark theme colors with purple accents
  static const Color primaryColor = Color(0xFFBB86FC);        // Purple 200
  static const Color primaryVariant = Color(0xFF3700B3);      // Purple 700
  static const Color secondaryColor = Color(0xFF03DAC6);      // Teal 200
  static const Color backgroundColor = Color(0xFF121212);     // Dark surface
  static const Color surfaceColor = Color(0xFF1E1E1E);        // Elevated surface
  static const Color cardColor = Color(0xFF1F1F1F);           // Card background
  static const Color textPrimary = Color(0xFFFFFFFF);         // White
  static const Color textSecondary = Color(0xFFB3B3B3);       // Grey 300
  static const Color textDisabled = Color(0xFF666666);        // Grey 600
  static const Color accentColor = Color(0xFF03DAC6);         // Teal for breaks
  static const Color lessonColor = Color(0xFFFFB74D);         // Orange for lessons
  static const Color bigBreakColor = Color(0xFFCE93D8);       // Purple for big breaks
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFCF6679);
  static const Color dividerColor = Color(0xFF2C2C2C);

  static TextStyle unboundedStyle({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w600,
    Color color = textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Unbounded',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? 0.5,
      height: height,
    );
  }

  static TextStyle onestStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Onest',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? 0.3,
      height: height,
    );
  }

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
    fontFamily: 'Onest',
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: textPrimary,
      onError: Colors.white,
    ),
    textTheme: TextTheme(
      displayLarge: unboundedStyle(fontSize: 32, fontWeight: FontWeight.w700),
      displayMedium: unboundedStyle(fontSize: 28, fontWeight: FontWeight.w600),
      displaySmall: unboundedStyle(fontSize: 24, fontWeight: FontWeight.w600),
      headlineLarge: unboundedStyle(fontSize: 22, fontWeight: FontWeight.w600),
      headlineMedium: unboundedStyle(fontSize: 20, fontWeight: FontWeight.w600),
      headlineSmall: unboundedStyle(fontSize: 18, fontWeight: FontWeight.w500),
      titleLarge: unboundedStyle(fontSize: 16, fontWeight: FontWeight.w600),
      titleMedium: unboundedStyle(fontSize: 14, fontWeight: FontWeight.w500),
      titleSmall: unboundedStyle(fontSize: 12, fontWeight: FontWeight.w500),
      bodyLarge: onestStyle(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: onestStyle(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: onestStyle(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: onestStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: unboundedStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
      iconTheme: IconThemeData(color: textPrimary),
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: onestStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: onestStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor),
      ),
      labelStyle: onestStyle(color: textSecondary),
      hintStyle: onestStyle(color: textDisabled),
      floatingLabelStyle: onestStyle(color: primaryColor),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    dividerTheme: DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: 1,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titleTextStyle: unboundedStyle(fontSize: 20, fontWeight: FontWeight.w600),
      contentTextStyle: onestStyle(fontSize: 16),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: surfaceColor,
      hourMinuteColor: primaryColor,
      hourMinuteTextColor: Colors.black,
      dayPeriodColor: primaryColor,
      dayPeriodTextColor: Colors.black,
      dialHandColor: primaryColor,
      dialBackgroundColor: backgroundColor,
      entryModeIconColor: primaryColor,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        return textDisabled;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor.withValues(alpha: 0.3);
        return textDisabled.withValues(alpha: 0.3);
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.black),
      side: BorderSide(color: dividerColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryColor,
      inactiveTrackColor: primaryColor.withValues(alpha: 0.3),
      thumbColor: primaryColor,
      overlayColor: primaryColor.withValues(alpha: 0.1),
      valueIndicatorColor: primaryColor,
      valueIndicatorTextStyle: onestStyle(color: Colors.black, fontSize: 12),
    ),
  );
}