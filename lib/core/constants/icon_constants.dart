import 'package:flutter/material.dart';

@immutable
class IconConstants {
  const IconConstants._();

  // Main Logo
  static const String elkitap = 'assets/icons/e.svg';
  static const String elkitapDark = 'assets/icons/e1.svg';
  static const String addtoshelf = 'assets/icons/add_to_shelf.png';
  static const String savemybooks = 'assets/icons/save_my_books.png';
  static const String bookdescription = 'assets/icons/book_description.png';

  // Navigation & Bottom Bar
  static const String libraryFilled = 'assets/icons/library_filled.svg';
  static const String libraryFilledG = 'assets/icons/library_f.svg';
  static const String bag = 'assets/icons/bag.svg';
  static const String bagFilledG = 'assets/icons/bag_filled_g.svg';
  static const String search = 'assets/icons/search.svg';
  static const String searchActive = 'assets/icons/search_2.svg';

  // Library & Collections
  static const String i1 = 'assets/icons/i1.svg';
  static const String m1 = 'assets/icons/m1.svg';
  static const String m2 = 'assets/icons/m2.svg';
  static const String m3 = 'assets/icons/m3.svg';
  static const String m4 = 'assets/icons/m4.svg';
  static const String m5 = 'assets/icons/m5.svg';

  // Audio Player Controls
  static const String a1 = 'assets/icons/a1.svg';
  static const String a2 = 'assets/icons/a2.svg';
  static const String a3 = 'assets/icons/a3.svg';
  static const String a4 = 'assets/icons/a4.svg';
  static const String a6 = 'assets/icons/a6.svg';
  static const String a7 = 'assets/icons/a7.svg';
  static const String a9 = 'assets/icons/a9.svg';
  static const String a10 = 'assets/icons/a10.svg';
  static const String a11 = 'assets/icons/a11.svg';
  static const String a12 = 'assets/icons/a12.svg';
  static const String a13 = 'assets/icons/do1.svg';
  static const String a14 = 'assets/icons/do3.svg';

  // Download & Actions
  static const String d1 = 'assets/icons/d1.svg';
  static const String d2 = 'assets/icons/d2.svg';
  static const String d5 = 'assets/icons/d5.svg';
  static const String d6 = 'assets/icons/d6.svg';
  static const String d7 = 'assets/icons/d7.svg';
  static const String d8 = 'assets/icons/d8.svg';
  static const String d9 = 'assets/icons/d9.svg';
  static const String d10 = 'assets/icons/d10.svg';
  static const String d11 = 'assets/icons/d11.svg';

  // Profile & Settings
  static const String p1 = 'assets/icons/p1.svg';
  static const String p2 = 'assets/icons/p2.svg';
  static const String p3 = 'assets/icons/p3.svg';
  static const String p4 = 'assets/icons/p4.svg';
  static const String p5 = 'assets/icons/p5.svg';
  static const String p6 = 'assets/icons/p6.svg';
  static const String p7 = 'assets/icons/p7.svg';
  static const String p8 = 'assets/icons/p8.svg';
  static const String p9 = 'assets/icons/p9.svg';
  static const String p10 = 'assets/icons/p10.svg';
  static const String p11 = 'assets/icons/p11.svg';

  // Help & Support
  static const String h1 = 'assets/icons/h1.svg';
  static const String h2 = 'assets/icons/h2.svg';
  static const String h3 = 'assets/icons/h3.svg';
}

@immutable
class ImageConstants {
  const ImageConstants._();

  // Default Images
  static const String book = 'assets/images/book.png';
  static const String bg1 = 'assets/images/bg1.png';
  static const String bg2 = 'assets/images/bg2.png';

  // Audio & Player
  static const String b4 = 'assets/images/b4.png';
  static const String b6 = 'assets/images/b6.png';
  static const String b8 = 'assets/images/b8.png';

  // Account & Subscription
  static const String a2 = 'assets/images/a2.png';
  static const String a3 = 'assets/images/a3.png';
  static const String subscribed = 'assets/images/subscribed.png';

  // Loading & UI
  static const String l1 = 'assets/images/l1.png';
  static const String ic1 = 'assets/images/ic1.png';

  // Get book cover by index (b1.png, b2.png, etc.)
  static String getBookCover(int index) => 'assets/images/b$index.png';
}
