import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/country_codes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A phone number input field with country code dropdown and search
class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final CountryCode? initialCountryCode;
  final void Function(CountryCode)? onCountryChanged;
  final String label;
  final String hint;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.validator,
    this.initialCountryCode,
    this.onCountryChanged,
    this.label = 'Phone Number',
    this.hint = 'Enter 10-digit number',
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late CountryCode _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountryCode ?? CountryCodes.defaultCountry;
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountryPickerSheet(
        selectedCountry: _selectedCountry,
        onSelect: (country) {
          setState(() => _selectedCountry = country);
          widget.onCountryChanged?.call(country);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: InkWell(
              onTap: _showCountryPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedCountry.shortDisplay,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
      ],
    );
  }

  /// Get the full phone number with country code
  String get fullPhoneNumber =>
      '${_selectedCountry.dialCode}${widget.controller.text}';
}

class _CountryPickerSheet extends StatefulWidget {
  final CountryCode selectedCountry;
  final void Function(CountryCode) onSelect;

  const _CountryPickerSheet({
    required this.selectedCountry,
    required this.onSelect,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  List<CountryCode> _filteredCountries = CountryCodes.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    setState(() {
      _filteredCountries = CountryCodes.search(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('Select Country Code', style: AppTypography.h4),
          ),
          const SizedBox(height: AppSpacing.md),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search country or code...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Country list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = country.code == widget.selectedCountry.code;
                return ListTile(
                  leading: Text(
                    country.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(country.name, style: AppTypography.bodyMedium),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        country.dialCode,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                  onTap: () => widget.onSelect(country),
                  tileColor: isSelected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
