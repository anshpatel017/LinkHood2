import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/phone_input_field.dart';
import '../../../../core/constants/country_codes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  CountryCode _selectedCountryCode = CountryCodes.defaultCountry;

  bool _isLoading = false;
  XFile? _selectedAvatar;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize with current values
    final user = ref.read(currentUserProvider).valueOrNull;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    // Parse existing phone number to extract country code and number
    _initPhoneNumber(user?.phone);
  }

  void _initPhoneNumber(String? fullPhone) {
    if (fullPhone == null || fullPhone.isEmpty) {
      _phoneController = TextEditingController();
      return;
    }
    // Try to find matching country code
    for (final country in CountryCodes.all) {
      if (fullPhone.startsWith(country.dialCode)) {
        _selectedCountryCode = country;
        _phoneController = TextEditingController(
          text: fullPhone.substring(country.dialCode.length),
        );
        return;
      }
    }
    // No match found, use default and full number
    _phoneController = TextEditingController(
      text: fullPhone.replaceAll('+', ''),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() => _selectedAvatar = image);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final name = _nameController.text.trim();
      final phoneDigits = _phoneController.text.trim();
      // Combine country code with phone number
      final fullPhone = phoneDigits.isNotEmpty
          ? '${_selectedCountryCode.dialCode}$phoneDigits'
          : null;

      // Upload avatar if changed (skip on web for now)
      if (_selectedAvatar != null && !kIsWeb) {
        await ref
            .read(avatarUploadControllerProvider)
            .uploadAvatar(_selectedAvatar!.path);
      }

      // Update text fields
      await ref
          .read(authControllerProvider)
          .updateProfile(fullName: name, phone: fullPhone);

      // Refresh user data so the updated profile is fetched
      ref.invalidate(currentUserProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    ImageProvider? avatarImage;
    // On web, we can't use FileImage, so only show network images
    if (user?.avatarUrl != null) {
      avatarImage = NetworkImage(user!.avatarUrl!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar editor
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: AppSpacing.avatarXl / 2,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? const Icon(
                              Icons.person,
                              size: 44,
                              color: AppColors.textOnPrimary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary,
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                          onPressed: _pickAvatar,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              AppTextField(
                label: 'Full Name',
                hint: 'Enter your full name',
                controller: _nameController,
                validator: Validators.name,
              ),
              const SizedBox(height: AppSpacing.lg),

              PhoneInputField(
                controller: _phoneController,
                validator: Validators.phoneOptional,
                initialCountryCode: _selectedCountryCode,
                onCountryChanged: (country) {
                  setState(() => _selectedCountryCode = country);
                },
              ),
              const SizedBox(height: AppSpacing.xxxl),

              AppButton(
                label: 'Save Changes',
                onPressed: _saveProfile,
                isLoading: _isLoading,
                icon: Icons.check,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
