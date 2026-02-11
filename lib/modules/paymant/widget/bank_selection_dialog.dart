import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/modules/paymant/controller/payment_controller.dart';
import 'package:elkitap/modules/paymant/widget/bank_list_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BankSelectionDialog extends StatelessWidget {
  final PaymentController paymentController;

  const BankSelectionDialog({
    Key? key,
    required this.paymentController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'select_bank_t'.tr,
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: StringConstants.SFPro,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Divider(height: 1),
            Flexible(
              child: Obx(() {
                if (paymentController.isBanksLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (paymentController.banksErrorMessage.value.isNotEmpty) {
                  return _buildErrorState(context);
                }

                if (paymentController.banks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'no_banks_available_t'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: StringConstants.SFPro,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: paymentController.banks.length,
                  itemBuilder: (context, index) {
                    final bank = paymentController.banks[index];
                    return BankListItem(
                      bank: bank,
                      paymentController: paymentController,
                      onTap: () {
                        paymentController.selectBank(bank);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              paymentController.banksErrorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontFamily: StringConstants.SFPro,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await paymentController.fetchBanks();
              },
              child: Text('retry_t'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
