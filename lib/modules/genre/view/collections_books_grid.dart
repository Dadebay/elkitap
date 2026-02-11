import 'package:elkitap/core/widgets/navigation/custom_appbar.dart';
import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/genre/widget/book_grid_cart.dart';
import 'package:elkitap/modules/store/controllers/collections_controller.dart';

import 'package:elkitap/modules/store/views/store_detail_view.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CollectionBooksGridScreen extends StatelessWidget {
  final String title;
  final int id;

  const CollectionBooksGridScreen({
    required this.title,
    required this.id,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BookCollectionController collectionController =
        Get.find<BookCollectionController>();

    return Scaffold(
      appBar: CustomAppBar(
        title: title.tr,
        leadingText: 'leading_text'.tr,
      ),
      body: Obx(() {
        if (collectionController.isLoading.value) {
          return const Center(child: LoadingWidget());
        }

        if (collectionController.hasError.value) {
          return ErrorStateWidget(
            errorMessage: collectionController.errorMessage.value,
            onRetry: () => collectionController.refreshCollections(),
          );
        }
        final collection = collectionController.getCollectionById(id);

        if (collection == null || collection.books.isEmpty) {
          return NoGenresAvailable(title: 'no_books_found'.tr);
        }

        return RefreshIndicator(
          onRefresh: () => collectionController.refreshCollections(),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: collection.books.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            itemBuilder: (context, index) {
              final book = collection.books[index];
              return BookCardGridView(
                book: book,
                onTap: () {
                  Get.to(() => BookDetailView(book: book));
                },
                discountPercentage: 2,
              );
            },
          ),
        );
      }),
    );
  }
}
