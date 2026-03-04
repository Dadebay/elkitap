import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/profile/controllers/contacts_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

enum LegalDocumentType {
  privacyPolicy,
  userAgreement,
}

class LegalDocumentPage extends GetView<ContactsController> {
  final LegalDocumentType documentType;

  const LegalDocumentPage({
    super.key,
    required this.documentType,
  });

  String get _title {
    switch (documentType) {
      case LegalDocumentType.privacyPolicy:
        return 'privacy_and_policy'.tr;
      case LegalDocumentType.userAgreement:
        return 'legal_terms_of_use'.tr;
    }
  }

  String get _url {
    switch (documentType) {
      case LegalDocumentType.privacyPolicy:
        return controller.privacyPolicyLink;
      case LegalDocumentType.userAgreement:
        return controller.userAgreementUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).iconTheme.color,
            size: 20,
          ),
        ),
        title: Text(
          _title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return LoadingWidget(removeBackWhite: true);
        }

        if (_url.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'link_not_available'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: StringConstants.SFPro,
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                ),
              ),
            ),
          );
        }

        return InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(_url)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            useWideViewPort: false,
            loadWithOverviewMode: false,
            builtInZoomControls: false,
            displayZoomControls: false,
            supportZoom: true,
            transparentBackground: true,
          ),
        );
      }),
    );
  }
}
