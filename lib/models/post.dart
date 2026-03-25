class Post {
  final int? id;
  final String title;
  final String content;
  final String author;
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
  })  : assert(title.isNotEmpty, 'Title cannot be empty'),
        assert(content.isNotEmpty, 'Content cannot be empty'),
        assert(author.isNotEmpty, 'Author cannot be empty');

  // FIX: Only include 'id' in the map if it's not null.
  // Passing null id to SQLite can interfere with AUTOINCREMENT on insert.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'content': content,
      'author': author,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  // FIX: Added null-safe casting on all fields to prevent runtime crashes
  // if a DB row is missing a field due to corruption or a schema change.
  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      author: map['author'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Post copyWith({
    int? id,
    String? title,
    String? content,
    String? author,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}