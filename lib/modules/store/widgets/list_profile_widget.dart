import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/store/controllers/pro_readers_controller.dart';
import 'package:elkitap/modules/store/views/profesional_readers_profil.dart';
import 'package:elkitap/modules/store/views/profesionals_read_view.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
import 'package:elkitap/modules/store/widgets/profile_cart_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ListProfileWidget extends StatefulWidget {
  final int tabIndex;

  const ListProfileWidget({super.key, this.tabIndex = 0});

  @override
  State<ListProfileWidget> createState() => _ListProfileWidgetState();
}

class _ListProfileWidgetState extends State<ListProfileWidget> {
  final ProfessionalReadsController controller = Get.put(ProfessionalReadsController());

  @override
  void initState() {
    super.initState();
    print('=== ListProfileWidget initState ===');
    print('tabIndex: ${widget.tabIndex}');
    print('isAudioMode: ${widget.tabIndex == 1}');
    // Fetch professional reads with audio filter if in audio mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchProfessionalReads(isAudioMode: widget.tabIndex == 1);
    });
  }

  @override
  void didUpdateWidget(ListProfileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabIndex != widget.tabIndex) {
      print('=== ListProfileWidget tabIndex changed ===');
      print('Old tabIndex: ${oldWidget.tabIndex}');
      print('New tabIndex: ${widget.tabIndex}');
      print('New isAudioMode: ${widget.tabIndex == 1}');
      controller.fetchProfessionalReads(isAudioMode: widget.tabIndex == 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 32, right: 32, top: 32, bottom: 14),
          child: GestureDetector(
            onTap: () => Get.to(() => ProfessionalsReadView()),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'professionals_read_t'.tr,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: StringConstants.GilroyBold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        Obx(() {
          if (controller.isLoading.value) {
            return LoadingWidget(removeBackWhite: true);
          }

          // Show error message
          if (controller.errorMessage.value.isNotEmpty) {
            return ErrorStateWidget(
              errorMessage: controller.errorMessage.value,
              onRetry: () => controller.refreshProfessionalReads(
                isAudioMode: widget.tabIndex == 1,
              ),
            );
          }

          // Show empty state
          if (controller.professionalReads.isEmpty) {
            return NoGenresAvailable(title: 'no_professional_reads_available'.tr);
          }

          // Show data
          return SizedBox(
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: controller.professionalReads.length,
              itemBuilder: (context, idx) {
                final professional = controller.professionalReads[idx];

                return GestureDetector(
                  onTap: () {
                    Get.to(
                      () => ProfesionalReadersProfil(professionalRead: professional),
                      arguments: professional, // Pass the professional data
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.only(left: idx == 0 ? 32 : 16),
                    child: ProfileCard(
                      role: professional.position,
                      name: professional.name,
                      imageUrl: professional.fullImageUrl,
                      description: professional.description,
                      professionalId: professional.id,
                      professionalReadBooks: professional.professionalReadBooks,
                    ),
                  ),
                );
              },
            ),
          );
        }),
        SizedBox(height: 24),
      ],
    );
  }
}
