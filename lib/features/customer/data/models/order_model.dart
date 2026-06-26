class CartItemModel {
  final String medicineId;
  final String medicineName;
  final String unitName;
  final bool requiresPrescription;
  final int quantity;
  final int price;
  final int subtotal;

  const CartItemModel({
    required this.medicineId,
    required this.medicineName,
    required this.unitName,
    required this.requiresPrescription,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  Map<String, dynamic> toOrderItemJson(String orderId) {
    return {
      'order_id': orderId,
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'unit_name': unitName,
      'requires_prescription': requiresPrescription,
      'quantity': quantity,
      'price': price.toDouble(),
      'subtotal': subtotal.toDouble(),
    };
  }
}

class OrderItemModel {
  final String id;
  final String orderId;
  final String medicineId;
  final String medicineName;
  final String unitName;
  final bool requiresPrescription;
  final int quantity;
  final double price;
  final double subtotal;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.medicineId,
    required this.medicineName,
    required this.unitName,
    required this.requiresPrescription,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      medicineId: json['medicine_id'] as String? ?? json['medicine']?['id'] as String? ?? '',
      medicineName: json['medicine_name'] as String? ?? json['medicine']?['name'] as String? ?? '',
      unitName: json['unit_name'] as String? ?? json['medicine']?['unit'] as String? ?? 'Pcs',
      requiresPrescription: json['requires_prescription'] as bool? ??
          json['medicine']?['requires_prescription'] as bool? ??
          false,
      quantity: json['quantity'] as int? ?? 1,
      price: double.parse((json['price'] ?? 0).toString()),
      subtotal: double.parse((json['subtotal'] ?? 0).toString()),
    );
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String pharmacyId;
  final String orderNumber;
  final String verificationCode;
  final String serviceType;
  final String paymentMethod;
  final String orderStatus;
  final String paymentStatus;
  final double subtotalAmount;
  final double grandTotal;
  final String? notes;
  final String? cancellationReason;
  final double? distanceKm;
  final DateTime? paidAt;
  final DateTime expiredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.pharmacyId,
    required this.orderNumber,
    required this.verificationCode,
    required this.serviceType,
    required this.paymentMethod,
    required this.orderStatus,
    required this.paymentStatus,
    required this.subtotalAmount,
    required this.grandTotal,
    this.notes,
    this.cancellationReason,
    this.distanceKm,
    this.paidAt,
    required this.expiredAt,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['order_items'];
    final List<OrderItemModel> items = itemsRaw != null
        ? (itemsRaw as List<dynamic>)
            .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : [];

    return OrderModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      pharmacyId: json['pharmacy_id'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? '',
      verificationCode: json['verification_code'] as String? ?? '',
      serviceType: json['service_type'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? '',
      orderStatus: json['order_status'] as String? ?? 'PENDING',
      paymentStatus: json['payment_status'] as String? ?? 'UNPAID',
      subtotalAmount: double.parse((json['subtotal_amount'] ?? 0).toString()),
      grandTotal: double.parse((json['grand_total'] ?? 0).toString()),
      notes: json['notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at'] as String) : null,
      expiredAt: DateTime.tryParse(json['expired_at'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      items: items,
    );
  }
}

class Order {
  final String id;
  final String userId;
  final String pharmacyId;
  final String orderNumber;
  final String verificationCode;
  final String serviceType;
  final String paymentMethod;
  final String orderStatus;
  final String paymentStatus;
  final double subtotalAmount;
  final double grandTotal;
  final String? notes;
  final String? cancellationReason;
  final double? distanceKm;
  final DateTime? paidAt;
  final DateTime expiredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItemModel> items;

  const Order({
    required this.id,
    required this.userId,
    required this.pharmacyId,
    required this.orderNumber,
    required this.verificationCode,
    required this.serviceType,
    required this.paymentMethod,
    required this.orderStatus,
    required this.paymentStatus,
    required this.subtotalAmount,
    required this.grandTotal,
    this.notes,
    this.cancellationReason,
    this.distanceKm,
    this.paidAt,
    required this.expiredAt,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  String get status => orderStatus;
  double get totalAmount => grandTotal;

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['order_items'];
    final List<OrderItemModel> items = itemsRaw != null
        ? (itemsRaw as List<dynamic>)
            .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : [];

    return Order(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      pharmacyId: json['pharmacy_id'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? '',
      verificationCode: json['verification_code'] as String? ?? '',
      serviceType: json['service_type'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? '',
      orderStatus: json['order_status'] as String? ?? 'PENDING',
      paymentStatus: json['payment_status'] as String? ?? 'UNPAID',
      subtotalAmount: double.tryParse((json['subtotal_amount'] ?? 0).toString()) ?? 0.0,
      grandTotal: double.tryParse((json['grand_total'] ?? 0).toString()) ?? 0.0,
      notes: json['notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at'] as String) : null,
      expiredAt: DateTime.tryParse(json['expired_at'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      items: items,
    );
  }
}
