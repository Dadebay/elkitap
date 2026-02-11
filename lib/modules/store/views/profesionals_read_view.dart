import 'package:elkitap/core/widgets/navigation/custom_appbar.dart';
import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/store/controllers/pro_readers_controller.dart';
import 'package:elkitap/modules/store/views/profesional_readers_profil.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
import 'package:elkitap/modules/store/widgets/profesionales_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfessionalsReadView extends StatelessWidget {
  const ProfessionalsReadView({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfessionalReadsController controller = Get.find<ProfessionalReadsController>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'professionals_read_t'.tr,
        leadingText: 'leading_text'.tr,
      ),
      body: Obx(() {
        // Loading state
        if (controller.isLoading.value) {
          return Center(
            child: LoadingWidget(),
          );
        }

        // Error state
        if (controller.errorMessage.value.isNotEmpty) {
          return ErrorStateWidget(
            errorMessage: controller.errorMessage.value,
            onRetry: () => controller.refreshProfessionalReads(),
          );
        }

        // Empty state
        if (controller.professionalReads.isEmpty) {
          return NoGenresAvailable(title: 'no_professional_reads_available'.tr);
        }

        // Data state with RefreshIndicator
        return RefreshIndicator(
          onRefresh: () => controller.refreshProfessionalReads(),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: controller.professionalReads.length,
            itemBuilder: (context, index) {
              final professional = controller.professionalReads[index];
              return GestureDetector(
                onTap: () {
                  Get.to(() => ProfesionalReadersProfil(professionalRead: professional));
                },
                child: ProfessionalCard(
                  professional: professional,
                  name: professional.name,
                  role: professional.position,
                  imageUrl: professional.fullImageUrl,
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
