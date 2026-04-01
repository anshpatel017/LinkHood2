/// Rental entity (domain layer)
class Rental {
  final String id;
  final String listingId;
  final String borrowerId;
  final String lenderId;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final double totalCost;
  final String status;
  final String? pickupNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data (optional)
  final String? listingTitle;
  final List<String>? listingImages;
  final double? listingPricePerDay;
  final String? counterpartyName;
  final String? counterpartyAvatar;

  const Rental({
    required this.id,
    required this.listingId,
    required this.borrowerId,
    required this.lenderId,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.totalCost,
    required this.status,
    this.pickupNote,
    required this.createdAt,
    required this.updatedAt,
    this.listingTitle,
    this.listingImages,
    this.listingPricePerDay,
    this.counterpartyName,
    this.counterpartyAvatar,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isDisputed => status == 'disputed';
}
