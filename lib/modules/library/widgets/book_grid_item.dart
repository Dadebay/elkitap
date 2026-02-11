import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/core/utils/performance_utils.dart';
import 'package:elkitap/modules/library/controllers/library_controller.dart';
import 'package:elkitap/modules/store/views/store_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';
import 'package:get/get.dart';

class BookGridItem extends StatefulWidget {
  final Book book;
  final ReadingListController controller;
  final double? discountPercentage;

  const BookGridItem({
    super.key,
    required this.book,
    required this.controller,
    this.discountPercentage,
  });

  @override
  State<BookGridItem> createState() => _BookGridItemState();
}

class _BookGridItemState extends State<BookGridItem> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.controller.selectedBooks.isNotEmpty) {
          widget.controller.toggleSelection(widget.book.id.toString());
          setState(() {});
        } else {
          Get.to(() => BookDetailView(book: widget.book));
        }
      },
      onLongPress: () {
        widget.controller.toggleSelection(widget.book.id.toString());
      },
      child: Obx(() {
        final isSelected =
            widget.controller.isSelected(widget.book.id.toString());
        final isInSelectionMode = widget.controller.selectedBooks.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  height: widget.book.withAudio ? 150 : 220,
                  width: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: () {
                    String? imageToUse;
                    if (widget.book.withAudio &&
                        widget.book.audioImage != null &&
                        widget.book.audioImage!.isNotEmpty) {
                      imageToUse = widget.book.audioImage;
                    } else {
                      imageToUse = widget.book.image;
                    }
                    if (imageToUse == null || imageToUse.isEmpty) {
                      return Container(
                        color: Colors.grey[100],
                        child: Center(
                          child: CustomIcon(
                            title: IconConstants.libraryFilled,
                            height: 40,
                            width: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                      );
                    }

                    return OptimizedImage(
                      imageUrl: '${ApiEndpoints.imageBaseUrl}$imageToUse',
                      width: 150,
                      height: widget.book.withAudio ? 150 : 220,
                      fit: BoxFit.fill,
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
                            height: 40,
                            width: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    );
                  }(),
                ),
                if (isInSelectionMode && !isSelected)
                  Positioned.fill(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black.withOpacity(0.6)
                                    : Colors.white.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.black
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color.fromARGB(
                                        255, 238, 238, 238),
                                    width: 1)),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                height: 24,
                                width: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isSelected)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color.fromARGB(255, 238, 238, 238),
                              width: 1)),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.mainColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(
              width: 150,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.book.name,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontFamily: StringConstants.SFPro,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    // const SizedBox(height: 2),
                    Text(
                      widget.book.authors.first.name,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey[700],
                        fontSize: 12,
                        fontFamily: StringConstants.SFPro,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    // if (widget.discountPercentage != null && widget.discountPercentage! * 100 > 3)
                    //   Padding(
                    //     padding: const EdgeInsets.only(top: 4.0),
                    //     child: Align(
                    //       alignment: Alignment.centerLeft,
                    //       child: DiscountBadgeMini(
                    //         percentage: (widget.discountPercentage! * 100).toInt(),
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
