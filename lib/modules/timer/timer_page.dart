import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';

class TimerPage extends ConsumerStatefulWidget {
  const TimerPage({super.key});

  @override
  ConsumerState<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends ConsumerState<TimerPage> {
  Habit? _habit;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;

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
        if (habit?.isTiming == true) {
          _isRunning = true;
          _startTimer();
        }
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
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
      _stopTimer();
      final now = DateTime.now().millisecondsSinceEpoch;
      final updated = _habit!.copyWith(
        isTiming: false,
        totalDuration: _habit!.totalDuration + _elapsedSeconds,
        todayDuration: _habit!.todayDuration + _elapsedSeconds,
        updatedAt: now,
      );
      await ref.read(habitNotifierProvider.notifier).updateHabit(updated);
      setState(() => _isRunning = false);
    } else {
      final now = DateTime.now().millisecondsSinceEpoch;
      final updated = _habit!.copyWith(
        isTiming: true,
        updatedAt: now,
      );
      await ref.read(habitNotifierProvider.notifier).updateHabit(updated);
      setState(() => _isRunning = true);
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_habit?.name ?? '计时'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
          ],
        ),
      ),
    );
  }
}
