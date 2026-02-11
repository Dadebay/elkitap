import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/library/views/library_view.dart';
import 'package:elkitap/modules/search/views/search_view.dart';
import 'package:elkitap/modules/store/views/store_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int selectedIndex = 1;
  bool showSplash = true;

  @override
  void dispose() {
    super.dispose();
  }

  final List<Widget> page = [MyLibraryViewScreen(), StoreViewScreen(), SearchViewScreen()];

  @override
  void initState() {
    super.initState();
    // Hide splash animation after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          showSplash = false;
        });
      }
    });
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.mainColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.exit_to_app_rounded,
                      size: 32,
                      color: AppColors.mainColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'do_you_want_to_exit'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: StringConstants.SFPro,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'exit_app_message'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: StringConstants.SFPro,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(false),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'no'.tr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: StringConstants.SFPro,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Exit Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop(true);
                            SystemNavigator.pop();
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.mainColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'yes'.tr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: StringConstants.SFPro,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          // Main Scaffold with content and bottom nav
          Scaffold(
            body: IndexedStack(index: selectedIndex, children: page),
            bottomNavigationBar: Theme(
              data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
              child: BottomNavigationBar(
                currentIndex: selectedIndex,
                onTap: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                selectedItemColor: AppColors.mainColor,
                unselectedItemColor: AppColors.disableColor,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontFamily: StringConstants.SFPro),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontFamily: StringConstants.SFPro),
                items: [
                  BottomNavigationBarItem(
                    icon: CustomIcon(
                      title: selectedIndex == 0 ? IconConstants.libraryFilled : IconConstants.libraryFilledG,
                      height: 32,
                      width: 32,
                      color: selectedIndex == 0 ? AppColors.mainColor : AppColors.disableColor,
                    ),
                    label: 'myLibrary'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: CustomIcon(
                      title: selectedIndex == 1 ? IconConstants.bagFilledG : IconConstants.bag,
                      height: 32,
                      width: 32,
                      color: selectedIndex == 1 ? AppColors.mainColor : AppColors.disableColor,
                    ),
                    label: 'bookStore'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: CustomIcon(
                      title: selectedIndex == 2 ? IconConstants.searchActive : IconConstants.search,
                      height: 32,
                      width: 32,
                      color: selectedIndex == 2 ? AppColors.mainColor : AppColors.disableColor,
                    ),
                    label: 'search'.tr,
                  ),
                ],
              ),
            ),
          ),
          if (showSplash)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: showSplash ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Lottie.asset(
                        'assets/animations/Artboard1.json',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
