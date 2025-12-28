import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        // Primary colors
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        
        // Secondary colors
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        
        // Surface colors
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        
        // Error - use softSageGreen for neutral error states (no red)
        error: AppColors.softSageGreen,
        onError: AppColors.textPrimary,
        
        // Outline for borders and dividers
        outline: AppColors.textSecondary.withValues(alpha: 0.3),
        outlineVariant: AppColors.textSecondary.withValues(alpha: 0.1),
        
        // Container colors for elevated surfaces
        primaryContainer: AppColors.warmBackground,
        onPrimaryContainer: AppColors.onWarmBackground,
        secondaryContainer: AppColors.twilightLavender.withValues(alpha: 0.1),
        onSecondaryContainer: AppColors.twilightLavender,
        
        // Surface container for cards and elevated elements
        surfaceContainerHighest: AppColors.surfaceVariant,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      fontFamily: 'System',
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.surfaceVariant,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Elevated button theme - uses warmWindowGlow for primary actions
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      ),
      
      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceVariant,
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    // For dark theme, use night/dim colors
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        // Primary colors - keep warmWindowGlow for actions
        primary: AppColors.primary,
        onPrimary: AppColors.textPrimary,
        
        // Secondary colors - use lavender tones
        secondary: AppColors.twilightLavender,
        onSecondary: AppColors.warmOffWhite,
        
        // Surface colors - use night sky blue
        surface: AppColors.dimBackground,
        onSurface: AppColors.onDimBackground,
        onSurfaceVariant: AppColors.warmOffWhite.withValues(alpha: 0.8),
        
        // Error - use softSageGreen for neutral error states (no red)
        error: AppColors.softSageGreen,
        onError: AppColors.textPrimary,
        
        // Outline for borders and dividers
        outline: AppColors.warmOffWhite.withValues(alpha: 0.3),
        outlineVariant: AppColors.warmOffWhite.withValues(alpha: 0.1),
        
        // Container colors
        primaryContainer: AppColors.warmWindowGlow.withValues(alpha: 0.2),
        onPrimaryContainer: AppColors.warmWindowGlow,
        secondaryContainer: AppColors.twilightLavender.withValues(alpha: 0.3),
        onSecondaryContainer: AppColors.warmOffWhite,
        
        // Surface container
        surfaceContainerHighest: AppColors.nightSkyBlue.withValues(alpha: 0.6),
      ),
      scaffoldBackgroundColor: AppColors.dimBackground,
      fontFamily: 'System',
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.dimBackground,
        foregroundColor: AppColors.onDimBackground,
        elevation: 0,
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.nightSkyBlue.withValues(alpha: 0.8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.nightSkyBlue.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.warmOffWhite.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.warmOffWhite.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      ),
      
      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.nightSkyBlue.withValues(alpha: 0.9),
        contentTextStyle: const TextStyle(
          color: AppColors.onDimBackground,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}



