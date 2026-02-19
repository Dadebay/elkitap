import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:elkitap/modules/reader/models/reader_theme_model.dart';

/// UI builder helper for reader overlays and controls
class ReaderUIBuilder {
  /// Build top overlay bar with close button, title, and menu
  static Widget buildTopOverlay({
    required bool showControls,
    required ReaderThemeModel theme,
    required String bookTitle,
    required VoidCallback onClose,
    required VoidCallback onMenuTap,
  }) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      top: showControls ? 0 : -100,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 350),
        opacity: showControls ? 1.0 : 0.0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.backgroundColor,
                theme.backgroundColor.withOpacity(0.0),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 35,
                        height: 35,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.buttonBackgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/icons/x.png',
                          width: 16,
                          height: 16,
                          color: theme.buttonColor,
                        ),
                      )),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        bookTitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onMenuTap,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: theme.buttonBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.more_horiz,
                        color: theme.buttonColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build minimal chapter title overlay for focus mode
  static Widget buildMinimalChapterTitle({
    required bool showControls,
    required String chapterTitle,
  }) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      top: showControls ? -100 : 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 350),
        opacity: showControls ? 0.0 : 1.0,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16).copyWith(top: 10),
            child: Text(
              chapterTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build bottom overlay bar with chapter drawer, page counter, and theme settings
  static Widget buildBottomOverlay({
    required bool showControls,
    required ReaderThemeModel theme,
    required int currentPage,
    required int totalPages,
    required bool isLoadingPages,
    required VoidCallback onChapterDrawerTap,
    required VoidCallback onThemeSettingsTap,
    required BuildContext context,
    required bool isProgressLongPressed,
    required double tempSliderValue,
    required double lastProgressFactor,
    required Function(DragStartDetails) onHorizontalDragStart,
    required Function(DragUpdateDetails) onHorizontalDragUpdate,
    required Function(DragEndDetails) onHorizontalDragEnd,
    bool isRegeneratingLocations = false,
  }) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      bottom: (showControls || isProgressLongPressed) ? 10 : -100,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 350),
        opacity: (showControls || isProgressLongPressed) ? 1.0 : 0.0,
        child: Container(
          decoration: theme.isDark
              ? null
              : BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      theme.backgroundColor,
                      theme.backgroundColor.withOpacity(0.0),
                    ],
                  ),
                ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Chapter drawer button (hamburger menu)
                  AnimatedOpacity(
                    opacity: isProgressLongPressed ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: onChapterDrawerTap,
                      child: Container(
                        width: 38,
                        height: 38,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.buttonBackgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/icons/content_list.png',
                          color: theme.buttonColor,
                        ),
                      ),
                    ),
                  ),
                  // Page counter with horizontal drag navigation
                  Expanded(
                    child: GestureDetector(
                      onHorizontalDragStart: onHorizontalDragStart,
                      onHorizontalDragUpdate: onHorizontalDragUpdate,
                      onHorizontalDragEnd: onHorizontalDragEnd,
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.symmetric(horizontal: isProgressLongPressed ? 6 : 12),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.buttonBackgroundColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: (isLoadingPages || isRegeneratingLocations)
                              ? const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Progress bar background
                                    Positioned.fill(
                                      child: TweenAnimationBuilder<double>(
                                        duration: const Duration(milliseconds: 200),
                                        tween: Tween<double>(
                                          begin: lastProgressFactor,
                                          end: totalPages > 0 ? (isProgressLongPressed ? (tempSliderValue * totalPages).round().clamp(1, totalPages) : currentPage) / totalPages : 0.0,
                                        ),
                                        builder: (context, value, child) {
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(20),
                                            child: FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: value.clamp(0.0, 1.0),
                                              child: Container(
                                                color: theme.buttonColor.withOpacity(0.15),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    // Page text
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: isProgressLongPressed ? '${(tempSliderValue * totalPages).round().clamp(1, totalPages)}' : '$currentPage',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: theme.textColor.withOpacity(0.4),
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' / $totalPages',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w400,
                                              color: theme.textColor.withOpacity(0.4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  // Theme settings button (Aa)
                  AnimatedOpacity(
                    opacity: isProgressLongPressed ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: onThemeSettingsTap,
                      child: Container(
                        width: 40,
                        height: 40,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.buttonBackgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/icons/font_logo.png',
                          color: theme.buttonColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build minimal page indicator for focus mode
  static Widget buildMinimalPageIndicator({
    required bool showControls,
    required int currentPage,
  }) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      bottom: showControls ? -100 : 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 350),
        opacity: showControls ? 0.0 : 1.0,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20).copyWith(bottom: 0),
            child: Center(
              child: Text(
                '$currentPage',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build popup indicator shown during long press navigation
  static Widget buildLongPressPageIndicator({
    required bool isProgressLongPressed,
    required ReaderThemeModel theme,
    required int currentPage,
    required int totalPages,
    required double tempSliderValue,
    required String chapterTitle,
    required BuildContext context,
    required List<dynamic> chapters,
    required Map<String, int> chapterPages,
  }) {
    // Show only during long press
    if (!isProgressLongPressed) return const SizedBox.shrink();

    final displayPage = (tempSliderValue * totalPages).round().clamp(1, totalPages);

    // Find the chapter for the display page using chapterPages map
    String displayChapterTitle = chapterTitle;
    if (chapters.isNotEmpty && chapterPages.isNotEmpty) {
      // Find the chapter whose start page is <= displayPage
      for (int i = chapters.length - 1; i >= 0; i--) {
        final chapter = chapters[i];
        final startPage = chapterPages[chapter.href] ?? 0;
        if (displayPage >= startPage && startPage > 0) {
          // Clean up chapter title - remove extra whitespace and newlines
          final cleanTitle = (chapter.title ?? chapterTitle).trim().replaceAll(RegExp(r'\s+'), ' ');
          displayChapterTitle = cleanTitle;
          print('🔍 Page $displayPage → $cleanTitle (starts at $startPage, href: ${chapter.href})');
          break;
        }
      }
      if (displayChapterTitle == chapterTitle) {
        print('⚠️ No matching chapter found for page $displayPage (total chapters: ${chapters.length}, mapped: ${chapterPages.length})');
        // Debug: print all chapter pages
        chapterPages.forEach((href, page) {
          print('  📖 $href → page $page');
        });
      }
    } else {
      print('⚠️ Chapter lookup failed - chapters: ${chapters.length}, chapterPages: ${chapterPages.length}');
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: Platform.isIOS ? 120 : 80,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.68,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: theme.isDark ? Color(0xff37373a) : Color.fromARGB(255, 229, 229, 229),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: theme.isDark ? Color(0xff37373a).withOpacity(0.2) : Color(0xffd5d5d7).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Page $displayPage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  displayChapterTitle.isNotEmpty ? displayChapterTitle.trim().replaceAll(RegExp(r'\s+'), ' ') : 'Reading',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textColor.withOpacity(0.6),
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
