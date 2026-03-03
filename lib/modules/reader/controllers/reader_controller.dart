import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'dart:async';

import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:get_storage/get_storage.dart';

class EpubController extends GetxController {
  var currentPage = 0.obs;
  var totalPages = 0.obs;
  var isAtLastPage = false.obs;
  var isProgressSaving = false.obs;

  /// Called once after progress is successfully saved as 100%.
  VoidCallback? onReachedLastPage;

  int? _currentBookId;
  NetworkManager? _networkManager;
  final _storage = GetStorage();

  Timer? _saveProgressTimer;
  void initialize({required int bookId}) {
    _currentBookId = bookId;

    if (Get.isRegistered<NetworkManager>()) {
      _networkManager = Get.find<NetworkManager>();
    }
  }

  void onPageFlip(int current, int total) {
    currentPage.value = current;
    totalPages.value = total;
    _saveProgressTimer?.cancel();
    _saveProgressTimer = Timer(const Duration(seconds: 2), () {
      _saveProgress();
    });
  }

  void onLastPage(int index) {
    isAtLastPage.value = true;
    _saveProgress();
  }

  // Save progress directly to API
  Future<void> _saveProgress() async {
    if (_currentBookId == null || totalPages.value == 0 || _networkManager == null) {
      return;
    }

    if (isProgressSaving.value) {
      return;
    }

    try {
      isProgressSaving.value = true;

      // Clamp to 1.0 when on the last page to avoid 99% due to off-by-one
      final rawProgress = currentPage.value / totalPages.value;
      final progress = (currentPage.value >= totalPages.value) ? 1.0 : rawProgress;

      log("✅ Cosmos save backend succes %%% $progress");

      final response = await _networkManager!.post(
        ApiEndpoints.bookProgress(_currentBookId!),
        body: {
          'progress': (double.parse(progress.toStringAsFixed(3)) * 100).toInt(),
        },
        sendToken: true,
      );

      if (response['success'] == true) {
        log("✅ Cosmos save backend succes");

        // Save progress to local storage for CurrentBookSection
        final progressPercentage = (progress * 100).toStringAsFixed(1);
        _storage.write('book_${_currentBookId}_progress', progressPercentage);
        log("💾 Saved progress to local storage: $progressPercentage%");

        // Notify listener when 100% is reached for auto-mark-as-finished.
        // Use 0.995 threshold to also cover VPP off-by-one cases.
        if (progress >= 0.995 && onReachedLastPage != null) {
          onReachedLastPage!();
        }
      } else {}
    } catch (e) {
    } finally {
      isProgressSaving.value = false;
    }
  }

  // Call when closing the reader - saves progress synchronously before closing
  Future<void> saveProgressAndClose() async {
    _saveProgressTimer?.cancel();

    if (currentPage.value > 0 && totalPages.value > 0) {
      await _saveProgress();
    }

    // Reset state after saving
    reset();
  }

  void reset() {
    currentPage.value = 0;
    totalPages.value = 0;
    isAtLastPage.value = false;
    // _currentBookId = null;
    // _saveProgressTimer?.cancel();
  }

  @override
  void onClose() {
    _saveProgressTimer?.cancel();
    super.onClose();
  }
}
