import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/modules/notifications/models/suggestion_model.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class NotificationController extends GetxController {
  final RxList<SuggestionModel> suggestions = <SuggestionModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt unreadCount = 0.obs;
  final _storage = GetStorage();
  final RxList<int> _readSuggestionIds = <int>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadReadStatus();
    fetchNotifications();
  }

  void _loadReadStatus() {
    final List<dynamic>? storedIds = _storage.read('read_notifications');
    if (storedIds != null) {
      _readSuggestionIds.value = storedIds.cast<int>();
    }
  }

  void markAsRead(int id) {
    if (!_readSuggestionIds.contains(id)) {
      _readSuggestionIds.add(id);
      _storage.write('read_notifications', _readSuggestionIds.toList());
      _updateUnreadCount();
    }
  }

  bool isRead(int id) {
    return _readSuggestionIds.contains(id);
  }

  void _updateUnreadCount() {
    unreadCount.value = suggestions.where((s) => !isRead(s.id)).length;
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      final NetworkManager networkManager = Get.find<NetworkManager>();

      final response = await networkManager.get(ApiEndpoints.mySuggestions, sendToken: true);

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        print(response);
        print(response['data']);
        final list = data.map((json) => SuggestionModel.fromJson(json)).toList();
        // updated_at'e göre en yeniden en eskiye sırala
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        suggestions.value = list;
        _updateUnreadCount();
      } else {
        suggestions.clear();
        unreadCount.value = 0;
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshNotifications() async {
    await fetchNotifications();
  }
}
