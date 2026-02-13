import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    final cleaned = _phoneController.text.replaceAll(RegExp(r'[\s-]'), '');
    ref.read(authProvider.notifier).phoneLogin(
          cleaned,
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isLoggedIn) {
        context.go('/friends');
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo / Title ─────────────────────────
                  const Icon(
                    Icons.chat_bubble_rounded,
                    size: 72,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Light Talk',
                    textAlign: TextAlign.center,
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '로그인하여 계속하기',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8E8E93),
                        ),
                  ),
                  const SizedBox(height: 48),

                  // ── Phone Number Field ─────────────────────
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    maxLength: 11,
                    onChanged: (value) {
                      final filtered = value.replaceAll(RegExp(r'[^\d]'), '');
                      if (filtered != value) {
                        _phoneController.value = TextEditingValue(
                          text: filtered,
                          selection: TextSelection.collapsed(offset: filtered.length),
                        );
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: '01012345678',
                      prefixIcon: Icon(Icons.phone_outlined),
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '전화번호를 입력해주세요.';
                      }
                      final cleaned =
                          value.replaceAll(RegExp(r'[\s-]'), '');
                      if (!RegExp(r'^01[016789]\d{7,8}$')
                          .hasMatch(cleaned)) {
                        return '올바른 휴대폰 번호를 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Password Field ───────────────────────
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      hintText: '비밀번호',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요.';
                      }
                      if (value.length < 6) {
                        return '비밀번호는 6자 이상이어야 합니다.';
                      }
                      if (!RegExp(r'[a-z]').hasMatch(value)) {
                        return '비밀번호에 소문자를 포함해야 합니다.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Login Button ─────────────────────────
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleLogin,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('로그인'),
                  ),
                  const SizedBox(height: 24),

                  // ── Register Link ────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '계정이 없으신가요? ',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF8E8E93),
                                ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/register/phone'),
                        child: const Text('회원가입'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
