import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/add_listing_controller.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/currency_formatter.dart';

class AddListingPage extends ConsumerStatefulWidget {
  const AddListingPage({super.key});

  @override
  ConsumerState<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends ConsumerState<AddListingPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();
  String? _selectedCategory;
  bool _isInstant = false;
  bool _isLoading = false;

  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: 70, // Compress to save bandwidth
    );
    if (images.isNotEmpty) {
      if (_selectedImages.length + images.length > 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 5 images allowed.')),
          );
        }
        return;
      }
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _createListing() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
      }
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(addListingControllerProvider).createListing(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        pricePerDay: double.parse(_priceController.text.trim()),
        depositAmount: double.tryParse(_depositController.text.trim()) ?? 0,
        images: _selectedImages,
        isInstant: _isInstant,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing created successfully!')),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo upload
              Text('Photos (Max 5)', style: AppTypography.h4),
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_selectedImages.length < 5)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: AppColors.primary),
                              SizedBox(height: 4),
                              Text('Add', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    ...List.generate(_selectedImages.length, (index) {
                      return Stack(
                        children: [
                          Container(
                            height: 100,
                            width: 100,
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              image: DecorationImage(
                                image: NetworkImage(_selectedImages[index].path),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              AppTextField(
                label: 'Title',
                hint: 'e.g. Bosch Power Drill',
                controller: _titleController,
                validator: (v) => Validators.required(v, 'Title'),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Category dropdown
              Text('Category', style: AppTypography.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                hint: const Text('Select a category'),
                items: CategoryConstants.allCategories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text('${CategoryConstants.getIcon(cat)} ${CategoryConstants.getLabel(cat)}'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                label: 'Price per day (₹)',
                hint: 'e.g. 50',
                controller: _priceController,
                validator: Validators.price,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.currency_rupee),
              ),

              // Earnings estimate
              if (_priceController.text.isNotEmpty &&
                  double.tryParse(_priceController.text) != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    CurrencyFormatter.earningsEstimate(double.parse(_priceController.text)),
                    style: AppTypography.caption.copyWith(color: AppColors.accent),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                label: 'Description (optional)',
                hint: 'Describe the item, its condition, etc.',
                controller: _descriptionController,
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                label: 'Deposit amount (₹, optional)',
                hint: 'e.g. 200',
                controller: _depositController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.security),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Instant availability toggle
              SwitchListTile(
                title: Text('Available Today', style: AppTypography.labelLarge),
                subtitle: Text(
                  'Mark this item as instantly available for rent',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
                value: _isInstant,
                onChanged: (val) => setState(() => _isInstant = val),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.xxl),

              AppButton(
                label: 'Create Listing',
                onPressed: _createListing,
                isLoading: _isLoading,
                icon: Icons.check,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
