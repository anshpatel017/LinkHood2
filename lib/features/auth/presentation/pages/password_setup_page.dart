import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class PasswordSetupPage extends ConsumerStatefulWidget {
  const PasswordSetupPage({super.key});

  @override
  ConsumerState<PasswordSetupPage> createState() => _PasswordSetupPageState();
}

class _PasswordSetupPageState extends ConsumerState<PasswordSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _setPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider).setPassword(_passCtrl.text);

      if (mounted) {
        context.go('/onboarding');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg.startsWith('AuthException: ') ? msg.substring(15) : msg,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPaddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.huge),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_outlined,
                    size: 64,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Email Verified!',
                  style: AppTypography.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Now set a password for future sign-ins.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxxl),

                AppTextField(
                  label: 'Password',
                  hint: 'Min. 6 characters',
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '• At least 6 characters',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                AppTextField(
                  label: 'Confirm Password',
                  hint: 'Re-enter password',
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirm,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (v != _passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSpacing.xxl),

                AppButton(
                  label: 'Set Password & Continue',
                  onPressed: _setPassword,
                  isLoading: _isLoading,
                  icon: Icons.arrow_forward,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
