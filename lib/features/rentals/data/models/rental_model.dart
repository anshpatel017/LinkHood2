import '../../domain/entities/rental.dart';

/// Rental data model — handles JSON ←→ Entity mapping
class RentalModel extends Rental {
  const RentalModel({
    required super.id,
    required super.listingId,
    required super.borrowerId,
    required super.lenderId,
    required super.startDate,
    required super.endDate,
    required super.totalDays,
    required super.totalCost,
    required super.status,
    super.pickupNote,
    required super.createdAt,
    required super.updatedAt,
    super.listingTitle,
    super.listingImages,
    super.listingPricePerDay,
    super.counterpartyName,
    super.counterpartyAvatar,
  });

  factory RentalModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    // Extract nested listing data if present
    final listing = json['listings'] as Map<String, dynamic>?;
    // Extract counterparty (borrower or lender depending on current user)
    Map<String, dynamic>? counterparty;
    if (currentUserId != null) {
      final isBorrower = json['borrower_id'] == currentUserId;
      final key = isBorrower ? 'lender' : 'borrower';
      // Handle joined user data from different key patterns
      counterparty = json[key] as Map<String, dynamic>?;
    }

    return RentalModel(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      borrowerId: json['borrower_id'] as String,
      lenderId: json['lender_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      totalDays: json['total_days'] as int? ?? 0,
      totalCost: (json['total_cost'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      pickupNote: json['pickup_note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      listingTitle: listing?['title'] as String?,
      listingImages: (listing?['image_urls'] as List?)?.cast<String>(),
      listingPricePerDay: (listing?['price_per_day'] as num?)?.toDouble(),
      counterpartyName: counterparty?['full_name'] as String?,
      counterpartyAvatar: counterparty?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'listing_id': listingId,
      'borrower_id': borrowerId,
      'lender_id': lenderId,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'total_cost': totalCost,
    };
  }
}
