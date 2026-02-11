class BookDetailsEntity {
  final int id;
  final String name;
  final String slug;
  final int totalPages;
  final BookImage image;
  final String electronic;

  BookDetailsEntity({
    required this.id,
    required this.name,
    required this.slug,
    required this.totalPages,
    required this.image,
    required this.electronic,
  });
}


class BookImage {
  final String url;

  BookImage({required this.url});
}