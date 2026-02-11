import 'package:cached_network_image/cached_network_image.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String role;
  final String name;
  final String imageUrl;
  final String description;
  final int professionalId;
  final List<dynamic>? professionalReadBooks; // Add this parameter

  const ProfileCard({
    super.key,
    required this.role,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.professionalId,
    this.professionalReadBooks, // Add to constructor
  });

  // A small "shelf" with book covers
  Widget _buildShelf(BuildContext context) {
    final books = professionalReadBooks;
    if (books == null || books.isEmpty) {
      // If no books, show placeholder
      return Container(
        width: 212,
        height: 90,
        margin: EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/b8.png'),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Get up to 4 books
    final bookImages = <String>[];
    for (var item in books.take(4)) {
      try {
        final book = item['book'];
        if (book != null && book is Map) {
          final bookImage = book['image'];
          if (bookImage != null && bookImage.toString().isNotEmpty) {
            bookImages.add('${ApiEndpoints.imageBaseUrl}$bookImage');
          }
        }
      } catch (e) {
        // Skip invalid items
      }
    }

    if (bookImages.isEmpty) {
      return Container(
        width: 212,
        height: 90,
        margin: EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/b8.png'),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Calculate total width needed for overlapping books
    final bookWidth = 53.0;
    final bookHeight = 75.0;
    final overlap = 10.0;
    final totalWidth = bookWidth + ((bookImages.length - 1) * (bookWidth - overlap));

    return Container(
      width: 220,
      height: 95,
      // color: Colors.red,
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Overlapping Books
          Center(
            child: Container(
              width: totalWidth,
              height: bookHeight + 90,
              child: Stack(
                children: List.generate(bookImages.length, (index) {
                  final leftPosition = index * (bookWidth - overlap);
                  return Positioned(
                    left: leftPosition,
                    top: 0,
                    bottom: 20,
                    child: Container(
                      width: bookWidth,
                      height: bookHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: CachedNetworkImage(
                          imageUrl: bookImages[index],
                          fit: BoxFit.fill,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.book, color: Colors.grey[600], size: 20),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          // Shelf background image
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: Image.asset(
                'assets/images/shelf.png',
                height: 9,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = professionalReadBooks;

    return Container(
      width: 265,
      height: 240,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Color.fromARGB(255, 40, 40, 43) : Color(0xffE5E5EA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          width: 2,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Color(0xffdadadd),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 22),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[300],
            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty ? Icon(Icons.person, size: 32, color: Colors.grey[600]) : null,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Text(
              role.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontFamily: StringConstants.SFPro,
                color: Colors.grey[600],
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: (books == null || books.isEmpty) ? 10 : 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildShelf(context),
          ),
        ],
      ),
    );
  }
}
