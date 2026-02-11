import 'package:elkitap/core/constants/string_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? leadingText;
  final Color backgroundColor;
  final Color textColor;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.leadingText,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          showBackButton
              ? Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 8,
                      ),
                      child: GestureDetector(
                          onTap: () async {
                            await Future.delayed(Duration.zero);
                            Get.back();
                          },
                          child: Icon(Icons.arrow_back_ios)),
                    ),
                    if (leadingText != null)
                      Text(
                        leadingText!,
                        style: TextStyle(
                          fontSize: 17,
                          fontFamily: StringConstants.SFPro,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                )
              : SizedBox(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: StringConstants.SFPro,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 80),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
