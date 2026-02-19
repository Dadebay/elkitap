import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bottom sheet for adding notes with color selection - iOS style
class AddNoteSheet extends StatefulWidget {
  final String selectedText;
  final Future<void> Function(String note, Color color) onSave;

  const AddNoteSheet({
    Key? key,
    required this.selectedText,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();

  static Future<void> show(
    BuildContext context, {
    required String selectedText,
    required Future<void> Function(String note, Color color) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: false,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => AddNoteSheet(
        selectedText: selectedText,
        onSave: onSave,
      ),
    );
  }
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Color _selectedColor = const Color(0xFF9E9E9E); // Grey default

  final List<Color> _colors = [
    const Color(0xFF9E9E9E), // Grey
    const Color(0xFFFF3B30), // Red
    const Color(0xFFFFCC00), // Yellow
    const Color(0xFFA2845E), // Brown
    const Color(0xFFAF52DE), // Purple
    const Color(0xFF34C759), // Green
    const Color(0xFF007AFF), // Blue
  ];

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field when sheet opens
    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleDone() async {
    final note = _noteController.text.trim();
    await widget.onSave(note, _selectedColor);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final sheetBackground = colorScheme.surface;
    final primaryText = colorScheme.onSurface;
    final secondaryText = colorScheme.onSurface.withOpacity(0.72);
    final dividerColor = colorScheme.outline.withOpacity(isDark ? 0.5 : 0.35);
    final actionColor = colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: sheetBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Note title and Done button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: dividerColor,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'add_note'.tr,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: primaryText,
                      ),
                    ),
                    GestureDetector(
                      onTap: _handleDone,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text(
                          'done'.tr,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: actionColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content area
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selected text with left border
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(left: 16, right: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: _selectedColor,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Text(
                            widget.selectedText,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: secondaryText,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Note input field
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(left: 24),
                          child: TextField(
                            controller: _noteController,
                            focusNode: _focusNode,
                            maxLines: 4,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color: primaryText,
                            ),
                            decoration: InputDecoration(
                              hintText: 'add_note'.tr,
                              hintStyle: TextStyle(
                                fontSize: 16,
                                color: secondaryText,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _colors.map((color) {
                            final isSelected = _selectedColor == color;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedColor = color;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        size: 20,
                                        color: isDark ? Colors.white : Colors.black,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
