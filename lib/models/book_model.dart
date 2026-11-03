class BookModel {
  final int? id;
  final String title;
  final String author;
  final String category;
  final String description;
  final int isAvailable; // 1 = Available, 0 = Borrowed

  BookModel({
    this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.description,
    this.isAvailable = 1,
  });

  // Convert BookModel to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'category': category,
      'description': description,
      'is_available': isAvailable,
    };
  }

  // Create BookModel from SQLite Map
  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map['id'],
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      isAvailable: map['is_available'] ?? 1,
    );
  }
}

