import 'dart:ui';

import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/modules/library/controllers/suggestion_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuggestContentWidget extends StatelessWidget {
  const SuggestContentWidget({super.key});

  void _showSuggestContentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SuggestContentDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1c1c1e) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'suggest_content'.tr,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: StringConstants.GilroyBold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'suggest_content_description'.tr,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontFamily: StringConstants.SFPro,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showSuggestContentDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5A3C),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/book_sugges.png',
                    height: 28,
                    width: 28,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'suggest_content_button'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: StringConstants.SFPro,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SuggestContentDialog extends StatelessWidget {
  const SuggestContentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SuggestionController>(
      builder: (controller) => SuggestContentDialogBody(controller: controller),
    );
  }
}

class SuggestContentDialogBody extends StatelessWidget {
  final SuggestionController controller;

  const SuggestContentDialogBody({
    super.key,
    required this.controller,
  });

  Future<void> _submitSuggestion(BuildContext context) async {
    final success = await controller.submitSuggestion();
    if (success && context.mounted) {
      Navigator.pop(context);
      _showSuccessDialog(context);
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2E) : Colors.white.withOpacity(0.70),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5A3C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'content_suggested'.tr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: StringConstants.GilroyBold,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'content_suggested_description'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Color(0xFF6B6B6B),
                        fontFamily: StringConstants.SFPro,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: controller.formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[600] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'suggest_content'.tr,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: StringConstants.GilroyBold,
                        color: textColor,
                      ),
                    ),
                  ),
                  Text(
                    'title_required'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: StringConstants.SFPro,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller.titleController,
                    maxLength: 255,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'enter_title_of_content'.tr,
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                        fontFamily: StringConstants.SFPro,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF5A3C),
                          width: 2,
                        ),
                      ),
                      counterStyle: TextStyle(
                        color: subtitleColor,
                        fontSize: 12,
                        fontFamily: StringConstants.SFPro,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'title_required_validation'.tr;
                      }
                      return null;
                    },
                  ),
                  Text(
                    'author'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: StringConstants.SFPro,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller.authorController,
                    maxLength: 255,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'enter_author'.tr,
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                        fontFamily: StringConstants.SFPro,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF5A3C),
                          width: 2,
                        ),
                      ),
                      counterStyle: TextStyle(
                        color: subtitleColor,
                        fontSize: 12,
                        fontFamily: StringConstants.SFPro,
                      ),
                    ),
                  ),
                  Text(
                    'comment_additional'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: StringConstants.SFPro,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller.commentController,
                    maxLength: 500,
                    maxLines: 5,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'enter_your_comment'.tr,
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                        fontFamily: StringConstants.SFPro,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF5A3C),
                          width: 2,
                        ),
                      ),
                      counterStyle: TextStyle(
                        color: subtitleColor,
                        fontSize: 12,
                        fontFamily: StringConstants.SFPro,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: controller.isLoading.value ? null : () => _submitSuggestion(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5A3C),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            disabledBackgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300],
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'suggest_content_button'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: StringConstants.SFPro,
                                  ),
                                ),
                        ),
                      )),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
