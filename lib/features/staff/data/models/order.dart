class DeliveryTracking {
  final String? biteshipId;
  final String? courierName;
  final String? courierCode;
  final String? courierService;
  final String? trackingNumber;
  final String? trackingUrl;
  final num deliveryFee;
  final String status;

  DeliveryTracking({
    this.biteshipId,
    this.courierName,
    this.courierCode,
    this.courierService,
    this.trackingNumber,
    this.trackingUrl,
    this.deliveryFee = 0,
    required this.status,
  });

  factory DeliveryTracking.fromJson(Map<String, dynamic> json) {
    return DeliveryTracking(
      biteshipId: json['biteship_id']?.toString(),
      courierName: json['courier_name']?.toString(),
      courierCode: json['courier_code']?.toString(),
      courierService: json['courier_service']?.toString(),
      trackingNumber: json['tracking_number']?.toString(),
      trackingUrl: json['tracking_url']?.toString(),
      deliveryFee:
          num.tryParse(json['delivery_fee']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'WAITING_PICKUP',
    );
  }

  Map<String, dynamic> toJson() => {
        'biteship_id': biteshipId,
        'courier_name': courierName,
        'courier_code': courierCode,
        'courier_service': courierService,
        'tracking_number': trackingNumber,
        'tracking_url': trackingUrl,
        'delivery_fee': deliveryFee,
        'status': status,
      };
}

class OrderStatusLog {
  final String id;
  final String status;
  final String? description;
  final String createdAt;

  const OrderStatusLog({
    required this.id,
    required this.status,
    this.description,
    required this.createdAt,
  });

  factory OrderStatusLog.fromJson(Map<String, dynamic> json) {
    return OrderStatusLog(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      description: json['description']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class PrescriptionData {
  final String id;
  final String? imageUrl;
  final String status;

  PrescriptionData({
    required this.id,
    this.imageUrl,
    required this.status,
  });

  factory PrescriptionData.fromJson(Map<String, dynamic> json) {
    return PrescriptionData(
      id: json['id']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      status: json['status']?.toString() ?? 'UPLOADING',
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isVerified => status == 'VERIFIED';
  bool get isRejected => status == 'REJECTED';
}

class Order {
  final String id;
  final String orderNumber;
  final String orderStatus;
  final String paymentStatus;
  final String paymentMethod;
  final String serviceType;
  final num grandTotal;
  final num subtotalAmount;
  final num shippingCost;
  final String? notes;
  final bool requiresPrescription;
  final String createdAt;
  final Map<String, dynamic> buyer;
  final Map<String, dynamic> pharmacy;
  final List<OrderItem> items;
  final List<OrderStatusLog> statusLogs;
  final DeliveryTracking? tracking;
  final Map<String, dynamic>? address;
  final Map<String, dynamic>? prescription;
  final String? verificationCode;
  final PrescriptionData? prescription;

  Order({
    required this.id,
    required this.orderNumber,
    required this.orderStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.serviceType,
    required this.grandTotal,
    required this.subtotalAmount,
    required this.shippingCost,
    this.notes,
    required this.requiresPrescription,
    required this.createdAt,
    required this.buyer,
    required this.pharmacy,
    required this.items,
    this.statusLogs = const [],
    this.tracking,
    this.address,
    this.prescription,
    this.verificationCode,
    this.prescription,
  });

  // Getter untuk backward compatibility dengan kode staff yang pakai order.customer
  Map<String, dynamic> get customer => buyer;

  // Getter untuk backward compatibility dengan kode staff yang pakai hasPrescription
  bool get hasPrescription => requiresPrescription;

  factory Order.fromJson(Map<String, dynamic> json) {
    final buyerData = json['buyer'] ?? json['user'] ?? {};
    final pharmacyData = json['pharmacy'] ?? {};
    final trackingData = json['tracking'] ?? json['delivery_tracking'];

    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? 'N/A',
      orderStatus: json['order_status']?.toString() ?? 'PENDING',
      paymentStatus: json['payment_status']?.toString() ?? 'UNPAID',
      paymentMethod: json['payment_method']?.toString() ?? '',
      serviceType: json['service_type']?.toString() ?? 'PICK_UP',
      grandTotal:
          num.tryParse(json['grand_total']?.toString() ?? '0') ?? 0,
      subtotalAmount:
          num.tryParse(json['subtotal_amount']?.toString() ?? '0') ?? 0,
      shippingCost:
          num.tryParse(json['shipping_cost']?.toString() ?? '0') ?? 0,
      notes: json['notes']?.toString(),
      requiresPrescription: json['requires_prescription'] == true ||
          json['requires_prescription'] == 1,
      createdAt: json['created_at']?.toString() ?? '-',
      buyer: buyerData is Map<String, dynamic>
          ? buyerData
          : {'username': 'Pembeli Umum'},
      pharmacy: pharmacyData is Map<String, dynamic>
          ? pharmacyData
          : {},
      items: (json['items'] as List? ?? [])
          .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      statusLogs: (json['status_logs'] as List<dynamic>? ?? [])
          .map((e) =>
              OrderStatusLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      tracking: trackingData != null && trackingData is Map
          ? DeliveryTracking.fromJson(
              trackingData as Map<String, dynamic>)
          : null,
      address: json['address'] is Map
          ? json['address'] as Map<String, dynamic>
          : null,
      prescription: json['prescription'] is Map
          ? json['prescription'] as Map<String, dynamic>
          : null,
      verificationCode: json['verification_code']?.toString(),
      prescription: prescriptionData is Map<String, dynamic> ? PrescriptionData.fromJson(prescriptionData) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_number': orderNumber,
      };
}

class OrderItem {
  final String id;
  final String medicineName;
  final String unitName;
  final num price;
  final int quantity;
  final num subtotal;
  final bool requiresPrescription;
  final Map<String, dynamic> medicine;

  OrderItem({
    required this.id,
    required this.medicineName,
    required this.unitName,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.requiresPrescription,
    required this.medicine,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      medicineName: json['medicine_name']?.toString() ?? '',
      unitName: json['unit_name']?.toString() ?? '',
      price: num.tryParse(json['price']?.toString() ?? '0') ?? 0,
      quantity:
          int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      subtotal:
          num.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      requiresPrescription: json['requires_prescription'] == true ||
          json['requires_prescription'] == 1,
      medicine: json['medicine'] is Map<String, dynamic>
          ? json['medicine'] as Map<String, dynamic>
          : {},
    );
  }
}