import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/genre/view/genrs_page_view.dart';
import 'package:elkitap/modules/store/controllers/all_geners_controller.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AllGenresView extends StatelessWidget {
  const AllGenresView({super.key});

  @override
  Widget build(BuildContext context) {
    final AllGenresController controller = Get.find<AllGenresController>();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'leading_text'.tr,
          style: const TextStyle(fontSize: 17, fontFamily: StringConstants.SFPro, fontWeight: FontWeight.w400),
        ),
        titleSpacing: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 8, 16, 16),
            child: Text(
              'genres'.tr,
              style: const TextStyle(
                fontSize: 34,
                fontFamily: StringConstants.GilroyRegular,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              // Show loading indicator
              if (controller.isLoading.value) {
                return const Center(
                  child: LoadingWidget(),
                );
              }

              // Show error message
              if (controller.errorMessage.value.isNotEmpty) {
                return ErrorStateWidget(
                  errorMessage: controller.errorMessage.value,
                  onRetry: () => controller.refreshGenres(),
                );
              }

              // Show empty state
              if (controller.genres.isEmpty) {
                return Center(
                    child: NoGenresAvailable(
                  title: 'no_genres_available'.tr,
                ));
              }

              // Show genres list
              return RefreshIndicator(
                onRefresh: () => controller.refreshGenres(),
                child: ListView.separated(
                  itemCount: controller.genres.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 32,
                    endIndent: 32,
                  ),
                  itemBuilder: (context, index) {
                    final genre = controller.genres[index];
                    print('Genre: ${genre.name}, ID: ${genre.id}');
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 8,
                      ),
                      title: Text(
                        genre.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          fontFamily: StringConstants.SFPro,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () async {
                        await Get.to(
                          () => GenrsDetailViewScreen(
                            title: genre.name,
                            id: genre.id,
                          ),
                          arguments: genre,
                        );

                        // Refresh genres after navigation

                        controller.refreshGenres();
                      },
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
