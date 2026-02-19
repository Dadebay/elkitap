import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/genre/view/books_grid_screen_view.dart';
import 'package:elkitap/modules/genre/widget/ranked_books_list.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TopOfWeekSection extends StatefulWidget {
  const TopOfWeekSection({this.tabIndex = 0, super.key});

  final int tabIndex;

  @override
  State<TopOfWeekSection> createState() => _TopOfWeekSectionState();
}

class _TopOfWeekSectionState extends State<TopOfWeekSection> {
  late GetAllBooksController controller;
  int lastPage = 0;
  late PageController pageController;

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    controller =
        Get.put(GetAllBooksController(), tag: 'top_of_week_${widget.tabIndex}');
    pageController = PageController(viewportFraction: 0.85);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.searchBooksWithFilters(
        topOfTheWeekFilter: true,
        withAudioFilter: widget.tabIndex == 1,
      );
    });

    pageController.addListener(() {
      if (!pageController.hasClients) return;
      final currentPage = pageController.page?.round() ?? 0;
      final totalPages = (controller.books.length / 3).ceil();
      if (currentPage >= totalPages - 2 &&
          currentPage != lastPage &&
          !controller.isLoadingMore.value &&
          controller.hasMore.value) {
        lastPage = currentPage;
        controller.loadMoreBooks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: 28, right: 32, bottom: 12, top: 40),
          child: GestureDetector(
            onTap: () {
              Get.to(() => BooksGridScreen(
                    title: "top_of_the_week_t".tr,
                    id: 0,
                    isWeekly: true,
                    isAudio: widget.tabIndex == 1,
                  ));
            },
            child: Text(
              "top_of_the_week_t".tr,
              style: TextStyle(
                fontSize: 22,
                fontFamily: StringConstants.GilroyBold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Obx(() {
          if (controller.isLoading.value) {
            return Center(child: LoadingWidget(removeBackWhite: true));
          }

          if (controller.errorMessage.value.isNotEmpty) {
            return ErrorStateWidget(
              errorMessage: controller.errorMessage.value,
              onRetry: () => controller.searchBooksWithFilters(
                topOfTheWeekFilter: true,
                withAudioFilter: widget.tabIndex == 1,
              ),
            );
          }

          final books = controller.books;

          if (books.isEmpty) {
            return NoGenresAvailable(title: 'no_books_found'.tr);
          }

          return RankedBooksList(
            books: books,
            tabIndex: widget.tabIndex,
            pageController: pageController,
          );
        }),
      ],
    );
  }
}
