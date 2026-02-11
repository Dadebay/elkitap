// ignore_for_file: deprecated_member_use

import 'package:elkitap/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

final class CustomColorScheme {
  CustomColorScheme._();

  static const lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.kPrimaryColor,
    onPrimary: Colors.white,
    secondary: AppColors.kSecondaryColor,
    onSecondary: Colors.white,
    surface: AppColors.whiteColor,
    onSurface: AppColors.blackColor,
    outline: AppColors.greyColor,
    error: AppColors.redColor,
    onError: Colors.white,
    errorContainer: AppColors.redColorwithOpacity,
    onErrorContainer: AppColors.redColor,
    shadow: Colors.black,
    tertiary: AppColors.purpleColor,
    tertiaryContainer: AppColors.purpleColorwithOpacity,
    inversePrimary: AppColors.kPrimaryColor2,
    surfaceTint: AppColors.blueColorwithOpacity,
    scrim: Colors.black,
    onSurfaceVariant: Colors.grey,
    inverseSurface: Color(0xff313033),
    onInverseSurface: Colors.white,
    primaryContainer: Color(0xFFEADDFF),
    onPrimaryContainer: Color(0xFF21005D),
    secondaryContainer: Color(0xFFE8DEF8),
    onSecondaryContainer: Color(0xFF1D192B),
    background: Color(0xFFCAC4D0),
    onBackground: Color(0xFFCAC4D0),
  );

  static const darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xff43A0D9),
    onPrimary: AppColors.whiteColor,
    secondary: AppColors.kSecondaryColor,
    onSecondary: AppColors.blackColor,
    primaryContainer: AppColors.kPrimaryColor2,
    onPrimaryContainer: AppColors.whiteColor,
    secondaryContainer: AppColors.greenColorwithOpacity,
    onSecondaryContainer: AppColors.blackColor,
    tertiary: AppColors.purpleColor,
    onTertiary: AppColors.whiteColor,
    tertiaryContainer: AppColors.purpleColorwithOpacity,
    onTertiaryContainer: AppColors.blackColor,
    error: AppColors.redColor,
    onError: AppColors.whiteColor,
    errorContainer: AppColors.redColorwithOpacity,
    onErrorContainer: AppColors.whiteColor,
    surface: Color(0xFF121212),
    onSurface: AppColors.whiteColor,
    outline: AppColors.greyColor,
    outlineVariant: Color(0xFF4B4B4B),
    shadow: AppColors.blackColor,
    surfaceTint: AppColors.blueColorwithOpacity,
    scrim: AppColors.blackColor,
    inverseSurface: AppColors.whiteColor,
    onInverseSurface: AppColors.blackColor,
    inversePrimary: AppColors.kPrimaryColor2,
    // outlineVariant: Color(0xFFCAC4D0),
    background: Color(0xFFCAC4D0), onBackground: Color(0xFFCAC4D0),
  );
}
