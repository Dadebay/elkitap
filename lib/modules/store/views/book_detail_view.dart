import 'dart:developer';

import 'package:elkitap/data/network/token_managet.dart';
import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/audio_player/controllers/audio_player_controller.dart';
import 'package:elkitap/modules/paymant/controller/payment_controller.dart';
import 'package:elkitap/modules/reader/controllers/reader_controller.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';
import 'package:elkitap/modules/store/model/book_item_model.dart';
import 'package:elkitap/modules/store/services/book_detail_audio_service.dart';
import 'package:elkitap/modules/store/widgets/book_about_section.dart';
import 'package:elkitap/modules/store/widgets/book_action_buttons.dart';
import 'package:elkitap/modules/store/widgets/book_cover_section.dart';
import 'package:elkitap/modules/store/widgets/book_detail_app_bar.dart';
import 'package:elkitap/modules/store/widgets/book_info_section.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookDetailView extends StatefulWidget {
  final Book? book;
  final int? bookId;
  final bool isAudio;

  const BookDetailView({
    this.book,
    this.bookId,
    this.isAudio = false,
    super.key,
  });

  @override
  State<BookDetailView> createState() => _BookDetailViewState();
}

class _BookDetailViewState extends State<BookDetailView> with WidgetsBindingObserver, RouteAware {
  late BooksDetailController controller;
  late GlobalMiniPlayerController globalMiniCtrl;
  late EpubController epubCtrl;
  late BookDetailAudioService audioService;
  final PaymentController paymentController = Get.find<PaymentController>();
  late final int resolvedBookId;

  final Color accent = const Color(0xFFFF5A3C);
  DateTime? _lastProgressRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
    _initializeServices();
    _fetchBookDetail();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshProgress();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (ModalRoute.of(context)?.isCurrent == true) {
      _refreshProgress();
    }
  }

  void _refreshProgress() {
    if (controller.bookDetail.value != null) {
      final now = DateTime.now();
      if (_lastProgressRefreshTime == null || now.difference(_lastProgressRefreshTime!) > const Duration(seconds: 1)) {
        _lastProgressRefreshTime = now;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.fetchProgress();
        });
      }
    }
  }

  void _initializeControllers() {
    resolvedBookId = widget.book?.id ?? widget.bookId ?? 0;

    controller = Get.put(
      BooksDetailController(),
      tag: resolvedBookId.toString(),
    );

    if (widget.isAudio) {
      controller.isAudio.value = true;
    }

    globalMiniCtrl = Get.find<GlobalMiniPlayerController>();

    if (!Get.isRegistered<EpubController>()) {
      Get.lazyPut<EpubController>(() => EpubController());
    }
    epubCtrl = Get.find<EpubController>();
  }

  void _initializeServices() {
    audioService = BookDetailAudioService(
      controller: controller,
      globalMiniCtrl: globalMiniCtrl,
    );
  }

  void _fetchBookDetail() {
    if (controller.bookDetail.value == null) {
      controller.fetchBookDetail(resolvedBookId).then((_) {
        Future.delayed(const Duration(seconds: 2), () {
          _refreshProgress();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final TokenManager tokenManager = Get.find<TokenManager>();

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
      appBar: BookDetailAppBar(
        controller: controller,
        paymentController: paymentController,
        accent: accent,
        context: context,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return LoadingWidget(removeBackWhite: true);
        }

        if (controller.hasError.value) {
          return ErrorStateWidget(
            errorMessage: controller.errorMessage.value,
            onRetry: () => controller.fetchBookDetail(resolvedBookId),
          );
        }

        final bookDetail = controller.bookDetail.value;
        if (bookDetail == null) {
          return Center(
            child: Text('no_book_data_available'.tr),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 14),
                child: BookCoverSection(
                  controller: controller,
                  bookId: resolvedBookId,
                ),
              ),
              BookInfoSection(controller: controller, bookDetail: bookDetail, context: context),
              BookActionButtons(
                  controller: controller,
                  paymentController: paymentController,
                  bookDetail: bookDetail,
                  tokenManager: tokenManager,
                  audioService: audioService,
                  bookId: widget.book?.id.toString() ?? widget.bookId.toString(),
                  context: context),
              const SizedBox(height: 32),
              BookAboutSection(
                controller: controller,
                bookId: widget.book?.id.toString() ?? widget.bookId.toString(),
                context: context,
              ),
            ],
          ),
        );
      }),
    );
  }
}
