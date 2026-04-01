import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/validators.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.huge),

            // ── Brand ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.handshake_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'LinkHood',
              style: AppTypography.h1.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Rent what you need from neighbors',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Tabs ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingLarge,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTypography.labelLarge,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Sign Up'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Tab Content ────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _SignInTab(onNeedSignUp: () => _tabController.animateTo(1)),
                  _SignUpTab(onNeedSignIn: () => _tabController.animateTo(0)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sign In Tab ───────────────────────────────────────────────────────────────

class _SignInTab extends ConsumerStatefulWidget {
  final VoidCallback onNeedSignUp;
  const _SignInTab({required this.onNeedSignUp});

  @override
  ConsumerState<_SignInTab> createState() => _SignInTabState();
}

class _SignInTabState extends ConsumerState<_SignInTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final needsOnboarding = await ref
          .read(authControllerProvider)
          .signInWithPassword(_emailCtrl.text.trim(), _passCtrl.text);

      if (mounted) {
        context.go(needsOnboarding ? '/onboarding' : '/home');
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

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final needsOnboarding = await ref
          .read(authControllerProvider)
          .signInWithGoogle();
      if (mounted) {
        context.go(needsOnboarding ? '/onboarding' : '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  String _friendlyError(String e) {
    if (e.contains('Invalid login credentials') ||
        e.contains('invalid_credentials')) {
      return 'Incorrect email or password.';
    }
    if (e.contains('Email not confirmed')) {
      return 'Please verify your email first. Check your inbox.';
    }
    if (e.contains('rate_limit') || e.contains('429')) {
      return 'Too many attempts. Please wait a moment.';
    }
    return e;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingLarge,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Email Address',
              hint: 'you@example.com',
              controller: _emailCtrl,
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Password',
              hint: 'Your password',
              controller: _passCtrl,
              obscureText: _obscure,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Password is required' : null,
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: 'Sign In',
              onPressed: _signIn,
              isLoading: _isLoading,
              icon: Icons.login,
            ),
            const SizedBox(height: AppSpacing.lg),
            _orDivider(),
            const SizedBox(height: AppSpacing.lg),
            _googleButton(),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: TextButton(
                onPressed: widget.onNeedSignUp,
                child: Text.rich(
                  TextSpan(
                    text: "Don't have an account? ",
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      TextSpan(
                        text: 'Sign Up',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orDivider() => Row(
    children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Text(
          'OR',
          style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
        ),
      ),
      const Expanded(child: Divider()),
    ],
  );

  Widget _googleButton() => OutlinedButton(
    onPressed: _isGoogleLoading ? null : _signInWithGoogle,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    ),
    child: _isGoogleLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://www.google.com/favicon.ico',
                height: 22,
                width: 22,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.g_mobiledata, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Continue with Google',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
  );
}

// ─── Sign Up Tab ───────────────────────────────────────────────────────────────

class _SignUpTab extends ConsumerStatefulWidget {
  final VoidCallback onNeedSignIn;
  const _SignUpTab({required this.onNeedSignIn});

  @override
  ConsumerState<_SignUpTab> createState() => _SignUpTabState();
}

class _SignUpTabState extends ConsumerState<_SignUpTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authControllerProvider)
          .signInWithOtp(_emailCtrl.text.trim());

      if (!mounted) return;
      context.go('/otp', extra: _emailCtrl.text.trim());
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

  String _friendlyError(String e) {
    final msg = e.startsWith('AuthException: ') ? e.substring(15) : e;

    if (msg.contains('already registered') || msg.contains('already exists')) {
      return 'This email is already registered. Try signing in.';
    }
    if (msg.contains('rate_limit') || msg.contains('429')) {
      return 'Too many attempts. Please wait a moment.';
    }
    if (msg.contains('sending') || msg.contains('unexpected_failure')) {
      return 'Failed to send verification code. Please try again.';
    }
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingLarge,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'We\'ll send a 6-digit code to verify your email, then you\'ll set your password.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppTextField(
              label: 'Email Address',
              hint: 'you@example.com',
              controller: _emailCtrl,
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: 'Send Verification Code',
              onPressed: _sendOtp,
              isLoading: _isLoading,
              icon: Icons.send_outlined,
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: TextButton(
                onPressed: widget.onNeedSignIn,
                child: Text.rich(
                  TextSpan(
                    text: 'Already have an account? ',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
