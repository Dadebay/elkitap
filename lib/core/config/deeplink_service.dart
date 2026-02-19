import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:elkitap/modules/store/views/book_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _isInitialized = false;

  /// Initialize deep link listening
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('Deep link service already initialized');
      return;
    }

    try {
      _appLinks = AppLinks();

      // Handle initial link (when app is closed and opened via link)
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        debugPrint('Initial link received: $initialLink');
        // Delay handling to ensure app is fully initialized
        Future.delayed(const Duration(milliseconds: 1000), () {
          _handleDeepLink(initialLink);
        });
      }

      // Handle links when app is already running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          debugPrint('Deep link received while app running: $uri');
          _handleDeepLink(uri);
        },
        onError: (err) {
          debugPrint('Deep link error: $err');
        },
      );

      _isInitialized = true;
      debugPrint('Deep link service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing deep link service: $e');
    }
  }

  /// Handle incoming deep link
  void _handleDeepLink(Uri uri) {
    debugPrint('Processing deep link: $uri');
    debugPrint('Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');

    if (uri.host == 'book' || uri.pathSegments.contains('book')) {
      // Extract book ID from the URI
      int? bookId = _extractBookId(uri);

      if (bookId != null) {
        debugPrint('Extracted book ID: $bookId');
        // Navigate to book detail screen
        _navigateToBookDetail(bookId);
      } else {
        debugPrint('Failed to extract book ID from URI');
      }
    } else {
      debugPrint('Unknown deep link format');
    }
  }

  /// Extract book ID from URI
  int? _extractBookId(Uri uri) {
    try {
      // For custom scheme: elkitap://books/123
      if (uri.scheme == 'elkitap' && uri.host == 'book') {
        if (uri.pathSegments.isNotEmpty) {
          final bookId = int.tryParse(uri.pathSegments.first);
          if (bookId != null) return bookId;
        }
      }

      // For web URLs: https://elkitap.com/books/123
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'book') {
        final bookId = int.tryParse(uri.pathSegments[1]);
        if (bookId != null) return bookId;
      }

      // For web URLs with single segment: https://elkitap.com/books/123
      if (uri.pathSegments.length == 1) {
        final segment = uri.pathSegments[0];
        // Check if it starts with 'book'
        if (segment.startsWith('book')) {
          // Try to extract number after 'book'
          final idStr = segment.replaceAll(RegExp(r'[^0-9]'), '');
          if (idStr.isNotEmpty) {
            final bookId = int.tryParse(idStr);
            if (bookId != null) return bookId;
          }
        }
      }

      // Check query parameters: elkitap://book?id=123
      if (uri.queryParameters.containsKey('id')) {
        final bookId = int.tryParse(uri.queryParameters['id']!);
        if (bookId != null) return bookId;
      }

      // Check if the entire path is just a number
      if (uri.path.isNotEmpty) {
        final pathWithoutSlash = uri.path.replaceAll('/', '');
        final bookId = int.tryParse(pathWithoutSlash);
        if (bookId != null) return bookId;
      }
    } catch (e) {
      debugPrint('Error extracting book ID: $e');
    }
    return null;
  }

  /// Navigate to book detail screen
  void _navigateToBookDetail(int bookId) {
    debugPrint('Navigating to book detail with ID: $bookId');

    try {
      // Use GetX navigation
      Get.to(
        () => BookDetailView(bookId: bookId),
        // preventDuplicates: true,
        // transition: Transition.cupertino,
        // duration: const Duration(milliseconds: 300),
      );
    } catch (e) {
      debugPrint('Error navigating to book detail: $e');
      // If navigation fails, try again after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          Get.to(
            () => BookDetailView(bookId: bookId),
            // preventDuplicates: true,
          );
        } catch (e) {
          debugPrint('Second attempt to navigate failed: $e');
        }
      });
    }
  }

  /// Generate deep link for sharing
  static String generateBookDeepLink(int bookId) {
    // Custom scheme (works only with app installed)
    return 'elkitap.com.tm/books/$bookId';

    // If you have a web domain, use this instead:
    // return 'https://elkitap.com/books/$bookId';
  }

  /// Generate web fallback link
  static String generateWebLink(int bookId) {
    // Return your web URL if available
    return 'https://elkitap.com/books/$bookId';
  }

  /// Generate universal link (works on both web and app)
  static String generateUniversalLink(int bookId) {
    // This should be your actual domain
    // For testing, use the custom scheme
    return 'elkitap://books/$bookId';
  }

  /// Check if deep link service is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose the service
  void dispose() {
    _linkSubscription?.cancel();
    _isInitialized = false;
    debugPrint('Deep link service disposed');
  }
}
