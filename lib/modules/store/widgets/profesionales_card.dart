import 'package:cached_network_image/cached_network_image.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/modules/store/model/pro_readers_model.dart';
import 'package:elkitap/modules/store/views/profesional_readers_profil.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfessionalCard extends StatelessWidget {
  final ProfessionalRead professional;
  final String name;
  final String role;
  final String imageUrl;

  const ProfessionalCard({
    super.key,
    required this.professional,
    required this.name,
    required this.role,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [Color(0x001C1C1E), Color(0xFF1C1C1E)] // dark mode gradient
              : [Color(0x00E5E5EA), Color.fromARGB(255, 205, 205, 208)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[300],
            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty ? Icon(Icons.person, size: 45, color: Colors.grey[600]) : null,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4, top: 12),
            child: Text(
              role,
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: StringConstants.SFPro,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Get.to(() => ProfesionalReadersProfil(professionalRead: professional));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: StringConstants.GilroyRegular,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 20),
            width: MediaQuery.of(context).size.width * 0.8,
            height: 140,
            child: _buildBookShelf(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookShelf() {
    // Extract book images from professional_read_books
    final books = professional.professionalReadBooks;

    if (books == null || books.isEmpty) {
      // If no books, show placeholder
      return Image.asset(
        'assets/images/b8.png',
        width: 40,
        height: 60,
        fit: BoxFit.fitWidth,
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
      return Image.asset(
        'assets/images/b8.png',
        width: 40,
        height: 60,
        fit: BoxFit.fitWidth,
      );
    }

    // Calculate total width needed for overlapping books
    final bookWidth = 80.0;
    final bookHeight = 125.0;
    final overlap = 30.0; // How much each book overlaps the previous one
    final totalWidth = bookWidth + ((bookImages.length - 1) * (bookWidth - overlap));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Overlapping Books
          Center(
            child: Container(
              width: totalWidth,
              // color: Colors.red,
              height: bookHeight, // Extra space for shelf
              child: Stack(
                children: List.generate(bookImages.length, (index) {
                  final leftPosition = index * (bookWidth - overlap);
                  return Positioned(
                    left: leftPosition,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: bookWidth,
                      height: bookHeight + 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: bookImages[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.book, color: Colors.grey[600], size: 32),
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
            bottom: -16,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/shelf.png',
              height: 18,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
