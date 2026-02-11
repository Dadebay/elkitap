import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ignore: must_be_immutable
class BottomNavbarButton extends StatefulWidget {
  final Function() onTapp;
  final int selectedIndex;
  final int index;
  final bool icon;

  const BottomNavbarButton({
    required this.onTapp,
    required this.selectedIndex,
    required this.index,
    required this.icon,
    super.key,
  });

  @override
  State<BottomNavbarButton> createState() => _BottomNavbarButtonState();
}

class _BottomNavbarButtonState extends State<BottomNavbarButton> {
  List iconsLight = [
    CustomIcon(
      title: 'assets/icons/library_filled.svg',
      height: 32,
      width: 32,
      color: AppColors.disableColor,
    ),
    CustomIcon(
      title: 'assets/icons/bag.svg',
      height: 32,
      width: 32,
      color: AppColors.disableColor,
    ),
    CustomIcon(
      title: 'assets/icons/search.svg',
      height: 32,
      width: 32,
      color: AppColors.disableColor,
    ),
  ];

  List iconsBold = [
    CustomIcon(
      title: 'assets/icons/library_filled.svg',
      height: 32,
      width: 32,
      color: AppColors.mainColor,
    ),
    CustomIcon(
      title: 'assets/icons/bag.svg',
      height: 32,
      width: 32,
      color: AppColors.mainColor,
    ),
    CustomIcon(
      title: 'assets/icons/search_2.svg',
      height: 32,
      width: 32,
      color: AppColors.mainColor,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    List<String> title = ['myLibrary'.tr, 'bookStore'.tr, 'search'.tr];

    bool isSelected = widget.index == widget.selectedIndex;

    return GestureDetector(
      onTap: widget.onTapp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        height: 70, // fixed height
        width: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, 
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              widget.icon
                  ? Icon(
                      isSelected ? Icons.add : Icons.local_activity,
                      color: isSelected
                          ? AppColors.mainColor
                          : AppColors.disableColor,
                    )
                  : (isSelected
                      ? iconsBold[widget.index]
                      : iconsLight[widget.index]),
              const SizedBox(height: 4),
              Text(
                title[widget.index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      isSelected ? AppColors.mainColor : AppColors.disableColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontFamily: StringConstants.SFPro,
                  fontSize: 12,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
