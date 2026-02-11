import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/paymant/controller/payment_controller.dart';
import 'package:elkitap/modules/paymant/models/tariff_model.dart';
import 'package:elkitap/modules/paymant/view/payment_webview_screen.dart';
import 'package:elkitap/modules/paymant/widget/bank_selection_dialog.dart';
import 'package:elkitap/modules/paymant/widget/bank_selector.dart';
import 'package:elkitap/modules/paymant/widget/promo_image.dart';
import 'package:elkitap/modules/paymant/widget/subscribe_button.dart';
import 'package:elkitap/modules/paymant/widget/subscription_header.dart';
import 'package:elkitap/modules/paymant/widget/tariff_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widget/account_info_card.dart';

class SubscriptionPlansSheet extends StatefulWidget {
  const SubscriptionPlansSheet({Key? key}) : super(key: key);

  @override
  State<SubscriptionPlansSheet> createState() => _SubscriptionPlansSheetState();
}

class _SubscriptionPlansSheetState extends State<SubscriptionPlansSheet> {
  int _selectedPlan = 0;
  final PaymentController _paymentController = Get.put(PaymentController());

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1C1E) : Colors.grey[100],
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubscriptionHeader(
            onBack: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
          const AccountInfoCard(),
          const SizedBox(height: 20),
          const PromoImage(),
          const SizedBox(height: 20),
          BankSelector(
            onTap: () => _showBankSelectionDialog(context),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: TariffList(
              paymentController: _paymentController,
              selectedPlan: _selectedPlan,
              onPlanSelected: (index) => setState(() => _selectedPlan = index),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'agreement_text'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SubscribeButton(
            paymentController: _paymentController,
            selectedPlan: _selectedPlan,
            onSubscribe: _handleSubscribe,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubscribe(TariffModel tariff) async {
    if (_paymentController.selectedBank.value == null) {
      AppSnackbar.error('please_select_bank_t'.tr);
      return;
    }

    Get.defaultDialog(
      content: LoadingWidget(),
      backgroundColor: Colors.transparent,
      title: '',
      barrierDismissible: false,
    );

    final invoiceUrl = await _paymentController.createOrder(
      tariff.id,
      _paymentController.selectedBank.value!.id,
    );

    Get.back();

    if (invoiceUrl != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebViewScreen(invoiceUrl: invoiceUrl),
        ),
      );

      if (result == true) {
        Navigator.pop(context, true);
      }
    }
  }

  void _showBankSelectionDialog(BuildContext context) async {
    await _paymentController.fetchBanks();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BankSelectionDialog(
          paymentController: _paymentController,
        );
      },
    );
  }
}
