import 'package:elkitap/core/constants/string_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubscriptionHeader extends StatelessWidget {
  final VoidCallback onBack;

  const SubscriptionHeader({
    Key? key,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: onBack,
        ),
        Text(
          'leading_text'.tr,
          style: TextStyle(
            fontSize: 18,
            fontFamily: StringConstants.SFPro,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}
