import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/core/utils/performance_utils.dart';
import 'package:elkitap/modules/library/controllers/downloaded_controller.dart';
import 'package:elkitap/modules/library/model/book_download_model.dart';
import 'package:elkitap/modules/library/views/downloaded_book_detail_view.dart';
import 'package:elkitap/modules/store/widgets/book_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DownloadedListView extends StatelessWidget {
  final DownloadController controller;

  const DownloadedListView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.downloadedBooks.length,
          itemBuilder: (context, index) {
            final book = controller.downloadedBooks[index];
            return DownloadedBookListItem(
              book: book,
              controller: controller,
              discountPercentage: 1,
            );
          },
        ));
  }
}

class DownloadedBookListItem extends StatefulWidget {
  final int? discountPercentage;
  final BookDownload book;
  final DownloadController controller;

  const DownloadedBookListItem({
    super.key,
    this.discountPercentage,
    required this.book,
    required this.controller,
  });

  @override
  State<DownloadedBookListItem> createState() => _DownloadedBookListItemState();
}

class _DownloadedBookListItemState extends State<DownloadedBookListItem> {
  void _openBookDetail() {
    Get.to(() => DownloadedBookDetailView(
          bookId: widget.book.id,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = widget.controller.selectedBooks.contains(widget.book.id);
      final isInSelectionMode = widget.controller.selectedBooks.isNotEmpty;

      return GestureDetector(
        onTap: () {
          if (widget.controller.selectedBooks.isNotEmpty) {
            widget.controller.toggleSelection(widget.book.id);
          } else {
            _openBookDetail();
          }
        },
        onLongPress: () {
          widget.controller.toggleSelection(widget.book.id);
        },
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.only(bottom: 16),
              decoration: const BoxDecoration(),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color.fromARGB(255, 223, 220, 220),
                        width: 1,
                      ),
                    ),
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
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 130,
                    child: Stack(
                      children: [
                        if (widget.discountPercentage != null && widget.discountPercentage! > 3)
                          Positioned(
                            right: 10,
                            bottom: 0,
                            child: DiscountBadgeMini(
                              percentage: widget.discountPercentage!,
                            ),
                          ),
                        Container(
                          width: 75,
                          height: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: OptimizedImage(
                            imageUrl: widget.book.coverUrl ?? '',
                            width: 75,
                            height: 110,
                            fit: BoxFit.cover,
                            placeholder: Container(
                              width: 75,
                              height: 110,
                              color: Colors.grey[300],
                              child: const Center(
                                child: LoadingWidget(),
                              ),
                            ),
                            errorWidget: Container(
                              width: 75,
                              height: 110,
                              color: Colors.grey[300],
                              child: CustomIcon(
                                title: IconConstants.libraryFilled,
                                height: 24,
                                width: 24,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Book info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.book.title,
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
                          widget.book.author,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: StringConstants.SFPro,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Download info badge
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
