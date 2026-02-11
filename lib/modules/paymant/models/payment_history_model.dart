class PaymentHistoryModel {
  final int id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int amount;
  final bool processed;
  final String bankOrderUuid;
  final int orderId;
  final int bankId;
  final int userId;
  final Map<String, dynamic> bankResponse;
  final OrderDetail order;

  PaymentHistoryModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.amount,
    required this.processed,
    required this.bankOrderUuid,
    required this.orderId,
    required this.bankId,
    required this.userId,
    required this.bankResponse,
    required this.order,
  });

  factory PaymentHistoryModel.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryModel(
      id: json['id'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      amount: json['amount'] ?? 0,
      processed: json['processed'] ?? false,
      bankOrderUuid: json['bank_order_uuid'] ?? '',
      orderId: json['order_id'] ?? 0,
      bankId: json['bank_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      bankResponse: json['bank_response'] ?? {},
      order: OrderDetail.fromJson(json['order'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'amount': amount,
      'processed': processed,
      'bank_order_uuid': bankOrderUuid,
      'order_id': orderId,
      'bank_id': bankId,
      'user_id': userId,
      'bank_response': bankResponse,
      'order': order.toJson(),
    };
  }
}

class OrderDetail {
  final int id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int userId;
  final int tariffId;
  final int amount;
  final TariffDetail tariff;

  OrderDetail({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.tariffId,
    required this.amount,
    required this.tariff,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      userId: json['user_id'] ?? 0,
      tariffId: json['tariff_id'] ?? 0,
      amount: json['amount'] ?? 0,
      tariff: TariffDetail.fromJson(json['tariff'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
      'tariff_id': tariffId,
      'amount': amount,
      'tariff': tariff.toJson(),
    };
  }
}

class TariffDetail {
  final int id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int monthCount;
  final int price;
  final int? actualPrice;

  TariffDetail({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.monthCount,
    required this.price,
    this.actualPrice,
  });

  factory TariffDetail.fromJson(Map<String, dynamic> json) {
    return TariffDetail(
      id: json['id'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      monthCount: json['month_count'] ?? 0,
      price: json['price'] ?? 0,
      actualPrice: json['actual_price'],
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
}

class PaymentHistoryResponse {
  final int statusCode;
  final String message;
  final List<PaymentHistoryModel> data;

  PaymentHistoryResponse({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory PaymentHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => PaymentHistoryModel.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}
