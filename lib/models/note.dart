class Note {
  final String id;
  final String? title;
  final String content;
  final String? plainText;
  final String? imagePaths;
  final int createdAt;
  final int updatedAt;

  Note({
    required this.id,
    this.title,
    required this.content,
    this.plainText,
    this.imagePaths,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String?,
      content: map['content'] as String,
      plainText: map['plain_text'] as String?,
      imagePaths: map['image_paths'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'plain_text': plainText,
      'image_paths': imagePaths,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? plainText,
    String? imagePaths,
    int? createdAt,
    int? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      plainText: plainText ?? this.plainText,
      imagePaths: imagePaths ?? this.imagePaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
