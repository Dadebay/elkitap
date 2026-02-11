import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/core/utils/performance_utils.dart';
import 'package:elkitap/modules/library/controllers/library_controller.dart';
import 'package:elkitap/modules/store/views/store_detail_view.dart';
import 'package:elkitap/modules/store/widgets/book_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';
import 'package:get/get.dart';

class BookListItem extends StatefulWidget {
  final Book book;
  final ReadingListController controller;
  final double? discountPercentage;

  const BookListItem({
    super.key,
    required this.book,
    required this.controller,
    required this.discountPercentage,
  });

  @override
  State<BookListItem> createState() => _BookListItemState();
}

class _BookListItemState extends State<BookListItem> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = widget.controller.isSelected(widget.book.id.toString());
      final isInSelectionMode = widget.controller.selectedBooks.isNotEmpty;

      return GestureDetector(
        onTap: () {
          if (isInSelectionMode) {
            widget.controller.toggleSelection(widget.book.id.toString());
          } else {
            Get.to(() => BookDetailView(
                  book: widget.book,
                ));
          }
        },
        onLongPress: () {
          widget.controller.toggleSelection(widget.book.id.toString());
        },
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(),
              child: Row(
                children: [
                  if (isInSelectionMode)
                    Container(
                      decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color.fromARGB(255, 223, 220, 220), width: 1)),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? AppColors.mainColor : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? AppColors.mainColor : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                        ),
                      ),
                    ),
                  if (isInSelectionMode) const SizedBox(width: 16),
                  SizedBox(
                    height: 140,
                    child: Stack(
                      children: [
                        Container(
                          width: 95,
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: () {
                            String? imageToUse;
                            if (widget.book.withAudio && widget.book.audioImage != null && widget.book.audioImage!.isNotEmpty) {
                              imageToUse = widget.book.audioImage;
                            } else {
                              imageToUse = widget.book.image;
                            }

                            if (imageToUse != null) {
                              return OptimizedImage(
                                imageUrl: '${ApiEndpoints.imageBaseUrl}$imageToUse',
                                width: 95,
                                height: 140,
                                fit: BoxFit.cover,
                                placeholder: Container(
                                  color: Colors.grey[100],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                                errorWidget: Container(
                                  color: Colors.grey[100],
                                  child: Center(
                                    child: CustomIcon(
                                      title: IconConstants.libraryFilled,
                                      height: 32,
                                      width: 32,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return Container(
                                color: Colors.grey[100],
                                child: Center(
                                  child: CustomIcon(
                                    title: IconConstants.libraryFilled,
                                    height: 32,
                                    width: 32,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              );
                            }
                          }(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.book.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: StringConstants.SFPro,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.book.authors.first.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: StringConstants.SFPro,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (widget.discountPercentage != null && widget.discountPercentage! * 100 > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: DiscountBadgeMini(
                              percentage: (widget.discountPercentage! * 100).toInt(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isInSelectionMode && !isSelected)
              Positioned.fill(
                child: Container(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.55),
                ),
              ),
          ],
        ),
      );
    });
  }
}
