import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/theme/app_colors.dart';
import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/genre/view/genrs_page_view.dart';
import 'package:elkitap/modules/store/controllers/all_geners_controller.dart';
import 'package:elkitap/modules/store/views/all_geners_view.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GenericListWidget extends StatefulWidget {
  final bool isAudioMode;

  const GenericListWidget({
    super.key,
    this.isAudioMode = false,
  });

  @override
  State<GenericListWidget> createState() => _GenericListWidgetState();
}

class _GenericListWidgetState extends State<GenericListWidget> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<AllGenresController>();
      controller.fetchAllGenres(withAudio: widget.isAudioMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AllGenresController controller = Get.find<AllGenresController>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 18, top: 32, bottom: 16),
            child: Text(
              "genres_title_t".tr,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: StringConstants.GilroyBold,
              ),
            ),
          ),
          Obx(() {
            if (controller.isLoading.value) {
              return LoadingWidget(removeBackWhite: true);
            }

            if (controller.errorMessage.value.isNotEmpty) {
              return ErrorStateWidget(errorMessage: controller.errorMessage.value, onRetry: () => controller.refreshGenres(withAudio: widget.isAudioMode));
            }

            if (controller.genres.isEmpty) {
              return NoGenresAvailable(title: 'no_genres_available'.tr);
            }

            final firstFiveGenres = controller.genres.take(5).toList();

            return Padding(
              padding: const EdgeInsets.only(left: 18, right: 18),
              child: Column(
                children: [
                  ...firstFiveGenres.asMap().entries.map((entry) {
                    final genre = entry.value;

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            genre.name,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: StringConstants.SFPro),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 22, color: Colors.grey[400]),
                          onTap: () async {
                            await Get.to(() => GenrsDetailViewScreen(title: genre.name, id: genre.id, isAudioMode: widget.isAudioMode), arguments: genre);
                            controller.refreshGenres(withAudio: widget.isAudioMode);
                          },
                        ),
                        Container(
                          height: 1,
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.dividerColor : Colors.grey[200],
                        ),
                      ],
                    );
                  }),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'all_genres_t'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: StringConstants.SFPro),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 22, color: Colors.grey[400]),
                    onTap: () async {
                      await Get.to(() => const AllGenresView());
                      controller.refreshGenres();
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
