class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type; // 'content_added', 'content_declined'
  final int? bookId;
  final String? bookTitle;
  final String? authorName;
  final String timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.bookId,
    this.bookTitle,
    this.authorName,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'content_added',
      bookId: json['book_id'],
      bookTitle: json['book_title'],
      authorName: json['author_name'],
      timestamp: json['timestamp'] ?? '',
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'book_id': bookId,
      'book_title': bookTitle,
      'author_name': authorName,
      'timestamp': timestamp,
      'is_read': isRead,
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      bookId: bookId,
      bookTitle: bookTitle,
      authorName: authorName,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
