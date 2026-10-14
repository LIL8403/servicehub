import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final textTheme = AppTypography.textTheme(AppColors.textPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      dividerColor: AppColors.borderLight,

      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.textInverse,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.textInverse,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textInverse,
        secondaryContainer: AppColors.secondaryLight,
        onSecondaryContainer: AppColors.primaryDark,
        surface: AppColors.cardLight,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.textInverse,
        outline: AppColors.borderLight,
      ),

      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textInverse,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h3.copyWith(
          color: AppColors.textInverse,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textInverse,
          disabledBackgroundColor: AppColors.disabledBg,
          disabledForegroundColor: AppColors.disabledText,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 12,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.borderMd,
          ),
          textStyle: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            height: 20 / 16,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.disabledText,
          side: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.borderMd,
          ),
          textStyle: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(40),
          foregroundColor: AppColors.textSecondary,
          disabledForegroundColor: const Color(0xFFCBD5E1),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.borderMd,
          ),
          textStyle: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textMuted,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: BorderSide(
            color: AppColors.borderLight,
            width: 1.0,
          ),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: BorderSide(
            color: AppColors.borderLight,
            width: 1.0,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 2.0,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: BorderSide(
            color: AppColors.error,
            width: 2.0,
          ),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: BorderSide(
            color: AppColors.borderLight,
            width: 1.0,
          ),
        ),
      ),

      cardTheme: const CardThemeData(
        color: AppColors.cardLight,
        elevation: 1,
        margin: EdgeInsets.all(AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderLg,
          side: BorderSide(
            color: AppColors.borderLight,
            width: 1.0,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.neutralBadgeBg,
        disabledColor: AppColors.disabledBg,
        labelStyle: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.borderSm,
        ),
        side: BorderSide.none,
      ),
    );
  }

  static ThemeData dark() {
    final textTheme = AppTypography.textTheme(AppColors.textInverse);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      dividerColor: AppColors.borderDark,

      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primaryLight,
        onPrimary: AppColors.textInverse,
        primaryContainer: AppColors.primary,
        onPrimaryContainer: AppColors.textInverse,
        secondary: AppColors.secondaryLight,
        onSecondary: AppColors.primaryDark,
        secondaryContainer: AppColors.secondary,
        onSecondaryContainer: AppColors.textInverse,
        surface: AppColors.cardDark,
        onSurface: AppColors.textInverse,
        error: AppColors.error,
        onError: AppColors.textInverse,
        outline: AppColors.borderDark,
      ),

      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textInverse,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h3.copyWith(
          color: AppColors.textInverse,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.textInverse,
          disabledBackgroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.textMuted,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 12,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.borderMd,
          ),
          textStyle: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            height: 20 / 16,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: AppColors.textInverse,
          disabledForegroundColor: AppColors.textMuted,
          side: const BorderSide(
            color: AppColors.borderDark,
            width: 1.5,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.borderMd,
          ),
          textStyle: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(40),
          foregroundColor: AppColors.textMuted,
          disabledForegroundColor: AppColors.borderDark,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.borderMd,
          ),
          textStyle: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textMuted,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textMuted,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: BorderSide(
            color: AppColors.borderDark,
            width: 1.0,
          ),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: BorderSide(
            color: AppColors.borderDark,
            width: 1.0,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: BorderSide(
            color: AppColors.secondary,
            width: 2.0,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: BorderSide(
            color: AppColors.error,
            width: 2.0,
          ),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: BorderSide(
            color: AppColors.borderDark,
            width: 1.0,
          ),
        ),
      ),

      cardTheme: const CardThemeData(
        color: AppColors.cardDark,
        elevation: 1,
        margin: EdgeInsets.all(AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderLg,
          side: BorderSide(
            color: AppColors.borderDark,
            width: 1.0,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryLight,
        disabledColor: AppColors.primaryDark,
        labelStyle: AppTypography.caption.copyWith(
          color: AppColors.textInverse,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.borderSm,
        ),
        side: BorderSide.none,
      ),
    );
  }

  // Backwards compatibility getter for main.dart
  static ThemeData get lightTheme => light();
  static ThemeData get darkTheme => dark();
}
