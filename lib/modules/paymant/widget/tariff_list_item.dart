import 'package:elkitap/modules/paymant/models/tariff_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TariffListItem extends StatelessWidget {
  final TariffModel tariff;
  final bool isSelected;
  final VoidCallback onTap;

  const TariffListItem({
    Key? key,
    required this.tariff,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final monthText = tariff.monthCount == 1
        ? '1 ${'month_t'.tr}'
        : '${tariff.monthCount} ${'months_t'.tr}';

    final price = '${tariff.price} ${'currency_man_t'.tr}';
    final actualPrice = tariff.actualPrice != null
        ? '${tariff.actualPrice} ${'currency_man_t'.tr}'
        : null;

    final discount = tariff.hasDiscount
        ? 'save_discount_t'.trParams({
            'amount': (tariff.actualPrice! - tariff.price).toStringAsFixed(0)
          })
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (actualPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          actualPrice,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (discount != null)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF5722) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  discount,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            _buildSelectionIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator() {
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