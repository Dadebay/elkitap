import 'dart:ui';
import 'package:get/get.dart';

class NoteItem {
  final int id;
  final String createdAt;
  final String noteUpdatedAt;
  final int noteUserId;
  final int noteBookId;
  final String note;
  final String snippet;
  final int bookId;
  final String? bookImage;
  final String bookName;
  final String? bookAuthor;
  final Color color;

  NoteItem({
    required this.id,
    required this.createdAt,
    required this.noteUpdatedAt,
    required this.noteUserId,
    required this.noteBookId,
    required this.note,
    required this.snippet,
    required this.bookId,
    this.bookImage,
    required this.bookName,
    this.bookAuthor,
    required this.color,
  });

  /// Factory constructor to create NoteItem from API response
  factory NoteItem.fromJson(Map<String, dynamic> json, Color color) {
    return NoteItem(
      id: json['id'] ?? 0,
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      noteUpdatedAt:
          json['note_updated_at'] ?? DateTime.now().toIso8601String(),
      noteUserId: json['note_user_id'] ?? 0,
      noteBookId: json['note_book_id'] ?? 0,
      note: json['note'] ?? '',
      snippet: json['snippet'] ?? '',
      bookId: json['book_id'] ?? 0,
      bookImage: json['book_image'],
      bookName: json['book_name'] ?? 'unknown_book'.tr,
      bookAuthor: json['book_author'],
      color: color,
    );
  }

  /// Convert NoteItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt,
      'note_updated_at': noteUpdatedAt,
      'note_user_id': noteUserId,
      'note_book_id': noteBookId,
      'note': note,
      'snippet': snippet,
      'book_id': bookId,
      'book_image': bookImage,
      'book_name': bookName,
      'book_author': bookAuthor,
    };
  }

  /// Create a copy of NoteItem with updated fields
  NoteItem copyWith({
    int? id,
    String? createdAt,
    String? noteUpdatedAt,
    int? noteUserId,
    int? noteBookId,
    String? note,
    String? snippet,
    int? bookId,
    String? bookImage,
    String? bookName,
    String? bookAuthor,
    Color? color,
  }) {
    return NoteItem(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      noteUpdatedAt: noteUpdatedAt ?? this.noteUpdatedAt,
      noteUserId: noteUserId ?? this.noteUserId,
      noteBookId: noteBookId ?? this.noteBookId,
      note: note ?? this.note,
      snippet: snippet ?? this.snippet,
      bookId: bookId ?? this.bookId,
      bookImage: bookImage ?? this.bookImage,
      bookName: bookName ?? this.bookName,
      bookAuthor: bookAuthor ?? this.bookAuthor,
      color: color ?? this.color,
    );
  }

  // Convenience getters for backward compatibility with UI code
  String get title => bookName;
  String get author => bookAuthor ?? 'unknown_author'.tr;
  String get quote => snippet;
  String get comment => note;
  String get date => _formatDate(createdAt);

  /// Format date for display
  String _formatDate(String dateString) {
    try {
      final DateTime parsedDate = DateTime.parse(dateString);
      return '${parsedDate.hour}:${parsedDate.minute.toString().padLeft(2, '0')} ${_getMonthName(parsedDate.month)} ${parsedDate.day}, ${parsedDate.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// Get month name
  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
