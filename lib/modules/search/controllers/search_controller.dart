import 'dart:developer';

import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/modules/search/controllers/filter_controller.dart';
import 'package:elkitap/modules/search/models/authors_model.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SearchResultsController extends GetxController {
  final NetworkManager _networkManager = Get.find<NetworkManager>();
  final TextEditingController searchController = TextEditingController();
  final GetStorage _storage = GetStorage();

  // Storage key
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 10;
  // Search history
  final RxList<String> searchHistory = <String>[].obs;
  // Authors
  final RxList<Author> authors = <Author>[].obs;
  final RxInt currentAuthorPage = 1.obs;
  final RxBool hasMoreAuthors = true.obs;

  // Books
  final RxList<Book> books = <Book>[].obs;
  final RxInt currentBookPage = 1.obs;
  final RxBool hasMoreBooks = true.obs;
  final RxBool isLoadingMore = false.obs;

  // Loading and error states
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;

  /// 'all' | 'books' | 'authors'
  final RxString searchMode = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    loadSearchHistory();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // Load search history from storage
  void loadSearchHistory() {
    final List<dynamic>? history = _storage.read<List>(_searchHistoryKey);
    if (history != null) {
      searchHistory.assignAll(history.cast<String>());
    }
  }

  // Save search query to history
  void saveToHistory(String query) {
    if (query.trim().isEmpty) return;

    // Remove if already exists (to move it to top)
    searchHistory.remove(query);

    // Add to beginning
    searchHistory.insert(0, query);
    if (searchHistory.length > _maxHistoryItems) {
      searchHistory.removeLast();
    }

    // Save to storage
    _storage.write(_searchHistoryKey, searchHistory.toList());
  }

  // Remove single item from history
  void removeFromHistory(String query) {
    searchHistory.remove(query);
    _storage.write(_searchHistoryKey, searchHistory.toList());
  }

  // Clear all history
  void clearHistory() {
    searchHistory.clear();
    _storage.remove(_searchHistoryKey);
  }

  // Search from history item
  void searchFromHistory(String query) {
    searchController.text = query;
    searchAuthors(query);
  }

  // Search both authors and books
  Future<void> searchAuthors(String query) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    // Prevent multiple simultaneous searches
    if (isLoading.value) {
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';
      searchQuery.value = query;
      searchMode.value = 'all';
      currentAuthorPage.value = 1;
      currentBookPage.value = 1;
      hasMoreAuthors.value = true;
      hasMoreBooks.value = true;
      authors.clear();
      books.clear();

      saveToHistory(query);

      await Future.wait([
        _fetchAuthors(query),
        _fetchBooks(query),
      ]);
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
      log('Search error: $e');
    } finally {
      // This ensures isLoading is set to false AFTER both futures complete
      isLoading.value = false;
    }
  }

  // Fetch authors
  Future<void> _fetchAuthors(String query) async {
    try {
      log('_fetchAuthors: Starting request...');
      final response = await _networkManager.get(
        ApiEndpoints.searchAuthors,
        sendToken: true,
        queryParameters: {
          'search': query,
          'page': currentAuthorPage.value.toString(),
          'size': '10', // Limit to 10 authors
        },
      );

      log('_fetchAuthors: Response received');
      log('data _fetchAuthors: $response');

      if (response['success']) {
        final data = response['data'];
        if (data != null && data is List) {
          // If data is directly a list of authors
          log('_fetchAuthors: Processing list data with ${data.length} items');
          final newAuthors = data.map((json) => Author.fromJson(json)).toList();

          if (currentAuthorPage.value == 1) {
            authors.assignAll(newAuthors);
          } else {
            authors.addAll(newAuthors);
          }

          log('Authors loaded: ${authors.length}');
          hasMoreAuthors.value = false; // Update based on your pagination logic
        } else if (data != null && data is Map<String, dynamic>) {
          // If data is wrapped in an object with 'items'
          log('_fetchAuthors: Processing map data');
          final List<dynamic> items = data['items'] ?? [];
          log('_fetchAuthors: Found ${items.length} items');

          final newAuthors = items.map((json) => Author.fromJson(json)).toList();

          if (currentAuthorPage.value == 1) {
            authors.assignAll(newAuthors);
          } else {
            authors.addAll(newAuthors);
          }

          final int total = data['totalCount'] ?? 0;
          hasMoreAuthors.value = (currentAuthorPage.value * 10) < total;
        } else {}
      } else {}

      log('_fetchAuthors: Method completing with ${authors.length} authors');
    } catch (e, stackTrace) {
      log('Error fetching authors: $e');
      log('Stack trace: $stackTrace');
      // Don't rethrow - let the search continue with books
    }
  }

  // Fetch books
  Future<void> _fetchBooks(String query, {bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        isLoadingMore.value = true;
      }

      final Map<String, String> queryParams = {
        'search': query,
        'page': currentBookPage.value.toString(),
        'size': '20',
      };

      // Add filter params if FilterController is registered
      if (Get.isRegistered<FilterController>()) {
        final filterController = Get.find<FilterController>();
        queryParams.addAll(filterController.buildFilterParams());
      }

      log('🔍 [_fetchBooks] ===== API REQUEST =====');
      log('🔍 [_fetchBooks] Endpoint: ${ApiEndpoints.allBooks}');
      log('🔍 [_fetchBooks] Params: $queryParams');

      final response = await _networkManager.get(
        ApiEndpoints.allBooks,
        sendToken: true,
        queryParameters: queryParams,
      );

      log('🔍 [_fetchBooks] ===== API RESPONSE =====');
      log('🔍 [_fetchBooks] success: ${response['success']}');
      log('🔍 [_fetchBooks] full response keys: ${response.keys.toList()}');
      log('🔍 [_fetchBooks] data: ${response['data']}');
      if (response['message'] != null) log('🔍 [_fetchBooks] message: ${response['message']}');
      if (response['error'] != null) log('🔍 [_fetchBooks] error: ${response['error']}');

      if (response['success']) {
        final data = response['data'];
        log('data _fetchBooks: $data');
        if (data != null && data is Map<String, dynamic>) {
          final List<dynamic> items = data['items'] ?? [];
          final newBooks = items.map((json) => Book.fromJson(json)).toList();

          if (currentBookPage.value == 1) {
            // Use assignAll for better reactivity
            books.assignAll(newBooks);
          } else {
            books.addAll(newBooks);
          }

          final int total = data['totalCount'] ?? 0;
          hasMoreBooks.value = (currentBookPage.value * 20) < total;

          log('Books loaded: ${books.length}');
        }
      }
    } catch (e) {
    } finally {
      if (isLoadMore) {
        isLoadingMore.value = false;
      }
    }
  }

  // Load more books (pagination)
  // Works for both search-query mode and filter-only mode.
  Future<void> loadMoreBooks() async {
    if (isLoadingMore.value || !hasMoreBooks.value || isLoading.value) return;

    // In filter-only mode searchQuery is empty but we still paginate.
    final isFilterMode = searchQuery.value.isEmpty && Get.isRegistered<FilterController>() && Get.find<FilterController>().hasActiveFilters;

    if (searchQuery.value.isEmpty && !isFilterMode) return;

    currentBookPage.value++;
    if (isFilterMode) {
      await _fetchFilteredBooksPage();
    } else {
      await _fetchBooks(searchQuery.value, isLoadMore: true);
    }
  }

  // Re-apply search with current filters
  Future<void> reSearchWithFilters() async {
    final filterCtrl = Get.isRegistered<FilterController>() ? Get.find<FilterController>() : null;
    final hasFilters = filterCtrl?.hasActiveFilters ?? false;

    if (searchQuery.value.isNotEmpty) {
      // Has a search query — redo the search with new filters applied
      await searchAuthors(searchQuery.value);
    } else if (hasFilters) {
      // No query but filters active — fetch filtered books
      await _fetchFilteredBooks();
    } else {
      // No query, no filters — clear results so UI shows history/empty
      books.clear();
      authors.clear();
    }
  }

  // Fetch books with filters only (no search query needed).
  // Called when filters are active but searchQuery is empty.
  Future<void> _fetchFilteredBooks() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      currentBookPage.value = 1;
      hasMoreBooks.value = true;
      books.clear();
      authors.clear();

      final Map<String, String> queryParams = {
        'page': '1',
        'size': '20',
      };

      if (Get.isRegistered<FilterController>()) {
        queryParams.addAll(Get.find<FilterController>().buildFilterParams());
      }

      log('🔍 [_fetchFilteredBooks] Params: $queryParams');

      final response = await _networkManager.get(
        ApiEndpoints.allBooks,
        sendToken: true,
        queryParameters: queryParams,
      );

      if (response['success']) {
        final data = response['data'];
        if (data != null && data is Map<String, dynamic>) {
          final List<dynamic> items = data['items'] ?? [];
          books.assignAll(items.map((json) => Book.fromJson(json)).toList());
          final int total = data['totalCount'] ?? 0;
          hasMoreBooks.value = (1 * 20) < total;
          log('🔍 [_fetchFilteredBooks] Loaded ${books.length} books, total=$total');
        }
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch next page for filter-only mode (pagination)
  Future<void> _fetchFilteredBooksPage() async {
    try {
      isLoadingMore.value = true;

      final Map<String, String> queryParams = {
        'page': currentBookPage.value.toString(),
        'size': '20',
      };

      if (Get.isRegistered<FilterController>()) {
        queryParams.addAll(Get.find<FilterController>().buildFilterParams());
      }

      log('🔍 [_fetchFilteredBooksPage] page=${currentBookPage.value} Params: $queryParams');

      final response = await _networkManager.get(
        ApiEndpoints.allBooks,
        sendToken: true,
        queryParameters: queryParams,
      );

      if (response['success']) {
        final data = response['data'];
        if (data != null && data is Map<String, dynamic>) {
          final List<dynamic> items = data['items'] ?? [];
          books.addAll(items.map((json) => Book.fromJson(json)).toList());
          final int total = data['totalCount'] ?? 0;
          hasMoreBooks.value = (currentBookPage.value * 20) < total;
          log('🔍 [_fetchFilteredBooksPage] Appended ${items.length} books, total=${books.length}');
        }
      }
    } catch (e) {
      log('🔍 [_fetchFilteredBooksPage] error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // Clear search
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    searchMode.value = 'all';
    authors.clear();
    books.clear();
    errorMessage.value = '';
    currentAuthorPage.value = 1;
    currentBookPage.value = 1;
    hasMoreAuthors.value = true;
    hasMoreBooks.value = true;
  }
}
