import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../models/checkin_record.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../repositories/habit_repository.dart';

class TimerPage extends ConsumerStatefulWidget {
  const TimerPage({super.key});

  @override
  ConsumerState<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends ConsumerState<TimerPage> {
  Habit? _habit;
  CheckinRecord? _currentRecord;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  final _audioPlayer = AudioPlayer();

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
    if (mounted) {
      setState(() {
        _habit = habit;
        if (habit?.isTiming == true && habit?.currentRecordId != null) {
          _isRunning = true;
          _loadCurrentRecord(habit!.currentRecordId!);
        }
      });
    }
  }

  Future<void> _loadCurrentRecord(String recordId) async {
    final repo = ref.read(habitRepositoryProvider);
    final record = await repo.getRecordById(recordId);
    if (record != null && mounted) {
      setState(() {
        _currentRecord = record;
        // 恢复已流逝时间
        final now = DateTime.now().millisecondsSinceEpoch;
        _elapsedSeconds = ((now - record.startTime) ~/ 1000);
        if (_habit?.habitType == 'countdown' && _habit?.planDuration != null) {
          _elapsedSeconds = _habit!.planDuration! - _elapsedSeconds;
          if (_elapsedSeconds <= 0) {
            _elapsedSeconds = 0;
            _isRunning = false;
            _onCountdownFinished();
          }
        }
      });
      if (_isRunning) {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_habit?.habitType == 'countdown') {
          if (_elapsedSeconds > 0) {
            _elapsedSeconds--;
          } else {
            _elapsedSeconds = 0;
            _isRunning = false;
            _timer?.cancel();
            _onCountdownFinished();
          }
        } else {
          _elapsedSeconds++;
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _onCountdownFinished() async {
    _stopTimer();
    _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    if (_habit != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final planDuration = _habit!.planDuration ?? 0;
      final updated = _habit!.copyWith(
        isTiming: false,
        totalDuration: _habit!.totalDuration + planDuration,
        todayDuration: _habit!.todayDuration + planDuration,
        todayCount: _habit!.todayCount + 1,
        checkinCount: _habit!.checkinCount + 1,
        currentRecordId: null,
        updatedAt: now,
      );
      await ref.read(habitNotifierProvider.notifier).updateHabit(updated);
      if (_currentRecord != null) {
        final completedRecord = _currentRecord!.copyWith(
          endTime: now,
          duration: planDuration,
          isCompleted: true,
        );
        await ref.read(habitRepositoryProvider).updateCheckinRecord(completedRecord);
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('倒计时结束，打卡完成！')),
      );
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleTimer() async {
    if (_habit == null) return;

    if (_isRunning) {
      // 结束计时
      _stopTimer();
      final now = DateTime.now().millisecondsSinceEpoch;
      final duration = _habit!.habitType == 'countdown'
          ? (_habit!.planDuration ?? 0) - _elapsedSeconds
          : _elapsedSeconds;

      final updated = _habit!.copyWith(
        isTiming: false,
        totalDuration: _habit!.totalDuration + duration,
        todayDuration: _habit!.todayDuration + duration,
        todayCount: _habit!.todayCount + 1,
        currentRecordId: null,
        updatedAt: now,
      );
      await ref.read(habitNotifierProvider.notifier).updateHabit(updated);

      if (_currentRecord != null) {
        final completedRecord = _currentRecord!.copyWith(
          endTime: now,
          duration: duration,
          isCompleted: true,
        );
        await ref.read(habitRepositoryProvider).updateCheckinRecord(completedRecord);
      }

      setState(() => _isRunning = false);
    } else {
      // 开始计时
      final now = DateTime.now().millisecondsSinceEpoch;
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
          _elapsedSeconds = _habit!.planDuration ?? 0;
        } else {
          _elapsedSeconds = 0;
        }
      });
      _startTimer();
    }
  }

  void _addTime(int minutes) {
    if (_habit?.habitType != 'countdown' || !_isRunning) return;
    setState(() {
      _elapsedSeconds += minutes * 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCountdown = _habit?.habitType == 'countdown';
    final planDuration = _habit?.planDuration ?? 0;
    final progress = isCountdown && planDuration > 0
        ? (_elapsedSeconds / planDuration).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_habit?.name ?? '计时'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isCountdown && _isRunning) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress < 0.2 ? AppColors.danger : AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              _formatTime(_elapsedSeconds),
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 16),
            if (_habit != null)
              Text(
                '今日累计: ${_formatTime(_habit!.todayDuration)}',
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _toggleTimer,
              icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow),
              label: Text(_isRunning ? '结束打卡' : '开始打卡'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRunning ? AppColors.danger : AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            if (isCountdown && _isRunning) ...[
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                children: [
                  _buildAddTimeButton('+5分钟', 5),
                  _buildAddTimeButton('+10分钟', 10),
                  _buildAddTimeButton('+30分钟', 30),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddTimeButton(String label, int minutes) {
    return OutlinedButton(
      onPressed: () => _addTime(minutes),
      child: Text(label),
    );
  }
}
