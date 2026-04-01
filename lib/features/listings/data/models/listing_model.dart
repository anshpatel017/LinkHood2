import '../../domain/entities/listing.dart';

/// Listing data model — handles JSON ←→ Entity mapping
class ListingModel extends Listing {
  const ListingModel({
    required super.id,
    required super.ownerId,
    required super.title,
    super.description,
    required super.category,
    required super.pricePerDay,
    super.depositAmount,
    super.imageUrls,
    super.latitude,
    super.longitude,
    super.areaName,
    super.isAvailable,
    super.isInstant,
    super.viewCount,
    required super.createdAt,
    required super.updatedAt,
    super.ownerName,
    super.ownerAvatar,
    super.ownerRating,
    super.distanceMeters,
  });

  /// From standard listings table JSON
  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      pricePerDay: (json['price_per_day'] as num).toDouble(),
      depositAmount: (json['deposit_amount'] as num?)?.toDouble() ?? 0,
      imageUrls: (json['image_urls'] as List?)?.cast<String>() ?? [],
      areaName: json['area_name'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      isInstant: json['is_instant'] as bool? ?? false,
      viewCount: json['view_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// From ranked nearby listings RPC result
  factory ListingModel.fromRankedJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['listing_id'] as String,
      ownerId: json['owner_id'] as String? ?? '',
      title: json['title'] as String,
      description: null,
      category: json['category'] as String,
      pricePerDay: (json['price_per_day'] as num).toDouble(),
      imageUrls: (json['image_urls'] as List?)?.cast<String>() ?? [],
      isAvailable: json['is_available'] as bool? ?? true,
      isInstant: json['is_instant'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.now(),
      ownerName: json['owner_name'] as String?,
      ownerAvatar: json['owner_avatar'] as String?,
      ownerRating: (json['owner_rating'] as num?)?.toDouble(),
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'category': category,
      'price_per_day': pricePerDay,
      'deposit_amount': depositAmount,
      'image_urls': imageUrls,
      'area_name': areaName,
      'is_available': isAvailable,
      'is_instant': isInstant,
    };
  }

  Map<String, dynamic> toCreateJson(double lat, double lng) {
    final json = toJson();
    json['location'] = 'POINT($lng $lat)';
    return json;
  }
}
