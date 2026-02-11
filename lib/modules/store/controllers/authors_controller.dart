import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/modules/search/models/authors_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthorController extends GetxController {
  final NetworkManager _networkManager = Get.find<NetworkManager>();
  final TextEditingController searchController = TextEditingController();

  // Observable list of authors
  final RxList<Author> authors = <Author>[].obs;

  // Single author detail
  final Rx<Author?> authorDetail = Rx<Author?>(null);
  final RxBool isLoadingDetail = false.obs;

  final RxList<String> recentSearches = <String>[].obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt pageSize = 10.obs;
  final RxBool hasMore = true.obs;

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;

  // Error message
  final RxString errorMessage = ''.obs;

  // Search query
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // Load recent searches from storage (you can use GetStorage)
  void _loadRecentSearches() {}

  // Save recent search
  void _saveRecentSearch(String query) {
    if (query.isEmpty) return;

    // Remove if already exists
    recentSearches.remove(query);

    // Add to beginning
    recentSearches.insert(0, query);

    // Keep only last 10 searches
    if (recentSearches.length > 10) {
      recentSearches.removeRange(10, recentSearches.length);
    }
  }

  // Clear recent searches
  void clearRecentSearches() {
    recentSearches.clear();
  }

  // Search authors
  Future<void> searchAuthors(String query) async {
    if (query.trim().isEmpty) {
      authors.clear();
      searchQuery.value = '';
      return;
    }

    try {
      searchQuery.value = query;
      currentPage.value = 1;
      hasMore.value = true;
      isLoading.value = true;
      errorMessage.value = '';
      authors.clear();

      final response = await _networkManager.get(
        ApiEndpoints.searchAuthors,
        sendToken: true,
        queryParameters: {
          'search': query.trim(),
          'page': currentPage.value.toString(),
          'size': pageSize.value.toString(),
        },
      );

      if (response['success']) {
        final List<dynamic> data = response['data'] ?? [];
        authors.value = data.map((json) => Author.fromJson(json)).toList();

        // Save to recent searches
        _saveRecentSearch(query.trim());

        hasMore.value = data.length >= pageSize.value;
      } else {
        errorMessage.value = response['error'] ?? 'Failed to search authors';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch author detail by ID
  Future<void> fetchAuthorDetail(int authorId) async {
    try {
      isLoadingDetail.value = true;
      errorMessage.value = '';

      final response = await _networkManager.get(
        ApiEndpoints.authorDetail(authorId),
        sendToken: true,
      );

      if (response['statusCode'] == 200) {
        authorDetail.value = Author.fromJson(response['data']);
      } else {
        errorMessage.value =
            response['message'] ?? 'Failed to load author details';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
    } finally {
      isLoadingDetail.value = false;
    }
  }

  Future<void> loadMoreAuthors() async {
    if (isLoadingMore.value || !hasMore.value || searchQuery.value.isEmpty) {
      return;
    }

    try {
      isLoadingMore.value = true;
      currentPage.value++;

      final response = await _networkManager.get(
        ApiEndpoints.searchAuthors,
        sendToken: true,
        queryParameters: {
          'search': searchQuery.value,
          'page': currentPage.value.toString(),
          'size': pageSize.value.toString(),
        },
      );

      if (response['success']) {
        final List<dynamic> data = response['data'] ?? [];
        final newAuthors = data.map((json) => Author.fromJson(json)).toList();

        authors.addAll(newAuthors);

        // Check if there are more pages
        hasMore.value = data.length >= pageSize.value;
      }
    } catch (e) {
      // Revert page number on error
      currentPage.value--;
    } finally {
      isLoadingMore.value = false;
    }
  }

  // Clear search
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    authors.clear();
    errorMessage.value = '';
    currentPage.value = 1;
    hasMore.value = true;
  }

  // Search from recent
  void searchFromRecent(String query) {
    searchController.text = query;
    searchAuthors(query);
  }
}
