
import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:get/get.dart';

class ReadingListController extends GetxController {
  final NetworkManager _networkManager = Get.find<NetworkManager>();

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
      final response = await _networkManager.get(
        ApiEndpoints.wantsToCount,
        sendToken: true,
      );

      if (response['statusCode'] == 200) {
        final data = response['data'];
        listenCount.value = data['listen_count'] ?? 0;
        readCount.value = data['read_count'] ?? 0;
        finishedCount.value = data['finished_count'] ?? 0;
      } else {}
    } catch (e) {
      // AppSnackbar.error('an_error_occurred'.tr);
    } finally {
      isLoading.value = false;
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
