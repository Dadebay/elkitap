import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/modules/notifications/controllers/notification_controller.dart';
import 'package:elkitap/modules/notifications/models/suggestion_model.dart';
import 'package:elkitap/modules/store/views/store_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationItem extends StatelessWidget {
  final SuggestionModel suggestion;

  const NotificationItem({
    super.key,
    required this.suggestion,
  });

  String _getNotificationTitle() {
    if (suggestion.status == SuggestionStatus.COMPLETED) {
      return 'notification_content_added'.tr;
    } else if (suggestion.status == SuggestionStatus.REJECTED) {
      return 'notification_content_declined'.tr;
    }
    return suggestion.name;
  }

  String _getNotificationMessage() {
    final locale = Get.locale;
    final languageCode = locale?.languageCode ?? 'tk';
    final bookName = suggestion.getBookName(languageCode);
    final author = suggestion.author;

    if (suggestion.status == SuggestionStatus.COMPLETED) {
      return 'notification_content_added_message'.tr.replaceAll('@author', author).replaceAll('@book', bookName);
    } else if (suggestion.status == SuggestionStatus.REJECTED) {
      return 'notification_content_declined_message'.tr.replaceAll('@book', bookName);
    }
    return suggestion.description;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDeclined = suggestion.status == SuggestionStatus.REJECTED;

    return Obx(() {
      final isRead = controller.isRead(suggestion.id);

      return Material(
        color: isDark ? const Color(0xFF000000) : Colors.white,
        child: InkWell(
          onTap: () {
            controller.markAsRead(suggestion.id);
            if (suggestion.bookId != null) {
              Get.to(
                () => BookDetailView(bookId: suggestion.bookId!),
                transition: Transition.rightToLeft,
                duration: const Duration(milliseconds: 300),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isRead ? (isDark ? const Color(0xFF000000) : Colors.white) : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDeclined ? (isDark ? Colors.grey[800] : Colors.grey[200]) : const Color(0xFFFF5A3C).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDeclined
                        ? Icon(
                            Icons.info_outline,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            size: 20,
                          )
                        : Image.asset(
                            'assets/images/book_sugges.png',
                            width: 20,
                            height: 20,
                            color: const Color(0xFFFF5A3C),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _getNotificationTitle(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: StringConstants.SFPro,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 6, left: 8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF5A3C),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getNotificationMessage(),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          fontFamily: StringConstants.SFPro,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            suggestion.createdAt.contains('T') ? suggestion.createdAt.split('T').last.substring(0, 5) : suggestion.createdAt,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[600] : Colors.grey[500],
                              fontFamily: StringConstants.SFPro,
                            ),
                          ),
                          Text(
                            "  •  ",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[600] : Colors.grey[500],
                              fontFamily: StringConstants.SFPro,
                            ),
                          ),
                          Text(
                            suggestion.createdAt.contains('T') ? suggestion.createdAt.split('T').first : suggestion.createdAt,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[600] : Colors.grey[500],
                              fontFamily: StringConstants.SFPro,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
