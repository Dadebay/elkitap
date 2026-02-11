class Author {
  final int id;
  final String name;
  final String? image;
  final String? bio;
  final String bookCount;

  Author({
    required this.id,
    required this.name,
    this.image,
    this.bio,
    required this.bookCount,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'],
      name: json['name'] ?? '',
      image: json['image'],
      bio: json['bio'],
      bookCount: json['book_count'] ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'bio': bio,
      'book_count': bookCount,
    };
  }

  // Helper method to get full image URL
  String? getFullImageUrl(String baseUrl) {
    if (image == null || image!.isEmpty) return null;
    if (image!.startsWith('http')) return image;
    return '$baseUrl$image';
  }
}

