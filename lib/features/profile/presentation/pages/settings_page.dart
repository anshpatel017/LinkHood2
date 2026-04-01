import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _locationServices = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          _buildSectionHeader('Preferences'),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive alerts for requests and messages'),
            value: _pushNotifications,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _pushNotifications = val),
          ),
          SwitchListTile(
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive weekly digests and updates'),
            value: _emailNotifications,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _emailNotifications = val),
          ),
          SwitchListTile(
            title: const Text('Location Services'),
            subtitle: const Text('Allow precise location for nearby listings'),
            value: _locationServices,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _locationServices = val),
          ),
          
          const Divider(height: AppSpacing.xxl),
          _buildSectionHeader('Support'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help Center'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {},
          ),
          
          const SizedBox(height: AppSpacing.xxxl),
          Center(
            child: Text(
              'RentNear v1.0.0',
              style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
      ),
    );
  }
}
