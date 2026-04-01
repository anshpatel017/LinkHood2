import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';

class OnboardingInventoryPage extends ConsumerStatefulWidget {
  const OnboardingInventoryPage({super.key});

  @override
  ConsumerState<OnboardingInventoryPage> createState() =>
      _OnboardingInventoryPageState();
}

class _OnboardingInventoryPageState
    extends ConsumerState<OnboardingInventoryPage> {
  final Set<String> _selectedCategories = {};
  bool _isLoading = false;

  Future<void> _saveInventory() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authControllerProvider)
          .saveInventory(_selectedCategories.toList());
      // Refresh user data before navigation
      ref.invalidate(currentUserProvider);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving inventory: ${e.toString()}')),
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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPaddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Text('What do you own?', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Select items you own so neighbors can find them when they need to rent.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Expanded(
                child: ListView.builder(
                  itemCount: CategoryConstants.allCategories.length,
                  itemBuilder: (context, index) {
                    final category = CategoryConstants.allCategories[index];
                    final isSelected = _selectedCategories.contains(category);
                    final examples =
                        CategoryConstants.categoryExamples[category] ?? [];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedCategories.remove(category);
                            } else {
                              _selectedCategories.add(category);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : AppColors.surface,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                CategoryConstants.getIcon(category),
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      CategoryConstants.getLabel(category),
                                      style: AppTypography.labelLarge,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      examples.join(', '),
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: _selectedCategories.isEmpty
                    ? 'Skip for now'
                    : 'Continue (${_selectedCategories.length} selected)',
                onPressed: _saveInventory,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
