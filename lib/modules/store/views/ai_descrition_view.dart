import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/modules/store/controllers/book_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconly/iconly.dart';

class AiDescriptionScreen extends StatefulWidget {
  final String bookId;

  const AiDescriptionScreen({
    super.key,
    required this.bookId,
  });

  @override
  State<AiDescriptionScreen> createState() => _AiDescriptionScreenState();
}

class _AiDescriptionScreenState extends State<AiDescriptionScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _box = GetStorage();

  final RxList<String> _pages = <String>[].obs;
  final RxInt _currentPage = 0.obs;

  /// Theme and font settings
  final RxBool _isDarkMode = false.obs;
  final RxDouble _fontSize = 14.0.obs;
  final RxBool _showControls = true.obs;

  /// Example: replace with API value
  late final String aiDescription;

  @override
  void initState() {
    super.initState();

    /// ⬅️ get text from your controller / API
    final controller = Get.find<BooksDetailController>(tag: widget.bookId);
    final translate = controller.getCurrentTranslate();
    aiDescription = translate?.aiDescription ?? '';

    print('🤖 AI Description Screen - Book ID: ${widget.bookId}');
    print('🤖 Current Translate: ${translate?.id}');
    print('🤖 AI Description length: ${aiDescription.length}');
    print('🤖 AI Description content: ${aiDescription.isEmpty ? "EMPTY!" : aiDescription.substring(0, aiDescription.length > 100 ? 100 : aiDescription.length)}...');

    _currentPage.value = _box.read('ai_page_${widget.bookId}') ?? 0;
    // Sync with app's theme mode instead of local storage
    _isDarkMode.value = Get.isDarkMode;
    _fontSize.value = _box.read('ai_font_size') ?? 14.0;

    _pageController = PageController(initialPage: _currentPage.value);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _splitContentIntoPages();
      _animationController.forward();
    });
  }

  void _splitContentIntoPages() {
    final size = MediaQuery.of(context).size;

    final textStyle = TextStyle(
      fontSize: _fontSize.value,
      height: 1,
      color: _isDarkMode.value ? Colors.white70 : Colors.black87,
    );

    final maxWidth = size.width - 32;

    final double lineHeight = _fontSize.value * 1;

    // Use this height for pagination constraints
    final double maxHeight = 15 * lineHeight;

    final words = aiDescription.split(RegExp(r'\s+'));

    String currentText = '';
    List<String> pages = [];

    for (final word in words) {
      final testText = currentText.isEmpty ? word : '$currentText $word';

      final painter = TextPainter(
        text: TextSpan(text: testText, style: textStyle),
        textDirection: TextDirection.ltr,
      );

      painter.layout(maxWidth: maxWidth);

      if (painter.height > maxHeight) {
        pages.add(currentText.trim());
        currentText = word;
      } else {
        currentText = testText;
      }

      painter.dispose();
    }

    if (currentText.isNotEmpty) {
      pages.add(currentText.trim());
    }

    _pages.value = pages;
  }

  void _toggleDarkMode() {
    _isDarkMode.value = !_isDarkMode.value;
    // Sync with app's theme
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    _splitContentIntoPages();
  }

  void _increaseFontSize() {
    if (_fontSize.value < 24) {
      _fontSize.value += 2;
      _box.write('ai_font_size', _fontSize.value);
      _splitContentIntoPages();
    }
  }

  void _decreaseFontSize() {
    if (_fontSize.value > 12) {
      _fontSize.value -= 2;
      _box.write('ai_font_size', _fontSize.value);
      _splitContentIntoPages();
    }
  }

  void _toggleControls() {
    _showControls.value = !_showControls.value;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final backgroundColor = _isDarkMode.value ? const Color(0xFF1C1C1E) : Colors.white;
      final textColor = _isDarkMode.value ? Colors.white : Colors.black;
      final appBarColor = _isDarkMode.value ? const Color(0xFF2C2C2E) : Colors.white;

      // Check if AI description is empty
      if (aiDescription.trim().isEmpty) {
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: appBarColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                IconlyLight.arrow_left_circle,
                color: textColor,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'AI Content',
              style: TextStyle(
                fontSize: 18,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: Center(
            child: Text(
              'no_ai_description_available'.tr,
              style: TextStyle(
                fontSize: 16,
                color: textColor.withOpacity(0.6),
              ),
            ),
          ),
        );
      }

      if (_pages.isEmpty) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: const Center(child: LoadingWidget(removeBackWhite: true)),
        );
      }

      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: _showControls.value
            ? AppBar(
                backgroundColor: appBarColor,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    IconlyLight.arrow_left_circle,
                    color: textColor,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  Get.find<BooksDetailController>(tag: widget.bookId).getBookName(),
                  style: TextStyle(
                    fontSize: 18,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: Icon(Icons.text_decrease, color: _fontSize.value <= 12 ? Colors.grey : textColor, size: 20),
                    onPressed: _fontSize.value <= 12 ? null : _decreaseFontSize,
                  ),
                  IconButton(
                    icon: Icon(Icons.text_increase, color: _fontSize.value >= 24 ? Colors.grey : textColor, size: 20),
                    onPressed: _fontSize.value >= 24 ? null : _increaseFontSize,
                  ),
                  IconButton(
                    icon: Icon(_isDarkMode.value ? Icons.light_mode : Icons.dark_mode, color: textColor, size: 20),
                    onPressed: _toggleDarkMode,
                  ),
                  const SizedBox(width: 8),
                ],
              )
            : null,
        body: GestureDetector(
          onTap: _toggleControls,
          behavior: HitTestBehavior.translucent,
          child: SafeArea(
            child: Stack(
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      _currentPage.value = index;
                      _box.write('ai_page_${widget.bookId}', index);
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 50),
                            child: Text(
                              _pages[index],
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontSize: _fontSize.value,
                                height: 1.7,
                                color: _isDarkMode.value ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Fixed page counter at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: backgroundColor.withOpacity(0.9),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left button
                        IconButton(
                          icon: Icon(
                            IconlyLight.arrow_left_circle,
                            color: _currentPage.value > 0 ? textColor : Colors.grey,
                            size: 20,
                          ),
                          onPressed: _currentPage.value > 0
                              ? () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              : null,
                        ),
                        // Page counter
                        Text(
                          '${_currentPage.value + 1} / ${_pages.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        // Right button
                        IconButton(
                          icon: Icon(
                            IconlyLight.arrow_right_circle,
                            color: _currentPage.value < _pages.length - 1 ? textColor : Colors.grey,
                            size: 20,
                          ),
                          onPressed: _currentPage.value < _pages.length - 1
                              ? () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
