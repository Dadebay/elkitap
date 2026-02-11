import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/modules/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AccountInfoCard extends StatelessWidget {
  const AccountInfoCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset('assets/images/a2.png'),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'account'.tr,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontFamily: StringConstants.SFPro,
              ),
            ),
            Obx(() {
              final authController = Get.find<AuthController>();
              final phone = authController.currentUser.value?.phone ?? '+993';
              return Text(
                phone,
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: StringConstants.SFPro,
                  fontWeight: FontWeight.w600,
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
