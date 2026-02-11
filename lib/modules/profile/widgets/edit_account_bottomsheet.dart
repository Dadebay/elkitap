import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/modules/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditAccountBottomSheet extends StatefulWidget {
  const EditAccountBottomSheet({super.key});

  @override
  State<EditAccountBottomSheet> createState() => _EditAccountBottomSheetState();
}

class _EditAccountBottomSheetState extends State<EditAccountBottomSheet> {
  final AuthController _authController = Get.find<AuthController>();
  late TextEditingController _nameController;
  late String _phoneNumber;
  late String _initialUsername;

  late FocusNode _nameFocusNode;
  bool _isSaveButtonActive = false;

  @override
  void initState() {
    super.initState();

    final user = _authController.currentUser.value;
    _initialUsername = user?.username ?? '';
    _phoneNumber = user?.phone ?? '';

    _nameController = TextEditingController(text: _initialUsername);
    _nameFocusNode = FocusNode();
    _nameFocusNode.addListener(_updateSaveButtonState);
    _nameController.addListener(_updateSaveButtonState);
    _updateSaveButtonState();
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_updateSaveButtonState);
    _nameFocusNode.dispose();
    _nameController.removeListener(_updateSaveButtonState);
    _nameController.dispose();
    super.dispose();
  }

  void _updateSaveButtonState() {
    final bool hasText = _nameController.text.isNotEmpty;
    final bool hasChanged = _nameController.text != _initialUsername;
    final bool newIsActive = hasText && hasChanged;

    if (_isSaveButtonActive != newIsActive) {
      setState(() {
        _isSaveButtonActive = newIsActive;
      });
    }
  }

  Future<void> _saveUsername() async {
    if (!_isSaveButtonActive) return;

    FocusScope.of(context).unfocus();

    final success = await _authController.updateUsername(_nameController.text);

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    final Color activeSaveButtonColor = Colors.deepOrange;
    final Color inactiveSaveButtonColor = Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[200]!;

    final Color activeSaveButtonTextColor = Colors.white;
    final Color inactiveSaveButtonTextColor = Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.5) : Colors.grey[500]!;

    return Padding(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  'edit_account'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: StringConstants.SFPro,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset('assets/images/a2.png'),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'account'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: StringConstants.SFPro,
                            color: Theme.of(context).textTheme.bodySmall!.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _phoneNumber,
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: StringConstants.SFPro,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "name".tr,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: StringConstants.SFPro,
                      color: Theme.of(context).textTheme.bodySmall!.color,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Obx(() => GestureDetector(
                      onTap: _authController.isLoading.value ? null : _saveUsername,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _isSaveButtonActive && !_authController.isLoading.value ? activeSaveButtonColor : inactiveSaveButtonColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: _authController.isLoading.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'save'.tr,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: StringConstants.SFPro,
                                    color: _isSaveButtonActive ? activeSaveButtonTextColor : inactiveSaveButtonTextColor,
                                  ),
                                ),
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ));
  }
}
