// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:elkitap/modules/paymant/controller/promo_code_controller.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'promo_code_scanner_screen.dart';

class PromocodeSheet extends StatefulWidget {
  const PromocodeSheet({super.key});

  @override
  State<PromocodeSheet> createState() => _PromocodeSheetState();
}

class _PromocodeSheetState extends State<PromocodeSheet> {
  final TextEditingController _promoController = TextEditingController();
  final PromoCodeController _controller = Get.put(PromoCodeController());
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _promoController.addListener(() {
      setState(() {
        _hasText = _promoController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _openScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const PromoCodeScannerScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _promoController.text = result.toUpperCase();
      });
    }
  }

  void _validatePromoCode() async {
    final promoCode = _promoController.text.trim();
    print('═══════════════════════════════════════');
    print('🎫 PROMO CODE VALIDATION STARTED');
    print('Input: "$promoCode"');
    print('Length: ${promoCode.length}');
    print('═══════════════════════════════════════');

    try {
      final result = await _controller.validatePromoCode(promoCode);

      print('\n📊 VALIDATION RESULT:');
      print('Result: $result');
      print('Result Type: ${result.runtimeType}');

      if (result != null) {
        print('✅ Validation successful');
        print('Data: $result');

        // Extract added days from result
        int addedDays = 0;
        if (result is Map<String, dynamic>) {
          addedDays = (result['added_days'] as num?)?.toInt() ?? 0;
        }

        // Show success snackbar
        if (addedDays > 0) {
          AppSnackbar.success(
            'promo_code_success_days_t'.trParams({'days': addedDays.toString()}),
          );
        } else {
          AppSnackbar.success('promo_code_success_t'.tr);
        }

        if (mounted) {
          print('🔄 Popping with result');
          Navigator.pop(context, result);
        } else {
          print('⚠️ Widget not mounted, cannot pop');
        }
      } else {
        print('❌ Validation failed - result is null');
        print('Error message: ${_controller.errorMessage.value}');
      }
    } catch (e, stackTrace) {
      print('\n💥 EXCEPTION IN _validatePromoCode:');
      print('Error: $e');
      print('StackTrace: $stackTrace');
    }
    print('═══════════════════════════════════════\n');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'promocode'.tr,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 36),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        width: 200,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.card_giftcard,
                            size: 80,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'use_gift_card_t'.tr,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'promo_code_prompt_t'.tr,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _promoController,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'enter_promo_code_hint_t'.tr,
                                  hintStyle: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[500],
                                    fontSize: 16,
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.qr_code_scanner,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[700],
                                size: 28,
                              ),
                              onPressed: _openScanner,
                            ),
                          ),
                        ],
                      ),
                      Obx(() {
                        if (_controller.errorMessage.value.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _controller.errorMessage.value,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }
                        return const SizedBox(height: 40);
                      }),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _hasText ? _validatePromoCode : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasText ? const Color(0xFFFF5722) : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300]),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Obx(() {
                      if (_controller.isLoading.value) {
                        return const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        );
                      }
                      return Text(
                        'use_promo_code_button_t'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _hasText ? Colors.white : Colors.grey[500],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
