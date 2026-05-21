class CheckinRecord {
  final String id;
  final String habitId;
  final String recordType;
  final int startTime;
  final int? endTime;
  final int? duration;
  final bool isCompleted;
  final int createdAt;

  CheckinRecord({
    required this.id,
    required this.habitId,
    required this.recordType,
    required this.startTime,
    this.endTime,
    this.duration,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory CheckinRecord.fromMap(Map<String, dynamic> map) {
    return CheckinRecord(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      recordType: map['record_type'] as String,
      startTime: map['start_time'] as int,
      endTime: map['end_time'] as int?,
      duration: map['duration'] as int?,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'record_type': recordType,
      'start_time': startTime,
      'end_time': endTime,
      'duration': duration,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt,
    };
  }

  CheckinRecord copyWith({
    String? id,
    String? habitId,
    String? recordType,
    int? startTime,
    int? endTime,
    int? duration,
    bool? isCompleted,
    int? createdAt,
  }) {
    return CheckinRecord(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      recordType: recordType ?? this.recordType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
