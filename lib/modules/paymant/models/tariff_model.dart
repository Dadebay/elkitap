class TariffModel {
  final int id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int monthCount;
  final double price;
  final double? actualPrice;

  TariffModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.monthCount,
    required this.price,
    this.actualPrice,
  });

  factory TariffModel.fromJson(Map<String, dynamic> json) {
    return TariffModel(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      monthCount: json['month_count'] as int,
      price: (json['price'] as num).toDouble(),
      actualPrice: json['actual_price'] != null
          ? (json['actual_price'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'month_count': monthCount,
      'price': price,
      'actual_price': actualPrice,
    };
  }

  /// Check if this tariff has a discount
  bool get hasDiscount => actualPrice != null && actualPrice! > price;

  /// Calculate discount percentage
  double get discountPercentage {
    if (!hasDiscount) return 0.0;
    return ((actualPrice! - price) / actualPrice!) * 100;
  }

  /// Get display price (actual price if exists, otherwise regular price)
  double get displayPrice => actualPrice ?? price;
}

class TariffResponse {
  final int statusCode;
  final String message;
  final List<TariffModel> data;

  TariffResponse({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory TariffResponse.fromJson(Map<String, dynamic> json) {
    return TariffResponse(
      statusCode: json['statusCode'] as int,
      message: json['message'] as String,
      data: (json['data'] as List)
          .map((item) => TariffModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'data': data.map((tariff) => tariff.toJson()).toList(),
    };
  }
}
