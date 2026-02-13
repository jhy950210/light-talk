import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).phoneRegister(
          _passwordController.text,
          _nicknameController.text.trim(),
        );
  }

  Future<void> _handleBack() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원가입 취소'),
        content: const Text('처음 화면으로 돌아가시겠습니까?\n인증 정보가 초기화됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('예'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(authProvider.notifier).resetPhoneAuthFlow();
      context.go('/login');
    }
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
                  // ── Back Button ──────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: _handleBack,
                      icon: const Icon(Icons.arrow_back_ios_rounded),
                      color: const Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Title ────────────────────────────────
                  Text(
                    '프로필 설정',
                    textAlign: TextAlign.center,
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1C1C1E),
                            ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '닉네임과 비밀번호를 설정해주세요',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8E8E93),
                        ),
                  ),
                  const SizedBox(height: 40),

                  // ── Nickname Field ───────────────────────
                  TextFormField(
                    controller: _nicknameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: '닉네임',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '닉네임을 입력해주세요.';
                      }
                      if (value.trim().length < 2) {
                        return '닉네임은 2자 이상이어야 합니다.';
                      }
                      if (value.trim().length > 20) {
                        return '닉네임은 20자 이하이어야 합니다.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Password Field ───────────────────────
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
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
                  const SizedBox(height: 16),

                  // ── Confirm Password Field ───────────────
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleRegister(),
                    decoration: InputDecoration(
                      hintText: '비밀번호 확인',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirm = !_obscureConfirm;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 다시 입력해주세요.';
                      }
                      if (value != _passwordController.text) {
                        return '비밀번호가 일치하지 않습니다.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Register Button ──────────────────────
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleRegister,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('시작하기'),
                  ),
                  const SizedBox(height: 24),

                  // ── Login Link ───────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '이미 계정이 있으신가요? ',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF8E8E93),
                                ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('로그인'),
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
