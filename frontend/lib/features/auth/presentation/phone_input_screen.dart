import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Validate Korean mobile phone format
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '전화번호를 입력해주세요.';
    }
    // Remove dashes and spaces for validation
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^01[016789]\d{7,8}$').hasMatch(cleaned)) {
      return '올바른 휴대폰 번호를 입력해주세요.';
    }
    return null;
  }

  void _handleSendOtp() {
    if (!_formKey.currentState!.validate()) return;
    final cleaned = _phoneController.text.replaceAll(RegExp(r'[\s-]'), '');
    ref.read(authProvider.notifier).sendOtp(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.otpSent && previous?.otpSent != true) {
        context.go('/register/otp');
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
                  // ── Logo / Icon ────────────────────────────
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
                    '전화번호로 시작하기',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF1C1C1E),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 48),

                  // ── Phone Number Field ─────────────────────
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleSendOtp(),
                    maxLength: 13,
                    onChanged: (value) {
                      final filtered = value.replaceAll(RegExp(r'[^\d-]'), '');
                      if (filtered != value) {
                        _phoneController.value = TextEditingValue(
                          text: filtered,
                          selection: TextSelection.collapsed(offset: filtered.length),
                        );
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: '010-1234-5678',
                      prefixIcon: Icon(Icons.phone_outlined),
                      counterText: '',
                    ),
                    validator: _validatePhone,
                  ),
                  const SizedBox(height: 32),

                  // ── Send OTP Button ────────────────────────
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleSendOtp,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('인증번호 받기'),
                  ),
                  const SizedBox(height: 24),

                  // ── Login Link ─────────────────────────────
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
