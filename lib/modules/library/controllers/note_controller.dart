// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:elkitap/core/constants/string_constants.dart';
import 'package:elkitap/core/widgets/common/app_snackbar.dart';
import 'package:elkitap/data/network/network_manager.dart';
import 'package:elkitap/modules/library/model/note_item_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotesController extends GetxController {
  final NetworkManager _networkManager = Get.find<NetworkManager>();
  var notes = <NoteItem>[].obs;
  var isSelectionMode = false.obs;
  var selectedNotes = <int>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isUpdating = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt totalCount = 0.obs;

  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  String? currentBookId;

  @override
  void onInit() {
    super.onInit();
    fetchBookNotes();
  }

  void setCurrentBook(String bookId) {
    currentBookId = bookId;
    fetchBookNotes();
  }

  Future<void> fetchBookNotes() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _networkManager.get(
        '/users/notes',
        sendToken: true,
      );

      isLoading.value = false;

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> apiNotes = response['data'] as List? ?? [];

        notes.value = apiNotes.asMap().entries.map((entry) {
          return NoteItem.fromJson(entry.value, _getColorByIndex(entry.key));
        }).toList();

        totalCount.value = notes.length;
      } else {
        errorMessage.value = response['error'] ?? 'failed_to_fetch_notes'.tr;
        notes.clear();
      }
    } on SocketException {
      isLoading.value = false;

      errorMessage.value = 'network_error_check_connection'.tr;
    } catch (e) {
      isLoading.value = false;

      errorMessage.value = 'error_fetching_notes'.trParams({'error': e.toString()});
    }
  }

  Future<Map<String, dynamic>> addNote({
    required String bookId,
    required String note,
    String? snippet,
    String? bookTitle,
    String? bookAuthor,
  }) async {
    int attempts = 0;
    isSaving.value = true;
    errorMessage.value = '';

    while (attempts < maxRetries) {
      attempts++;

      try {
        final response = await _networkManager
            .post(
          '/users/notes',
          body: {
            'book_id': int.parse(bookId),
            'note': note,
            'snippet': snippet ?? note,
          },
          sendToken: true,
        )
            .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            return {
              'success': false,
              'statusCode': 408,
              'error': 'request_timeout'.tr,
              'data': null,
            };
          },
        );

        final isSuccess = response['success'] == true || (response['statusCode'] != null && response['statusCode'] >= 200 && response['statusCode'] < 300);

        if (isSuccess) {
          isSaving.value = false;

          if (response['data'] != null) {
            final noteData = response['data'];
            final newNote = NoteItem.fromJson(noteData, _getColorByIndex(notes.length));
            notes.insert(0, newNote);
            totalCount.value = notes.length;
          }

          return {
            'success': true,
            'message': response['message'] ?? 'note_saved_successfully'.tr,
            'data': response['data'],
          };
        } else {
          final statusCode = response['statusCode'];
          if (statusCode != null && statusCode >= 400 && statusCode < 500) {
            isSaving.value = false;
            errorMessage.value = response['error'] ?? 'failed_to_save_note'.tr;
            return {
              'success': false,
              'message': response['error'] ?? 'failed_to_save_note'.tr,
            };
          }

          if (attempts < maxRetries) {
            await Future.delayed(retryDelay);
            continue;
          }

          isSaving.value = false;
          errorMessage.value = response['error'] ?? 'failed_to_save_note'.tr;
          return {
            'success': false,
            'message': response['error'] ?? 'failed_to_save_note'.tr,
          };
        }
      } on SocketException {
        if (attempts < maxRetries) {
          await Future.delayed(retryDelay);
          continue;
        }

        isSaving.value = false;
        'network_error_check_connection'.tr;
        return {
          'success': false,
          'message': 'network_error_check_connection'.tr,
        };
      } catch (e) {
        if (attempts < maxRetries) {
          await Future.delayed(retryDelay);
          continue;
        }

        isSaving.value = false;
        errorMessage.value = 'error_saving_note'.trParams({'error': e.toString()});
        return {
          'success': false,
          'message': 'Error saving note: ${e.toString()}',
        };
      }
    }

    isSaving.value = false;
    errorMessage.value = 'failed_to_save_note_attempts'.trParams({'attempts': maxRetries.toString()});
    return {
      'success': false,
      'message': 'failed_to_save_note_attempts'.trParams({'attempts': maxRetries.toString()}),
    };
  }

  Future<Map<String, dynamic>> updateNote({
    required int noteId,
    required String note,
    required String snippet,
  }) async {
    try {
      isUpdating.value = true;
      errorMessage.value = '';

      final response = await _networkManager
          .patch(
        '/users/notes/$noteId',
        body: {
          'note': note,
          'snippet': snippet,
        },
        sendToken: true,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          return {
            'success': false,
            'statusCode': 408,
            'error': 'request_timeout'.tr,
            'data': null,
          };
        },
      );

      final isSuccess = response['success'] == true || (response['statusCode'] != null && response['statusCode'] >= 200 && response['statusCode'] < 300);

      if (isSuccess) {
        final index = notes.indexWhere((n) => n.id == noteId);
        if (index != -1 && response['data'] != null) {
          final updatedNoteData = response['data'];
          final updatedNote = NoteItem.fromJson(
            updatedNoteData,
            notes[index].color,
          );
          notes[index] = updatedNote;
          notes.refresh();
        }

        isUpdating.value = false;

        AppSnackbar.success('note_updated_successfully'.tr);

        return {
          'success': true,
          'message': response['message'] ?? 'note_updated_successfully'.tr,
          'data': response['data'],
        };
      } else {
        isUpdating.value = false;
        errorMessage.value = response['error'] ?? 'failed_to_update_note'.tr;

        AppSnackbar.error(response['error'] ?? 'failed_to_update_note'.tr);

        return {
          'success': false,
          'message': response['error'] ?? 'failed_to_update_note'.tr,
        };
      }
    } on SocketException {
      isUpdating.value = false;

      'network_error_check_connection'.tr;

      AppSnackbar.error('network_error_check_connection'.tr);

      return {
        'success': false,
        'message': 'network_error_check_connection'.tr,
      };
    } catch (e) {
      isUpdating.value = false;
      errorMessage.value = 'error_updating_note'.trParams({'error': e.toString()});

      AppSnackbar.error('error_updating_note'.trParams({'error': e.toString()}));

      return {
        'success': false,
        'message': 'error_updating_note'.trParams({'error': e.toString()}),
      };
    }
  }

  Future<void> deleteNote(int noteId) async {
    try {
      final response = await _networkManager.delete(
        '/users/notes/$noteId',
        sendToken: true,
      );

      if (response['success'] == true) {
        notes.removeWhere((note) => note.id == noteId);
        totalCount.value = notes.length;

        AppSnackbar.success('note_deleted_successfully'.tr);
      } else {
        AppSnackbar.error(response['error'] ?? 'failed_to_delete_note'.tr);
      }
    } catch (e) {
      AppSnackbar.error('error_deleting_note'.trParams({'error': e.toString()}));
    }
  }

  Future<void> deleteSelectedNotes() async {
    if (selectedNotes.isEmpty) return;

    try {
      int successCount = 0;
      int failCount = 0;

      for (var noteId in selectedNotes) {
        final response = await _networkManager.delete(
          '/users/notes/$noteId',
          sendToken: true,
        );

        if (response['success'] == true) {
          successCount++;
          notes.removeWhere((note) => note.id == noteId);
        } else {
          failCount++;
        }
      }

      selectedNotes.clear();
      isSelectionMode.value = false;
      totalCount.value = notes.length;

      if (failCount == 0) {
        AppSnackbar.success('notes_deleted_count'.trParams({'count': successCount.toString()}));
      } else {
        AppSnackbar.warning('notes_deletion_partial_success'.trParams({'successCount': successCount.toString(), 'failCount': failCount.toString()}));
      }
    } catch (e) {
      AppSnackbar.error('error_deleting_notes'.trParams({'error': e.toString()}));
    }
  }

  void toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
      selectedNotes.clear();
    }
  }

  void selectAll() {
    selectedNotes.clear();
    for (var note in notes) {
      selectedNotes.add(note.id);
    }
  }

  void toggleNoteSelection(int id) {
    if (selectedNotes.contains(id)) {
      selectedNotes.remove(id);
    } else {
      selectedNotes.add(id);
    }
    if (selectedNotes.isEmpty && isSelectionMode.value) {
      isSelectionMode.value = false;
    }
  }

  void updateNoteColor(int id, Color color) {
    final index = notes.indexWhere((note) => note.id == id);
    if (index != -1) {
      notes[index] = notes[index].copyWith(color: color);
      notes.refresh();
    }
  }

  bool get isAllSelected => notes.isNotEmpty && selectedNotes.length == notes.length;

  void toggleSelectAll() {
    if (isAllSelected) {
      selectedNotes.clear();
    } else {
      selectAll();
    }
  }

  void showCupertinoMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'remove_this_note_question'.tr,
            style: TextStyle(
              fontSize: 17,
              fontFamily: StringConstants.GilroySemiBold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              deleteSelectedNotes();
            },
            isDestructiveAction: true,
            child: Text(
              'remove'.tr,
              style: TextStyle(fontWeight: FontWeight.w600, fontFamily: StringConstants.GilroyRegular, color: Colors.red),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'cancel'.tr,
            style: TextStyle(fontWeight: FontWeight.w600, fontFamily: StringConstants.GilroyRegular, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Color _getColorByIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.yellow,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  void clearNotes() {
    notes.clear();
    selectedNotes.clear();
    isSelectionMode.value = false;
    errorMessage.value = '';
  }

  @override
  void onClose() {
    clearNotes();
    super.onClose();
  }
}
