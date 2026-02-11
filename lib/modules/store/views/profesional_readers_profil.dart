import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/core/widgets/navigation/custom_appbar.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';
import 'package:elkitap/modules/store/model/pro_readers_model.dart';
import 'package:elkitap/modules/store/widgets/book_cart_profil.dart';
import 'package:elkitap/core/widgets/states/empty_states.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfesionalReadersProfil extends StatefulWidget {
  final ProfessionalRead professionalRead;
  const ProfesionalReadersProfil({super.key, required this.professionalRead});

  @override
  State<ProfesionalReadersProfil> createState() => _ProfesionalReadersProfilState();
}

class _ProfesionalReadersProfilState extends State<ProfesionalReadersProfil> {
  bool isExpanded = false;

  final String shortBio = "bio_short_t";
  final String fullBio = "bio_full_t";

  List<Map<String, dynamic>> get books {
    final professionalReadBooks = widget.professionalRead.professionalReadBooks;
    if (professionalReadBooks == null || professionalReadBooks is! List) {
      return [];
    }
    return professionalReadBooks.map<Map<String, dynamic>>((item) {
      final bookJson = item['book'] ?? {};

      // Create Book model
      final bookModel = Book.fromJson(bookJson);

      log(bookModel.authors.toString());

      final bookImage = bookJson['image'] ?? '';
      final fullImageUrl = bookImage.isNotEmpty ? '${ApiEndpoints.imageBaseUrl}$bookImage' : '';

      return {
        'model': bookModel, // ← add real model here
        'title': bookJson['name'] ?? '',
        'author': bookModel.authors.isNotEmpty ? bookModel.authors.first.name : 'unknown'.tr,
        'description': item['comment'] ?? '',
        'imageUrl': fullImageUrl,
        'buttonText': 'read_button_t'.tr,
        'buttonColor': Colors.grey[200],
        'buttonTextColor': Colors.black,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final reader = widget.professionalRead;
    return Scaffold(
      appBar: CustomAppBar(title: '', leadingText: 'leading_text'.tr),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image with Glass Effect Gradient
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 400,
                          decoration: const BoxDecoration(color: Colors.white),
                          child: reader.fullImageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: reader.fullImageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => LoadingWidget(removeBackWhite: true),

                                  // Error placeholder
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[300],
                                    child: CustomIcon(
                                      title: IconConstants.libraryFilled,
                                      height: 24,
                                      width: 24,
                                      color: Colors.black,
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  'assets/images/book.png',
                                  fit: BoxFit.cover,
                                  color: Colors.black,
                                ),
                        ),

                        // Glass effect gradient overlay at bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: Theme.of(context).brightness == Brightness.dark
                                    ? [
                                        Colors.black.withOpacity(0.0),
                                        Colors.black.withOpacity(0.3),
                                        Colors.black.withOpacity(0.7),
                                        Colors.black.withOpacity(0.95),
                                        Colors.black,
                                      ]
                                    : [
                                        Colors.white.withOpacity(0.0),
                                        Colors.white.withOpacity(0.3),
                                        Colors.white.withOpacity(0.7),
                                        Colors.white.withOpacity(0.95),
                                        Colors.white,
                                      ],
                                stops: const [0.0, 0.3, 0.6, 0.85, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Profile Info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            reader.name,
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16, top: 4),
                            child: Text(
                              reader.position,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reader.description,
                                maxLines: isExpanded ? null : 3,
                                overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: StringConstants.GilroyMedium,
                                  color: Colors.grey[600],
                                  height: 1.5,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isExpanded = !isExpanded;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    isExpanded ? 'show_less_t'.tr : 'show_more_t'.tr,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: StringConstants.GilroyBold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    if (books.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          return Column(
                            children: [
                              BookCardProfRedares(
                                book: book['model'],
                                title: book['title'],
                                author: book['author'],
                                description: book['description'],
                                imageUrl: book['imageUrl'],
                                buttonText: book['buttonText'],
                                buttonColor: book['buttonColor'],
                                buttonTextColor: book['buttonTextColor'],
                              ),
                            ],
                          );
                        },
                      )
                    else
                      NoGenresAvailable(
                        title: 'no_books_found'.tr,
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
