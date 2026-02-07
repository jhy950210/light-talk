import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Start countdown from auth state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      _startTimer(authState.otpExpiresIn);
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = seconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _handleVerify() {
    final code = _otpController.text.trim();
    if (code.length != 6) return;
    ref.read(authProvider.notifier).verifyOtp(code);
  }

  void _handleResend() {
    final phone = ref.read(authProvider).phoneNumber;
    if (phone == null) return;
    _otpController.clear();
    ref.read(authProvider.notifier).sendOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final phoneDisplay = authState.phoneNumber ?? '';

    ref.listen<AuthState>(authProvider, (previous, next) {
      // OTP resent – restart timer
      if (next.otpSent && next.otpExpiresIn > 0 &&
          previous?.otpExpiresIn != next.otpExpiresIn) {
        _startTimer(next.otpExpiresIn);
      }
      // OTP verified – navigate based on isNewUser
      if (next.verificationToken != null &&
          previous?.verificationToken == null) {
        if (next.isNewUser) {
          context.go('/register');
        } else {
          context.go('/login');
        }
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // ── Back Button ──────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).resetPhoneAuthFlow();
                    context.go('/register/phone');
                  },
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  color: const Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 24),

              // ── Title ─────────────────────────────────
              Text(
                '인증번호 입력',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C1C1E),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '$phoneDisplay로 전송된\n인증번호를 입력해주세요',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF8E8E93),
                    ),
              ),
              const SizedBox(height: 40),

              // ── 6-Digit OTP Input ─────────────────────
              SizedBox(
                height: 56,
                child: Stack(
                  children: [
                    // Visual boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        final text = _otpController.text;
                        final hasValue = index < text.length;
                        final isActive = index == text.length;
                        return Container(
                          width: 46,
                          height: 56,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? AppTheme.primaryColor
                                  : hasValue
                                      ? AppTheme.primaryLight
                                      : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            hasValue ? text[index] : '',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1C1C1E),
                                ),
                          ),
                        );
                      }),
                    ),
                    // Hidden TextField
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0,
                        child: TextField(
                          controller: _otpController,
                          focusNode: _focusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            setState(() {});
                            if (value.length == 6) {
                              _handleVerify();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Timer ─────────────────────────────────
              Text(
                _formatTime(_remainingSeconds),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _remainingSeconds > 0
                          ? AppTheme.primaryColor
                          : AppTheme.errorRed,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),

              // ── Resend Button ─────────────────────────
              TextButton(
                onPressed: (_remainingSeconds <= 0 && !authState.isLoading)
                    ? _handleResend
                    : null,
                child: Text(
                  '재전송',
                  style: TextStyle(
                    color: (_remainingSeconds <= 0 && !authState.isLoading)
                        ? AppTheme.primaryColor
                        : const Color(0xFFC7C7CC),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Verify Button ─────────────────────────
              ElevatedButton(
                onPressed: (authState.isLoading ||
                        _otpController.text.length != 6)
                    ? null
                    : _handleVerify,
                child: authState.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('확인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
