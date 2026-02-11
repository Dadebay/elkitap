import 'dart:ui';
import 'package:get/get.dart';

class BookItem {
  final String title;
  final String author;
  final Color color;
  final int? discountPercentage;

  BookItem({
    required this.title,
    required this.author,
    required this.color,
    this.discountPercentage,
  });
}

class BookCollection {
  final int id;
  final String name;
  final List<Book> books;

  BookCollection({required this.id, required this.name, required this.books});

  factory BookCollection.fromJson(Map<String, dynamic> json) {
    return BookCollection(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      books: (json['books'] as List<dynamic>?)
              ?.map((e) => Book.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class BookAuthor {
  final int id;
  final String name;
  final String? image;

  BookAuthor({
    required this.id,
    required this.name,
    this.image,
  });

  factory BookAuthor.fromJson(Map<String, dynamic> json) {
    return BookAuthor(
      id: json['id'],
      name: json['name'] ?? '',
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
    };
  }

  // Helper method to get full image URL
  String? getFullImageUrl(String baseUrl) {
    if (image == null || image!.isEmpty) return null;
    if (image!.startsWith('http')) return image;
    return '$baseUrl$image';
  }
}

// Book Model
class Book {
  final int id;
  final String name;
  final String? image;
  final String? audioImage;
  final bool withAudio;
  final String? progress;
  final int? age;
  final int? year;
  final int? likedBookId;
  final List<BookAuthor> authors;

  Book({
    required this.id,
    required this.name,
    this.image,
    this.audioImage,
    this.withAudio = false,
    this.age,
    this.year,
    this.progress,
    this.likedBookId,
    required this.authors,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      name: json['name'] ?? '',
      image: json['image'],
      audioImage: json['audio_image'],
      withAudio: json['with_audio'] ?? false,
      age: json['age'],
      year: json['year'],
      progress: json['progress'],
      likedBookId: json['liked_book_id'],
      authors: (json['authors'] as List<dynamic>?)
              ?.map((author) => BookAuthor.fromJson(author))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'audio_image': audioImage,
      'with_audio': withAudio,
      'age': age,
      'year': year,
       'progress': progress,
      'liked_book_id': likedBookId,
      'authors': authors.map((author) => author.toJson()).toList(),
    };
  }

  // Helper method to get full image URL
  String? getFullImageUrl(String baseUrl) {
    if (image == null || image!.isEmpty) return null;
    if (image!.startsWith('http')) return image;
    return '$baseUrl$image';
  }

  // Get formatted authors string (comma-separated names)
  String getAuthorsString() {
    if (authors.isEmpty) return 'unknown_author'.tr;
    return authors.map((author) => author.name).join(', ');
  }

  // Get first author
  BookAuthor? get firstAuthor => authors.isNotEmpty ? authors.first : null;
}
