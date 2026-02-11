import 'package:elkitap/modules/search/models/authors_model.dart';

class BookDetail {
  final int id;
  final String? image;
  final String? audioImage;
  final bool withAudio;
  final int? age;
  final int? year;
  final String? progress;
  final int? likedBookId;
  final String? wantsTo;
  final int? wantsToListenBookId;
  final int? wantsToReadBookId;
  final int? wantsToFinishedBookId;
  final String name;
  final List<GenreBook> genres;
  final List<Author> authors;
  final List<Translate> translates;

  BookDetail({
    required this.id,
    this.image,
    this.audioImage,
    this.withAudio = false,
    this.age,
    this.year,
    this.progress,
    this.likedBookId,
    this.wantsTo,
    this.wantsToListenBookId,
    this.wantsToReadBookId,
    this.wantsToFinishedBookId,
    required this.name,
    required this.genres,
    required this.authors,
    required this.translates,
  });

  factory BookDetail.fromJson(Map<String, dynamic> json) {
    return BookDetail(
      id: json['id'] ?? 0,
      image: json['image'],
      audioImage: json['audio_image'],
      withAudio: json['with_audio'] ?? false,
      age: json['age'],
      year: json['year'],
      progress: json['progress'],
      likedBookId: json['liked_book_id'],
      wantsTo: json['wants_to'],
      wantsToListenBookId: json['wants_to_listen_book_id'],
      wantsToReadBookId: json['wants_to_read_book_id'],
      wantsToFinishedBookId: json['wants_to_finished_book_id'],
      name: json['name'] ?? '',
      genres: (json['genres'] as List<dynamic>?)
              ?.map((genre) => GenreBook.fromJson(genre))
              .toList() ??
          [],
      authors: (json['authors'] as List<dynamic>?)
              ?.map((author) => Author.fromJson(author))
              .toList() ??
          [],
      translates: json['translates'] != null
          ? List<dynamic>.from(json['translates'])
              .map((translate) => Translate.fromJson(translate))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'audio_image': audioImage,
      'with_audio': withAudio,
      'age': age,
      'year': year,
      'progress': progress,
      'liked_book_id': likedBookId,
      'wants_to': wantsTo,
      'wants_to_listen_book_id': wantsToListenBookId,
      'wants_to_read_book_id': wantsToReadBookId,
      'wants_to_finished_book_id': wantsToFinishedBookId,
      'name': name,
      'genres': genres.map((genre) => genre.toJson()).toList(),
      'authors': authors.map((author) => author.toJson()).toList(),
      'translates': translates.map((translate) => translate.toJson()).toList(),
    };
  }
}

// Genre Model
class GenreBook {
  final int id;
  final String name;

  GenreBook({
    required this.id,
    required this.name,
  });

  factory GenreBook.fromJson(Map<String, dynamic> json) {
    return GenreBook(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

// Translate Model
class Translate {
  final int id;
  final String name;
  final String? description;
  final String? image;
  final int bookId;
  final String? bookKey;
  final String language;
  final String? aiDescription;
  final String? audioImage;

  Translate({
    required this.id,
    required this.name,
    this.description,
    this.image,
    required this.bookId,
    this.bookKey,
    required this.language,
    this.aiDescription,
    this.audioImage,
  });

  factory Translate.fromJson(Map<String, dynamic> json) {
    return Translate(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      image: json['image'],
      bookId: json['book_id'] ?? 0,
      bookKey: json['book_key'],
      language: json['language'] ?? '',
      aiDescription: json['ai_description'],
      audioImage: json['audio_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'book_id': bookId,
      'book_key': bookKey,
      'language': language,
      'ai_description': aiDescription,
      'audio_image': audioImage,
    };
  }
}
