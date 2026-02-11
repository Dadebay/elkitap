import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NoResultsWidget extends StatelessWidget {
  const NoResultsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomIcon(title: IconConstants.search, height: 32, width: 32, color: Colors.black),
          const SizedBox(height: 16),
          Text(
            'no_results_search'.tr,
            style: TextStyle(
              fontSize: 20,
              fontFamily: StringConstants.GilroyRegular,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'try_different_keywords'.tr,
            style: TextStyle(
              fontSize: 13,
              fontFamily: StringConstants.GilroyRegular,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
