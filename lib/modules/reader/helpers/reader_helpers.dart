import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart' as epub;
import 'package:path_provider/path_provider.dart';

/// Helper class for reader-related operations
class ReaderHelpers {
  /// Find chapter title by href
  static String getChapterTitleByHref(
    String? href,
    List<epub.EpubChapter> chapters,
    String fallbackTitle,
  ) {
    if (href == null || href.isEmpty || chapters.isEmpty) {
      return fallbackTitle;
    }

    // Remove fragment identifier (#...) from href if present
    String cleanHref = href.split('#').first;

    // Flatten chapters with parent info
    List<Map<String, dynamic>> flatChapters = [];
    void addChapters(List<epub.EpubChapter> chapters, {epub.EpubChapter? parent}) {
      for (var chapter in chapters) {
        flatChapters.add({'chapter': chapter, 'parent': parent});
        if (chapter.subitems.isNotEmpty) {
          addChapters(chapter.subitems, parent: chapter);
        }
      }
    }

    addChapters(chapters);

    // Find the chapter matching this href
    Map<String, dynamic>? currentChapterInfo;

    for (var info in flatChapters) {
      epub.EpubChapter chapter = info['chapter'];
      String chapterHref = chapter.href.split('#').first;

      if (chapterHref == cleanHref || cleanHref.endsWith(chapterHref)) {
        currentChapterInfo = info;
        break;
      }
    }

    if (currentChapterInfo == null) return fallbackTitle;

    epub.EpubChapter currentChapter = currentChapterInfo['chapter'];
    epub.EpubChapter? parentChapter = currentChapterInfo['parent'];

    // If there's a parent, show both
    if (parentChapter != null) {
      return '${parentChapter.title.trim()}\n${currentChapter.title.trim()}';
    }

    return currentChapter.title.trim();
  }

  /// Get local file path for book
  static Future<String> getLocalFilePath(String bookId, String? epubPath) async {
    final directory = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${directory.path}/books');

    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }

    if (epubPath != null && epubPath.isNotEmpty) {
      final safeKey = epubPath.split('/').last;
      log('Using translation-specific cache path: ${booksDir.path}/$safeKey');
      return '${booksDir.path}/$safeKey';
    }

    log('Using default cache path: ${booksDir.path}/book_$bookId.epub');
    return '${booksDir.path}/book_$bookId.epub';
  }

  /// Check if downloaded file is a .zip containing an .epub and extract it
  static Future<String> extractEpubFromZipIfNeeded(String savePath) async {
    String actualEpubPath = savePath;

    if (savePath.toLowerCase().endsWith('.zip')) {
      log('Detected .zip file, checking if it contains .epub...');

      try {
        final zipFile = File(savePath);
        final bytes = await zipFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        ArchiveFile? epubFile;
        for (var file in archive.files) {
          if (file.name.toLowerCase().endsWith('.epub') && file.content != null) {
            epubFile = file;
            log('Found .epub in .zip: ${file.name}');
            break;
          }
        }

        if (epubFile != null && epubFile.content != null) {
          final extractedEpubPath = savePath.replaceAll('.zip', '.epub');
          final extractedFile = File(extractedEpubPath);

          try {
            await extractedFile.writeAsBytes(epubFile.content as List<int>);
            log('Extracted .epub to: $extractedEpubPath');
            actualEpubPath = extractedEpubPath;
          } catch (e) {
            log('Error writing extracted .epub: $e');
          }
        } else {
          log('No .epub file found inside .zip, will try to open as is');
        }
      } catch (e) {
        log('Error extracting .zip file: $e, will try to open as is');
      }
    }

    return actualEpubPath;
  }

  /// Check if error is authentication related
  static bool isAuthError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('authentication required') || errorStr.contains('unauthorized') || errorStr.contains('unauthenticated') || errorStr.contains('401');
  }

  /// Check if response is authentication error
  static bool isAuthErrorResponse(Map<String, dynamic> response) {
    if (response['success'] == false) {
      final statusCode = response['statusCode'];
      if (statusCode == 401) return true;

      final error = response['error']?.toString().toLowerCase() ?? '';
      final message = response['data']?['message']?.toString().toLowerCase() ?? '';

      return error.contains('authentication required') ||
          error.contains('unauthorized') ||
          error.contains('unauthenticated') ||
          message.contains('authentication required') ||
          message.contains('unauthorized') ||
          message.contains('unauthenticated');
    }
    return false;
  }
}
