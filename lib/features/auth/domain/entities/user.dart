/// User entity (domain layer)
class User {
  final String id;
  final String email;
  final String? phone;
  final String fullName;
  final String? avatarUrl;
  final double? latitude;
  final double? longitude;
  final String? areaName;
  final String? fcmToken;
  final bool isPhoneVerified;
  final double ratingAvg;
  final int ratingCount;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    this.phone,
    required this.fullName,
    this.avatarUrl,
    this.latitude,
    this.longitude,
    this.areaName,
    this.fcmToken,
    this.isPhoneVerified = false,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    required this.createdAt,
  });

  bool get isVerifiedNeighbor =>
      ratingCount >= 3 && ratingAvg >= 3.5 && isPhoneVerified;

  User copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    double? latitude,
    double? longitude,
    String? areaName,
    String? fcmToken,
    bool? isPhoneVerified,
    double? ratingAvg,
    int? ratingCount,
  }) {
    return User(
      id: id,
      email: email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      areaName: areaName ?? this.areaName,
      fcmToken: fcmToken ?? this.fcmToken,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt,
    );
  }
}
