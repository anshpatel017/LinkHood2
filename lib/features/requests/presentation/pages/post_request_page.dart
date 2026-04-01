import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/validators.dart';
import '../providers/request_provider.dart';

class PostRequestPage extends ConsumerStatefulWidget {
  const PostRequestPage({super.key});

  @override
  ConsumerState<PostRequestPage> createState() => _PostRequestPageState();
}

class _PostRequestPageState extends ConsumerState<PostRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;

  DateTime? _startDate;
  DateTime? _endDate;

  int get _durationDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => _datePickerTheme(context, child),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Reset end date if it's before the new start date
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date first')),
      );
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!,
      lastDate: _startDate!.add(const Duration(days: 365)),
      builder: (context, child) => _datePickerTheme(context, child),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Widget _datePickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          surface: Colors.white,
        ),
      ),
      child: child!,
    );
  }

  Future<void> _postRequest() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
      }
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the rental date range')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final double? budget = double.tryParse(_budgetController.text);

      await ref.read(postRequestControllerProvider).postRequest(
        category: _selectedCategory!,
        itemName: _itemNameController.text.trim(),
        description: _descriptionController.text.trim(),
        budgetPerDay: budget,
        durationDays: _durationDays,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request posted! Nearby neighbors will be notified.'),
            backgroundColor: AppColors.success,
          ),
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

  Widget _buildDateTile({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final fmt = DateFormat('dd MMM yyyy');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: date != null ? AppColors.primary : AppColors.border,
            width: date != null ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          color: date != null
              ? AppColors.primary.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: date != null ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date != null ? fmt.format(date) : 'Select date',
                  style: AppTypography.bodyMedium.copyWith(
                    color: date != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight:
                        date != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Need something? Ask your neighbors!',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Category ──────────────────────────────────────────
              Text('What do you need?', style: AppTypography.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Select a category'),
                items: CategoryConstants.allCategories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(
                        '${CategoryConstants.getIcon(cat)} ${CategoryConstants.getLabel(cat)}'),
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

              // ── Item Name ─────────────────────────────────────────
              AppTextField(
                label: 'Item Name',
                hint: 'e.g. Power Drill, Ladder, Tent',
                controller: _itemNameController,
                validator: (v) => Validators.required(v, 'Item name'),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Description ───────────────────────────────────────
              AppTextField(
                label: 'Description',
                hint: 'e.g. Need a power drill for hanging shelves',
                controller: _descriptionController,
                validator: (v) => Validators.required(v, 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Budget ────────────────────────────────────────────
              AppTextField(
                label: 'Budget per day (₹)',
                hint: 'e.g. 50',
                controller: _budgetController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.currency_rupee),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Date Range ────────────────────────────────────────
              Text('Rental Period', style: AppTypography.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildDateTile(
                      label: 'From Date',
                      date: _startDate,
                      onTap: _pickStartDate,
                      icon: Icons.calendar_today_outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildDateTile(
                      label: 'To Date',
                      date: _endDate,
                      onTap: _pickEndDate,
                      icon: Icons.event_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Duration (auto-computed) ──────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _durationDays > 0
                    ? Container(
                        key: const ValueKey('duration'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.08),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Duration: ',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '$_durationDays ${_durationDays == 1 ? 'day' : 'days'}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Info Banner ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.broadcast_on_home, color: AppColors.info),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'This will notify neighbors within 500m who own items in this category.',
                        style:
                            AppTypography.caption.copyWith(color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              AppButton(
                label: 'Broadcast Request',
                onPressed: _postRequest,
                isLoading: _isLoading,
                icon: Icons.send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
