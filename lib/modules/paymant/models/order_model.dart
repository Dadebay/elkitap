class OrderRequest {
  final int tariffId;
  final int bankId;

  OrderRequest({
    required this.tariffId,
    required this.bankId,
  });

  Map<String, dynamic> toJson() {
    return {
      'tariff_id': tariffId,
      'bank_id': bankId,
    };
  }
}

class OrderResponse {
  final int statusCode;
  final String message;
  final OrderData data;

  OrderResponse({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      statusCode: json['statusCode'] as int,
      message: json['message'] as String,
      data: OrderData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class OrderData {
  final String invoiceUrl;

  OrderData({
    required this.invoiceUrl,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      invoiceUrl: json['invoiceUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceUrl': invoiceUrl,
    };
  }
}
