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

class CustomBottomSheet extends GetView<ContactsController> {
  final LegalDocumentType documentType;

  const CustomBottomSheet({
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
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
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
                        fontSize: 16,
                        fontFamily: StringConstants.SFPro,
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          _title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: StringConstants.SFPro,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 60),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Obx(() {
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

                  return ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: InAppWebView(
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
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
