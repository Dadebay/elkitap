import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/data/network/token_managet.dart';
import 'package:elkitap/modules/audio_player/controllers/audio_player_controller.dart';
import 'package:elkitap/modules/audio_player/views/audio_player_view.dart';
import 'package:elkitap/modules/auth/widget/login_bottom_sheet.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';
import 'package:get/get.dart';

class BookDetailAudioService {
  final BooksDetailController controller;
  final GlobalMiniPlayerController globalMiniCtrl;

  BookDetailAudioService({
    required this.controller,
    required this.globalMiniCtrl,
  });

  Future<void> handleListenButtonTap(
    dynamic bookDetail,
    TokenManager tokenManager,
  ) async {
    if (!tokenManager.isAuthenticated.value) {
      _showLoginBottomSheet();
      return;
    }

    if (controller.isLoadingAudio.value) return;

    await controller.fetchAudioHlsUrl();

    if (controller.audioHlsUrl.value.isEmpty) {
      AppSnackbar.error('audio_not_available'.tr, title: 'error'.tr);
      return;
    }

    controller.isAudio.value = true;

    final bookTitle = controller.getBookName();
    final bookAuthor = controller.getAuthorsString();
    final bookCover = controller.getBookCoverImage();
    final hlsUrl = controller.audioHlsUrl.value;

    double? initialProgress;
    if (controller.progress.value != null) {
      initialProgress = (double.tryParse(controller.progress.value!) ?? 0.0) / 100;
    }

    Get.to(
      () => AudiobookPlayerScreen(
        bookTitle: bookTitle,
        bookAuthor: bookAuthor,
        bookCover: bookCover,
        hlsUrl: hlsUrl,
        bookId: bookDetail.id,
        initialProgress: initialProgress,
      ),
    );

    globalMiniCtrl.hide();
  }

  void _showLoginBottomSheet() {
    Get.bottomSheet(
      const LoginBottomSheet(),
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
    );
  }
}
