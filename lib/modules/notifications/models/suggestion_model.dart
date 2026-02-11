enum SuggestionStatus {
  NEW,
  ACCEPTED,
  PROCESSING,
  COMPLETED,
  REJECTED;

  String get value {
    switch (this) {
      case SuggestionStatus.NEW:
        return "new";
      case SuggestionStatus.ACCEPTED:
        return 'accepted';
      case SuggestionStatus.PROCESSING:
        return "processing";
      case SuggestionStatus.COMPLETED:
        return "completed";
      case SuggestionStatus.REJECTED:
        return "rejected";
    }
  }

  static SuggestionStatus fromString(String status) {
    switch (status) {
      case 'new':
        return SuggestionStatus.NEW;
      case 'accepted':
        return SuggestionStatus.ACCEPTED;
      case 'processing':
        return SuggestionStatus.PROCESSING;
      case 'completed':
        return SuggestionStatus.COMPLETED;
      case 'rejected':
        return SuggestionStatus.REJECTED;
      default:
        return SuggestionStatus.NEW;
    }
  }
}

class SuggestionModel {
  final int id;
  final String name;
  final String author;
  final String description;
  final String language;
  final SuggestionStatus status;
  final String? rejectedReason;
  final String createdAt;
  final String updatedAt;
  final int? bookId;
  final Map<String, dynamic>? book;

  SuggestionModel({
    required this.id,
    required this.name,
    required this.author,
    required this.description,
    required this.language,
    required this.status,
    this.rejectedReason,
    required this.createdAt,
    required this.updatedAt,
    this.bookId,
    this.book,
  });

  factory SuggestionModel.fromJson(Map<String, dynamic> json) {
    return SuggestionModel(
      id: json['id'],
      name: json['name'] ?? '',
      author: json['author'] ?? '',
      description: json['description'] ?? '',
      language: json['language'] ?? '',
      status: SuggestionStatus.fromString(json['status'] ?? 'new'),
      rejectedReason: json['rejected_reason'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? json['created_at'] ?? '',
      bookId: json['book_id'],
      book: json['book'],
    );
  }

  String getBookName(String languageCode) {
    if (book != null && book!['name'] != null) {
      final bookName = book!['name'];
      if (bookName is Map) {
        return bookName[languageCode] ?? bookName['tk'] ?? bookName['en'] ?? name;
      }
    }
    return name;
  }
}
