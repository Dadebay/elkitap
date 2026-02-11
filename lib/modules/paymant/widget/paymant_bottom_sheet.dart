import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/modules/paymant/controller/payment_controller.dart';
import 'package:elkitap/modules/paymant/models/payment_history_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentHistoryBottomSheet extends StatefulWidget {
  const PaymentHistoryBottomSheet({super.key});

  @override
  State<PaymentHistoryBottomSheet> createState() =>
      _PaymentHistoryBottomSheetState();
}

class _PaymentHistoryBottomSheetState extends State<PaymentHistoryBottomSheet> {
  final PaymentController _paymentController = Get.put(PaymentController());

  @override
  void initState() {
    super.initState();
    _paymentController.fetchPaymentHistory();
    _paymentController.fetchBanks();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy HH:mm').format(date);
  }

  String _getBankName(int bankId) {
    // You can enhance this by fetching bank names from the banks list
    final bank =
        _paymentController.banks.firstWhereOrNull((b) => b.id == bankId);
    return bank?.name ?? 'bank_service_t'.tr;
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double sheetHeight = screenHeight * 0.80;
    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Theme.of(context).iconTheme.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'profile'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: StringConstants.SFPro,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Expanded(
                  child: Text(
                    "payment_history_title_t".tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: StringConstants.SFPro,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                ),
                const SizedBox(width: 46),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_paymentController.isPaymentHistoryLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              // Ensure we rebuild when banks are loaded
              // ignore: unused_local_variable
              final banksLoaded = _paymentController.banks.length;

              if (_paymentController
                  .paymentHistoryErrorMessage.value.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _paymentController.paymentHistoryErrorMessage.value,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _paymentController.fetchPaymentHistory();
                        },
                        child: Text('retry_t'.tr),
                      ),
                    ],
                  ),
                );
              }

              if (_paymentController.paymentHistory.isEmpty) {
                return Center(
                  child: Text(
                    'no_payment_history_t'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => _paymentController.refreshPaymentHistory(),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _paymentController.paymentHistory.length,
                  itemBuilder: (context, index) {
                    final payment = _paymentController.paymentHistory[index];
                    return _buildPaymentItem(
                      context,
                      payment: payment,
                      showDivider:
                          index < _paymentController.paymentHistory.length - 1,
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

  Widget _buildPaymentItem(
    BuildContext context, {
    required PaymentHistoryModel payment,
    bool showDivider = true,
  }) {
    // Define colors based on theme and status
    final bool isPaid = payment.processed;
    final Color statusColor = isPaid ? Colors.green : Colors.red;

    final Color primaryTextColor =
        Theme.of(context).textTheme.bodyLarge!.color!;
    final Color secondaryTextColor =
        Theme.of(context).textTheme.bodySmall!.color!;

    // Get status text
    final String status = isPaid ? "status_paid_t".tr : "status_unpaid_t".tr;

    // Get bank name
    final String bankService = _getBankName(payment.bankId);

    // Format date
    final String date = _formatDate(payment.createdAt);

    // Format amount
    final String amount = "${payment.amount} ${'currency_man_t'.tr}";

    // Get duration from tariff
    final int monthCount = payment.order.tariff.monthCount;
    String duration;
    if (monthCount == 1) {
      duration = "duration_1_month_t".tr;
    } else if (monthCount == 3) {
      duration = "duration_3_months_t".tr;
    } else if (monthCount == 6) {
      duration = "duration_6_months_t".tr;
    } else if (monthCount == 12) {
      duration = "duration_12_months_t".tr;
    } else {
      duration = "$monthCount ${'months_t'.tr}";
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: StringConstants.SFPro,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bankService,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: StringConstants.SFPro,
                        color: primaryTextColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: StringConstants.SFPro,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Right side: Amount, Duration
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: StringConstants.SFPro,
                      fontWeight: FontWeight.w500,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: StringConstants.SFPro,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Divider(
              height: 1,
              color: Theme.of(context).dividerColor.withOpacity(0.5),
              thickness: 0.5,
            ),
          ),
      ],
    );
  }
}
