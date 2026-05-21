class Habit {
  final String id;
  final String name;
  final String? tag;
  final String habitType;
  final int? planDuration;
  final int totalDuration;
  final int todayDuration;
  final int checkinCount;
  final int todayCount;
  final bool isPinned;
  final bool isTiming;
  final String? currentRecordId;
  final int? lastCheckinAt;
  final int createdAt;
  final int updatedAt;

  Habit({
    required this.id,
    required this.name,
    this.tag,
    required this.habitType,
    this.planDuration,
    this.totalDuration = 0,
    this.todayDuration = 0,
    this.checkinCount = 0,
    this.todayCount = 0,
    this.isPinned = false,
    this.isTiming = false,
    this.currentRecordId,
    this.lastCheckinAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      name: map['name'] as String,
      tag: map['tag'] as String?,
      habitType: map['habit_type'] as String,
      planDuration: map['plan_duration'] as int?,
      totalDuration: map['total_duration'] as int? ?? 0,
      todayDuration: map['today_duration'] as int? ?? 0,
      checkinCount: map['checkin_count'] as int? ?? 0,
      todayCount: map['today_count'] as int? ?? 0,
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      isTiming: (map['is_timing'] as int? ?? 0) == 1,
      currentRecordId: map['current_record_id'] as String?,
      lastCheckinAt: map['last_checkin_at'] as int?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tag': tag,
      'habit_type': habitType,
      'plan_duration': planDuration,
      'total_duration': totalDuration,
      'today_duration': todayDuration,
      'checkin_count': checkinCount,
      'today_count': todayCount,
      'is_pinned': isPinned ? 1 : 0,
      'is_timing': isTiming ? 1 : 0,
      'current_record_id': currentRecordId,
      'last_checkin_at': lastCheckinAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Habit copyWith({
    String? id,
    String? name,
    String? tag,
    String? habitType,
    int? planDuration,
    int? totalDuration,
    int? todayDuration,
    int? checkinCount,
    int? todayCount,
    bool? isPinned,
    bool? isTiming,
    String? currentRecordId,
    int? lastCheckinAt,
    int? createdAt,
    int? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      tag: tag ?? this.tag,
      habitType: habitType ?? this.habitType,
      planDuration: planDuration ?? this.planDuration,
      totalDuration: totalDuration ?? this.totalDuration,
      todayDuration: todayDuration ?? this.todayDuration,
      checkinCount: checkinCount ?? this.checkinCount,
      todayCount: todayCount ?? this.todayCount,
      isPinned: isPinned ?? this.isPinned,
      isTiming: isTiming ?? this.isTiming,
      currentRecordId: currentRecordId ?? this.currentRecordId,
      lastCheckinAt: lastCheckinAt ?? this.lastCheckinAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class HabitTag {
  final String id;
  final String name;
  final int? sortOrder;

  HabitTag({
    required this.id,
    required this.name,
    this.sortOrder,
  });

  factory HabitTag.fromMap(Map<String, dynamic> map) {
    return HabitTag(
      id: map['id'] as String,
      name: map['name'] as String,
      sortOrder: map['sort_order'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sort_order': sortOrder,
    };
  }
}
