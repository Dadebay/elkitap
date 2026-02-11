import 'package:elkitap/data/network/api_edpoints.dart';

class ProfessionalRead {
  final int id;
  final String image;
  final String name;
  final String position;
  final String description;
  final dynamic professionalReadBooks;

  ProfessionalRead({
    required this.id,
    required this.image,
    required this.name,
    required this.position,
    required this.description,
    this.professionalReadBooks,
  });

  factory ProfessionalRead.fromJson(Map<String, dynamic> json) {
    return ProfessionalRead(
      id: json['id'] ?? 0,
      image: json['image'] ?? '',
      name: json['name'] ?? '',
      position: json['position'] ?? '',
      description: json['description'] ?? '',
      professionalReadBooks: json['professional_read_books'],
    );
  }

  // Get full image URL
  String get fullImageUrl {
    if (image.isEmpty) return '';
    return '${ApiEndpoints.imageBaseUrl}$image';
  }
}