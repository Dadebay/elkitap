// book_download_model.dart
class BookDownload {
  final String id;
  final String title;
  final String author;
  final String fileName;
  final String? coverUrl;
  final DateTime downloadDate;
  final int fileSize;
  final String hash;
  final String encryptedPath;
  final bool isAudio;
  final String? hlsUrl;

  BookDownload({
    required this.id,
    required this.title,
    required this.author,
    required this.fileName,
    this.coverUrl,
    required this.downloadDate,
    required this.fileSize,
    required this.hash,
    required this.encryptedPath,
    this.isAudio = false,
    this.hlsUrl,
  });

  bool get isAudioBook => isAudio;
  bool get isTextBook => !isAudio;

  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(2)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  String get fileType => isAudio ? 'Audio' : 'Text';

  BookDownload copyWith({
    String? id,
    String? title,
    String? author,
    String? fileName,
    String? coverUrl,
    DateTime? downloadDate,
    int? fileSize,
    String? hash,
    String? encryptedPath,
    bool? isAudio,
    String? hlsUrl,
  }) {
    return BookDownload(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      fileName: fileName ?? this.fileName,
      coverUrl: coverUrl ?? this.coverUrl,
      downloadDate: downloadDate ?? this.downloadDate,
      fileSize: fileSize ?? this.fileSize,
      hash: hash ?? this.hash,
      encryptedPath: encryptedPath ?? this.encryptedPath,
      isAudio: isAudio ?? this.isAudio,
      hlsUrl: hlsUrl ?? this.hlsUrl,
    );
  }

  @override
  String toString() {
    return 'BookDownload(id: $id, title: $title, author: $author, isAudio: $isAudio, fileSize: $formattedFileSize)';
  }

  // JSON serialization for GetStorage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'fileName': fileName,
      'coverUrl': coverUrl,
      'downloadDate': downloadDate.toIso8601String(),
      'fileSize': fileSize,
      'hash': hash,
      'encryptedPath': encryptedPath,
      'isAudio': isAudio,
      'hlsUrl': hlsUrl,
    };
  }

  factory BookDownload.fromJson(Map<String, dynamic> json) {
    return BookDownload(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      fileName: json['fileName'] as String,
      coverUrl: json['coverUrl'] as String?,
      downloadDate: DateTime.parse(json['downloadDate'] as String),
      fileSize: json['fileSize'] as int,
      hash: json['hash'] as String,
      encryptedPath: json['encryptedPath'] as String,
      isAudio: json['isAudio'] as bool? ?? false,
      hlsUrl: json['hlsUrl'] as String?,
    );
  }
}
