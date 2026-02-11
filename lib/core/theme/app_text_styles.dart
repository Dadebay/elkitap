import 'package:flutter/material.dart';
import 'package:elkitap/core/constants/string_constants.dart';


class AppTextStyles {
  // Private constructor to prevent instantiation
  const AppTextStyles._();

  // ==================== DISPLAY STYLES ====================
  /// Display Large - 57px, Regular
  static const TextStyle displayLarge = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );

  /// Display Medium - 45px, Regular
  static const TextStyle displayMedium = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );

  /// Display Small - 36px, Regular
  static const TextStyle displaySmall = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );

  // ==================== HEADLINE STYLES ====================
  /// Headline Large - 32px, Regular
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.25,
  );

  /// Headline Medium - 28px, Regular
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.29,
  );

  /// Headline Small - 24px, Regular
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.33,
  );

  // ==================== TITLE STYLES ====================
  /// Title Large - 22px, Regular
  static const TextStyle titleLarge = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 22,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.27,
  );

  /// Title Medium - 16px, Medium (500)
  static const TextStyle titleMedium = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.5,
  );

  /// Title Small - 14px, Medium (500)
  static const TextStyle titleSmall = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // ==================== BODY STYLES ====================
  /// Body Large - 16px, Regular
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );

  /// Body Medium - 14px, Regular
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  /// Body Small - 12px, Regular
  static const TextStyle bodySmall = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // ==================== LABEL STYLES ====================
  /// Label Large - 14px, Medium (500)
  static const TextStyle labelLarge = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  /// Label Medium - 12px, Medium (500)
  static const TextStyle labelMedium = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );

  /// Label Small - 11px, Medium (500)
  static const TextStyle labelSmall = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // ==================== CUSTOM STYLES ====================
  /// Book Title - 18px, SemiBold
  static const TextStyle bookTitle = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  /// Book Author - 14px, Regular
  static const TextStyle bookAuthor = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  /// Button Text - 14px, Medium (500)
  static const TextStyle button = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  /// Caption - 12px, Regular
  static const TextStyle caption = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  /// Overline - 10px, Medium (500), Uppercase
  static const TextStyle overline = TextStyle(
    fontFamily: StringConstants.GilroyMedium,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    height: 1.6,
  );
}
