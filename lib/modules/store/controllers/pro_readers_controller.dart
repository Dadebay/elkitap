// Controller
// import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/modules/store/model/pro_readers_model.dart';
import 'package:get/get.dart';

class ProfessionalReadsController extends GetxController {
  final RxString errorMessage = ''.obs;
  final RxBool isLoading = false.obs;
  // Observable variables
  final RxList<ProfessionalRead> professionalReads = <ProfessionalRead>[].obs;

  final NetworkManager _networkManager = Get.find<NetworkManager>();

  @override
  void onInit() {
    super.onInit();
    fetchProfessionalReads();
  }

  // Fetch professional reads
  Future<void> fetchProfessionalReads({bool isAudioMode = false}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final endpoint = isAudioMode ? '/professional-reads/all?with_audio=true' : '/professional-reads/all';

      final response = await _networkManager.get(
        endpoint,
        sendToken: false,
      );

      if (response['success']) {
        final List<dynamic> data = response['data'] ?? [];
        professionalReads.value = data.map((json) => ProfessionalRead.fromJson(json)).toList();
      } else {
        errorMessage.value = response['error'] ?? 'Failed to fetch data';
        // AppSnackbar.error(errorMessage.value, title: 'Error');
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
      // AppSnackbar.error(errorMessage.value, title: 'Error');
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh data
  Future<void> refreshProfessionalReads({bool isAudioMode = false}) async {
    await fetchProfessionalReads(isAudioMode: isAudioMode);
  }
}
