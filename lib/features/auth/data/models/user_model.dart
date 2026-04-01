import '../../domain/entities/user.dart';

/// User data model — handles JSON ←→ Entity mapping
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.phone,
    required super.fullName,
    super.avatarUrl,
    super.latitude,
    super.longitude,
    super.areaName,
    super.fcmToken,
    super.isPhoneVerified,
    super.ratingAvg,
    super.ratingCount,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      latitude: _extractLat(json['location']),
      longitude: _extractLng(json['location']),
      areaName: json['area_name'] as String?,
      fcmToken: json['fcm_token'] as String?,
      isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['rating_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'area_name': areaName,
      'fcm_token': fcmToken,
      'is_phone_verified': isPhoneVerified,
    };
  }

  /// Update fields only (for PATCH)
  Map<String, dynamic> toUpdateJson() {
    final map = <String, dynamic>{};
    map['full_name'] = fullName;
    if (phone != null) map['phone'] = phone;
    if (avatarUrl != null) map['avatar_url'] = avatarUrl;
    if (areaName != null) map['area_name'] = areaName;
    if (fcmToken != null) map['fcm_token'] = fcmToken;
    return map;
  }

  static double? _extractLat(dynamic location) {
    // PostGIS returns location as a string or object — parse accordingly
    if (location == null) return null;
    if (location is Map) return (location['coordinates'] as List?)?.last as double?;
    return null;
  }

  static double? _extractLng(dynamic location) {
    if (location == null) return null;
    if (location is Map) return (location['coordinates'] as List?)?.first as double?;
    return null;
  }
}
