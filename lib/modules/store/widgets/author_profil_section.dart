import 'package:cached_network_image/cached_network_image.dart';
import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/search/models/authors_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';

class AuthorProfileSection extends StatefulWidget {
  final Author author;
  const AuthorProfileSection({super.key, required this.author});

  @override
  State<AuthorProfileSection> createState() => _AuthorProfileSectionState();
}

class _AuthorProfileSectionState extends State<AuthorProfileSection> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    bool theme = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // Profile Image
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 400,
              color: Colors.white,
              child: (widget.author.image == null || widget.author.image!.isEmpty)
                  ? Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.grey[500],
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: ApiEndpoints.imageBaseUrl + widget.author.image!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: LoadingWidget(removeBackWhite: true),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: CustomIcon(
                          title: IconConstants.libraryFilled,
                          height: 24,
                          width: 24,
                          color: Colors.black,
                        ),
                      ),
                    ),
            ),
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
                    colors: theme
                        ? [
                            Color(0xFF1C1C1E).withOpacity(0),
                            Color(0xFF1C1C1E).withOpacity(0.4),
                            Color(0xFF1C1C1E).withOpacity(0.7),
                            Color(0xFF1C1C1E).withOpacity(0.85),
                            Color(0xFF1C1C1E),
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
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: theme
                  ? [Color(0xFF1C1C1E), Color(0xFF1C1C1E)] // dark mode gradient
                  : [Color(0x00E5E5EA), Color(0xFFE5E5EA)],
              begin: theme ? Alignment.bottomCenter : Alignment.topCenter,
              end: theme ? Alignment.topCenter : Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.author.name,
                  style: TextStyle(
                    fontSize: 28,
                    fontFamily: StringConstants.GilroyRegular,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'author'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: StringConstants.SFPro,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.author.bio != null && widget.author.bio!.isNotEmpty)
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        fontFamily: StringConstants.GilroyMedium,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: isExpanded ? widget.author.bio : (widget.author.bio!.length > 150 ? '${widget.author.bio!.substring(0, 150)}...' : widget.author.bio),
                        ),
                        if (widget.author.bio!.length > 150)
                          TextSpan(
                            text: isExpanded ? ' ${'show_less_t'.tr}' : ' ${'show_more_t'.tr}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              fontFamily: StringConstants.SFPro,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                setState(() {
                                  isExpanded = !isExpanded;
                                });
                              },
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
