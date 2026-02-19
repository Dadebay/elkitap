import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/modules/paymant/models/bank_model.dart';
import 'package:elkitap/modules/paymant/models/order_model.dart';
import 'package:elkitap/modules/paymant/models/payment_history_model.dart';
import 'package:elkitap/modules/paymant/models/tariff_model.dart';
import 'package:get/get.dart';

class PaymentController extends GetxController {
  final NetworkManager _networkManager = Get.find<NetworkManager>();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<TariffModel> tariffs = <TariffModel>[].obs;
  final Rx<TariffModel?> selectedTariff = Rx<TariffModel?>(null);

  // Banks state
  final RxBool isBanksLoading = false.obs;
  final RxString banksErrorMessage = ''.obs;
  final RxList<BankModel> banks = <BankModel>[].obs;
  final Rx<BankModel?> selectedBank = Rx<BankModel?>(null);

  // Payment history state
  final RxBool isPaymentHistoryLoading = false.obs;
  final RxString paymentHistoryErrorMessage = ''.obs;
  final RxList<PaymentHistoryModel> paymentHistory = <PaymentHistoryModel>[].obs;

  // Payment status state
  final RxBool isPaymentActive = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTariffs();
    getPaymentStatus();
  }

  /// Get payment status
  Future<void> getPaymentStatus() async {
    try {
      final response = await _networkManager.get(ApiEndpoints.paymentIsActive);

      if (response['statusCode'] == 200) {
        if (response['data'] != null && response['data']['is_active'] == true) {
          isPaymentActive.value = true;
        } else {
          isPaymentActive.value = false;
        }
      }
    } catch (e) {
      print('Error checking payment status: $e');
      // Default to false on error to show audio book
      isPaymentActive.value = false;
    }
  }

  /// Fetch all available tariffs from the API
  Future<void> fetchTariffs() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _networkManager.get(
        ApiEndpoints.tariffs,
        sendToken: true,
      );

      isLoading.value = false;

      if (response['statusCode'] == 200) {
        final tariffResponse = TariffResponse.fromJson(response);
        tariffs.value = tariffResponse.data;

        // Auto-select the first tariff if available
        if (tariffs.isNotEmpty) {
          selectedTariff.value = tariffs.first;
        }
      } else {
        errorMessage.value = response['message'] ?? 'Failed to load tariffs';
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'An error occurred while loading tariffs';
      print('Error fetching tariffs: $e');
    }
  }

  /// Select a tariff
  void selectTariff(TariffModel tariff) {
    selectedTariff.value = tariff;
  }

  /// Get tariff by month count
  TariffModel? getTariffByMonthCount(int monthCount) {
    try {
      return tariffs.firstWhere((tariff) => tariff.monthCount == monthCount);
    } catch (e) {
      return null;
    }
  }

  /// Refresh tariffs
  Future<void> refreshTariffs() async {
    await fetchTariffs();
  }

  /// Fetch all available banks from the API
  Future<void> fetchBanks() async {
    try {
      isBanksLoading.value = true;
      banksErrorMessage.value = '';

      final response = await _networkManager.get(
        ApiEndpoints.banks,
        sendToken: true,
      );

      isBanksLoading.value = false;

      if (response['statusCode'] == 200) {
        final bankResponse = BankResponse.fromJson(response);
        banks.value = bankResponse.data;

        // Auto-select the first bank if available
        if (banks.isNotEmpty) {
          selectedBank.value = banks.first;
        }
      } else {
        banksErrorMessage.value = response['message'] ?? 'Failed to load banks';
      }
    } catch (e) {
      isBanksLoading.value = false;
      banksErrorMessage.value = 'An error occurred while loading banks';
      print('Error fetching banks: $e');
    }
  }

  /// Select a bank
  void selectBank(BankModel bank) {
    selectedBank.value = bank;
  }

  /// Create payment order
  Future<String?> createOrder(int tariffId, int bankId) async {
    try {
      final request = OrderRequest(
        tariffId: tariffId,
        bankId: bankId,
      );

      final response = await _networkManager.post(
        ApiEndpoints.orders,
        body: request.toJson(),
        sendToken: true,
      );

      if (response['statusCode'] == 201) {
        final orderResponse = OrderResponse.fromJson(response);
        return orderResponse.data.invoiceUrl;
      } else {
        AppSnackbar.error(response['message'] ?? 'Failed to create order');
        return null;
      }
    } catch (e) {
      print('Error creating order: $e');
      AppSnackbar.error('An error occurred while creating order');
      return null;
    }
  }

  /// Fetch payment history from the API
  Future<void> fetchPaymentHistory() async {
    try {
      isPaymentHistoryLoading.value = true;
      paymentHistoryErrorMessage.value = '';

      final response = await _networkManager.get(
        ApiEndpoints.paymentHistory,
        sendToken: true,
      );

      isPaymentHistoryLoading.value = false;

      if (response['statusCode'] == 200) {
        final paymentHistoryResponse = PaymentHistoryResponse.fromJson(response);
        paymentHistory.value = paymentHistoryResponse.data;
      } else {
        paymentHistoryErrorMessage.value = response['message'] ?? 'Failed to load payment history';
      }
    } catch (e) {
      isPaymentHistoryLoading.value = false;
      paymentHistoryErrorMessage.value = 'An error occurred while loading payment history';
      print('Error fetching payment history: $e');
    }
  }

  /// Refresh payment history
  Future<void> refreshPaymentHistory() async {
    await fetchPaymentHistory();
  }

  /// Reset controller state
  void resetState() {
    isLoading.value = false;
    errorMessage.value = '';
    selectedTariff.value = null;
    isBanksLoading.value = false;
    banksErrorMessage.value = '';
    selectedBank.value = null;
    isPaymentHistoryLoading.value = false;
    paymentHistoryErrorMessage.value = '';
    paymentHistory.clear();
  }
}
