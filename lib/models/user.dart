class User {
  final String id;
  final String username;
  final String? nickname;
  final String? avatar;
  final int createdAt;

  User({
    required this.id,
    required this.username,
    this.nickname,
    this.avatar,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      username: map['username'] as String,
      nickname: map['nickname'] as String?,
      avatar: map['avatar'] as String?,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'avatar': avatar,
      'created_at': createdAt,
    };
  }
}
