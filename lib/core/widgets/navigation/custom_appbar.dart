import 'package:elkitap/core/constants/string_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? leadingText;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.leadingText,
    this.backgroundColor,
    this.textColor,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedBackgroundColor = backgroundColor ?? colorScheme.surface;
    final resolvedTextColor = textColor ?? colorScheme.onSurface;
    final leadingWidth = leadingText != null ? 130.0 : 56.0;

    return AppBar(
      elevation: 0,
      backgroundColor: resolvedBackgroundColor,
      iconTheme: IconThemeData(color: resolvedTextColor),
      automaticallyImplyLeading: false,
      centerTitle: true,
      titleSpacing: 0,
      leadingWidth: showBackButton ? leadingWidth : 0,
      leading: showBackButton
          ? GestureDetector(
              onTap: () async {
                await Future.delayed(Duration.zero);
                Get.back();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Icon(
                      Icons.arrow_back_ios,
                      size: 18,
                    ),
                  ),
                  if (leadingText != null)
                    Expanded(
                      child: Text(
                        leadingText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: StringConstants.SFPro,
                          fontWeight: FontWeight.w500,
                          color: resolvedTextColor,
                        ),
                      ),
                    ),
                ],
              ),
            )
          : const SizedBox.shrink(),
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontFamily: StringConstants.SFPro,
            fontWeight: FontWeight.bold,
            color: resolvedTextColor,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
