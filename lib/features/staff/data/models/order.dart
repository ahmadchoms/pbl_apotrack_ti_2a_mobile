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
      deliveryFee: num.tryParse(json['delivery_fee']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'WAITING_PICKUP',
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
  final String serviceType;
  final num grandTotal;
  final num shippingCost;
  final String? notes;
  final bool hasPrescription;
  final String createdAt;
  final Map<String, dynamic> customer;
  final List<OrderItem> items;
  final DeliveryTracking? tracking;
  final Map<String, dynamic>? address;
  final String? verificationCode;
  final PrescriptionData? prescription;

  Order({
    required this.id,
    required this.orderNumber,
    required this.orderStatus,
    required this.paymentStatus,
    required this.serviceType,
    required this.grandTotal,
    required this.shippingCost,
    this.notes,
    required this.hasPrescription,
    required this.createdAt,
    required this.customer,
    required this.items,
    this.tracking,
    this.address,
    this.verificationCode,
    this.prescription,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] ?? json['buyer'] ?? {};
    final trackingData = json['delivery_tracking'] ?? json['tracking'];
    final prescriptionData = json['prescription'];
    
    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? 'N/A',
      orderStatus: json['order_status']?.toString() ?? 'PENDING',
      paymentStatus: json['payment_status']?.toString() ?? 'UNPAID',
      serviceType: json['service_type']?.toString() ?? 'PICKUP',
      grandTotal: num.tryParse(json['grand_total']?.toString() ?? '0') ?? 0,
      shippingCost: num.tryParse(json['shipping_cost']?.toString() ?? '0') ?? 0,
      notes: json['notes'],
      hasPrescription: prescriptionData is Map<String, dynamic> || json['has_prescription'] == true || json['has_prescription'] == 1 || json['has_prescription']?.toString() == 'true',
      createdAt: json['created_at']?.toString() ?? '-',
      customer: userData is Map<String, dynamic> ? userData : {'username': 'Pembeli Umum'},
      items: (json['items'] as List? ?? [])
          .map((i) => OrderItem.fromJson(i))
          .toList(),
      tracking: trackingData != null ? DeliveryTracking.fromJson(trackingData) : null,
      address: json['address'],
      verificationCode: json['verification_code']?.toString(),
      prescription: prescriptionData is Map<String, dynamic> ? PrescriptionData.fromJson(prescriptionData) : null,
    );
  }
}

class OrderItem {
  final String id;
  final num price;
  final int quantity;
  final num subtotal;
  final Map<String, dynamic> medicine;

  OrderItem({
    required this.id,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.medicine,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      price: num.tryParse(json['price']?.toString() ?? '0') ?? 0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      subtotal: num.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      medicine: json['medicine'] is Map ? json['medicine'] : {},
    );
  }
}
