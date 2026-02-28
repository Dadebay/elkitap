// ignore_for_file: avoid_print

import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/data/network/token_managet.dart';
import 'package:get/get.dart';

class ReadingListController extends GetxController {
  final NetworkManager _networkManager = Get.find<NetworkManager>();
  final TokenManager _tokenManager = Get.find<TokenManager>();

  final RxBool isLoading = false.obs;
  final RxInt listenCount = 0.obs;
  final RxInt readCount = 0.obs;
  final RxInt finishedCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    getCounts();
  }

  Future<void> getCounts() async {
    try {
      isLoading.value = true;

      // Check if user is authenticated
      final token = _tokenManager.getToken();
      if (token == null || token.isEmpty) {
        _resetCounts();
        return;
      }

      // Backend'deki count API'si tutarsız olduğu için
      // gerçek kitap sayılarını ayrı ayrı fetch ediyoruz
      await _fetchRealCounts();
    } catch (e) {
      // AppSnackbar.error('an_error_occurred'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void _resetCounts() {
    readCount.value = 0;
    listenCount.value = 0;
    finishedCount.value = 0;
  }

  // Gerçek kitap sayılarını fetch et (Backend count'ları tutarsız)
  Future<void> _fetchRealCounts() async {
    try {
      final readResponse = await _networkManager.get(
        ApiEndpoints.allBooks,
        sendToken: true,
        queryParameters: {
          'wants_to': 'read',
          'page': '1',
          'size': '1',
        },
      );

      if (readResponse['statusCode'] == 200) {
        final totalCount = readResponse['data']['totalCount'] ?? 0;
        readCount.value = totalCount;
      } else if (readResponse['statusCode'] == 401) {
        readCount.value = 0;
      }

      // Listen count - gerçek sayı
      final listenResponse = await _networkManager.get(
        ApiEndpoints.allBooks,
        sendToken: true,
        queryParameters: {
          'wants_to': 'listen',
          'page': '1',
          'size': '1',
        },
      );

      if (listenResponse['statusCode'] == 200) {
        final totalCount = listenResponse['data']['totalCount'] ?? 0;
        listenCount.value = totalCount;
      } else if (listenResponse['statusCode'] == 401) {
        listenCount.value = 0;
      }

      // Finished count - gerçek sayı

      final finishedResponse = await _networkManager.get(
        ApiEndpoints.allBooks,
        sendToken: true,
        queryParameters: {
          'wants_to': 'finished',
          'page': '1',
          'size': '1',
        },
      );

      if (finishedResponse['statusCode'] == 200) {
        final totalCount = finishedResponse['data']['totalCount'] ?? 0;
        finishedCount.value = totalCount;
      } else if (finishedResponse['statusCode'] == 401) {
        print('   ⚠️ Unauthorized - setting finished count to 0');
        finishedCount.value = 0;
      }
    } catch (e) {}
  }

  @override
  void onClose() {
    // Reset counts
    listenCount.value = 0;
    readCount.value = 0;
    finishedCount.value = 0;

    super.onClose();
  }
}
