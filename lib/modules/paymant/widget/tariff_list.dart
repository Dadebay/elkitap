import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/modules/paymant/controller/payment_controller.dart';
import 'package:elkitap/modules/paymant/widget/tariff_list_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TariffList extends StatelessWidget {
  final PaymentController paymentController;
  final int selectedPlan;
  final Function(int) onPlanSelected;

  const TariffList({
    Key? key,
    required this.paymentController,
    required this.selectedPlan,
    required this.onPlanSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Obx(() {
          if (paymentController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (paymentController.errorMessage.value.isNotEmpty) {
            return _buildErrorState(context);
          }

          if (paymentController.tariffs.isEmpty) {
            return Center(
              child: Text(
                'no_tariffs_available_t'.tr,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: StringConstants.SFPro,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: paymentController.tariffs.length,
            itemBuilder: (context, index) {
              final tariff = paymentController.tariffs[index];
              return TariffListItem(
                tariff: tariff,
                isSelected: selectedPlan == index,
                onTap: () => onPlanSelected(index),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              paymentController.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontFamily: StringConstants.SFPro,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => paymentController.refreshTariffs(),
              child: Text('retry_t'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
