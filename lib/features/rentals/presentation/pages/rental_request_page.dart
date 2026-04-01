import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../listings/presentation/providers/listing_provider.dart';
import '../providers/rental_provider.dart';

class RentalRequestPage extends ConsumerStatefulWidget {
  final String listingId;
  const RentalRequestPage({super.key, required this.listingId});

  @override
  ConsumerState<RentalRequestPage> createState() => _RentalRequestPageState();
}

class _RentalRequestPageState extends ConsumerState<RentalRequestPage> {
  DateTimeRange? _dateRange;
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (result != null) setState(() => _dateRange = result);
  }

  Future<void> _submitRequest(String lenderId, double pricePerDay) async {
    if (_dateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select rental dates')),
      );
      return;
    }

    final days = _dateRange!.end.difference(_dateRange!.start).inDays + 1;
    final totalCost = days * pricePerDay;

    setState(() => _isLoading = true);
    try {
      await ref.read(rentalControllerProvider).createRequest(
        listingId: widget.listingId,
        lenderId: lenderId,
        startDate: _dateRange!.start,
        endDate: _dateRange!.end,
        totalCost: totalCost,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rental request sent!')),
        );
        context.go('/rentals');
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
    final listingAsync = ref.watch(listingDetailProvider(widget.listingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Request to Rent')),
      body: listingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (listing) {
          final days = _dateRange != null
              ? _dateRange!.end.difference(_dateRange!.start).inDays + 1
              : 0;
          final totalCost = days * listing.pricePerDay;

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          image: listing.hasImages
                              ? DecorationImage(
                                  image: NetworkImage(listing.firstImageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: AppColors.border,
                        ),
                        child: !listing.hasImages ? const Icon(Icons.image, color: AppColors.textTertiary) : null,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(listing.title, style: AppTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: AppSpacing.xs),
                            Text('${CurrencyFormatter.format(listing.pricePerDay)}/day', style: AppTypography.caption.copyWith(color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                Text('Select Rental Period', style: AppTypography.h4),
                const SizedBox(height: AppSpacing.lg),
                GestureDetector(
                  onTap: _pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      color: AppColors.surface,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _dateRange != null
                                ? '${_formatDate(_dateRange!.start)} — ${_formatDate(_dateRange!.end)} ($days days)'
                                : 'Tap to select dates',
                            style: AppTypography.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (days > 0) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Duration:', style: AppTypography.bodyMedium),
                      Text('$days days', style: AppTypography.labelLarge),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Estimated Total:', style: AppTypography.bodyMedium),
                      Text(CurrencyFormatter.format(totalCost), style: AppTypography.h4.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ],

                const SizedBox(height: AppSpacing.xxl),
                AppTextField(
                  label: 'Pickup Note (optional)',
                  hint: 'e.g. I can pick up after 5pm',
                  controller: _noteController,
                  maxLines: 2,
                ),
                const Spacer(),
                AppButton(
                  label: 'Send Request',
                  onPressed: () => _submitRequest(listing.ownerId, listing.pricePerDay),
                  isLoading: _isLoading,
                  icon: Icons.send,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
