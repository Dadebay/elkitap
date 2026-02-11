import 'package:elkitap/core/constants/string_constants.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotSubscribedView extends StatelessWidget {
  final VoidCallback onSubscribe;

  const NotSubscribedView({super.key, required this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14.0).copyWith(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 25),
          Text(
            "not_subscribed_t".tr,
            style: const TextStyle(
              fontFamily: StringConstants.SFPro,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.grey[300]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: ElevatedButton(
              onPressed: onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5A26),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                elevation: 0,
              ),
              child: Text("subscribe".tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: StringConstants.SFPro, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
