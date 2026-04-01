/// Listing entity (domain layer)
class Listing {
  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final String category;
  final double pricePerDay;
  final double depositAmount;
  final List<String> imageUrls;
  final double? latitude;
  final double? longitude;
  final String? areaName;
  final bool isAvailable;
  final bool isInstant;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined owner data (optional, from ranked query)
  final String? ownerName;
  final String? ownerAvatar;
  final double? ownerRating;
  final double? distanceMeters;

  const Listing({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description,
    required this.category,
    required this.pricePerDay,
    this.depositAmount = 0,
    this.imageUrls = const [],
    this.latitude,
    this.longitude,
    this.areaName,
    this.isAvailable = true,
    this.isInstant = false,
    this.viewCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.ownerName,
    this.ownerAvatar,
    this.ownerRating,
    this.distanceMeters,
  });

  String get firstImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
  bool get hasImages => imageUrls.isNotEmpty;
}
