import 'package:elkitap/modules/paymant/controller/payment_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BankSelector extends StatelessWidget {
  final VoidCallback onTap;
  final PaymentController _paymentController = Get.find<PaymentController>();

  BankSelector({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          width: MediaQuery.of(context).size.width - 40,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Obx(() {
              final selectedBank = _paymentController.selectedBank.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'payment_credit_card_t'.tr,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    selectedBank != null
                        ? selectedBank.name
                        : 'choose_bank_t'.tr,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}