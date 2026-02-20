import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/navigation/custom_appbar.dart';
import 'package:elkitap/modules/genre/view/gerer_collections.dart';
import 'package:elkitap/modules/genre/view/sub_featured_books_section.dart';
import 'package:elkitap/modules/genre/view/sub_topof_week_section.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/modules/store/controllers/all_geners_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GenrsDetailViewScreen extends StatefulWidget {
  final String title;
  final int id;
  final bool isAudioMode;

  const GenrsDetailViewScreen({
    super.key,
    required this.title,
    required this.id,
    this.isAudioMode = false,
  });

  @override
  State<GenrsDetailViewScreen> createState() => _GenrsDetailViewScreenState();
}

class _GenrsDetailViewScreenState extends State<GenrsDetailViewScreen> {
  int selectedTab = 0;
  late GetAllBooksController recommendedController;
  late GetAllBooksController topOfWeekController;

  @override
  void initState() {
    super.initState();
    // Create separate controller instances for each section
    recommendedController = Get.put(
      GetAllBooksController(),
      tag: 'genre_recommended_${widget.id}',
    );
    topOfWeekController = Get.put(
      GetAllBooksController(),
      tag: 'genre_topweek_${widget.id}',
    );

    // Set genre_id and genre name
    recommendedController.genreId.value = widget.id;
    recommendedController.genreName.value = widget.title;
    recommendedController.getRecommendedBooks();

    topOfWeekController.genreId.value = widget.id;
    topOfWeekController.genreName.value = widget.title;
    topOfWeekController.getTopOfTheWeekBooks();
  }

  @override
  void dispose() {
    // Clean up controllers
    Get.delete<GetAllBooksController>(tag: 'genre_recommended_${widget.id}');
    Get.delete<GetAllBooksController>(tag: 'genre_topweek_${widget.id}');
    super.dispose();
  }

  // Refresh function
  Future<void> _onRefresh() async {
    try {
      recommendedController.getRecommendedBooks();
      topOfWeekController.getTopOfTheWeekBooks();
      Get.find<AllGenresController>().fetchSubGenres(widget.id);

      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: '', leadingText: 'leading_text'.tr),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: Theme.of(context).primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Header(widget.title),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: Theme.of(context).brightness == Brightness.dark ? [Color(0x001C1C1E), Color(0xFF1C1C1E)] : [Color(0x00E5E5EA), Color(0xFFE5E5EA)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SubFeaturedBooksSection(tabIndex: selectedTab, genreId: widget.id),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: Theme.of(context).brightness == Brightness.dark
                            ? [Color(0x001C1C1E), Color(0xFF1C1C1E)] // dark mode gradient
                            : [Color(0x00E5E5EA), Color(0xFFE5E5EA)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SubTopOfWeekSection(genreId: widget.id),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: Theme.of(context).brightness == Brightness.dark ? [Color(0x001C1C1E), Color(0xFF1C1C1E)] : [Color(0x00E5E5EA), Color(0xFFE5E5EA)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: CollectionsGenreSection(id: widget.id),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Header extends StatelessWidget {
  final String title;
  Header(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 30, right: 26, top: 0, bottom: 10),
      child: Text(
        title,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 26, fontFamily: StringConstants.GilroyBold, fontWeight: FontWeight.bold),
      ),
    );
  }
}
