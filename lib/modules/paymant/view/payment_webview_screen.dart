import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PaymentWebViewScreen extends StatelessWidget {
  const PaymentWebViewScreen({required this.invoiceUrl});

  final String invoiceUrl;

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
      return NavigationActionPolicy.CANCEL;
    }
    final uriString = uri.toString();
    if (uriString.startsWith('http://') || uriString.startsWith('https://')) {
      return NavigationActionPolicy.ALLOW;
    } else {
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
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            'cancel_payment_t'.tr,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'cancel_payment_confirmation_t'.tr,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          actionsPadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          // titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          actions: [
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(14),
                          ),
                        ),
                      ),
                      child: Text(
                        'no'.tr,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.blue,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 0.5,
                    height: 44,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Get.back(result: false);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(14),
                          ),
                        ),
                      ),
                      child: Text(
                        'yes'.tr,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(invoiceUrl)),
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
      ),
    );
  }
}
