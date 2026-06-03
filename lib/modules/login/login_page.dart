import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // 如果已登录，跳转到首页
    if (authState.value?.isLoggedIn == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              Image.asset(
                'assets/images/logo.png',
                width: 80,
                height: 80,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B8DEF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.edit_note, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '记途',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 8),
              const Text(
                '你的云端备忘录',
                style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
              ),
              const SizedBox(height: 48),
              // 账号输入
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: '账号',
                  hintText: '请输入账号',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              // 密码输入
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '密码',
                  hintText: '请输入密码',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              // 登录/注册按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B8DEF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isRegister ? '注册' : '登录', style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              // 切换登录/注册
              TextButton(
                onPressed: () => setState(() => _isRegister = !_isRegister),
                child: Text(
                  _isRegister ? '已有账号？去登录' : '没有账号？去注册',
                  style: const TextStyle(color: Color(0xFF5B8DEF)),
                ),
              ),
              // 错误提示
              if (authState.value?.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    authState.value!.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 24),
              // 跳过登录
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
                child: const Text('暂不登录，先体验', style: TextStyle(color: Color(0xFF999999))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入账号和密码')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码长度至少6位')),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (_isRegister) {
      await ref.read(authProvider.notifier).register(username, password);
    } else {
      await ref.read(authProvider.notifier).login(username, password);
    }

    setState(() => _isLoading = false);

    final authState = ref.read(authProvider);
    if (authState.value?.isLoggedIn == true && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }
}
