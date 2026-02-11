import 'dart:developer';

import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
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

          final newAuthors =
              items.map((json) => Author.fromJson(json)).toList();

          if (currentAuthorPage.value == 1) {
            authors.assignAll(newAuthors);
          } else {
            authors.addAll(newAuthors);
          }

          final int total = data['totalCount'] ?? 0;
          hasMoreAuthors.value = (currentAuthorPage.value * 10) < total;

         
        } else {
         
        }
      } else {
      
      }

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

      final response = await _networkManager.get(
        ApiEndpoints.allBooks,
        sendToken: true,
        queryParameters: {
          'search': query,
          'page': currentBookPage.value.toString(),
          'size': '20',
        },
      );

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
  Future<void> loadMoreBooks() async {
    if (isLoadingMore.value ||
        !hasMoreBooks.value ||
        isLoading.value ||
        searchQuery.value.isEmpty) {
      return;
    }

    currentBookPage.value++;
    await _fetchBooks(searchQuery.value, isLoadMore: true);
  }

  // Clear search
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    authors.clear();
    books.clear();
    errorMessage.value = '';
    currentAuthorPage.value = 1;
    currentBookPage.value = 1;
    hasMoreAuthors.value = true;
    hasMoreBooks.value = true;
  }
}
