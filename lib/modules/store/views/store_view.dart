import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/widgets/navigation/custom_tabbar.dart';
import 'package:elkitap/modules/store/controllers/all_books_controller.dart';
import 'package:elkitap/modules/store/controllers/all_geners_controller.dart';
import 'package:elkitap/modules/store/controllers/collections_controller.dart';
import 'package:elkitap/modules/store/controllers/pro_readers_controller.dart';
import 'package:elkitap/modules/store/widgets/featured_books_section.dart';
import 'package:elkitap/modules/store/widgets/generic_list_widget.dart';
import 'package:elkitap/modules/store/widgets/list_profile_widget.dart';
import 'package:elkitap/modules/store/widgets/main_collections.dart';
import 'package:elkitap/modules/store/widgets/top_of_week_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class StoreViewScreen extends StatefulWidget {
  const StoreViewScreen({super.key});

  @override
  State<StoreViewScreen> createState() => _StoreViewScreenState();
}

class _StoreViewScreenState extends State<StoreViewScreen> {
  int selectedTab = 0;

  GetAllBooksController _getOrCreateBooksController(String tag) {
    if (Get.isRegistered<GetAllBooksController>(tag: tag)) {
      return Get.find<GetAllBooksController>(tag: tag);
    }
    return Get.put(GetAllBooksController(), tag: tag);
  }

  AllGenresController _getOrCreateGenresController() {
    if (Get.isRegistered<AllGenresController>()) {
      return Get.find<AllGenresController>();
    }
    return Get.put(AllGenresController());
  }

  BookCollectionController _getOrCreateCollectionsController() {
    if (Get.isRegistered<BookCollectionController>()) {
      return Get.find<BookCollectionController>();
    }
    return Get.put(BookCollectionController());
  }

  ProfessionalReadsController _getOrCreateProfessionalReadsController() {
    if (Get.isRegistered<ProfessionalReadsController>()) {
      return Get.find<ProfessionalReadsController>();
    }
    return Get.put(ProfessionalReadsController());
  }

  BoxDecoration _gradientDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: Theme.of(context).brightness == Brightness.dark ? [Color(0x001C1C1E), Color(0xFF1C1C1E)] : [Color(0x00E5E5EA), Color(0xFFE5E5EA)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));

    final isAudioMode = selectedTab == 1;
    _getOrCreateBooksController('featured_books_$selectedTab').refreshBooks();
    _getOrCreateBooksController('top_of_week_$selectedTab').refreshBooks();
    _getOrCreateGenresController().refreshGenres(withAudio: isAudioMode);
    _getOrCreateCollectionsController().refreshCollections(isAudioMode: isAudioMode);
    _getOrCreateProfessionalReadsController().refreshProfessionalReads(isAudioMode: isAudioMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(),
                  CustomTabBar(
                    onTabChanged: (index) {
                      setState(() {
                        selectedTab = index;
                      });
                      // Refresh genres when tab changes
                      final isAudioMode = index == 1;
                      _getOrCreateGenresController().refreshGenres(withAudio: isAudioMode);
                    },
                  ),
                  if (selectedTab == 0) ...[
                    Container(decoration: _gradientDecoration(context), child: FeaturedBooksSection(tabIndex: selectedTab)),
                    Container(decoration: _gradientDecoration(context), child: TopOfWeekSection(tabIndex: selectedTab)),
                    const SizedBox(height: 24),
                    Container(decoration: _gradientDecoration(context), child: const MainCollectionsSection(tabIndex: 0)),
                    Container(decoration: _gradientDecoration(context), child: const ListProfileWidget(tabIndex: 0)),
                    GenericListWidget(isAudioMode: false),
                  ] else ...[
                    Container(decoration: _gradientDecoration(context), child: FeaturedBooksSection(tabIndex: selectedTab)),
                    Container(decoration: _gradientDecoration(context), child: TopOfWeekSection(tabIndex: selectedTab)),
                    Container(decoration: _gradientDecoration(context), margin: EdgeInsets.symmetric(vertical: 24), child: const MainCollectionsSection(tabIndex: 1)),
                    Container(decoration: _gradientDecoration(context), child: const ListProfileWidget(tabIndex: 1)),
                    GenericListWidget(isAudioMode: true),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: SvgPicture.asset(Theme.of(context).brightness == Brightness.dark ? IconConstants.elkitapDark : IconConstants.elkitap)),
      ],
    );
  }
}
