import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/navigation/custom_app_bar_book.dart';
import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/library/controllers/library_controller.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
import 'package:elkitap/modules/library/widgets/grid_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReadingListScreen extends StatelessWidget {
  final String type;
  final String title;

  const ReadingListScreen({
    super.key,
    required this.type,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReadingListController(type: type), tag: 'reading_list_$type');

    return Scaffold(
      appBar: customAppBar(controller, context),
      body: Obx(() {
        if (controller.isLoading && controller.books.isEmpty) {
          return Center(child: LoadingWidget(removeBackWhite: true));
        }

        if (controller.errorMessage.isNotEmpty && controller.books.isEmpty) {
          return ErrorStateWidget(errorMessage: controller.errorMessage, onRetry: () => controller.loadBooks());
        }

        if (controller.books.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => controller.loadBooks(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
                child: EmptyCollectionWidget(
                  descriptionKey: type == 'read'
                      ? 'emptyWantToReadDesc'
                      : type == 'listen'
                          ? 'emptyWantToListenDesc'
                          : type == 'finished'
                              ? 'emptyFinishedDesc'
                              : 'emptyDownloadedDesc',
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => controller.loadBooks(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Obx(() {
                  return Text(
                    controller.selectedBooks.isEmpty ? title : controller.selectedBooks.length.toString() + 'selectedBooksCount'.tr,
                    style: const TextStyle(
                      fontSize: 28,
                      fontFamily: StringConstants.GilroyBold,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }),
              ),
              Expanded(
                child: Obx(() {
                  return controller.isGridView.value ? GridViewWidget(controller: controller, isAudio: type == 'listen') : ListViewWidget(controller: controller);
                }),
              ),
            ],
          ),
        );
      }),
    );
  }
}
