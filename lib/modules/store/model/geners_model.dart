class Genre {
  final int id;
  final int? parentId;
  final int? position;
  final String createdAt;
  final String updatedAt;
  final String name;

  Genre({
    required this.id,
    this.parentId,
    this.position,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'],
      parentId: json['parent_id'],
      position: json['position'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'position': position,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'name': name,
    };
  }
}