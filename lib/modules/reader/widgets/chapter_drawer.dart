// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:elkitap/modules/reader/models/reader_theme_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:get/get.dart';

class ChapterDrawer {
  static Future<void> show(
    BuildContext context,
    EpubController controller, {
    String? bookTitle,
    int? currentPage,
    int? totalPages,
    String? currentCfi,
    String? currentHref,
    String? bookCoverUrl,
    bool isLoadingPages = false,
    ReaderThemeModel? theme,
  }) async {
    final ReaderThemeModel usedTheme = theme ?? ReaderThemeModel.lightThemes.first;
    final chapters = controller.getChapters();
    final metadata = await controller.getMetadata();

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: usedTheme.backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CoverImage(coverBase64: bookCoverUrl ?? metadata.coverImage, placeholderColor: usedTheme.buttonBackgroundColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bookTitle ?? metadata.title ?? 'contents_t'.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xff858589),
                              fontFamily: 'Gilroy',
                              fontSize: 17,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (isLoadingPages)
                            Row(
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      usedTheme.textColor.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Loading page count...',
                                  style: TextStyle(
                                    color: usedTheme.textColor.withOpacity(0.55),
                                    fontSize: 13,
                                    fontFamily: 'Gilroy',
                                  ),
                                ),
                              ],
                            )
                          else if (totalPages != null && totalPages > 0)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    text: 'page_text'.tr,
                                    style: TextStyle(
                                      color: usedTheme.textColor.withOpacity(0.55),
                                      fontSize: 13,
                                      fontFamily: 'Gilroy',
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${currentPage ?? 1} / $totalPages',
                                        style: TextStyle(
                                          color: usedTheme.textColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.5,
                                          fontFamily: 'Gilroy',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Text(
                                //   '${chapters.length} ${'chapters_t'.tr}',
                                //   style: TextStyle(
                                //     color: usedTheme.textColor.withOpacity(0.45),
                                //     fontSize: 12,
                                //     fontFamily: 'Gilroy',
                                //   ),
                                // ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: CircleAvatar(
                        backgroundColor: usedTheme.buttonBackgroundColor,
                        radius: 16,
                        child: Icon(
                          Icons.close,
                          color: usedTheme.buttonColor,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: usedTheme.textColor.withOpacity(0.15)),
              Expanded(
                child: FutureBuilder<Map<String, int>>(
                  future: _getChapterPages(controller, chapters, isLoadingPages),
                  builder: (context, snapshot) {
                    final chapterPages = snapshot.data ?? {};
                    final hasHrefMatch = currentHref != null &&
                        currentHref.isNotEmpty &&
                        chapters.any((chapter) {
                          final cleanCurrentHref = currentHref.split('#').first;
                          final cleanChapterHref = chapter.href.split('#').first;
                          return cleanChapterHref == cleanCurrentHref || cleanCurrentHref.endsWith(cleanChapterHref) || cleanChapterHref.endsWith(cleanCurrentHref);
                        });
                    final hasCfiMatch = currentCfi != null && currentCfi.isNotEmpty && chapters.any((chapter) => _cfiMatchesChapter(currentCfi, chapter));

                    // Build sorted page list for calculating page counts per chapter
                    final List<int> sortedStartPages = [];
                    for (final chapter in chapters) {
                      final page = chapter.startPage ?? chapterPages[chapter.href];
                      if (page != null) sortedStartPages.add(page);
                    }
                    sortedStartPages.sort();

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: chapters.length,
                      separatorBuilder: (context, index) {
                        final currentLevel = _getChapterLevel(chapters[index]);
                        final nextLevel = index + 1 < chapters.length ? _getChapterLevel(chapters[index + 1]) : 0;

                        if (currentLevel > 0 && nextLevel > 0) {
                          return Divider(
                            height: 1,
                            thickness: 0.3,
                            color: usedTheme.textColor.withOpacity(0.12),
                            indent: 16,
                            endIndent: 16,
                          );
                        }

                        return Divider(
                          height: 1,
                          thickness: 0.5,
                          color: usedTheme.textColor.withOpacity(0.18),
                          indent: 16,
                        );
                      },
                      itemBuilder: (context, index) {
                        final chapter = chapters[index];
                        final level = _getChapterLevel(chapter);
                        // Use chapter.startPage (from locationFromCfi),
                        // fallback to chapterPages map
                        final rawPageNumber = chapter.startPage ?? chapterPages[chapter.href];

                        // Determine if this is the current chapter based on current href
                        final bool isCurrentChapter = _isCurrentChapter(
                          rawPageNumber,
                          currentPage,
                          index,
                          chapters.length,
                          chapterPages,
                          currentCfi,
                          chapter,
                          currentHref,
                          hasHrefMatch,
                          hasCfiMatch,
                        );

                        final int? pageNumber = rawPageNumber;

                        // Calculate page count for this chapter
                        int? chapterPageCount;
                        if (pageNumber != null && totalPages != null && totalPages > 0) {
                          // Find next chapter's start page
                          int? nextStartPage;
                          for (int j = index + 1; j < chapters.length; j++) {
                            final nextPage = chapters[j].startPage ?? chapterPages[chapters[j].href];
                            if (nextPage != null && nextPage > pageNumber) {
                              nextStartPage = nextPage;
                              break;
                            }
                          }
                          if (nextStartPage != null) {
                            chapterPageCount = nextStartPage - pageNumber;
                          } else {
                            // Last chapter: remaining pages
                            chapterPageCount = totalPages - pageNumber + 1;
                          }
                          if (chapterPageCount < 1) chapterPageCount = null;
                        }

                        return GestureDetector(
                          onTap: () {
                            final hasAnchor = chapter.id.isNotEmpty && !chapter.href.contains('#');
                            final target = hasAnchor ? '${chapter.href}#${chapter.id}' : chapter.href;
                            controller.display(cfi: target);
                            Navigator.pop(context);
                          },
                          child: Container(
                            color: isCurrentChapter ? usedTheme.buttonBackgroundColor.withOpacity(0.6) : usedTheme.backgroundColor,
                            padding: EdgeInsets.symmetric(vertical: 18, horizontal: 25),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Text(
                                      chapter.title.trim(),
                                      textAlign: TextAlign.start,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isCurrentChapter ? usedTheme.textColor : Color(0xff858589),
                                        fontSize: level > 0 ? 14 : 16,
                                        fontFamily: 'Gilroy',
                                        fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                // if (pageNumber != null)
                                //   Column(
                                //     crossAxisAlignment: CrossAxisAlignment.end,
                                //     mainAxisSize: MainAxisSize.min,
                                //     children: [
                                //       Text(
                                //         '$pageNumber',
                                //         style: TextStyle(
                                //           color: isCurrentChapter ? usedTheme.textColor : Color(0xff858589).withOpacity(0.8),
                                //           fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.w600,
                                //           fontFamily: 'Gilroy',
                                //           fontSize: level > 0 ? 14 : 16,
                                //         ),
                                //       ),
                                //     ],
                                //   )
                                // else if (isLoading)
                                //   Container(
                                //     width: 14,
                                //     height: 14,
                                //     child: CircularProgressIndicator(
                                //       strokeWidth: 2,
                                //       valueColor: AlwaysStoppedAnimation<Color>(
                                //         isCurrentChapter ? usedTheme.textColor : usedTheme.textColor.withOpacity(0.5),
                                //       ),
                                //     ),
                                //   ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static int _getChapterLevel(EpubChapter chapter) {
    // Check for subchapter indicators
    final title = chapter.title;

    // Count leading spaces or indentation
    if (title.startsWith('    ') || title.startsWith('\t\t')) return 2;
    if (title.startsWith('  ') || title.startsWith('\t')) return 1;

    // Check for bullet points or other indicators
    if (title.trimLeft().startsWith('•') || title.trimLeft().startsWith('-') || title.trimLeft().startsWith('○')) {
      return 1;
    }

    return 0;
  }

  static bool _cfiMatchesChapter(String currentCfi, EpubChapter chapter) {
    if (currentCfi.isEmpty) return false;

    final anchorMatch = RegExp(r'\[([^\]]+)\]').firstMatch(currentCfi);
    if (anchorMatch != null) {
      final anchorId = anchorMatch.group(1);
      if (anchorId != null && anchorId.isNotEmpty) {
        if (chapter.id == anchorId) {
          return true;
        }
        if (chapter.href.contains('#$anchorId') || chapter.href.endsWith(anchorId)) {
          return true;
        }
      }
    }

    final spineMatch = RegExp(r'/6/(\d+)!').firstMatch(currentCfi);
    if (spineMatch != null) {
      final spineIndex = spineMatch.group(1);
      if (spineIndex != null && spineIndex.isNotEmpty) {
        if (chapter.href.contains('_$spineIndex.') || chapter.href.contains('_0$spineIndex.')) {
          return true;
        }
      }
    }

    return false;
  }

  static bool _isCurrentChapter(
    int? chapterPageNumber,
    int? currentPage,
    int chapterIndex,
    int totalChapters,
    Map<String, int> chapterPages,
    String? currentCfi,
    EpubChapter chapter,
    String? currentHref,
    bool hasHrefMatch,
    bool hasCfiMatch,
  ) {
    // First try to match by href (most accurate)
    if (currentHref != null && currentHref.isNotEmpty) {
      // Remove fragment identifiers (#...) for comparison
      String cleanCurrentHref = currentHref.split('#').first;
      String cleanChapterHref = chapter.href.split('#').first;

      // Direct match
      if (cleanChapterHref == cleanCurrentHref) {
        return true;
      }

      // Check if current href ends with chapter href (for relative paths)
      if (cleanCurrentHref.endsWith(cleanChapterHref) || cleanChapterHref.endsWith(cleanCurrentHref)) {
        return true;
      }
      // If any chapter matched the href, don't fall back for non-matching rows
      if (hasHrefMatch) {
        return false;
      }
    }

    // Second try: match by CFI if available
    if (currentCfi != null && currentCfi.isNotEmpty) {
      // Try to match by anchor id inside CFI, e.g. [calibre_toc_2]
      final anchorMatch = RegExp(r'\[([^\]]+)\]').firstMatch(currentCfi);
      if (anchorMatch != null) {
        final anchorId = anchorMatch.group(1);
        if (anchorId != null && anchorId.isNotEmpty) {
          if (chapter.id == anchorId) {
            return true;
          }
          if (chapter.href.contains('#$anchorId') || chapter.href.endsWith(anchorId)) {
            return true;
          }
        }
      }

      // Extract spine index from CFI: epubcfi(/6/22!/4/56/1:214) -> 22
      final spineMatch = RegExp(r'/6/(\d+)!').firstMatch(currentCfi);
      if (spineMatch != null) {
        final spineIndex = spineMatch.group(1);
        // Check if chapter href contains this spine index
        // e.g., index_split_010.xhtml contains "010" which could match spine index
        if (chapter.href.contains('_$spineIndex.') || chapter.href.contains('_0$spineIndex.')) {
          return true;
        }
      }
    }

    // If we have a CFI and any chapter matched, do not fall back to page numbers
    if (currentCfi != null && currentCfi.isNotEmpty && hasCfiMatch) {
      return false;
    }

    // Fallback to page number comparison
    if (chapterPageNumber == null || currentPage == null) {
      return false;
    }

    // Get next chapter's page number from the chapters list
    final sortedPages = chapterPages.values.toList()..sort();

    // Find the current chapter's position in sorted pages
    final currentChapterPageIndex = sortedPages.indexOf(chapterPageNumber);

    if (currentChapterPageIndex < 0) {
      return false;
    }

    // Get the next chapter's page
    final nextChapterPage = currentChapterPageIndex + 1 < sortedPages.length ? sortedPages[currentChapterPageIndex + 1] : null;

    // Current chapter if currentPage is between this chapter's page and next chapter's page
    if (nextChapterPage != null) {
      final isActive = currentPage >= chapterPageNumber && currentPage < nextChapterPage;
      return isActive;
    } else {
      // Last chapter - just check if current page is >= chapter page
      final isActive = currentPage >= chapterPageNumber;
      return isActive;
    }
  }

  static Future<Map<String, int>> _getChapterPages(
    EpubController controller,
    List<EpubChapter> chapters,
    bool isLoadingPages,
  ) async {
    final Map<String, int> chapterPages = {};

    if (isLoadingPages || chapters.isEmpty) {
      return chapterPages;
    }

    try {
      final pageInfo = await controller.getPageInfo();
      final totalPages = (pageInfo['totalPages'] as num?)?.toInt() ?? 1;

      // Don't build chapter pages with invalid total pages
      if (totalPages <= 10) {
        return chapterPages;
      }

      // Try to get accurate page numbers first
      try {
        final accuratePages = await controller.getAllChapterPages();

        if (accuratePages.isNotEmpty) {
          // Merge accurate pages into chapterPages as we find them
          // This allows mixing accurate pages with estimates for missing ones
          for (final chapter in chapters) {
            // Try direct match
            if (accuratePages.containsKey(chapter.href)) {
              chapterPages[chapter.href] = accuratePages[chapter.href]!;
              continue;
            }

            // Try stripping anchor
            final hrefNoAnchor = chapter.href.split('#').first;
            if (accuratePages.containsKey(hrefNoAnchor)) {
              chapterPages[chapter.href] = accuratePages[hrefNoAnchor]!;
              continue;
            }

            // Try finding by ending match (for relative paths)
            try {
              final matchingKey = accuratePages.keys.firstWhere(
                (key) => key.endsWith(chapter.href) || chapter.href.endsWith(key),
                orElse: () => '',
              );

              if (matchingKey.isNotEmpty) {
                chapterPages[chapter.href] = accuratePages[matchingKey]!;
              }
            } catch (e) {
              // Ignore errors during matching
            }
          }
        }
      } catch (e) {
        ('❌ CHAPTER DRAWER ERROR: Failed to get accurate pages: $e');
      }

      // Note: getPageFromCfi has a bridge issue - JavaScript finds pages
      // but Dart receives null. Using alternative approach with chapter indices.

      // Validate mapping and fill missing pages with estimates
      for (int i = 0; i < chapters.length; i++) {
        final chapter = chapters[i];

        // If we already have a page number from accurate mapping, skip estimation
        if (chapterPages.containsKey(chapter.href)) {
          continue;
        }

        // Calculate estimated start page based on chapter position
        // Chapters are typically evenly distributed, but we'll improve this
        final estimatedPage = ((i * totalPages) / chapters.length).round() + 1;
        final clampedPage = estimatedPage.clamp(1, totalPages);

        chapterPages[chapter.href] = clampedPage;
      }
    } catch (e) {
      print('❌ CHAPTER DRAWER ERROR: Exception during page mapping: $e');
      for (int i = 0; i < chapters.length; i++) {
        chapterPages[chapters[i].href] = i + 1;
      }
    }

    return chapterPages;
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.coverBase64, required this.placeholderColor});

  final String? coverBase64;
  final Color placeholderColor;

  @override
  Widget build(BuildContext context) {
    if (coverBase64 != null && coverBase64!.isNotEmpty) {
      if (coverBase64!.startsWith('http://') || coverBase64!.startsWith('https://')) {
        return Container(
          height: 80,
          width: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: placeholderColor,
          ),
          clipBehavior: Clip.hardEdge,
          child: Image.network(
            coverBase64!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.broken_image, color: Colors.white));
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            },
          ),
        );
      }

      // Try to decode as base64
      try {
        final bytes = base64.decode(coverBase64!);
        return Container(
          height: 80,
          width: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: placeholderColor,
          ),
          clipBehavior: Clip.hardEdge,
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.broken_image, color: Colors.white));
            },
          ),
        );
      } catch (_) {
        // Ignore decoding errors and fall back to placeholder
      }
    }

    return Container(
      height: 80,
      width: 60,
      decoration: BoxDecoration(
        color: placeholderColor,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: const Center(
        child: Icon(Icons.book, size: 40, color: Colors.white),
      ),
    );
  }
}
