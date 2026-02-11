import 'package:cached_network_image/cached_network_image.dart';
import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/modules/library/model/note_item_model.dart';
import 'package:elkitap/utils/dialog_utils.dart';
import 'package:flutter/material.dart';

import '../../../data/network/api_edpoints.dart';

class NoteCard extends StatelessWidget {
  final NoteItem note;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onBookTap;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String? baseUrl;

  const NoteCard({
    Key? key,
    required this.note,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onBookTap,
    required this.onShare,
    required this.onEdit,
    required this.onDelete,
    this.baseUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Opacity(
        opacity: isSelectionMode && !isSelected ? 0.4 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1F1F1F) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildBookImage(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: StringConstants.SFPro,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelectionMode)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.grey : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? AppColors.mainColor : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? AppColors.mainColor : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.more_horiz),
                        onPressed: () => DialogUtils.showIOSStylePopup(
                          context,
                          onBookTap,
                          onShare,
                          onEdit,
                          onDelete,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Kullanıcının notu (eğer varsa)
                if (_extractUserNote(note.comment).isNotEmpty)
                  Container(
                    padding: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: note.color, width: 4),
                      ),
                    ),
                    child: Text(
                      _extractSelectedText(note.comment),
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: StringConstants.GilroyRegular,
                      ),
                    ),
                  ),
                if (_extractUserNote(note.comment).isNotEmpty) const SizedBox(height: 12),
                // Seçilen metin (kalın yazı)
                Text(
                  _extractUserNote(note.comment),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  note.date,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookImage() {
    if (note.bookImage != null && note.bookImage!.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey[300],
        ),
        child: note.bookImage != null
            ? CachedNetworkImage(
                imageUrl: '${ApiEndpoints.imageBaseUrl}${note.bookImage}',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => CustomIcon(
                  title: IconConstants.libraryFilled,
                  height: 24,
                  width: 24,
                  color: Colors.black,
                ),
              )
            : CustomIcon(
                title: IconConstants.libraryFilled,
                height: 24,
                width: 24,
                color: Colors.black,
              ),
      );
    }
    return Container(
      width: 40,
      height: 40,
      child: CustomIcon(
        title: 'assets/icons/library_filled.svg',
        height: 24,
        width: 24,
        color: Colors.black,
      ),
    );
  }

  /// Extract user's note from comment (after \n\n if exists)
  String _extractUserNote(String comment) {
    if (comment.contains('\n\n')) {
      final parts = comment.split('\n\n');
      if (parts.length > 1) {
        return parts.last.trim();
      }
    }
    return '';
  }

  /// Extract selected text from comment (before \n\n if exists)
  String _extractSelectedText(String comment) {
    if (comment.contains('\n\n')) {
      final parts = comment.split('\n\n');
      return parts.first.trim();
    }
    return comment;
  }
}
