import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../../services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/validators.dart';

class OnboardingProfilePage extends ConsumerStatefulWidget {
  const OnboardingProfilePage({super.key});

  @override
  ConsumerState<OnboardingProfilePage> createState() =>
      _OnboardingProfilePageState();
}

class _OnboardingProfilePageState extends ConsumerState<OnboardingProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1. Get GPS Location
      final position = await LocationService.getCurrentPosition();

      // 2. Save profile
      await ref
          .read(authControllerProvider)
          .updateProfile(
            fullName: _nameController.text.trim(),
            areaName: _areaController.text.trim().isNotEmpty
                ? _areaController.text.trim()
                : null,
            latitude: position.latitude,
            longitude: position.longitude,
          );

      // Refresh user data so router sees updated fullName
      ref.invalidate(currentUserProvider);

      if (mounted) {
        context.go('/onboarding/inventory');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
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
                const SizedBox(height: AppSpacing.xxl),
                Text('Welcome to RentNear!', style: AppTypography.h2),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Let\'s set up your profile so neighbors know who they are renting with.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.huge),

                AppTextField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  controller: _nameController,
                  validator: Validators.name,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                const SizedBox(height: AppSpacing.lg),

                AppTextField(
                  label: 'Neighborhood / Area (Optional)',
                  hint: 'e.g. Koramangala, Bangalore',
                  controller: _areaController,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                AppButton(
                  label: 'Continue',
                  onPressed: _saveProfile,
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
