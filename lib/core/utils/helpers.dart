import 'package:flutter/material.dart';

/// 根据打卡名称匹配图标
IconData habitIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('书') || n.contains('读')) return Icons.menu_book;
  if (n.contains('跑') || n.contains('步') || n.contains('运动')) return Icons.directions_run;
  if (n.contains('水')) return Icons.local_drink;
  if (n.contains('想') || n.contains('冥想')) return Icons.self_improvement;
  if (n.contains('琴') || n.contains('吉他')) return Icons.music_note;
  if (n.contains('写')) return Icons.edit;
  if (n.contains('睡') || n.contains('眠') || n.contains('休息')) return Icons.bedtime;
  if (n.contains('吃') || n.contains('餐') || n.contains('饭')) return Icons.restaurant;
  if (n.contains('药') || n.contains('维')) return Icons.medication;
  if (n.contains('画') || n.contains('绘')) return Icons.brush;
  if (n.contains('瑜伽')) return Icons.self_improvement;
  if (n.contains('游') || n.contains('泳')) return Icons.pool;
  if (n.contains('歌') || n.contains('唱')) return Icons.music_note;
  if (n.contains('舞')) return Icons.celebration;
  if (n.contains('代码') || n.contains('编程')) return Icons.code;
  return Icons.star;
}

/// 格式化秒数为中文可读时长
String formatDuration(int seconds) {
  if (seconds < 0) seconds = 0;
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final parts = <String>[];
  if (h > 0) parts.add('$h小时');
  if (m > 0) parts.add('$m分');
  parts.add('$s秒');
  return parts.join('');
}

/// 获取打卡类型的中文标签
String getHabitTypeLabel(String type) {
  switch (type) {
    case 'countdown':
      return '倒计时';
    case 'timer':
      return '正向计时';
    case 'count':
      return '不计时';
    default:
      return '不计时';
  }
}

/// 获取打卡类型的颜色
Color getHabitTypeColor(String type) {
  switch (type) {
    case 'countdown':
      return const Color(0xFFEA4335);
    case 'timer':
      return const Color(0xFF5B8DEF);
    case 'count':
      return const Color(0xFF34A853);
    default:
      return const Color(0xFF34A853);
  }
}
