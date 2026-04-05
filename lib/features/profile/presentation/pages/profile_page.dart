import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/rating_stars.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.go('/profile/edit'),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.screenPadding, AppSpacing.screenPadding, 120),
              child: Column(
                children: [
                  // Avatar and name
                  CircleAvatar(
                    radius: AppSpacing.avatarXl / 2,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? const Icon(Icons.person, size: 44, color: AppColors.textOnPrimary)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(user.fullName, style: AppTypography.h3),
                  const SizedBox(height: AppSpacing.xs),
                  Text(user.email, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  RatingStars(rating: user.ratingAvg, size: 18, showLabel: true, count: user.ratingCount),
                  const SizedBox(height: AppSpacing.xxl),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat('0', 'Listings'),
                      _buildDivider(),
                      _buildStat('0', 'Rented Out'),
                      _buildDivider(),
                      _buildStat('0', 'Borrowed'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Menu items
                  _buildMenuItem(Icons.inbox_outlined, 'My Requests', () => context.go('/profile/my-requests')),
                  _buildMenuItem(Icons.inventory_2_outlined, 'My Listings', () => context.go('/profile/my-listings')),
                  _buildMenuItem(Icons.checklist_outlined, 'My Inventory', () {}),
                  _buildMenuItem(Icons.history, 'Rental History', () {}),
                  const Divider(height: AppSpacing.xxl),
                  _buildMenuItem(Icons.settings_outlined, 'Settings', () => context.go('/profile/settings')),
                  _buildMenuItem(Icons.help_outline, 'Help & Support', () {}),
                  _buildMenuItem(Icons.logout, 'Sign Out', () async {
                    await ref.read(authControllerProvider).signOut();
                    if (context.mounted) context.go('/login');
                  }, isDestructive: true),
                ],
              ),
            ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: AppTypography.h3.copyWith(color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 32, width: 1, color: AppColors.border);
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.textSecondary),
      title: Text(
        label,
        style: AppTypography.bodyLarge.copyWith(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
