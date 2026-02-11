import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/modules/paymant/controller/payment_controller.dart';
import 'package:elkitap/modules/paymant/models/tariff_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubscribeButton extends StatelessWidget {
  final PaymentController paymentController;
  final int selectedPlan;
  final Function(TariffModel) onSubscribe;

  const SubscribeButton({
    Key? key,
    required this.paymentController,
    required this.selectedPlan,
    required this.onSubscribe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Obx(() {
        final selectedTariff = paymentController.tariffs.isNotEmpty && selectedPlan < paymentController.tariffs.length ? paymentController.tariffs[selectedPlan] : null;

        final selectedBank = paymentController.selectedBank.value;
        final isEnabled = selectedTariff != null && selectedBank != null;

        String buttonText = _getButtonText(selectedTariff);

        return ElevatedButton(
          onPressed: () => _handlePress(selectedTariff, selectedBank, isEnabled),
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled ? const Color(0xFFFF5722) : Colors.grey,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            buttonText,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }),
    );
  }

  String _getButtonText(TariffModel? selectedTariff) {
    String buttonText = 'subscribe_t'.tr;
    if (selectedTariff != null) {
      final monthText = selectedTariff.monthCount == 1 ? '1 ${'month_t'.tr}' : '${selectedTariff.monthCount} ${'months_t'.tr}';
      buttonText = '${'subscribe_t'.tr}: $monthText / ${selectedTariff.price} ${'currency_man_t'.tr}';
    }
    return buttonText;
  }

  void _handlePress(TariffModel? selectedTariff, selectedBank, bool isEnabled) {
    if (isEnabled) {
      onSubscribe(selectedTariff!);
    } else {
      if (selectedTariff == null) {
        AppSnackbar.error('please_select_tariff_t'.tr);
      } else if (selectedBank == null) {
        AppSnackbar.error('please_select_bank_t'.tr);
      }
    }
  }
}
