class CloudBackup {
  final String id;
  final String userId;
  final String? backupJson;
  final int noteCount;
  final int todoCount;
  final int habitCount;
  final String? deviceInfo;
  final int createdAt;

  CloudBackup({
    required this.id,
    required this.userId,
    this.backupJson,
    this.noteCount = 0,
    this.todoCount = 0,
    this.habitCount = 0,
    this.deviceInfo,
    required this.createdAt,
  });

  factory CloudBackup.fromMap(Map<String, dynamic> map) {
    return CloudBackup(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      backupJson: map['backup_json'] as String?,
      noteCount: map['note_count'] as int? ?? 0,
      todoCount: map['todo_count'] as int? ?? 0,
      habitCount: map['habit_count'] as int? ?? 0,
      deviceInfo: map['device_info'] as String?,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'backup_json': backupJson,
      'note_count': noteCount,
      'todo_count': todoCount,
      'habit_count': habitCount,
      'device_info': deviceInfo,
      'created_at': createdAt,
    };
  }

  String get formattedTime {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt);
    return '${dt.year}年${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
