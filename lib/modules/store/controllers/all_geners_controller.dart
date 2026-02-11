import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/modules/store/model/geners_model.dart';
import 'package:get/get.dart';

class AllGenresController extends GetxController {
  final NetworkManager _networkManager = Get.find<NetworkManager>();

  // Observable list of main genres (for AllGenresView)
  final RxList<Genre> genres = <Genre>[].obs;

  // Observable list of sub genres (for GenrsDetailViewScreen)
  final RxList<Genre> subGenres = <Genre>[].obs;

  // Loading state
  final RxBool isLoading = false.obs;

  // Error message
  final RxString errorMessage = ''.obs;

  // Track current audio mode to avoid unnecessary refetches
  bool? _currentAudioMode;

  @override
  void onInit() {
    super.onInit();
    // Don't fetch automatically - let the widget control when to fetch
  }

  void onScreenVisible() {
    // Only fetch if genres are empty and no audio mode is set
    if (genres.isEmpty && _currentAudioMode == null) {
      fetchAllGenres();
    }
  }

  // Fetch all genres with optional parent_id and with_audio parameters
  Future<void> fetchAllGenres({int? parentId, bool? withAudio}) async {
    final startTime = DateTime.now();
    print('\n🎭 [AllGenresController] fetchAllGenres STARTED');
    print('⏱️  Start Time: ${startTime.toIso8601String()}');
    print('🔍 Params: parentId=$parentId, withAudio=$withAudio');

    try {
      // Normalize null to false for comparison
      final normalizedAudioMode = withAudio ?? false;
      final normalizedCurrentMode = _currentAudioMode ?? false;

      // Skip if we're fetching the same audio mode and genres already exist
      if (normalizedCurrentMode == normalizedAudioMode && genres.isNotEmpty && parentId == null) {
        print('⏭️  Skipping: Same audio mode and genres already loaded');
        return;
      }

      isLoading.value = true;
      errorMessage.value = '';

      // Update current audio mode
      _currentAudioMode = withAudio;

      // Build query parameters
      String endpoint = ApiEndpoints.geners;
      List<String> queryParams = [];

      // Add parent_id parameter
      if (parentId != null) {
        queryParams.add('parent_id=$parentId');
      } else {
        queryParams.add('parent_id=');
      }

      // Add with_audio parameter if specified
      // if (withAudio != null && withAudio) {
      //   queryParams.add('with_audio=true');
      // }

      // Combine all query parameters
      if (queryParams.isNotEmpty) {
        endpoint = '$endpoint?${queryParams.join('&')}';
      }

      final response = await _networkManager.get(
        endpoint,
        sendToken: true,
      );

      if (response['success']) {
        final List<dynamic> data = response['data'] ?? [];
        genres.value = data.map((json) => Genre.fromJson(json)).toList();
      } else {
        errorMessage.value = response['error'] ?? 'Failed to fetch genres';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh genres (force refetch)
  Future<void> refreshGenres({int? parentId, bool? withAudio}) async {
    _currentAudioMode = null; // Reset to force refetch
    await fetchAllGenres(parentId: parentId, withAudio: withAudio);
  }

  // Fetch main genres (parent_id is empty)
  Future<void> fetchMainGenres() async {
    // Force refresh main genres by resetting audio mode
    _currentAudioMode = null;
    await fetchAllGenres();
  }

  // Fetch sub genres by parent id
  Future<void> fetchSubGenres(int parentId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Build query parameters for sub genres
      String endpoint = '${ApiEndpoints.geners}?parent_id=$parentId';

      final response = await _networkManager.get(
        endpoint,
        sendToken: true,
      );

      if (response['success']) {
        final List<dynamic> data = response['data'] ?? [];
        subGenres.value = data.map((json) => Genre.fromJson(json)).toList();
      } else {
        errorMessage.value = response['error'] ?? 'Failed to fetch sub genres';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Get genre by id
  Genre? getGenreById(int id) {
    try {
      return genres.firstWhere((genre) => genre.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get parent genres (genres without parent_id)
  List<Genre> getParentGenres() {
    return genres.where((genre) => genre.parentId == null).toList();
  }

  // Get child genres by parent id
  List<Genre> getChildGenres(int parentId) {
    // Return sub genres from the subGenres list
    return subGenres.toList();
  }

  @override
  void onClose() {
    // Clear genres to free memory
    genres.clear();
    subGenres.clear();
    _currentAudioMode = null;

    super.onClose();
  }
}
