import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/genre/view/genrs_page_view.dart';
import 'package:elkitap/modules/store/controllers/all_geners_controller.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GenresSection extends StatelessWidget {
  const GenresSection({super.key});

  @override
  Widget build(BuildContext context) {
    final AllGenresController controller = Get.find<AllGenresController>();

    return Padding(
      padding: const EdgeInsets.only(left: 26, right: 26, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              "genres_title_t".tr,
              style: const TextStyle(
                fontSize: 22,
                fontFamily: StringConstants.GilroyBold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Obx(() {
            if (controller.isLoading.value) {
              return LoadingWidget(removeBackWhite: true);
            }

            if (controller.errorMessage.value.isNotEmpty) {
              return ErrorStateWidget(
                  errorMessage: controller.errorMessage.value,
                  onRetry: () => controller.refreshGenres());
            }

            if (controller.genres.isEmpty) {
              return Center(
                  child: NoGenresAvailable(title: 'no_genres_available'.tr));
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.genres.length,
              separatorBuilder: (_, __) => Container(
                height: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[300]!.withOpacity(0.25)
                    : Colors.grey[300],
              ),
              itemBuilder: (context, index) {
                final genre = controller.genres[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    genre.name,
                    style: const TextStyle(
                        fontFamily: StringConstants.GilroyMedium, fontSize: 16),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    await Get.to(
                        () => GenrsDetailViewScreen(
                            title: genre.name, id: genre.id),
                        arguments: genre);
                    controller.refreshGenres();
                  },
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
