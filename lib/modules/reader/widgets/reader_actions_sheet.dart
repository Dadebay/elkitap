// ignore_for_file: deprecated_member_use

import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReaderActionsSheet extends StatelessWidget {
  final VoidCallback? onBookDescription;
  final VoidCallback onSaveToLibrary;
  final VoidCallback onMarkAsFinished;
  final bool isAddedToShelf;
  final bool isMarkedAsFinished;

  const ReaderActionsSheet({
    this.onBookDescription,
    required this.onSaveToLibrary,
    required this.onMarkAsFinished,
    this.isAddedToShelf = false,
    this.isMarkedAsFinished = false,
    super.key,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onBookDescription,
    required VoidCallback onSaveToLibrary,
    required VoidCallback onMarkAsFinished,
    bool isAddedToShelf = false,
    bool isMarkedAsFinished = false,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Stack(
        children: [
          Positioned(
            top: 70,
            right: 16,
            child: ReaderActionsSheet(
              onBookDescription: onBookDescription,
              onSaveToLibrary: onSaveToLibrary,
              onMarkAsFinished: onMarkAsFinished,
              isAddedToShelf: isAddedToShelf,
              isMarkedAsFinished: isMarkedAsFinished,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),

            // Book description option
            if (onBookDescription != null)
              _buildMenuOption(
                context: context,
                iconPath: IconConstants.bookdescription,
                title: 'book_description'.tr.isNotEmpty ? 'book_description'.tr : 'Book description',
                onTap: () {
                  Navigator.pop(context);
                  onBookDescription!();
                },
              ),

            if (onBookDescription != null) _buildDivider(context),

            // Save to My Books option
            _buildMenuOption(
              context: context,
              iconPath: IconConstants.savemybooks,
              title: 'save_to_my_books'.tr.isNotEmpty ? 'save_to_my_books'.tr : 'Save to My Books',
              onTap: () {
                Navigator.pop(context);
                onSaveToLibrary();
              },
              isActive: isAddedToShelf,
            ),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required BuildContext context,
    required String iconPath,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use accent color (similar to BookDetailAppBar) or just theme color if active?
    // BookDetailAppBar uses accent color for background. Here we just change icon.
    // Let's use a green checkmark or theme color checkmark.
    // Since we don't have access to accent color directly here easily without context lookup or passing it,
    // we'll assume standard icon color but changed to tick.

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: StringConstants.SFPro,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Icon on right
            if (isActive)
              Icon(
                Icons.check,
                size: 22,
                color: isDark ? Colors.white : Colors.black87,
              )
            else
              Image.asset(
                iconPath,
                height: iconPath == IconConstants.savemybooks ? 22 : 18,
                width: iconPath == IconConstants.savemybooks ? 22 : 18,
                color: isDark ? Colors.white : Colors.black87,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: isDark ? Colors.grey[800] : Colors.grey[300],
      ),
    );
  }
}
