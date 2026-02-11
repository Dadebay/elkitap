import 'package:elkitap/modules/auth/models/subscription_model.dart';

class User {
  final int id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String phone;
  final String? username;
  final String? image;
  final Subscription? subscription;

  User({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.phone,
    this.username,
    this.image,
    this.subscription,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      phone: json['phone'] as String,
      username: json['username'] as String?,
      image: json['image'] as String?,
      subscription: json['subscription'] != null
          ? Subscription.fromJson(json['subscription'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'phone': phone,
      'username': username,
      'image': image,
      'subscription': subscription?.toJson(),
    };
  }

  // Helper method to check if user has active subscription
  bool get hasActiveSubscription {
    return subscription?.isActive ?? false;
  }

  // Helper method to get display name
  String get displayName {
    return username ?? phone;
  }

  // Copy with method for updating user data
  User copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? phone,
    String? username,
    String? image,
    Subscription? subscription,
  }) {
    return User(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      phone: phone ?? this.phone,
      username: username ?? this.username,
      image: image ?? this.image,
      subscription: subscription ?? this.subscription,
    );
  }
}
