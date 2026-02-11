import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:get/get.dart';

class ContactsController extends GetxController {
  final NetworkManager _networkManager = Get.find<NetworkManager>();

  final RxBool isLoading = false.obs;
  final Rx<Map<String, dynamic>?> contacts = Rx<Map<String, dynamic>?>(null);

  final RxString tgName = ''.obs;
  final RxString startName = ''.obs;
  final RxString phone = ''.obs;
  final RxString email = ''.obs;
  final RxString privacyLink = ''.obs;
  final RxString userAgreementLink = ''.obs;

  @override
  void onInit() {
    super.onInit();
    getContacts();
  }

  Future<bool> getContacts() async {
    try {
      isLoading.value = true;

      final response = await _networkManager.get(
        ApiEndpoints.contacts,
        sendToken: true,
      );

      if (response['statusCode'] == 200) {
        contacts.value = response['data'];

        final data = response['data'];
        tgName.value = data['tg_name'] ?? '';
        startName.value = data['start_name'] ?? '';
        phone.value = data['phone'] ?? '';
        email.value = data['email'] ?? '';
        privacyLink.value = data['privacy_link'] ?? '';
        userAgreementLink.value = data['user_aggreement_link'] ?? '';

        return true;
      } else {
        AppSnackbar.error(response['message'] ?? 'failed_to_load_contacts'.tr);
        return false;
      }
    } catch (e) {
      // AppSnackbar.error('an_error_occurred'.tr);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  String? getContactField(String field) {
    return contacts.value?[field];
  }

  String get telegramName => tgName.value;
  String get startupName => startName.value;
  String get phoneNumber => phone.value;
  String get emailAddress => email.value;
  String get privacyPolicyLink => privacyLink.value;
  String get userAgreementUrl => userAgreementLink.value;
  bool get hasContacts => contacts.value != null;

  Future<void> refreshContacts() async {
    await getContacts();
  }
}
