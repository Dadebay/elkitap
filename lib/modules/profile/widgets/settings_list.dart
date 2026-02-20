import 'dart:ui';

import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/init/theme_controller.dart';
import 'package:elkitap/core/init/translation_service.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/data/controller/connection_controller.dart';
import 'package:elkitap/data/network/token_managet.dart';
import 'package:elkitap/core/widgets/navigation/bottom_nav_bar.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/global_widgets/custom_bottom_sheet.dart';
import 'package:elkitap/modules/auth/controllers/auth_controller.dart';
import 'package:elkitap/modules/library/controllers/downloaded_controller.dart';
import 'package:elkitap/modules/library/controllers/library_main_controller.dart';
import 'package:elkitap/modules/library/controllers/note_controller.dart';
import 'package:elkitap/modules/paymant/controller/payment_controller.dart';
import 'package:elkitap/modules/paymant/controller/promo_code_controller.dart';
import 'package:elkitap/modules/profile/controllers/contacts_controller.dart';
import 'package:elkitap/modules/profile/widgets/help_and_support_sheet.dart';
import 'package:elkitap/modules/profile/widgets/model/menu_item.dart';
import 'package:elkitap/modules/paymant/widget/paymant_bottom_sheet.dart';
import 'package:elkitap/modules/search/controllers/search_controller.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/modules/store/controllers/all_geners_controller.dart';
import 'package:elkitap/modules/store/controllers/authors_controller.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';
import 'package:elkitap/modules/store/controllers/collections_controller.dart';
import 'package:elkitap/modules/store/controllers/pro_readers_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:restart_app/restart_app.dart';

class SettingsList extends StatefulWidget {
  const SettingsList({super.key});

