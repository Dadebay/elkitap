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
        print('⚠️ No token found, resetting counts to 0');
        _resetCounts();
        return;
      }

      // Backend'deki count API'si tutarsız olduğu için
      // gerçek kitap sayılarını ayrı ayrı fetch ediyoruz
      await _fetchRealCounts();
    } catch (e) {
      print('Exception in getCounts: $e');
      // AppSnackbar.error('an_error_occurred'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void _resetCounts() {
    readCount.value = 0;
    listenCount.value = 0;
    finishedCount.value = 0;
    print('📊 All counts reset to 0');
  }

  // Gerçek kitap sayılarını fetch et (Backend count'ları tutarsız)
  Future<void> _fetchRealCounts() async {
    try {
      print('\n📊 ========== FETCHING REAL COUNTS ==========');

      // Read count - gerçek sayı
      print('📖 READ COUNT REQUEST:');
      print('   Endpoint: ${ApiEndpoints.allBooks}');
      print('   Query Params: wants_to=read, page=1, size=1');

      final readResponse = await _networkManager.get(
        ApiEndpoints.allBooks,
        sendToken: true,
        queryParameters: {
          'wants_to': 'read',
          'page': '1',
          'size': '1',
        },
      );

      print('📖 READ COUNT RESPONSE:');
      print('   Status: ${readResponse['statusCode']}');
      print('   Full Response: $readResponse');

      if (readResponse['statusCode'] == 200) {
        final totalCount = readResponse['data']['totalCount'] ?? 0;
        readCount.value = totalCount;
        print('   ✅ Read Count Set To: ${readCount.value}');
        print('   Items Count: ${(readResponse['data']['items'] as List?)?.length ?? 0}');
      } else if (readResponse['statusCode'] == 401) {
        print('   ⚠️ Unauthorized - setting read count to 0');
        readCount.value = 0;
      }

      // Listen count - gerçek sayı
      print('\n🎧 LISTEN COUNT REQUEST:');
      print('   Endpoint: ${ApiEndpoints.allBooks}');
      print('   Query Params: wants_to=listen, page=1, size=1');

      final listenResponse = await _networkManager.get(
        ApiEndpoints.allBooks,
        sendToken: true,
        queryParameters: {
          'wants_to': 'listen',
          'page': '1',
          'size': '1',
        },
      );

      print('🎧 LISTEN COUNT RESPONSE:');
      print('   Status: ${listenResponse['statusCode']}');
      print('   Full Response: $listenResponse');

      if (listenResponse['statusCode'] == 200) {
        final totalCount = listenResponse['data']['totalCount'] ?? 0;
        listenCount.value = totalCount;
        print('   ✅ Listen Count Set To: ${listenCount.value}');
        print('   Items Count: ${(listenResponse['data']['items'] as List?)?.length ?? 0}');
      } else if (listenResponse['statusCode'] == 401) {
        print('   ⚠️ Unauthorized - setting listen count to 0');
        listenCount.value = 0;
      }

      // Finished count - gerçek sayı
      print('\n✔️ FINISHED COUNT REQUEST:');
      print('   Endpoint: ${ApiEndpoints.allBooks}');
      print('   Query Params: wants_to=finished, page=1, size=1');

      final finishedResponse = await _networkManager.get(
        ApiEndpoints.allBooks,
        sendToken: true,
        queryParameters: {
          'wants_to': 'finished',
          'page': '1',
          'size': '1',
        },
      );

      print('✔️ FINISHED COUNT RESPONSE:');
      print('   Status: ${finishedResponse['statusCode']}');
      print('   Full Response: $finishedResponse');

      if (finishedResponse['statusCode'] == 200) {
        final totalCount = finishedResponse['data']['totalCount'] ?? 0;
        finishedCount.value = totalCount;
        print('   ✅ Finished Count Set To: ${finishedCount.value}');
        print('   Items Count: ${(finishedResponse['data']['items'] as List?)?.length ?? 0}');
      } else if (finishedResponse['statusCode'] == 401) {
        print('   ⚠️ Unauthorized - setting finished count to 0');
        finishedCount.value = 0;
      }

      print('\n📊 FINAL COUNTS:');
      print('   Read: ${readCount.value}');
      print('   Listen: ${listenCount.value}');
      print('   Finished: ${finishedCount.value}');
      print('========== DONE ==========\n');
    } catch (e) {
      print('❌ Error fetching real counts: $e');
    }
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
