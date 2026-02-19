import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/core/utils/performance_utils.dart';
import 'package:elkitap/modules/library/controllers/downloaded_controller.dart';
import 'package:elkitap/modules/library/model/book_download_model.dart';
import 'package:elkitap/modules/library/views/downloaded_book_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DownloadedGridView extends StatelessWidget {
  final DownloadController controller;

  const DownloadedGridView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Obx(() => GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.55,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: controller.downloadedBooks.length,
            itemBuilder: (context, index) {
              final book = controller.downloadedBooks[index];
              return DownloadedBookGridItem(
                book: book,
                controller: controller,
              );
            },
          )),
    );
  }
}

class DownloadedBookGridItem extends StatefulWidget {
  final BookDownload book;
  final DownloadController controller;

  const DownloadedBookGridItem({
    super.key,
    required this.book,
    required this.controller,
  });

  @override
  State<DownloadedBookGridItem> createState() => _DownloadedBookGridItemState();
}

class _DownloadedBookGridItemState extends State<DownloadedBookGridItem> {
  // Navigate to book detail page (info view)
  void _openBookDetail() {
    Get.to(() => DownloadedBookDetailView(bookId: widget.book.id));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.controller.selectedBooks.isNotEmpty) {
          // In selection mode - toggle selection
          widget.controller.toggleSelection(widget.book.id);
          setState(() {});
        } else {
          // Normal tap - open book detail page
          _openBookDetail();
        }
      },
      onLongPress: () {
        // Long press - start selection mode
        widget.controller.toggleSelection(widget.book.id);
        setState(() {});
      },
      child: Obx(() {
        final isSelected = widget.controller.selectedBooks.contains(widget.book.id);
        final isInSelectionMode = widget.controller.selectedBooks.isNotEmpty;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Book Cover with Stack for overlays
            Stack(
              children: [
                // Book Cover
                Container(
                  height: widget.book.isAudio ? 148 : 200,
                  width: 148,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: OptimizedImage(
                    imageUrl: widget.book.coverUrl ?? '',
                    width: 148,
                    height: widget.book.isAudio ? 148 : 200,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: LoadingWidget(),
                      ),
                    ),
                    errorWidget: Container(
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

                // White/black glass overlay for unselected items in selection mode
                if (isInSelectionMode && !isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                // Empty checkbox for unselected items in selection mode
                if (isInSelectionMode && !isSelected)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color.fromARGB(255, 238, 238, 238),
                          width: 1,
                        ),
                      ),
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

                // Orange check icon for selected items
                if (isSelected)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color.fromARGB(255, 238, 238, 238),
                          width: 1,
                        ),
                      ),
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

            Container(
              width: 148,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.book.title,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontFamily: StringConstants.SFPro,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.book.author,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700],
                      fontSize: 12,
                      fontFamily: StringConstants.SFPro,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
