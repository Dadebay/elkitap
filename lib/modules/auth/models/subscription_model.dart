import 'package:elkitap/core/utils/time_helper.dart';

class Subscription {
  final int id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int userId;
  final int? promoCodeId;
  final DateTime activatedAt;
  final DateTime expiredAt;

  Subscription({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.promoCodeId,
    required this.activatedAt,
    required this.expiredAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userId: json['user_id'] as int,
      promoCodeId: json['promo_code_id'] as int?,
      activatedAt: DateTime.parse(json['activated_at'] as String),
      expiredAt: DateTime.parse(json['expired_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
      'promo_code_id': promoCodeId,
      'activated_at': activatedAt.toIso8601String(),
      'expired_at': expiredAt.toIso8601String(),
    };
  }

  // Helper method to check if subscription is active
  bool get isActive {
    final now = TimeHelper.now;
    // Check if subscription is activated and not expired
    return now.isAfter(activatedAt) && now.isBefore(expiredAt);
  }

  // Helper method to get days remaining
  int get daysRemaining {
    final now = TimeHelper.now;
    if (now.isAfter(expiredAt)) return 0;
    return expiredAt.difference(now).inDays;
  }
}
