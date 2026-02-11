import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/modules/paymant/controller/payment_controller.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';
import 'package:elkitap/utils/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final BooksDetailController controller;
  final PaymentController paymentController;
  final Color accent;
  final BuildContext context;

  const BookDetailAppBar({
    required this.controller,
    required this.paymentController,
    required this.accent,
    required this.context,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
      elevation: 0,
      leadingWidth: 45,
      centerTitle: true,
      leading: _buildCloseButton(context),
      title: paymentController.isPaymentActive.value ? SizedBox(width: 60) : _buildMediaTypeToggle(context),
      automaticallyImplyLeading: false,
      actions: [
        _buildAddToLibraryButton(context),
        _buildMoreOptionsButton(context),
      ],
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, size: 18),
      ),
    );
  }

  Widget _buildMediaTypeToggle(BuildContext context) {
    return Obx(() {
      if (!controller.hasBothVersions()) {
        return const SizedBox.shrink();
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Container(
        height: 32,
        width: 126,
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildToggleButton(
              context: context,
              label: "media_type_text_t".tr,
              isSelected: !controller.isAudio.value,
              onTap: controller.toggleToText,
            ),
            _buildToggleButton(
              context: context,
              label: "media_type_audio_t".tr,
              isSelected: controller.isAudio.value,
              onTap: controller.toggleToAudio,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildToggleButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Container(
          width: 60,
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? Colors.grey[700] : Colors.grey[200]) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontFamily: StringConstants.SFPro,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddToLibraryButton(BuildContext context) {
    return Obx(() => GestureDetector(
          onTap: () async {
            controller.isAuth.value = true;
            await controller.toggleWantToRead();
            if (controller.isAuth.value) {
              DialogUtils.showAddedDialog(
                context,
                controller.isAddedToWantToRead.value,
                controller.isAudio.value,
              );
            }
          },
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: controller.isAddedToWantToRead.value
                  ? accent
                  : Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]
                      : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              controller.isAddedToWantToRead.value ? Icons.check : Icons.add,
              size: 18,
              color: controller.isAddedToWantToRead.value
                  ? Colors.white
                  : Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black54,
            ),
          ),
        ));
  }

  Widget _buildMoreOptionsButton(BuildContext context) {
    return GestureDetector(
      onTap: () => DialogUtils.showOptionsPopupMenu(context, controller),
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.only(left: 8, right: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: const Icon(size: 18, Icons.more_horiz),
      ),
    );
  }
}
