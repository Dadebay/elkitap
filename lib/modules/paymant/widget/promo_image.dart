import 'package:flutter/material.dart';

class PromoImage extends StatelessWidget {
  const PromoImage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Image.asset('assets/images/a3.png'),
    );
  }
}