import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:flutter/material.dart';

class NoGenresAvailable extends StatelessWidget {
  final String? title;
  const NoGenresAvailable({this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomIcon(title: IconConstants.libraryFilled, height: 24, width: 24, color: Colors.black),
            SizedBox(height: 10),
            Text(
              title ?? '',
              style: TextStyle(
                fontFamily: StringConstants.SFPro,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
