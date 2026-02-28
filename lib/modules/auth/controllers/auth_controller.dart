// ignore_for_file: deprecated_member_use

import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/data/network/token_managet.dart';
import 'package:elkitap/modules/audio_player/controllers/audio_player_controller.dart';
import 'package:elkitap/modules/auth/models/user_model.dart';
import 'package:elkitap/modules/library/controllers/note_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final NetworkManager _networkManager = Get.find<NetworkManager>();
  final TokenManager _tokenManager = Get.find<TokenManager>();

  final RxBool isLoading = false.obs;
  final RxString currentPhone = ''.obs;
  final Rx<User?> currentUser = Rx<User?>(null);

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final token = _tokenManager.getToken();
    if (token != null && token.isNotEmpty) {
      await getMe();
    }
  }

  // Send verification code
  Future<bool> sendCode(String phone) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📲 SEND CODE STARTED');
      debugPrint('📞 Phone Input: $phone');

      isLoading.value = true;

      // Format phone number with country code
      final formattedPhone = phone.startsWith('+993') ? phone : '+993$phone';
      currentPhone.value = formattedPhone;

      debugPrint('📱 Formatted Phone: $formattedPhone');
      debugPrint('🌐 Endpoint: ${ApiEndpoints.sendCode}');

      final response = await _networkManager.post(
        ApiEndpoints.sendCode,
        body: {
          'phone': formattedPhone,
        },
        sendToken: false,
      );

      debugPrint('📥 Response:');
      debugPrint('   Success: ${response['success']}');
      debugPrint('   Data: ${response['data']}');
      debugPrint('   Error: ${response['error']}');

      if (response['success']) {
        debugPrint('✅ Code Sent Successfully');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return true;
      } else {
        debugPrint('❌ Failed to Send Code');
        debugPrint('Error: ${response['error']}');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('💥 EXCEPTION IN SEND CODE');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Verify code and login
  Future<bool> verifyCodeAndLogin(String code) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔐 OTP VERIFICATION STARTED');
      debugPrint('📱 Phone: ${currentPhone.value}');
      debugPrint('🔢 Code: $code');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      isLoading.value = true;

      final requestBody = {
        'phone': currentPhone.value,
        'code': int.parse(code),
      };

      debugPrint('📤 Request Body: $requestBody');
      debugPrint('🌐 Endpoint: ${ApiEndpoints.verifyCode}');

      final response = await _networkManager.post(
        ApiEndpoints.verifyCode,
        body: requestBody,
        sendToken: false,
      );

      debugPrint('📥 Response Received:');
      debugPrint('   Success: ${response['success']}');
      debugPrint('   Data: ${response['data']}');
      debugPrint('   Error: ${response['error']}');

      if (response['success']) {
        debugPrint('✅ OTP Verification Successful');

        // Extract token and user data from response
        final data = response['data'];
        final accessToken = data['accessToken'];

        debugPrint('🎟️ Access Token: ${accessToken?.substring(0, 20)}...');

        // Save token first
        await _tokenManager.saveToken(accessToken);
        debugPrint('💾 Token Saved Successfully');

        // Refresh user profile to get latest data including subscription status
        debugPrint('👤 Fetching User Profile...');
        await getMe();
        debugPrint('✅ User Profile Fetched Successfully');

        AppSnackbar.success('logged_in_successfully'.tr);

        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('✅ LOGIN PROCESS COMPLETED SUCCESSFULLY');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return true;
      } else {
        debugPrint('❌ OTP Verification Failed');
        debugPrint('Error Message: ${response['error']}');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackbar.error(response['error'] ?? 'invalid_code'.tr);
        });

        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('💥 EXCEPTION IN OTP VERIFICATION');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   AppSnackbar.error('an_error_occurred'.tr);
      // });
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get current user profile
  Future<bool> getMe() async {
    try {
      isLoading.value = true;

      final response = await _networkManager.get(
        ApiEndpoints.getMe,
        sendToken: true,
      );

      if (response['statusCode'] == 200) {
        // Only update currentUser in memory, don't persist to storage
        currentUser.value = User.fromJson(response['data']);
        return true;
      } else {
        // AppSnackbar.error(response['message'] ?? 'failed_to_load_profile'.tr);
        return false;
      }
    } catch (e) {
      // AppSnackbar.error('an_error_occurred'.tr);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update username
  Future<bool> updateUsername(String username) async {
    try {
      isLoading.value = true;

      final response = await _networkManager.patch(
        ApiEndpoints.updateUser,
        body: {
          'username': username,
        },
        sendToken: true,
      );

      if (response['success'] || response['statusCode'] == 200) {
        // Refresh user data after successful update
        await getMe();

        AppSnackbar.success('username_updated_successfully'.tr);
        return true;
      } else {
        AppSnackbar.error(response['message'] ?? 'failed_to_update_username'.tr);
        return false;
      }
    } catch (e) {
      // AppSnackbar.error('an_error_occurred'.tr);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🚪 LOGOUT STARTED');

      // Close all dialogs and snackbars first
      Get.closeAllSnackbars();
      while (Get.isDialogOpen ?? false) {
        Get.back();
      }
      debugPrint('✅ Closed all dialogs and snackbars');

      // Stop audio if playing
      try {
        if (Get.isRegistered<AudioPlayerController>()) {
          final audioController = Get.find<AudioPlayerController>();
          await audioController.stopAudio();
          debugPrint('✅ Stopped audio player');
        }
      } catch (e) {
        debugPrint('⚠️ Error stopping audio: $e');
      }

      // Clear user data
      await _tokenManager.clearToken();
      currentUser.value = null;
      debugPrint('✅ Cleared token and user data');

      // Navigate to auth screen FIRST
      debugPrint('🔄 Navigating to auth screen...');
      Get.offAllNamed('/auth');

      // Wait for navigation to complete and frame to build
      await Future.delayed(const Duration(milliseconds: 300));

      // Now cleanup controllers after we're on auth screen
      debugPrint('🧹 Starting cleanup...');
      _deleteSessionControllers();
      debugPrint('✅ Controllers cleaned up');

      // Recreate controllers for next session after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        debugPrint('🔄 Reinitializing controllers...');
        // _reinitializeControllers();
        debugPrint('✅ Controllers reinitialized');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      });
    } catch (e, stackTrace) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('💥 LOGOUT ERROR: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      // Force navigation even if cleanup fails
      Get.offAllNamed('/auth');
    }
  }

  void _deleteSessionControllers() {
    try {
      // Delete all tagged instances first
      debugPrint('🗑️ Deleting tagged controllers...');

      // Notes controllers with tags
      final notesInstances = ['collections_notes', 'book_notes', 'all_notes'];
      for (var tag in notesInstances) {
        try {
          if (Get.isRegistered<NotesController>(tag: tag)) {
            Get.delete<NotesController>(tag: tag, force: true);
            debugPrint('  ✓ Deleted NotesController($tag)');
          }
        } catch (e) {
          debugPrint('  ✗ Error deleting NotesController($tag): $e');
        }
      }

      // Books controllers with tags
      // final booksInstances = [
      //   'recently_opened',
      //   'recently_viewed',
      //   'featured',
      //   'top_week'
      // ];
      // for (var tag in booksInstances) {
      //   try {
      //     if (Get.isRegistered<GetAllBooksController>(tag: tag)) {
      //       Get.delete<GetAllBooksController>(tag: tag, force: true);
      //       debugPrint('  ✓ Deleted GetAllBooksController($tag)');
      //     }
      //   } catch (e) {
      //     debugPrint('  ✗ Error deleting GetAllBooksController($tag): $e');
      //   }
      // }

      // debugPrint('🗑️ Deleting main controllers...');
      // // Delete main controllers
      // final controllers = [
      //   (NotesController, 'NotesController'),
      //   (LibraryMainController, 'LibraryMainController'),
      //   (DownloadController, 'DownloadController'),
      //   (BookCollectionController, 'BookCollectionController'),
      //   (BooksDetailController, 'BooksDetailController'),
      //   (GetAllBooksController, 'GetAllBooksController'),
      //   (AuthorController, 'AuthorController'),
      //   (AllGenresController, 'AllGenresController'),
      //   (SearchResultsController, 'SearchResultsController'),
      //   (ProfessionalReadsController, 'ProfessionalReadsController'),
      //   (PaymentController, 'PaymentController'),
      //   (PromoCodeController, 'PromoCodeController'),
      //   (ContactsController, 'ContactsController'),
      // ];

      // for (var ctrl in controllers) {
      //   try {
      //     Get.delete(tag: ctrl.$1.toString(), force: true);
      //     debugPrint('  ✓ Deleted ${ctrl.$2}');
      //   } catch (e) {
      //     debugPrint('  ✗ Error deleting ${ctrl.$2}: $e');
      //   }
      // }
    } catch (e, stackTrace) {
      debugPrint('💥 Error in _deleteSessionControllers: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  // void _reinitializeControllers() {
  //   try {
  //     // Recreate controllers for next login session
  //     Get.put(AllGenresController());
  //     Get.put(AuthorController());
  //     Get.put(SearchResultsController());
  //     Get.put(BooksDetailController());
  //     Get.put(GetAllBooksController());
  //     Get.put(ProfessionalReadsController());
  //     Get.put(DownloadController());
  //     Get.put(BookCollectionController());
  //     Get.put(LibraryMainController());
  //     Get.put(NotesController());
  //     Get.put(ContactsController());
  //     Get.put(PromoCodeController());
  //     Get.put(PaymentController());
  //   } catch (e) {
  //     debugPrint('Error reinitializing controllers: $e');
  //   }
  // }
}
