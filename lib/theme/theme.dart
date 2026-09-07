import 'package:flutter/material.dart';

import 'colors.dart';

/// Black-and-white glass theme for Mindful.
class MindfulTheme {
  MindfulTheme._();

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: MindfulColors.black,
      colorScheme: const ColorScheme.dark(
        primary: MindfulColors.white,
        onPrimary: MindfulColors.black,
        secondary: MindfulColors.mist,
        onSecondary: MindfulColors.black,
        surface: Color(0x0F000000),
        onSurface: MindfulColors.white,
        onSurfaceVariant: MindfulColors.gray,
        outline: MindfulColors.gray,
        outlineVariant: MindfulColors.glassBorder,
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: MindfulColors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: MindfulColors.transparentGlass,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: MindfulColors.white,
          foregroundColor: MindfulColors.black,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: MindfulColors.white,
          side: const BorderSide(color: MindfulColors.glassStrong, width: 1.2),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MindfulColors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: MindfulColors.glassBorder,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xF21A1A1A),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          color: MindfulColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          color: MindfulColors.mist,
          fontSize: 15,
          height: 1.4,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x1AFFFFFF),
        hintStyle: const TextStyle(color: MindfulColors.gray),
        prefixIconColor: MindfulColors.gray,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: MindfulColors.glassBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: MindfulColors.glassBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: MindfulColors.white, width: 1.4),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: MindfulColors.white,
        iconColor: MindfulColors.white,
      ),
      textSelectionTheme:
          const TextSelectionThemeData(cursorColor: MindfulColors.white),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: MindfulColors.white),
    );
  }
}