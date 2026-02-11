// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';

class ReadingListController extends GetxController {
  final NetworkManager _networkManager = Get.find<NetworkManager>();
  late GetAllBooksController booksController;
  final String type;

  var selectedBooks = <String>[].obs;
  var isGridView = true.obs;
  var isDeleting = false.obs;

  ReadingListController({required this.type});

  @override
  void onInit() {
    super.onInit();
    booksController = Get.put(
      GetAllBooksController(),
      tag: 'reading_list_$type',
    );
    loadBooks();
  }

  @override
  void onClose() {
    Get.delete<GetAllBooksController>(tag: 'reading_list_$type');
    super.onClose();
  }

  List<Book> get books => booksController.books;
  bool get isLoading => booksController.isLoading.value;
  bool get hasMore => booksController.hasMore.value;
  bool get isLoadingMore => booksController.isLoadingMore.value;
  String get errorMessage => booksController.errorMessage.value;

  void loadBooks() {
    if (type == 'read') {
      booksController.getBooksWantToRead();
    } else if (type == 'listen') {
      booksController.getBooksWantToListen();
    } else if (type == 'finished') {
      booksController.getFinishedBooks();
    }
  }

  Future<void> loadMoreBooks() async {
    await booksController.loadMoreBooks();
  }

  void toggleSelection(String bookId) {
    if (selectedBooks.contains(bookId)) {
      selectedBooks.remove(bookId);
    } else {
      selectedBooks.add(bookId);
    }
  }

  void selectAll() {
    if (selectedBooks.length == books.length) {
      selectedBooks.clear();
    } else {
      selectedBooks.value = books.map((book) => book.id.toString()).toList();
    }
  }

  void toggleView() {
    isGridView.value = !isGridView.value;
  }

  Future<void> removeSelected() async {
    if (selectedBooks.isEmpty) return;

    try {
      isDeleting.value = true;
      final booksToRemove = books.where((book) => selectedBooks.contains(book.id.toString())).toList();

      int successCount = 0;
      int failCount = 0;

      for (final book in booksToRemove) {
        final success = await _deleteBookFromList(book);
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      }

      if (successCount > 0) {
        books.removeWhere((book) => selectedBooks.contains(book.id.toString()));
        selectedBooks.clear();
        loadBooks();
      }

      if (failCount == 0) {
        AppSnackbar.success('$successCount ${"books_removed_successfully".tr}', duration: const Duration(seconds: 2));
      } else {
        AppSnackbar.warning('$successCount ${"removed".tr}, $failCount ${"failed".tr}', title: 'partial_success'.tr, duration: const Duration(seconds: 3));
      }
    } catch (e) {
      AppSnackbar.error('failed_to_remove_books'.tr, duration: const Duration(seconds: 2));
    } finally {
      isDeleting.value = false;
    }
  }

  Future<bool> _deleteBookFromList(Book book) async {
    try {
      int? idToDelete;

      if (type == 'read') {
        idToDelete = book.likedBookId;
      } else if (type == 'listen') {
        idToDelete = book.likedBookId;
      } else if (type == 'finished') {
        idToDelete = book.likedBookId;
      }

      if (idToDelete == null) {
        return false;
      }
      final response = await _networkManager.delete(
        ApiEndpoints.bookUnlike(idToDelete),
        sendToken: true,
      );

      if (response['success']) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  bool isSelected(String bookId) {
    return selectedBooks.contains(bookId);
  }

  void showRemoveDialog(BuildContext context) {
    if (selectedBooks.isEmpty) return;

    final selected = books.where((book) => selectedBooks.contains(book.id.toString())).take(4).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.all(20).copyWith(bottom: 0),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SafeArea(
                child: Obx(() => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 90,
                          height: 125,
                          margin: EdgeInsets.only(top: 25),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: selected.isNotEmpty && selected.first.image != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: CachedNetworkImage(
                                    imageUrl: ApiEndpoints.imageBaseUrl + selected.first.image!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(child: CupertinoActivityIndicator()),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.book, size: 50, color: Colors.grey),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.book, size: 50, color: Colors.grey),
                                ),
                        ),
                        // Message
                        Padding(
                          padding: const EdgeInsets.only(left: 32, right: 32, top: 24, bottom: 24),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "${'remove_dialog_part1_t'.tr}${selectedBooks.length > 1 ? '${selectedBooks.length} books' : 'this book'} ",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                TextSpan(
                                  text: 'remove ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: 'from ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                TextSpan(
                                  text: type == 'read'
                                      ? 'Want to Read'
                                      : type == 'listen'
                                          ? 'Want to Listen'
                                          : 'Finished',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const TextSpan(text: '?'),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Divider
                        Divider(height: 1, thickness: 0.5, color: Colors.grey[300]),
                        // Remove button
                        InkWell(
                          onTap: isDeleting.value
                              ? null
                              : () async {
                                  Get.back();
                                  await removeSelected();
                                  Get.back();
                                },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: isDeleting.value
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                      ),
                                    )
                                  : Text(
                                      'Remove',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 20,
                                        fontFamily: StringConstants.SFPro,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    )),
              ),
            ),
            InkWell(
              onTap: isDeleting.value ? null : () => Get.back(),
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1C1E) : Colors.white,
                ),
                child: Center(
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 20,
                      fontFamily: StringConstants.SFPro,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
