import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/utils/validators.dart';

class OtpPage extends ConsumerStatefulWidget {
  final String email;
  const OtpPage({super.key, required this.email});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  // Resend cooldown
  static const _resendCooldown = 60;
  int _secondsLeft = _resendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _secondsLeft = _resendCooldown;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _verifyOtp() async {
    final error = Validators.otp(_otpController.text);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authControllerProvider)
          .verifyOtp(widget.email, _otpController.text);

      if (mounted) {
        context.go('/setup-password');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_secondsLeft > 0) return;
    setState(() => _isResending = true);
    try {
      await ref.read(authControllerProvider).signInWithOtp(widget.email);
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code resent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  String _friendlyError(String e) {
    final msg = e.startsWith('AuthException: ') ? e.substring(15) : e;
    if (msg.contains('Token has expired') || msg.contains('expired')) {
      return 'Code has expired. Please request a new one.';
    }
    if (msg.contains('invalid') || msg.contains('Invalid')) {
      return 'Invalid code. Please check and try again.';
    }
    if (msg.contains('rate_limit') || msg.contains('429')) {
      return 'Too many attempts. Please wait a moment.';
    }
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPaddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Check your email',
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'We sent a 6-digit code to',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.email,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // OTP input
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                autofocus: true,
                style: AppTypography.h2.copyWith(letterSpacing: 12),
                decoration: InputDecoration(
                  hintText: '------',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              AppButton(
                label: 'Verify & Continue',
                onPressed: _verifyOtp,
                isLoading: _isLoading,
                icon: Icons.verified_outlined,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Resend with cooldown
              Center(
                child: _isResending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: _secondsLeft > 0 ? null : _resendOtp,
                        child: Text(
                          _secondsLeft > 0
                              ? 'Resend code in ${_secondsLeft}s'
                              : 'Didn\'t receive the code? Resend',
                          style: AppTypography.bodyMedium.copyWith(
                            color: _secondsLeft > 0
                                ? AppColors.textTertiary
                                : AppColors.primary,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
