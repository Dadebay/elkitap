import 'package:elkitap/core/widgets/navigation/bottom_nav_bar.dart';

import 'package:elkitap/modules/library/views/notes_view.dart';

import 'package:elkitap/modules/profile/views/profile_view.dart';

import 'package:elkitap/modules/store/views/all_geners_view.dart';

import 'package:elkitap/modules/store/views/profesionals_read_view.dart';

import 'package:get/get.dart';

import 'app_routes.dart';

abstract class AppPages {
  static final pages = [
    GetPage(name: Routes.BOTTOMNAV, page: () => const BottomNavScreen()),
    GetPage(name: Routes.PROFILE, page: () => const ProfileScreen()),
    GetPage(name: Routes.NOTES, page: () => const NotesScreen()),
    GetPage(name: Routes.ALL_GENRES, page: () => const AllGenresView()),
    GetPage(
      name: Routes.PROFESSIONALS_READ,
      page: () => const ProfessionalsReadView(),
    ),
  ];
}
