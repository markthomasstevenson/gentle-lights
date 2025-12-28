import 'package:flutter/material.dart';

/// Core color palette for Gentle Lights app
/// 
/// All colors are derived from the app icon and should be used consistently
/// across the entire application to maintain visual harmony and avoid
/// medical-looking UI.
class AppColors {
  AppColors._(); // Prevent instantiation

  // Core palette colors
  
  /// Night sky blue - Used for night/dim states and backgrounds
  /// Represents the calm, evening atmosphere
  static const Color nightSkyBlue = Color(0xFF3E4C7A);

  /// Twilight lavender - Used for night/dim states and subtle accents
  /// Complements nightSkyBlue for evening/nighttime themes
  static const Color twilightLavender = Color(0xFF7A6FB0);

  /// Warm window glow - PRIMARY ACTION COLOR
  /// 
  /// MUST only be used for:
  /// - Primary action buttons
  /// - House "lights on" state
  /// - Positive completion feedback
  /// 
  /// This is the signature color representing warmth and completion
  static const Color warmWindowGlow = Color(0xFFFFC857);

  /// Soft candle orange - Used for warm accents and secondary highlights
  /// Complements warmWindowGlow for warm states
  static const Color softCandleOrange = Color(0xFFF6A85F);

  /// Warm off-white - Default background color
  /// Provides a warm, non-clinical base for all screens
  static const Color warmOffWhite = Color(0xFFFAF8F4);

  /// Soft sage green - Used for subtle accents and secondary elements
  /// Provides natural, calming contrast without medical associations
  static const Color softSageGreen = Color(0xFF8FB6A6);

  // Text colors
  
  /// Primary text color - Used for main content and headings
  static const Color textPrimary = Color(0xFF2E2E2E);

  /// Secondary text color - Used for subtitles, hints, and less prominent text
  static const Color textSecondary = Color(0xFF6F6F6F);

  // Semantic color mappings
  // These map app colors to Material 3 color scheme roles
  
  /// Primary color for the app (warmWindowGlow)
  static const Color primary = warmWindowGlow;

  /// Color for text/icons on primary background
  static const Color onPrimary = textPrimary;

  /// Secondary color (twilightLavender)
  static const Color secondary = twilightLavender;

  /// Color for text/icons on secondary background
  static const Color onSecondary = warmOffWhite;

  /// Surface color (warmOffWhite)
  static const Color surface = warmOffWhite;

  /// Color for text/icons on surface
  static const Color onSurface = textPrimary;

  /// Variant surface color for elevated surfaces
  static const Color surfaceVariant = Color(0xFFF5F3ED); // Slightly darker than warmOffWhite

  /// Color for text/icons on surface variant
  static const Color onSurfaceVariant = textSecondary;

  /// Background color for dim/night states
  static const Color dimBackground = nightSkyBlue;

  /// Color for text/icons on dim background
  static const Color onDimBackground = warmOffWhite;

  /// Background color for warm/completed states
  static const Color warmBackground = Color(0xFFFFF4E0); // Very light warm tint

  /// Color for text/icons on warm background
  static const Color onWarmBackground = textPrimary;

  // Note: No red or green error/success colors per design requirements
  // Use warmWindowGlow for positive feedback, softSageGreen for neutral states
}

