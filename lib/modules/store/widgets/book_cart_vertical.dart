import 'package:elkitap/core/constants/string_constants.dart';
import 'package:flutter/material.dart';

class BookVerticalCart extends StatelessWidget {
  final int index;
  final Map<String, String> book;
  final VoidCallback? onTap; 

  const BookVerticalCart({
    Key? key,
    required this.index,
    required this.book,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, 
      child: Row(
        children: [
          Text(
            "${index + 1}",
            style: const TextStyle(
              fontSize: 18,
               fontFamily: StringConstants.SFPro,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 60,
            width: 40,
            margin: const EdgeInsets.only(right: 12),
            child: Image.asset(
              'assets/images/b$index.png',
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book["title"] ?? "",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  book["author"] ?? "",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
