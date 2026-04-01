import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../domain/entities/request.dart';
import '../../domain/entities/request_response.dart';
import '../providers/request_provider.dart';

class MyRequestsPage extends ConsumerWidget {
  const MyRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(myRequestsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/request'),
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Failed to load requests',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  )),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: () => ref.invalidate(myRequestsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.broadcast_on_home_outlined,
              title: 'No Requests Yet',
              subtitle:
                  'Broadcast a request to neighbors and get help finding what you need.',
              actionLabel: 'Post a Request',
              onAction: () => context.go('/request'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myRequestsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.lg,
                AppSpacing.screenPadding,
                100,
              ),
              itemCount: requests.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) =>
                  _RequestCard(request: requests[i]),
            ),
          );
        },
      ),
    );
  }
}

// ─── Request Card ──────────────────────────────────────────────────────────────

class _RequestCard extends ConsumerStatefulWidget {
  final ItemRequest request;
  const _RequestCard({required this.request});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _expanded = false;
  List<RequestResponse>? _responses;
  bool _loadingResponses = false;

  Future<void> _loadResponses() async {
    if (_responses != null) return;
    setState(() => _loadingResponses = true);
    try {
      final repo = ref.read(requestRepositoryProvider);
      final list = await repo.getRequestResponses(widget.request.id);
      setState(() => _responses = list);
    } catch (_) {
      setState(() => _responses = []);
    } finally {
      setState(() => _loadingResponses = false);
    }
  }

  Future<void> _updateStatus(String responseId, String newStatus) async {
    try {
      final repo = ref.read(requestRepositoryProvider);
      await repo.updateResponseStatus(responseId, newStatus);
      await _loadResponses();
      setState(() => _responses = null);
      await _loadResponses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final fmt = DateFormat('d MMM');
    final cat = CategoryConstants.getLabel(req.category);
    final catIcon = CategoryConstants.getIcon(req.category);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Header ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: category pill + status chip
                Row(
                  children: [
                    _CategoryPill(icon: catIcon, label: cat),
                    const Spacer(),
                    _StatusChip(status: req.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Item name
                Text(
                  req.itemName.isEmpty ? 'Unnamed Request' : req.itemName,
                  style: AppTypography.h4,
                ),
                if (req.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    req.description,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                // Date + duration row
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (req.startDate != null && req.endDate != null)
                      _IconLabel(
                        icon: Icons.calendar_today_outlined,
                        label:
                            '${fmt.format(req.startDate!)} → ${fmt.format(req.endDate!)}',
                      ),
                    if (req.durationDays != null)
                      _IconLabel(
                        icon: Icons.schedule,
                        label:
                            '${req.durationDays} ${req.durationDays == 1 ? 'day' : 'days'}',
                      ),
                    if (req.budgetPerDay != null)
                      _IconLabel(
                        icon: Icons.currency_rupee,
                        label: '₹${req.budgetPerDay!.toStringAsFixed(0)}/day',
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Responses Section ────────────────────────────────────
          const Divider(height: 1),
          InkWell(
            onTap: () {
              setState(() => _expanded = !_expanded);
              if (_expanded) _loadResponses();
            },
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppSpacing.radiusMd),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Neighbor Responses',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded Responses ───────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1),
            if (_loadingResponses)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_responses == null || _responses!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'No responses yet. Waiting for neighbors...',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              )
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                itemCount: _responses!.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) => _ResponseTile(
                  response: _responses![i],
                  onAccept: _responses![i].isPending
                      ? () => _updateStatus(_responses![i].id, 'accepted')
                      : null,
                  onDecline: _responses![i].isPending
                      ? () => _updateStatus(_responses![i].id, 'declined')
                      : null,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─── Response Tile ─────────────────────────────────────────────────────────────

class _ResponseTile extends StatelessWidget {
  final RequestResponse response;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _ResponseTile({
    required this.response,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _bgColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: _bgColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: response.responderAvatarUrl.isNotEmpty
                    ? NetworkImage(response.responderAvatarUrl)
                    : null,
                child: response.responderAvatarUrl.isEmpty
                    ? Text(
                        response.responderName.isNotEmpty
                            ? response.responderName[0].toUpperCase()
                            : 'N',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      response.responderName,
                      style: AppTypography.labelMedium,
                    ),
                    Text(
                      _statusLabel,
                      style: AppTypography.caption.copyWith(
                        color: _bgColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: response.status),
            ],
          ),
          if (response.message != null && response.message!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '"${response.message}"',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          // Accept / Decline buttons for pending responses
          if (response.isPending) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDecline,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color get _bgColor {
    switch (response.status) {
      case 'accepted':
        return AppColors.success;
      case 'declined':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String get _statusLabel {
    switch (response.status) {
      case 'accepted':
        return 'Offer accepted';
      case 'declined':
        return 'Offer declined';
      default:
        return 'Offered to help';
    }
  }
}

// ─── Small reusable widgets ────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final String label;
    final Color fg;

    switch (status.toLowerCase()) {
      case 'fulfilled':
        bg = AppColors.success;
        fg = Colors.white;
        label = '✓ Fulfilled';
        break;
      case 'cancelled':
        bg = AppColors.textTertiary;
        fg = Colors.white;
        label = 'Cancelled';
        break;
      default: // open
        bg = AppColors.info.withOpacity(0.12);
        fg = AppColors.info;
        label = '● Open';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: fg),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    switch (status) {
      case 'accepted':
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'declined':
        color = AppColors.error;
        icon = Icons.cancel;
        break;
      default:
        color = AppColors.warning;
        icon = Icons.hourglass_empty;
    }
    return Icon(icon, color: color, size: 20);
  }
}

class _CategoryPill extends StatelessWidget {
  final String icon;
  final String label;
  const _CategoryPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        '$icon $label',
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _IconLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _IconLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style:
              AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
