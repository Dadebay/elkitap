import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmptyCollectionWidget extends StatelessWidget {
  final String descriptionKey;

  const EmptyCollectionWidget({Key? key, required this.descriptionKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIcon(title: IconConstants.libraryFilled, height: 48, width: 48, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
            const SizedBox(height: 32),
            Text(
              'emptyCollection'.tr,
              style: const TextStyle(
                fontSize: 24,
                fontFamily: StringConstants.SFPro,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              descriptionKey.tr,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontFamily: StringConstants.SFPro,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
