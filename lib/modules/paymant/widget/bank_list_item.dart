import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/modules/paymant/controller/payment_controller.dart';
import 'package:elkitap/modules/paymant/models/bank_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BankListItem extends StatelessWidget {
  final BankModel bank;
  final PaymentController paymentController;
  final VoidCallback onTap;

  const BankListItem({
    Key? key,
    required this.bank,
    required this.paymentController,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = paymentController.selectedBank.value?.id == bank.id;
      
      return InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[300]!,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  bank.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: StringConstants.SFPro,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              _buildSelectionIndicator(isSelected),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSelectionIndicator(bool isSelected) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? const Color(0xFFFF5722) : Colors.grey[400]!,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFF5722),
                ),
              ),
            )
          : null,
    );
  }
}