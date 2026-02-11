import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';
import 'package:get/get.dart';

class BookCollectionController extends GetxController {
  final NetworkManager _networkManager = Get.find<NetworkManager>();

  final RxList<BookCollection> collections = <BookCollection>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCollections();
  }

  Future<void> fetchCollections({bool isAudioMode = false}) async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final endpoint = isAudioMode ? '${ApiEndpoints.allCollections}?with_audio=true' : ApiEndpoints.allCollections;

      final apiStartTime = DateTime.now();
      final response = await _networkManager.get(
        endpoint,
        sendToken: true,
      );
      final apiEndTime = DateTime.now();
      apiEndTime.difference(apiStartTime);

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        collections.value = data.map((json) => BookCollection.fromJson(json)).toList();
      } else {
        hasError.value = true;
        errorMessage.value = response['error'] ?? 'Failed to fetch collections';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh collections
  Future<void> refreshCollections({bool isAudioMode = false}) async {
    await fetchCollections(isAudioMode: isAudioMode);
  }

  // Get collection by id
  BookCollection? getCollectionById(int id) {
    try {
      return collections.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // Get all books from all collections
  List<Book> get allBooks {
    return collections.expand((c) => c.books).toList();
  }

  @override
  void onClose() {
    // Clear collections to free memory
    collections.clear();

    super.onClose();
  }
}
