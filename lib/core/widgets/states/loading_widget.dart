import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingWidget extends StatelessWidget {
  final bool removeBackWhite;

  const LoadingWidget({
    super.key,
    this.removeBackWhite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: removeBackWhite == true ? Colors.transparent : Colors.white,
        shape: BoxShape.circle,
        boxShadow: removeBackWhite == true
            ? []
            : [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Lottie.asset(
        'assets/animations/loading2.json',
        height: MediaQuery.of(context).size.height * 0.3,
        width: MediaQuery.of(context).size.width * 0.3,
        fit: BoxFit.contain,
      ),
    );
  }
}