  @override
  State<SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> {
  String selectedTheme = 'light'.tr;
  String selectedLanguage = 'Turkmen';
  final _box = GetStorage();
  final _languageKey = 'selectedLanguage';
  late final ThemeController _themeController;
  late final TokenManager tokenManager;

  void _showUserAgreementBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CustomBottomSheet(
        documentType: LegalDocumentType.userAgreement,
      ),
    );
  }

  void _showPrivacyPolicyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CustomBottomSheet(
        documentType: LegalDocumentType.privacyPolicy,
      ),
    );
  }

  void _showHelpBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HelpAndSupportBottomSheet(),
    );
  }

  void _showPaymantHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PaymentHistoryBottomSheet(),
    );
  }

  @override
  void initState() {
    super.initState();

    _themeController = Get.find<ThemeController>();
    tokenManager = Get.find<TokenManager>();
    // final PaymentController paymentController = Get.find<PaymentController>();

    _initializeSelectedTheme(_themeController.themeMode);

    _loadSelectedLanguage();
  }

  void _loadSelectedLanguage() {
    final storedLanguage = _box.read(_languageKey);
    if (storedLanguage != null) {
      selectedLanguage = storedLanguage;
    } else {
      _box.write(_languageKey, selectedLanguage);
    }
  }

  void _initializeSelectedTheme(ThemeMode mode) {
    if (mode == ThemeMode.light) {
      selectedTheme = 'light'.tr;
    } else if (mode == ThemeMode.dark) {
      selectedTheme = 'dark'.tr;
    } else {
      selectedTheme = 'match_devices'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? Colors.black : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'settings'.tr,
              style: TextStyle(fontSize: 16, fontFamily: StringConstants.SFPro, color: Colors.grey),
            ),
          ),
          Container(
            height: 1,
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.dividerColor : Colors.grey[200],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  // 1. Payment History
                  Obx(() {
                    final paymentController = Get.find<PaymentController>();
                    if (paymentController.isPaymentActive.value) {
                      return const SizedBox.shrink();
                    }
                    return _buildSettingsItem(
                      context,
                      index: 0,
                      title: 'paymentHistory'.tr,
                      trailingText: null,
                      onTapDown: (details) => _showPaymantHistorySheet(context),
                      isLast: false,
                    );
                  }),

                  // 2. Theme
                  _buildSettingsItem(
                    context,
                    index: 1,
                    title: 'theme'.tr,
                    trailingText: selectedTheme,
                    onTapDown: (details) => _showThemeMenu(context, details.globalPosition),
                    isLast: false,
                  ),

                  // 3. Language
                  _buildSettingsItem(
                    context,
                    index: 2,
                    title: 'language'.tr,
                    trailingText: selectedLanguage,
                    onTapDown: (details) => _showLanguageMenu(context, details.globalPosition),
                    isLast: false,
                  ),

                  // 4. Help and Support
                  _buildSettingsItem(
                    context,
                    index: 3,
                    title: 'help_and_support'.tr,
                    trailingText: null,
                    onTapDown: (details) => _showHelpBottomSheet(context),
                    isLast: false,
                  ),

                  // 5. Legal Terms of Use
                  _buildSettingsItem(
                    context,
                    index: 4,
                    title: 'legal_terms_of_use'.tr,
                    trailingText: null,
                    onTapDown: (details) => _showUserAgreementBottomSheet(context),
                    isLast: false,
                  ),

                  // 6. Privacy and Policy
                  _buildSettingsItem(
                    context,
                    index: 5,
                    title: 'privacy_and_policy'.tr,
                    trailingText: null,
                    onTapDown: (details) => _showPrivacyPolicyBottomSheet(context),
                    isLast: false,
                  ),

                  _buildSettingsItem(
                    context,
                    index: 6,
                    title: 'sign_out'.tr,
                    trailingText: null,
                    onTapDown: (details) => _showLogoutDialog(context),
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    context,
                    index: 7,
                    title: 'delete_account'.tr,
                    trailingText: null,
                    onTapDown: (details) => _showDeleteAccountDialog(context),
                    iconName: 'd6.svg',
                    textColor: Colors.red,
                    iconColor: Colors.red,
                    isLast: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required int index,
    required String title,
    required String? trailingText,
    required Function(TapDownDetails) onTapDown,
    required bool isLast,
    String? iconName,
    Color? textColor,
    Color? iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTapDown: onTapDown,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CustomIcon(
              title: iconName != null ? 'assets/icons/$iconName' : 'assets/icons/p${index + 1}.svg',
              height: 24,
              width: 24,
              color: iconColor ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontFamily: StringConstants.SFPro,
                color: textColor,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (trailingText != null)
                  Text(
                    trailingText,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontFamily: StringConstants.SFPro,
                    ),
                  ),
                Icon(Icons.chevron_right, color: Colors.grey[350]),
              ],
            ),
          ),
        ),
        isLast
            ? const SizedBox.shrink()
            : Container(
                height: 1,
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.dividerColor : Colors.grey[200],
              ),
      ],
    );
  }

  void _showThemeMenu(BuildContext context, Offset position) async {
    final items = [
      MenuItem(title: 'light'.tr, value: 'Light', icon: Icons.wb_sunny_outlined),
      MenuItem(title: 'dark'.tr, value: 'Dark', icon: Icons.nightlight_round),
      MenuItem(title: 'match_devices'.tr, value: 'System', icon: Icons.contrast),
    ];

    // Convert selectedTheme to the corresponding value
    final String currentValue = selectedTheme == 'light'.tr
        ? 'Light'
        : selectedTheme == 'dark'.tr
            ? 'Dark'
            : 'System';

    final result = await showUniversalMenu(
      context: context,
      position: position,
      items: items,
      selectedValue: currentValue,
      showIcons: true,
    );

    if (result != null) {
      setState(() {
        selectedTheme = result == 'Light'
            ? 'light'.tr
            : result == 'Dark'
                ? 'dark'.tr
                : 'match_devices'.tr;
      });

      final themeController = Get.find<ThemeController>();

      // Use setTheme instead of changeTheme
      switch (result) {
        case 'Light':
          themeController.setTheme(ThemeMode.light);
          break;
        case 'Dark':
          themeController.setTheme(ThemeMode.dark);
          break;
        case 'System':
          themeController.setTheme(ThemeMode.system);
          break;
      }
    }
  }

  void _showLanguageMenu(BuildContext context, Offset position) async {
    final items = [
      MenuItem(title: 'Türkmençe', value: 'Türkmençe'),
      MenuItem(title: 'Русский', value: 'Русский'),
      MenuItem(title: 'English', value: 'English'),
    ];

    final result = await showUniversalMenu(
      context: context,
      position: position,
      items: items,
      selectedValue: selectedLanguage,
      showIcons: false,
    );

    if (result != null && result != selectedLanguage) {
      setState(() {
        selectedLanguage = result;
      });

      final TranslationService translationService = Get.find<TranslationService>();
      translationService.changeLocale(result);

      _box.write(_languageKey, result);

      // Wait for locale to update completely
      await Future.delayed(const Duration(milliseconds: 300));

      // Refresh user data with new language (without clearing token)
      try {
        final authController = Get.find<AuthController>();
        if (tokenManager.getToken() != null) {
          await authController.getMe();
        }
      } catch (_) {}

      Get.put(AllGenresController());
      Get.put(AuthorController());
      Get.put(SearchResultsController());
      Get.put(BooksDetailController());
      Get.put(GetAllBooksController());
      Get.put(ProfessionalReadsController());
      Get.put(DownloadController());
      Get.put(BookCollectionController());
      Get.put(LibraryMainController());
      Get.put(NotesController());
      Get.put(ConnectionController());
      Get.put(ContactsController());
      Get.put(PromoCodeController());

      // Wait a bit for controllers to be initialized
      await Future.delayed(const Duration(milliseconds: 100));

      // Restart the entire app to apply language changes and refetch all data
      // This ensures all API calls use the new content-language header
      Restart.restartApp();
    }
  }

  Future<String?> showUniversalMenu({
    required BuildContext context,
    required Offset position,
    required List<MenuItem> items,
    required String selectedValue,
    bool showIcons = false,
  }) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<PopupMenuEntry<String>> menuItems = [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isSelected = selectedValue == item.value;

      menuItems.add(
        PopupMenuItem<String>(
          value: item.value,
          height: 48,
          child: Row(
            children: [
              // Check icon on the left (only for theme with showIcons=true)
              if (showIcons && isSelected)
                Icon(
                  Icons.check,
                  size: 20,
                  color: isDark ? Colors.white : Colors.black,
                )
              else if (showIcons)
                const SizedBox(width: 20),
              if (showIcons) const SizedBox(width: 12),
              // Title
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: StringConstants.SFPro,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Icon on the right (for theme icons or language check)
              if (showIcons && item.icon != null)
                Icon(
                  item.icon,
                  size: 20,
                  color: isDark ? Colors.white : Colors.black,
                )
              else if (!showIcons && isSelected)
                Icon(
                  Icons.check,
                  size: 20,
                  color: isDark ? Colors.white : Colors.black,
                )
              else
                const SizedBox(width: 20),
            ],
          ),
        ),
      );

      // Add divider if not the last item
      if (i < items.length - 1) {
        menuItems.add(
          const PopupMenuDivider(height: 1),
        );
      }
    }

    return await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      color: isDark ? Colors.black : Colors.white,
      elevation: 8,
      items: menuItems,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
            'do_you_really_want_to_log_out'.tr,
            style: TextStyle(
              fontFamily: StringConstants.SFPro,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          content: Text(
            'log_out_warning'.tr,
            style: TextStyle(
              fontFamily: StringConstants.SFPro,
              fontSize: 13,
            ),
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'no'.tr,
                style: TextStyle(
                  fontFamily: StringConstants.SFPro,
                  color: CupertinoColors.activeBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
                tokenManager.clearToken();
                Get.offAll(() => const BottomNavScreen());
              },
              isDestructiveAction: true,
              child: Text(
                'yes'.tr,
                style: TextStyle(
                  fontFamily: StringConstants.SFPro,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
            'do_you_really_want_to_delete_account'.tr,
            style: TextStyle(
              fontFamily: StringConstants.SFPro,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          content: Text(
            'delete_account_warning'.tr,
            style: TextStyle(
              fontFamily: StringConstants.SFPro,
              fontSize: 13,
            ),
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'no'.tr,
                style: TextStyle(
                  fontFamily: StringConstants.SFPro,
                  color: CupertinoColors.activeBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();

                tokenManager.clearToken();
                Get.offAll(() => const BottomNavScreen());
              },
              isDestructiveAction: true,
              child: Text(
                'yes'.tr,
                style: TextStyle(
                  fontFamily: StringConstants.SFPro,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
