// ignore_for_file: constant_identifier_names

import 'package:flutter/cupertino.dart';

enum ColumnSize { small, medium, large }

/// String constants for the application
/// Contains font family names and other string constants
@immutable
class StringConstants {
  // Private constructor to prevent instantiation
  const StringConstants._();

  // Font Families
  /// SF Pro font family - Primary font for the app (mapped to Gilroy)
  static const String SFPro = 'GilroyMedium';

  /// New York font family - Serif font for reading (mapped to Gilroy)
  static const String NewYork = 'GilroyRegular';

  /// New York Italic font family (mapped to Gilroy)
  static const String NewYorkItalic = 'GilroyRegular';

  /// Gilroy Bold font family
  static const String GilroyBold = 'GilroyBold';

  /// Gilroy SemiBold font family
  static const String GilroySemiBold = 'GilroySemiBold';

  /// Gilroy Medium font family
  static const String GilroyMedium = 'GilroyMedium';

  /// Gilroy Regular font family
  static const String GilroyRegular = 'GilroyRegular';

  // static const String PrivacyPolicy = 'https://www.freeprivacypolicy.com/live/7a60122b-caf9-4bae-b9d2-02a069d71c4f';
  static const String TermsAndConditions = 'TermsAndConditions';
}
