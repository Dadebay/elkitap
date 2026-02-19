import 'dart:developer';

import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/modules/auth/widget/login_bottom_sheet.dart';
import 'package:elkitap/modules/store/model/book_detail_model.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class BooksDetailController extends GetxController {
  // Audio HLS URL
  final audioHlsUrl = ''.obs;

  // Book detail data
  final Rx<BookDetail?> bookDetail = Rx<BookDetail?>(null);

  final errorMessage = ''.obs;
  final hasError = false.obs;
  final isAddedToWantToRead = false.obs;
  // UI states
  final isAudio = false.obs;

  // Authentication state - set to false when auth error occurs
  final isAuth = true.obs;

  final isDescriptionExpanded = false.obs;
  // Observable states
  final isLoading = false.obs;

  final isLoadingAudio = false.obs;
  final isMarkedAsFinished = false.obs;
  final isProgressSaving = false.obs;
  // Progress state - stored as String (from API), posted as double
  final Rx<String?> progress = Rx<String?>(null);

  final selectedLanguage = 'Türkmençe'.obs;
  final selectedTranslateId = Rx<int?>(null);
  final wantsToFinishedBookId = false.obs;
  // Store the specific wants_to IDs - changed to bool
  final wantsToListenBookId = false.obs;

  final wantsToReadBookId = false.obs;

  final NetworkManager _networkManager = Get.find<NetworkManager>();
  final Rx<int?> _wantsToFinishedId = Rx<int?>(null);
  // Store actual IDs internally for API calls
  final Rx<int?> _wantsToListenId = Rx<int?>(null);

  final Rx<int?> _wantsToReadId = Rx<int?>(null);

  // Local storage for progress sync
  final _storage = GetStorage();
  static const String _audioProgressKey = 'audio_progress_';

  @override
  void onClose() {
    // Clear all observable data to free memory
    bookDetail.value = null;
    progress.value = null;
    audioHlsUrl.value = '';

    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    final bookId = Get.arguments?['bookId'];
    if (bookId != null) {
      fetchBookDetail(bookId);
    }
  }

  void toggleDescription() {
    isDescriptionExpanded.value = !isDescriptionExpanded.value;
  }

  Future<void> fetchBookDetail(int bookId) async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      // Only send with_audio parameter when audio mode is active
      // When text mode is active, don't send the parameter to get all translations
      final queryParams = isAudio.value ? {'with_audio': 'true'} : null;

      final response = await _networkManager.get(
        ApiEndpoints.bookDetail(bookId),
        sendToken: true,
        queryParameters: queryParams,
      );

      if (_isAuthError(response)) {
        isAuth.value = false;
        _showLoginBottomSheet();
        return;
      }

      if (response['success']) {
        // Log raw response to debug translation data

        bookDetail.value = BookDetail.fromJson(response['data']);

        // Log parsed translation count
        log('Parsed BookDetail - translates count: ${bookDetail.value?.translates.length ?? 0}');

        // Get progress from response as String
        final progressData = response['data']['progress'];
        if (progressData != null) {
          progress.value = progressData.toString();
        } else {
          progress.value = null;
        }

        // Get the wants_to IDs from response and convert to bool
        final listenId = response['data']['wants_to_listen_book_id'];
        final readId = response['data']['wants_to_read_book_id'];
        final finishedId = response['data']['wants_to_finished_book_id'];

        // Store internal IDs
        _wantsToListenId.value = listenId;
        _wantsToReadId.value = readId;
        _wantsToFinishedId.value = finishedId;

        // Set boolean values (true if ID exists, false if null)
        wantsToListenBookId.value = listenId != null;
        wantsToReadBookId.value = readId != null;
        wantsToFinishedBookId.value = finishedId != null;

        // Update UI states based on boolean values
        updateWantToReadState();
        updateFinishedState();

        // Auto-select audio mode if only audio version is available
        if (!hasTextVersion() && hasAudioVersion()) {
          isAudio.value = true;
          updateWantToReadState(); // Update again for audio mode
        }

        // Log each translation's audio info
        bookDetail.value?.translates.asMap().forEach((index, translate) {});

        if (bookDetail.value!.translates.isNotEmpty) {
          selectedLanguage.value = bookDetail.value!.translates.first.language;
          selectedTranslateId.value = bookDetail.value!.translates.first.id;
        }
      } else {
        hasError.value = true;
        errorMessage.value = response['error'] ?? 'Failed to load book details';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle want to read/listen
  Future<void> toggleWantToRead() async {
    if (bookDetail.value == null) return;

    try {
      final bookId = bookDetail.value!.id;
      final wantsToValue = isAudio.value ? 'listen' : 'read';

      // Determine which ID to check based on current mode
      int? currentId = isAudio.value ? _wantsToListenId.value : _wantsToReadId.value;

      if (currentId == null) {
        // POST - Add to want to read/listen
        final response = await _networkManager.post(
          ApiEndpoints.bookLike(bookId),
          body: {
            'wants_to': wantsToValue,
          },
          sendToken: true,
        );

        if (_isAuthError(response)) {
          isAuth.value = false;
          _showLoginBottomSheet();
          return;
        }

        if (response['success']) {
          if (isAudio.value) {
            _wantsToListenId.value = 1;
            wantsToListenBookId.value = true;
          } else {
            _wantsToReadId.value = 1;
            wantsToReadBookId.value = true;
          }

          isAuth.value = true;
        }
      } else {
        // DELETE - Remove from want to read/listen
        final response = await _networkManager.delete(
          ApiEndpoints.bookUnlike(currentId),
          sendToken: true,
        );

        if (_isAuthError(response)) {
          isAuth.value = false;
          _showLoginBottomSheet();
          return;
        }

        if (response['success']) {
          if (isAudio.value) {
            _wantsToListenId.value = null;
            wantsToListenBookId.value = false;
          } else {
            _wantsToReadId.value = null;
            wantsToReadBookId.value = false;
          }

          isAuth.value = true;
        } else {}
      }

      // Update UI state
      updateWantToReadState();
      updateFinishedState();
    } catch (e) {}
  }

  // Mark book as finished
  Future<bool> markAsFinished() async {
    if (bookDetail.value == null) return false;

    try {
      final bookId = bookDetail.value!.id;

      // If already marked as finished, remove it (toggle off)
      if (_wantsToFinishedId.value != null && isMarkedAsFinished.value) {
        // Call DELETE to remove
        final response = await _networkManager.delete(
          ApiEndpoints.bookUnlike(_wantsToFinishedId.value!),
          sendToken: true,
        );

        if (_isAuthError(response)) {
          isAuth.value = false;
          _showLoginBottomSheet();
          return false;
        }

        if (response['success']) {
          _wantsToFinishedId.value = null;
          wantsToFinishedBookId.value = false;
          isMarkedAsFinished.value = false;
          updateFinishedState();

          isAuth.value = true;
          return true;
        } else {
          return false;
        }
      } else {
        // Call POST to mark as finished
        final response = await _networkManager.post(
          ApiEndpoints.bookLike(bookId),
          body: {
            'wants_to': 'finished',
          },
          sendToken: true,
        );

        if (_isAuthError(response)) {
          isAuth.value = false;
          _showLoginBottomSheet();
          return false;
        }

        if (response['success']) {
          _wantsToFinishedId.value = 1;
          wantsToFinishedBookId.value = true;
          isMarkedAsFinished.value = true;
          updateFinishedState();

          isAuth.value = true;
          return true;
        } else {
          return false;
        }
      }
    } catch (e) {
      return false;
    }
  }

  // Unlike/Remove book (using appropriate ID based on current state)
  Future<bool> unlikeBook() async {
    int? idToDelete;

    // Determine which ID to use
    if (_wantsToFinishedId.value != null) {
      idToDelete = _wantsToFinishedId.value;
    } else if (isAudio.value && _wantsToListenId.value != null) {
      idToDelete = _wantsToListenId.value;
    } else if (!isAudio.value && _wantsToReadId.value != null) {
      idToDelete = _wantsToReadId.value;
    }

    if (idToDelete == null) {
      return false;
    }

    try {
      final response = await _networkManager.delete(
        ApiEndpoints.bookUnlike(idToDelete),
        sendToken: true,
      );

      if (_isAuthError(response)) {
        isAuth.value = false;
        _showLoginBottomSheet();
        return false;
      }

      if (response['success']) {
        _wantsToListenId.value = null;
        _wantsToReadId.value = null;
        _wantsToFinishedId.value = null;
        wantsToListenBookId.value = false;
        wantsToReadBookId.value = false;
        wantsToFinishedBookId.value = false;
        isAddedToWantToRead.value = false;
        isMarkedAsFinished.value = false;

        isAuth.value = true;
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Update UI state for want to read/listen
  void updateWantToReadState() {
    // Check wants to read/listen based on current mode
    if (isAudio.value) {
      isAddedToWantToRead.value = wantsToListenBookId.value;
    } else {
      isAddedToWantToRead.value = wantsToReadBookId.value;
    }
  }

  // Update UI state for finished status
  void updateFinishedState() {
    isMarkedAsFinished.value = wantsToFinishedBookId.value;
  }

  Future<void> refreshBookDetail() async {
    if (bookDetail.value != null) {
      await fetchBookDetail(bookDetail.value!.id);
    }
  }

  // Get progress as String (for display)
  String? getProgress() {
    return progress.value;
  }

  // Get progress as double (for calculations)
  double? getProgressAsDouble() {
    if (progress.value == null) return null;
    return double.tryParse(progress.value!);
  }

  // Get progress as percentage string (e.g., "12.23%")
  String getProgressPercentage() {
    if (progress.value == null) return '0%';
    try {
      double val = double.parse(progress.value!);
      if (val <= 1.0 && val > 0) {
        // Assume 0.0-1.0 range
        return '${(val * 100).toInt()}%';
      }
      return '${val.toInt()}%';
    } catch (e) {
      return '${progress.value}%';
    }
  }

  // Fetch only the progress from API (lightweight refresh)
  Future<void> fetchProgress() async {
    if (bookDetail.value == null) {
      log('📊 fetchProgress: bookDetail is null');
      return;
    }

    try {
      final bookId = bookDetail.value!.id;
      log('📊 fetchProgress: Fetching progress for book ID: $bookId');

      final response = await _networkManager.get(
        ApiEndpoints.bookDetail(bookId),
        sendToken: true,
      );

      if (response['success']) {
        final progressData = response['data']['progress'];
        log('📊 fetchProgress: Server response - progress: $progressData');

        if (progressData != null) {
          progress.value = progressData.toString();
          log('📊 fetchProgress: Set progress.value to: ${progress.value}');

          try {
            final progressValue = double.parse(progress.value!);
            final progressDecimal = progressValue / 100.0; // Convert percentage to decimal
            log('📊 fetchProgress: Converted to decimal: $progressDecimal (${(progressDecimal * 100).toStringAsFixed(1)}%)');

            // Save to local storage using the same key pattern as ProgressSyncMixin
            if (bookDetail.value?.id != null && selectedTranslateId.value != null) {
              final uniqueBookId = '${bookDetail.value!.id}_t${selectedTranslateId.value}';
              final key = '$_audioProgressKey$uniqueBookId';
              _storage.write(key, progressDecimal);
              log('📊 fetchProgress: Saved to storage with key: $key, value: $progressDecimal');
            }
          } catch (e) {
            log('📊 fetchProgress: Error parsing progress: $e');
          }
        } else {
          log('📊 fetchProgress: No progress data from server');
        }
      } else {}
    } catch (e) {}
  }

  // POST Progress - Save current reading progress
  Future<void> postProgress({
    required int currentPage,
    required int totalPages,
  }) async {
    if (bookDetail.value == null || totalPages == 0) return;

    try {
      isProgressSaving.value = true;
      final bookId = bookDetail.value!.id;
      final calculatedProgress = currentPage / totalPages;

      final response = await _networkManager.post(
        ApiEndpoints.bookProgress(bookId),
        body: {
          'progress': double.parse(calculatedProgress.toStringAsFixed(3)),
        },
        sendToken: true,
      );

      if (_isAuthError(response)) {
        isAuth.value = false;
        _showLoginBottomSheet();
        return;
      }

      if (response['success']) {
        progress.value = calculatedProgress.toStringAsFixed(2);

        isAuth.value = true;
      } else {}
    } catch (e) {
    } finally {
      isProgressSaving.value = false;
    }
  }

  // POST Progress with direct double value
  Future<void> postProgressValue(double progressValue) async {
    if (bookDetail.value == null) return;

    try {
      isProgressSaving.value = true;
      final bookId = bookDetail.value!.id;

      final response = await _networkManager.post(
        ApiEndpoints.bookProgress(bookId),
        body: {
          'progress': double.parse(progressValue.toStringAsFixed(3)),
        },
        sendToken: true,
      );

      if (_isAuthError(response)) {
        isAuth.value = false;
        _showLoginBottomSheet();
        return;
      }

      if (response['success']) {
        progress.value = progressValue.toStringAsFixed(2);

        isAuth.value = true;
      } else {}
    } catch (e) {
    } finally {
      isProgressSaving.value = false;
    }
  }

  void toggleToText() {
    isAudio.value = false;
    updateWantToReadState();
    // Refresh book detail to get all translations without audio filter
    if (bookDetail.value != null) {
      fetchBookDetail(bookDetail.value!.id);
    }
  }

  void toggleToAudio() {
    isAudio.value = true;
    updateWantToReadState();
    // Refresh book detail with audio filter
    if (bookDetail.value != null) {
      fetchBookDetail(bookDetail.value!.id);
    }
  }

  void toggleAddToWantToRead() {
    toggleWantToRead();
  }

  void toggleAddToFinish() {
    markAsFinished();
  }

  void changeLanguage(String language, int translateId) {
    log('=== CHANGING LANGUAGE ===');
    log('From: ${selectedLanguage.value} (ID: ${selectedTranslateId.value})');
    log('To: $language (ID: $translateId)');
    selectedLanguage.value = language;
    selectedTranslateId.value = translateId;
    log('Updated selectedTranslateId: ${selectedTranslateId.value}');
    log('========================');
  }

  Translate? getCurrentTranslate() {
    if (bookDetail.value == null) return null;
    return bookDetail.value!.translates.firstWhereOrNull(
      (translate) => translate.id == selectedTranslateId.value,
    );
  }

  String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    return '${ApiEndpoints.imageBaseUrl}$imagePath';
  }

  String getBookCoverImage() {
    // If in audio mode, prioritize book-level audioImage
    if (isAudio.value && bookDetail.value?.audioImage != null && bookDetail.value!.audioImage!.isNotEmpty) {
      return getFullImageUrl(bookDetail.value!.audioImage);
    }

    // Check translate-level images
    final translate = getCurrentTranslate();
    if (translate != null) {
      // In audio mode, prioritize translate audioImage
      if (isAudio.value && translate.audioImage != null && translate.audioImage!.isNotEmpty) {
        return getFullImageUrl(translate.audioImage);
      }

      // Fallback to translate image (text book cover or audio book without separate audio cover)
      if (translate.image != null && translate.image!.isNotEmpty) {
        return getFullImageUrl(translate.image);
      }
    }

    // Fallback to book-level image
    if (bookDetail.value?.image != null && bookDetail.value!.image!.isNotEmpty) {
      return getFullImageUrl(bookDetail.value!.image);
    }

    return '';
  }

  String getBookDescription() {
    final translate = getCurrentTranslate();

    return translate?.description ?? '';
  }

  String getBookName() {
    final translate = getCurrentTranslate();
    return translate?.name ?? bookDetail.value?.name ?? '';
  }

  String getAuthorsString() {
    if (bookDetail.value == null || bookDetail.value!.authors.isEmpty) {
      return '';
    }
    return bookDetail.value!.authors.map((author) => author.name).join(', ');
  }

  String getGenresString() {
    if (bookDetail.value == null || bookDetail.value!.genres.isEmpty) {
      return '';
    }
    return bookDetail.value!.genres.map((genre) => genre.name).join(', ');
  }

  List<GenreBook> getGenres() {
    return bookDetail.value?.genres ?? [];
  }

  String? getFirstGenreName() {
    if (bookDetail.value == null || bookDetail.value!.genres.isEmpty) {
      return null;
    }
    return bookDetail.value!.genres.first.name;
  }

  String getAgeRating() {
    if (bookDetail.value?.age != null) {
      return '${bookDetail.value!.age}+';
    }
    return '';
  }

  String? getBookEpubPath() {
    final translate = getCurrentTranslate();
    if (translate == null || translate.bookKey == null) {
      return null;
    }
    return '${translate.bookKey}';
  }

  void setLanguage(String language) {
    selectedLanguage.value = language;
  }

  // Check if book has text version (based on BookDetail's image field)
  bool hasTextVersion() {
    // Check if book has image (indicates text book availability)
    final hasImage = bookDetail.value?.image != null && bookDetail.value!.image!.isNotEmpty;

    return hasImage;
  }

  // Check if book has audio version (based on BookDetail's withAudio field)
  bool hasAudioVersion() {
    // Check if book has withAudio flag set to true
    final hasAudio = bookDetail.value?.withAudio ?? false;

    return hasAudio;
  }

  // Check if book has both text and audio versions
  bool hasBothVersions() {
    return hasTextVersion() && hasAudioVersion();
  }

  // Fetch HLS audio URL for the current book translation
  Future<void> fetchAudioHlsUrl() async {
    if (selectedTranslateId.value == null) {
      return;
    }

    try {
      isLoadingAudio.value = true;
      audioHlsUrl.value = '';

      final response = await _networkManager.get(
        ApiEndpoints.audioHlsKey(selectedTranslateId.value!),
        sendToken: true,
      );

      if (_isAuthError(response)) {
        isAuth.value = false;
        _showLoginBottomSheet();
        return;
      }

      if (response['success']) {
        final relativePath = response['data'] as String?;
        if (relativePath != null && relativePath.isNotEmpty) {
          // Construct full URL: baseUrl + relativePath
          audioHlsUrl.value = '${ApiEndpoints.imageBaseUrl}/$relativePath';
        } else {}
      } else {}
    } catch (e) {
    } finally {
      isLoadingAudio.value = false;
    }
  }

  // Send problem report to API
  Future<bool> sendProblemReport(String problem) async {
    try {
      final response = await _networkManager.post(
        ApiEndpoints.reportProblem,
        body: {'problem': problem},
        sendToken: true,
      );

      if (_isAuthError(response)) {
        isAuth.value = false;
        _showLoginBottomSheet();
        return false;
      }

      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Check if response contains authentication error
  bool _isAuthError(Map<String, dynamic> response) {
    if (!response['success']) {
      final error = response['error']?.toString().toLowerCase() ?? '';
      return error.contains('authentication required') || error.contains('unauthorized') || error.contains('unauthenticated');
    }
    return false;
  }

  // Show login bottom sheet
  void _showLoginBottomSheet() {
    Get.bottomSheet(
      const LoginBottomSheet(),
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
    );
  }
}
