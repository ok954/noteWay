import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';

class LockScreenPage extends ConsumerStatefulWidget {
  const LockScreenPage({super.key});

  @override
  ConsumerState<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends ConsumerState<LockScreenPage>
    with SingleTickerProviderStateMixin {
  String _inputPin = '';
  String _errorMessage = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  final int _maxPinLength = 6;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12).chain(
      CurveTween(curve: Curves.elasticIn),
    ).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_inputPin.length >= _maxPinLength) return;
    setState(() {
      _inputPin += digit;
      _errorMessage = '';
    });
    HapticFeedback.lightImpact();

    // Auto-verify when reaching expected length
    // We try all lengths from 4 to 6 since we don't know the stored PIN length
    if (_inputPin.length >= 4) {
      final notifier = ref.read(appLockProvider.notifier);
      if (notifier.verifyPin(_inputPin)) {
        _onVerified();
        return;
      }
      // If at max length and still not verified
      if (_inputPin.length == _maxPinLength) {
        _onFailed();
      }
    }
  }

  void _onDeletePressed() {
    if (_inputPin.isEmpty) return;
    setState(() {
      _inputPin = _inputPin.substring(0, _inputPin.length - 1);
      _errorMessage = '';
    });
    HapticFeedback.mediumImpact();
  }

  void _onVerified() {
    HapticFeedback.heavyImpact();
    // Navigate to home and clear the lock screen from stack
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _onFailed() {
    setState(() {
      _errorMessage = 'PIN码错误，请重试';
      _inputPin = '';
    });
    _shakeController.forward().then((_) => _shakeController.reverse());
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Lock icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '请输入PIN码',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '应用已锁定',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                // PIN dots
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        _shakeController.isAnimating
                            ? _shakeAnimation.value *
                                (_shakeController.status == AnimationStatus.forward ? 1 : -1)
                            : 0,
                        0,
                      ),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final isFilled = index < _inputPin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: isFilled ? 16 : 12,
                        height: isFilled ? 16 : 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled
                              ? (_errorMessage.isNotEmpty
                                  ? Colors.red
                                  : theme.colorScheme.primary)
                              : theme.colorScheme.surfaceContainerHighest,
                          border: Border.all(
                            color: isFilled
                                ? Colors.transparent
                                : theme.colorScheme.outlineVariant,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Error message
                SizedBox(
                  height: 32,
                  child: Center(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                ),
                const Spacer(flex: 1),
                // Numeric keypad
                _buildKeypad(context),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (int row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int col = 1; col <= 3; col++)
                  _buildKey(
                    '${row * 3 + col}',
                    theme,
                  ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72, height: 72),
            _buildKey('0', theme),
            _buildDeleteKey(theme),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String digit, ThemeData theme) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _onDigitPressed(digit),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey(ThemeData theme) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onDeletePressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 24,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
