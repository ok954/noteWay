import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/checkin_record.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';

class TimerPage extends ConsumerStatefulWidget {
  const TimerPage({super.key});

  @override
  ConsumerState<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends ConsumerState<TimerPage> {
  Habit? _habit;
  CheckinRecord? _currentRecord;
  Timer? _timer;
  int _elapsedMillis = 0;
  bool _isRunning = false;
  bool _isCompleted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final habitId = ModalRoute.of(context)?.settings.arguments as String?;
    if (habitId != null && _habit == null) {
      _loadHabit(habitId);
    }
  }

  Future<void> _loadHabit(String id) async {
    final repo = ref.read(habitRepositoryProvider);
    final habit = await repo.getHabitById(id);
    if (habit != null && mounted) {
      setState(() {
        _habit = habit;
        if (habit.currentRecordId != null) {
          // 有未完成的记录，恢复状态
          _loadCurrentRecord(habit.currentRecordId!, habit);
        }
      });
    }
  }

  Future<void> _loadCurrentRecord(String recordId, Habit habit) async {
    final repo = ref.read(habitRepositoryProvider);
    final record = await repo.getRecordById(recordId);
    if (record != null && mounted) {
      setState(() {
        _currentRecord = record;
        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsedMs = now - record.startTime;

        if (habit.habitType == 'countdown' && habit.planDuration != null) {
          // 倒计时模式：计算剩余毫秒
          final remainingMs = (habit.planDuration! * 1000) - elapsedMs;
          _elapsedMillis = remainingMs > 0 ? remainingMs : 0;
          _isRunning = remainingMs > 0 && habit.isTiming;
          _isCompleted = remainingMs <= 0;
        } else {
          // 正向计时模式
          _elapsedMillis = elapsedMs;
          _isRunning = habit.isTiming;
        }

        if (_isRunning) {
          _startTimer();
        }
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        if (_habit?.habitType == 'countdown') {
          if (_elapsedMillis > 0) {
            _elapsedMillis -= 50;
          } else {
            _elapsedMillis = 0;
            _isRunning = false;
            _isCompleted = true;
            _timer?.cancel();
            _onCountdownFinished();
          }
        } else {
          _elapsedMillis += 50;
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _onCountdownFinished() async {
    if (_habit == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final planDurationMs = (_habit!.planDuration ?? 0) * 1000;
    final finalDuration = planDurationMs ~/ 1000;

    final updated = _habit!.copyWith(
      isTiming: false,
      totalDuration: _habit!.totalDuration + finalDuration,
      todayDuration: _habit!.todayDuration + finalDuration,
      todayCount: _habit!.todayCount + 1,
      checkinCount: _habit!.checkinCount + 1,
      currentRecordId: null,
      lastCheckinAt: now,
      updatedAt: now,
    );

    if (_currentRecord != null) {
      final completedRecord = _currentRecord!.copyWith(
        endTime: now,
        duration: finalDuration,
        isCompleted: true,
      );
      await ref.read(habitRepositoryProvider).completeCheckin(completedRecord, updated);
    } else {
      await ref.read(habitNotifierProvider.notifier).updateHabit(updated);
    }
    setState(() => _isCompleted = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('倒计时结束，打卡完成！')),
      );
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  /// 格式化时间：HH:MM:SS.mmm（倒计时）或 HH:MM:SS（正向计时）
  String _formatTime(int millis, {bool showMs = true}) {
    if (millis < 0) millis = 0;
    final totalMs = millis;
    final h = totalMs ~/ 3600000;
    final m = (totalMs % 3600000) ~/ 60000;
    final s = (totalMs % 60000) ~/ 1000;
    final ms = totalMs % 1000;

    if (showMs) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.${(ms ~/ 10).toString().padLeft(2, '0')}';
    }
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleTimer() async {
    if (_habit == null) return;

    if (_isRunning) {
      // 暂停计时（不标记完成）
      _stopTimer();
      final now = DateTime.now().millisecondsSinceEpoch;
      // 保存当前状态：isTiming = false，保留 currentRecordId
      final updated = _habit!.copyWith(
        isTiming: false,
        updatedAt: now,
      );
      await ref.read(habitNotifierProvider.notifier).updateHabit(updated);
      setState(() => _isRunning = false);
    } else {
      // 继续或开始计时
      final now = DateTime.now().millisecondsSinceEpoch;

      if (_currentRecord == null) {
        // 首次开始，创建记录
        final record = CheckinRecord(
          id: const Uuid().v4(),
          habitId: _habit!.id,
          recordType: _habit!.habitType,
          startTime: now,
          createdAt: now,
        );
        await ref.read(habitRepositoryProvider).insertCheckinRecord(record);

        final updated = _habit!.copyWith(
          isTiming: true,
          currentRecordId: record.id,
          updatedAt: now,
        );
        await ref.read(habitNotifierProvider.notifier).updateHabit(updated);

        setState(() {
          _isRunning = true;
          _currentRecord = record;
          if (_habit!.habitType == 'countdown') {
            _elapsedMillis = (_habit!.planDuration ?? 0) * 1000;
          } else {
            _elapsedMillis = 0;
          }
        });
      } else {
        // 恢复计时，更新记录（更新 startTime 重新对齐）
        final updated = _habit!.copyWith(
          isTiming: true,
          updatedAt: now,
        );
        await ref.read(habitNotifierProvider.notifier).updateHabit(updated);
        setState(() => _isRunning = true);
      }
      _startTimer();
    }
  }

  Future<void> _finishTimer() async {
    // 完全结束计时
    _stopTimer();
    if (_habit == null || _currentRecord == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final duration = _habit!.habitType == 'countdown'
        ? ((_habit!.planDuration ?? 0) * 1000 - _elapsedMillis) ~/ 1000
        : _elapsedMillis ~/ 1000;

    if (duration <= 0 && _habit!.habitType == 'countdown') {
      // 已完成
      return;
    }

    final updated = _habit!.copyWith(
      isTiming: false,
      totalDuration: _habit!.totalDuration + duration,
      todayDuration: _habit!.todayDuration + duration,
      todayCount: _habit!.todayCount + 1,
      checkinCount: _habit!.checkinCount + 1,
      currentRecordId: null,
      lastCheckinAt: now,
      updatedAt: now,
    );

    final completedRecord = _currentRecord!.copyWith(
      endTime: now,
      duration: duration,
      isCompleted: true,
    );
    await ref.read(habitRepositoryProvider).completeCheckin(completedRecord, updated);

    setState(() {
      _isRunning = false;
      _isCompleted = true;
      _currentRecord = null;
    });
  }

  void _addTime(int minutes) {
    if (_habit?.habitType != 'countdown') return;
    setState(() {
      _elapsedMillis += minutes * 60 * 1000;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCountdown = _habit?.habitType == 'countdown';
    final planDurationMs = (_habit?.planDuration ?? 0) * 1000;
    final progress = isCountdown && planDurationMs > 0
        ? (_elapsedMillis / planDurationMs).clamp(0.0, 1.0)
        : 0.0;

    // 按钮状态
    String buttonLabel;
    Color buttonColor;
    VoidCallback? buttonAction;

    if (_isCompleted) {
      buttonLabel = '已完成';
      buttonColor = const Color(0xFF34A853);
      buttonAction = null;
    } else if (_isRunning) {
      buttonLabel = '暂停';
      buttonColor = const Color(0xFFFFA726);
      buttonAction = _toggleTimer;
    } else if (_currentRecord != null) {
      buttonLabel = '继续';
      buttonColor = AppColors.secondary;
      buttonAction = _toggleTimer;
    } else {
      buttonLabel = '开始';
      buttonColor = AppColors.secondary;
      buttonAction = _toggleTimer;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_habit?.name ?? '计时'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 标签信息
            if (_habit != null) ...[
              Text(
                '${getHabitTypeLabel(_habit!.habitType)} · ${_habit!.name}',
                style: const TextStyle(fontSize: 16, color: Color(0xFF999999)),
              ),
              const SizedBox(height: 24),
            ],
            // 核心计时显示
            Text(
              _formatTime(_elapsedMillis, showMs: isCountdown),
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 16),
            // 进度条（倒计时）
            if (isCountdown && !_isCompleted) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEEEEEE),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress < 0.2 ? AppColors.danger : AppColors.secondary,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '计划: ${_formatTime(planDurationMs, showMs: false)}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
              ),
              const SizedBox(height: 24),
            ],
            // 统计
            if (_habit != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatItem('今日累计', formatDuration(_habit!.todayDuration)),
                  const SizedBox(width: 32),
                  _buildStatItem('历史累计', formatDuration(_habit!.totalDuration)),
                ],
              ),
              const SizedBox(height: 48),
            ],
            // 主操作按钮
            ElevatedButton.icon(
              onPressed: buttonAction,
              icon: Icon(buttonLabel == '暂停' ? Icons.pause : Icons.play_arrow),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE8E8E8),
                disabledForegroundColor: const Color(0xFF999999),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            // 快捷加时（倒计时）
            if (isCountdown && !_isCompleted) ...[
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                children: [
                  _buildAddTimeButton('+5分', 5),
                  _buildAddTimeButton('+10分', 10),
                  _buildAddTimeButton('+30分', 30),
                ],
              ),
              const SizedBox(height: 16),
              // 结束打卡按钮
              if (_isRunning || _currentRecord != null)
                TextButton(
                  onPressed: _finishTimer,
                  child: const Text(
                    '结束打卡',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
            // 超时提示
            if (_isCompleted && isCountdown) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF34A853)),
                    SizedBox(width: 8),
                    Text('任务完成！', style: TextStyle(fontSize: 16, color: Color(0xFF34A853))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
      ],
    );
  }

  Widget _buildAddTimeButton(String label, int minutes) {
    return OutlinedButton(
      onPressed: () => _addTime(minutes),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF5B8DEF),
        side: const BorderSide(color: Color(0xFF5B8DEF)),
      ),
      child: Text(label),
    );
  }

}
