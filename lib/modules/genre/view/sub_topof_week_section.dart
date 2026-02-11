import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/genre/view/books_grid_screen_view.dart';
import 'package:elkitap/modules/genre/widget/ranked_books_list.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubTopOfWeekSection extends StatelessWidget {
  const SubTopOfWeekSection({super.key});

  @override
  Widget build(BuildContext context) {
    final GetAllBooksController controller = Get.find<GetAllBooksController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.books.isEmpty || controller.topOfTheWeek.value == true) {
        controller.getTopOfTheWeekBooks();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: GestureDetector(
            onTap: () {
              Get.to(() => BooksGridScreen(
                  title: "top_of_the_week_t".tr, id: 0, isWeekly: true));
            },
            child: Text(
              "top_of_the_week_t".tr,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: StringConstants.GilroyBold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.isLoading.value) {
            return LoadingWidget(removeBackWhite: true);
          }
          if (controller.errorMessage.value.isNotEmpty) {
            return ErrorStateWidget(
                errorMessage: controller.errorMessage.value,
                onRetry: () => controller.getRecommendedBooks());
          }
          final books = controller.books;
          if (books.isEmpty) {
            return NoGenresAvailable(title: 'no_books_found'.tr);
          }
          return RankedBooksList(books: books);
        }),
      ],
    );
  }
}
