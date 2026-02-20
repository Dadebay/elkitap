import 'package:elkitap/modules/paymant/controller/payment_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomTabBar extends StatefulWidget {
  final Function(int) onTabChanged;

  const CustomTabBar({super.key, required this.onTabChanged});

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          _TabItem(
            text: "books_t".tr,
            isSelected: selectedIndex == 0,
            onTap: () {
              setState(() {
                selectedIndex = 0;
              });
              widget.onTabChanged(0);
            },
          ),
          Obx(() {
            final paymentController = Get.find<PaymentController>();
            if (!paymentController.isPaymentActive.value) {
              return const SizedBox.shrink();
            }
            return Row(
              children: [
                const SizedBox(width: 14),
                _TabItem(
                  text: "audio_book".tr,
                  isSelected: selectedIndex == 1,
                  onTap: () {
                    setState(() {
                      selectedIndex = 1;
                    });
                    widget.onTabChanged(1);
                  },
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black
                  : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 1.5,
            width: text.length * 13.0,
            decoration: BoxDecoration(
              color: isSelected ? Colors.grey[300] : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
