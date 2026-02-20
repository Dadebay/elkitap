import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/navigation/custom_appbar.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/profile/widgets/profile_card_user.dart';
import 'package:elkitap/modules/profile/widgets/settings_list.dart';
import 'package:elkitap/modules/paymant/widget/subscription_expired_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:elkitap/modules/auth/controllers/auth_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController _authController = Get.find<AuthController>();
  bool isSubscribed = false;
  int daysLeft = 35;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await _authController.getMe();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: CustomAppBar(
        title: '',
        showBackButton: true,
        leadingText: 'leading_text'.tr,
        backgroundColor: isDark ? Color(0xff181818) : Colors.white,
      ),
      body: Obx(() => _authController.isLoading.value
          ? const Center(child: LoadingWidget(removeBackWhite: true))
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      color: isDark ? Color(0xff181818) : Colors.white,
                      padding: const EdgeInsets.only(left: 32, right: 32, bottom: 10),
                      child: Text(
                        "profile".tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: StringConstants.GilroyRegular,
                          fontSize: 34,
                        ),
                      ),
                    ),
                    Container(
                      color: isDark ? Colors.black : Colors.white,
                      // margin: EdgeInsets.only(top: 15),
                      padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(top: 15, bottom: 10),
                      child: Obx(() {
                        final user = _authController.currentUser.value;

                        return ProfileCardUser(
                          user: user,
                          onSubscribe: () async {
                            final result = await showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (context) => const SubscriptionExpiredSheet(),
                            );

                            if (result == true) {
                              await _loadUserData();
                            }
                          },
                        );
                      }),
                    ),
                    const SettingsList(),
                  ],
                ),
              ),
            )),
    );
  }
}
