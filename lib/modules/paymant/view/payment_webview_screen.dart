// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({required this.invoiceUrl});

  final String invoiceUrl;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  bool _isProcessing = false;
  Map<String, dynamic>? _paymentResponseData;

  Future<void> _activateOrder(String url) async {
    if (_isProcessing) {
      if (kDebugMode) {
        print('⚠️ PAYMENT: Already processing, skipping...');
      }
      return;
    }

    if (kDebugMode) {
      print('🔄 PAYMENT: Starting order activation...');
      print('📍 PAYMENT: URL = $url');
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final dio = Dio();
      if (kDebugMode) {
        print('📤 PAYMENT: Sending GET request to activation URL...');
      }

      final response = await dio.get(url);

      if (kDebugMode) {
        print('📥 PAYMENT: Response received');
        print('📊 PAYMENT: HTTP Status Code = ${response.statusCode}');
        print('📦 PAYMENT: Response Data = ${response.data}');
      }

      // Check if response body contains Status: 200
      final responseData = response.data;
      int? bodyStatus;

      if (responseData is Map) {
        bodyStatus = responseData['statusCode'] ?? responseData['Status'] ?? responseData['status'];
      }

      if (kDebugMode) {
        print('🔍 PAYMENT: Body Status = $bodyStatus');
      }

      if (bodyStatus == 200) {
        if (kDebugMode) {
          print('✅ PAYMENT: Order activated successfully! (Body Status: 200)');
        }
        // Store response data
        if (responseData is Map<String, dynamic>) {
          _paymentResponseData = responseData;
        }
        // Payment successful
        _showSuccessDialog();
      } else {
        if (kDebugMode) {
          print('❌ PAYMENT: Order activation not successful (Body Status: $bodyStatus)');
        }
        // Payment not successful
        _showFailureDialog();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('💥 PAYMENT: Error activating order');
        print('❌ PAYMENT: Error = $e');
        print('📜 PAYMENT: StackTrace = $stackTrace');
      }
      // Payment failed
      _showFailureDialog();
    }
  }

  void _showSuccessDialog() {
    if (kDebugMode) {
      print('🎉 PAYMENT: Showing success dialog');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green.shade600,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'payment_successful_t'.tr,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'payment_successful_desc_t'.tr,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (kDebugMode) {
                        print('✅ PAYMENT: User confirmed success dialog');
                      }
                      Navigator.of(context).pop();
                      // Return payment response data
                      Get.back(result: _paymentResponseData ?? {'success': true});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'ok'.tr,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFailureDialog() {
    if (kDebugMode) {
      print('❌ PAYMENT: Showing failure dialog');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_rounded,
                    color: Colors.red.shade600,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'payment_failed_t'.tr,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'payment_failed_desc_t'.tr,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (kDebugMode) {
                        print('❌ PAYMENT: User confirmed failure dialog');
                      }
                      Navigator.of(context).pop();
                      Get.back(result: false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'ok'.tr,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<ServerTrustAuthResponse> _onReceivedServerTrustAuthRequest(InAppWebViewController controller, URLAuthenticationChallenge challenge) async {
    return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
  }

  FutureOr<bool> _launchURL(String uri) async {
    try {
      String newUri = uri;
      if (uri.startsWith('intent')) {
        newUri = uri.replaceFirst('intent', 'https');
      }
      await launchUrlString(
        newUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
    }
    return false;
  }

  Future<NavigationActionPolicy> _shouldOverrideUrlLoading(InAppWebViewController controller, NavigationAction shouldOverrideUrlLoadingRequest) async {
    var uri = shouldOverrideUrlLoadingRequest.request.url;
    if (uri == null) {
      if (kDebugMode) {
        print('⚠️ URL_MONITOR: URL is null, canceling');
      }
      return NavigationActionPolicy.CANCEL;
    }
    final uriString = uri.toString();

    if (kDebugMode) {
      print('🔍 URL_MONITOR: Detected URL change');
      print('📍 URL_MONITOR: $uriString');
    }

    // Check if the URL is the activation URL
    if (uriString.contains('api.elkitap.com.tm/payments/activate-order/')) {
      if (kDebugMode) {
        print('🎯 URL_MONITOR: Activation URL detected!');
        print('🚀 URL_MONITOR: Triggering order activation...');
      }
      // Make GET request to activate the order
      await _activateOrder(uriString);
      return NavigationActionPolicy.CANCEL;
    }

    if (uriString.startsWith('http://') || uriString.startsWith('https://')) {
      if (kDebugMode) {
        print('✅ URL_MONITOR: Standard HTTP/HTTPS URL, allowing navigation');
      }
      return NavigationActionPolicy.ALLOW;
    } else {
      if (kDebugMode) {
        print('🔗 URL_MONITOR: Non-HTTP URL, launching externally: $uriString');
      }
      _launchURL(uriString);
      return NavigationActionPolicy.CANCEL;
    }
  }

  Future<bool> _onCreateWindow(InAppWebViewController controller, CreateWindowAction action) async {
    var uri = action.request.url;
    if (uri == null) {
      return false;
    }
    final uriString = uri.toString();
    if (uriString.startsWith('http://') || uriString.startsWith('https://')) {
      return true;
    } else {
      _launchURL(uriString);
      return false;
    }
  }

  void _showCancelDialog(BuildContext context) {
    if (kDebugMode) {
      print('⚠️ PAYMENT: User requested to cancel payment');
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Colors.orange.shade600,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'cancel_payment_t'.tr,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'cancel_payment_confirmation_t'.tr,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (kDebugMode) {
                            print('✅ PAYMENT: User chose to continue payment');
                          }
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'no'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (kDebugMode) {
                            print('❌ PAYMENT: User canceled payment');
                          }
                          Navigator.of(context).pop();
                          Get.back(result: false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'yes'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('payment_t'.tr),
        elevation: 1,
        centerTitle: true,
        shadowColor: Colors.grey.withOpacity(0.5),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showCancelDialog(context);
          },
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.invoiceUrl)),
              onCreateWindow: _onCreateWindow,
              shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
              onReceivedServerTrustAuthRequest: _onReceivedServerTrustAuthRequest,
              initialSettings: InAppWebViewSettings(
                useShouldOverrideUrlLoading: true,
                javaScriptEnabled: true,
                useHybridComposition: true,
                allowsInlineMediaPlayback: true,
              ),
            ),
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
