import 'package:elkitap/core/constants/icon_constants.dart';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/custom_icon.dart';
import 'package:elkitap/core/widgets/states/error_state_widget.dart';
import 'package:elkitap/core/widgets/states/loading_widget.dart';
import 'package:elkitap/core/widgets/widgets.dart';
import 'package:elkitap/modules/library/controllers/note_controller.dart';
import 'package:elkitap/modules/library/model/note_item_model.dart';
import 'package:elkitap/modules/library/widgets/note_cart.dart';
import 'package:elkitap/modules/store/views/book_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

class NotesScreen extends StatefulWidget {
  final String? baseUrl;

  const NotesScreen({
    Key? key,
    this.baseUrl,
  }) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late final NotesController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(NotesController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchBookNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          backgroundColor: _getBackgroundColor(),
          appBar: _buildAppBar(),
          body: _buildBody(),
        ));
  }

  Color _getBackgroundColor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (controller.isSelectionMode.value) {
      return isDark ? Colors.grey[700]! : Colors.grey[300]!;
    }
    return isDark ? Colors.black : Colors.white;
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _getBackgroundColor(),
      elevation: 0,
      leadingWidth: 170,
      leading: _buildAppBarLeading(),
      actions: _buildAppBarActions(),
    );
  }

  Widget _buildAppBarLeading() {
    if (controller.isSelectionMode.value) {
      return TextButton(
        onPressed: () => controller.toggleSelectAll(),
        child: Obx(() => Text(
              controller.isAllSelected ? 'deselectAll'.tr : 'selectAll'.tr,
              style: TextStyle(
                fontFamily: StringConstants.SFPro,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontSize: 17,
              ),
            )),
      );
    }

    return CustomAppBar(
      title: '',
      showBackButton: true,
      leadingText: 'leading_text'.tr,
    );
  }

  List<Widget> _buildAppBarActions() {
    if (controller.isSelectionMode.value) {
      return [
        TextButton(
          onPressed: () => controller.showCupertinoMenu(context),
          child: Text(
            'remove'.tr,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 17,
            ),
          ),
        ),
        TextButton(
          onPressed: () => controller.toggleSelectionMode(),
          child: Text(
            'done'.tr,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              fontSize: 17,
            ),
          ),
        ),
      ];
    }

    if (controller.notes.isEmpty) {
      return [Container()];
    }

    return [
      TextButton(
        onPressed: () => controller.toggleSelectionMode(),
        child: Text(
          'select'.tr,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            fontFamily: StringConstants.SFPro,
            fontSize: 17,
          ),
        ),
      ),
    ];
  }

  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: LoadingWidget());
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return ErrorStateWidget(
          errorMessage: controller.errorMessage.value,
          onRetry: () => controller.fetchBookNotes(),
        );
      }

      if (controller.notes.isEmpty) {
        return _buildEmptyState();
      }

      return _buildNotesList();
    });
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () async => await controller.fetchBookNotes(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIcon(
                    title: IconConstants.libraryFilled,
                    height: 60,
                    width: 60,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'emptyCollection'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'emptyNotesDescription'.tr,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesList() {
    return RefreshIndicator(
      onRefresh: () async => await controller.fetchBookNotes(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.notes.length,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) =>
            _buildNoteItem(controller.notes[index]),
      ),
    );
  }

  Widget _buildNoteItem(NoteItem note) {
    return Obx(() {
      final isSelected = controller.selectedNotes.contains(note.id);
      return NoteCard(
        note: note,
        isSelectionMode: controller.isSelectionMode.value,
        isSelected: isSelected,
        baseUrl: widget.baseUrl,
        onTap: () {
          if (controller.isSelectionMode.value) {
            controller.toggleNoteSelection(note.id);
          }
        },
        onLongPress: () {
          if (!controller.isSelectionMode.value) {
            controller.isSelectionMode.value = true;
            controller.toggleNoteSelection(note.id);
          }
        },
        onEdit: () => _showEditBottomSheet(context, note, controller),
        onDelete: () => controller.deleteNote(note.id),
        onBookTap: () => _navigateToBookDetail(note.bookId),
        onShare: () => _shareNote(context, note),
      );
    });
  }

  void _navigateToBookDetail(int bookId) {
    Get.to(() => BookDetailView(bookId: bookId, book: null));
  }

  void _shareNote(BuildContext context, NoteItem note) {
    final text = """
${note.bookName}

"${note.quote}"
Shared from ElKitap
""";

    final box = context.findRenderObject() as RenderBox?;
    final rect = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 0, 0);

    Share.share(text, sharePositionOrigin: rect);
  }

  void _showEditBottomSheet(
      BuildContext context, NoteItem note, NotesController controller) {
    final snippetController = TextEditingController(text: note.snippet);
    final noteController = TextEditingController(text: note.note);
    final selectedColor = note.color.obs;
    final hasChanges = false.obs;

    void checkForChanges() {
      hasChanges.value = snippetController.text != note.snippet ||
          noteController.text != note.note ||
          selectedColor.value != note.color;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEditBottomSheetContent(
        context,
        note,
        snippetController,
        noteController,
        selectedColor,
        hasChanges,
        checkForChanges,
      ),
    );
  }

  Widget _buildEditBottomSheetContent(
    BuildContext context,
    NoteItem note,
    TextEditingController snippetController,
    TextEditingController noteController,
    Rx<Color> selectedColor,
    RxBool hasChanges,
    VoidCallback checkForChanges,
  ) {
    return Obx(() => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildEditHeader(context, note, snippetController, noteController,
                  selectedColor),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildEditTextField(snippetController,
                        noteController, selectedColor, checkForChanges),
                  ),
                ),
              ),
              _buildColorPicker(selectedColor, checkForChanges),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 15),
            ],
          ),
        ));
  }

  Widget _buildEditHeader(
    BuildContext context,
    NoteItem note,
    TextEditingController snippetController,
    TextEditingController noteController,
    Rx<Color> selectedColor,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'notes'.tr,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          _buildDoneButton(
              context, note, snippetController, noteController, selectedColor),
        ],
      ),
    );
  }

  Widget _buildDoneButton(
    BuildContext context,
    NoteItem note,
    TextEditingController snippetController,
    TextEditingController noteController,
    Rx<Color> selectedColor,
  ) {
    return Obx(() {
      return TextButton(
        onPressed: controller.isUpdating.value
            ? null
            : () => _handleNoteSave(context, note, snippetController,
                noteController, selectedColor),
        child: controller.isUpdating.value
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              )
            : Text(
                'done'.tr,
                style: TextStyle(
                  fontSize: 17,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontFamily: StringConstants.SFPro,
                  fontWeight: FontWeight.w600,
                ),
              ),
      );
    });
  }

  Future<void> _handleNoteSave(
    BuildContext context,
    NoteItem note,
    TextEditingController snippetController,
    TextEditingController noteController,
    Rx<Color> selectedColor,
  ) async {
    controller.updateNoteColor(note.id, selectedColor.value);

    final currentSnippet = snippetController.text;
    final currentNote = noteController.text;

    if (currentSnippet != note.snippet || currentNote != note.note) {
      final result = await controller.updateNote(
        noteId: note.id,
        note: currentNote,
        snippet: currentSnippet,
      );

      if (result['success']) {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildEditTextField(
    TextEditingController snippetController,
    TextEditingController noteController,
    Rx<Color> selectedColor,
    VoidCallback checkForChanges,
  ) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: selectedColor.value,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: snippetController,
                  maxLines: null,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'snippet'.tr,
                  ),
                  style: const TextStyle(fontSize: 17),
                  onChanged: (_) => checkForChanges(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: TextField(
            controller: noteController,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'add_note'.tr,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(fontSize: 17),
            onChanged: (_) => checkForChanges(),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker(
      Rx<Color> selectedColor, VoidCallback checkForChanges) {
    final colors = [
      Colors.grey,
      Colors.red,
      Colors.amber,
      Colors.brown,
      Colors.purple,
      Colors.green,
      Colors.blue,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: colors
            .map((color) =>
                _buildColorButton(color, selectedColor.value, (newColor) {
                  selectedColor.value = newColor;
                  checkForChanges();
                }))
            .toList(),
      ),
    );
  }

  Widget _buildColorButton(
      Color color, Color selectedColor, Function(Color) onTap) {
    final isSelected = color == selectedColor;
    return GestureDetector(
      onTap: () => onTap(color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
        ),
      ),
    );
  }
}
