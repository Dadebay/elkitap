import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/genre/view/collections_books_grid.dart';
import 'package:elkitap/modules/store/controllers/collections_controller.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';
import 'package:elkitap/modules/store/views/book_detail_view.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
import 'package:elkitap/modules/store/widgets/popular_gerners_book_cart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainCollectionsSection extends StatefulWidget {
  const MainCollectionsSection({super.key, this.tabIndex = 0});

  final int tabIndex;

  @override
  State<MainCollectionsSection> createState() => _MainCollectionsSectionState();
}

class _MainCollectionsSectionState extends State<MainCollectionsSection> {
  @override
  void didUpdateWidget(MainCollectionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabIndex != widget.tabIndex) {
      final controller = Get.find<BookCollectionController>();
      controller.fetchCollections(isAudioMode: widget.tabIndex == 1);
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch collections with audio filter if in audio mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<BookCollectionController>();
      controller.fetchCollections(isAudioMode: widget.tabIndex == 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final BookCollectionController collectionController = Get.find<BookCollectionController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 32, right: 32, top: 22),
          child: Text(
            "collections".tr,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: StringConstants.GilroyBold),
          ),
        ),
        Obx(() {
          if (collectionController.isLoading.value) {
            return LoadingWidget(removeBackWhite: true);
          }

          if (collectionController.hasError.value) {
            return ErrorStateWidget(
              errorMessage: collectionController.errorMessage.value,
              onRetry: () => collectionController.refreshCollections(
                isAudioMode: widget.tabIndex == 1,
              ),
            );
          }

          if (collectionController.collections.isEmpty) {
            return NoGenresAvailable(title: 'no_genres_available'.tr);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: collectionController.collections.map((collection) {
              return CollectionBookSection(
                collection: collection,
                tabIndex: widget.tabIndex,
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}

class CollectionBookSection extends StatelessWidget {
  const CollectionBookSection({
    super.key,
    required this.collection,
    this.tabIndex = 0,
  });

  final BookCollection collection;
  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 20, right: 32),
            child: Container(
              height: 1.5,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300]!.withOpacity(0.25) : Colors.grey[300],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 22, bottom: 10),
            child: GestureDetector(
              onTap: () {
                Get.to(() => CollectionBooksGridScreen(title: collection.name, id: collection.id));
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      collection.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: StringConstants.GilroyBold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
          SizedBox(
              height: 160,
              child: collection.books.isEmpty
                  ? NoGenresAvailable(title: 'no_books_found'.tr)
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      physics: const BouncingScrollPhysics(),
                      itemCount: collection.books.length,
                      itemBuilder: (context, index) {
                        final book = collection.books[index];
                        final isLast = index == collection.books.length - 1;

                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 300 + (index * 80)),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(20 * (1 - value), 0),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.only(right: isLast ? 0 : 14, bottom: 20, top: 8),
                            child: BookCardPopular(
                              book: book,
                              index: index,
                              tabIndex: tabIndex,
                              onTap: () {
                                Get.to(
                                  () => BookDetailView(
                                    book: book,
                                    isAudio: tabIndex == 1,
                                  ),
                                  transition: Transition.rightToLeft,
                                  duration: const Duration(milliseconds: 300),
                                );
                              },
                              discountPercentage: 1,
                            ),
                          ),
                        );
                      },
                    )),
        ],
      ),
    );
  }
}
