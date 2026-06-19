class DeliveryTracking {
  final String id;
  final String? biteshipOrderId;
  final String? biteshipTrackingId;
  final String? trackingNumber;
  final String? trackingLink;
  final num deliveryFee;
  final String status;
  final Map<String, dynamic>? courier;
  final Map<String, dynamic>? origin;
  final Map<String, dynamic>? destination;
  final List<Map<String, dynamic>> history;

  DeliveryTracking({
    required this.id,
    this.biteshipOrderId,
    this.biteshipTrackingId,
    this.trackingNumber,
    this.trackingLink,
    this.deliveryFee = 0,
    required this.status,
    this.courier,
    this.origin,
    this.destination,
    this.history = const [],
  });

  String? get driverName => courier?['driver_name']?.toString();
  String? get driverPhone => courier?['driver_phone']?.toString();
  String? get driverPhotoUrl => courier?['driver_photo_url']?.toString();
  String? get driverPlateNumber => courier?['driver_plate_number']?.toString();
  String? get courierCompany => courier?['company']?.toString();
  String? get latestHistoryStatus =>
      history.isNotEmpty ? history.last['status']?.toString() : null;

  factory DeliveryTracking.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> parseHistory(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    }

    return DeliveryTracking(
      id: json['id']?.toString() ?? '',
      biteshipOrderId: json['biteship_order_id']?.toString(),
      biteshipTrackingId: json['biteship_tracking_id']?.toString(),
      trackingNumber: json['tracking_number']?.toString(),
      trackingLink: json['tracking_link']?.toString(),
      deliveryFee:
          num.tryParse(json['delivery_fee']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'confirmed',
      courier: json['courier'] is Map
          ? Map<String, dynamic>.from(json['courier'] as Map)
          : null,
      origin: json['origin'] is Map
          ? Map<String, dynamic>.from(json['origin'] as Map)
          : null,
      destination: json['destination'] is Map
          ? Map<String, dynamic>.from(json['destination'] as Map)
          : null,
      history: parseHistory(json['history']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'biteship_order_id': biteshipOrderId,
        'biteship_tracking_id': biteshipTrackingId,
        'tracking_number': trackingNumber,
        'tracking_link': trackingLink,
        'delivery_fee': deliveryFee,
        'status': status,
        'courier': courier,
        'origin': origin,
        'destination': destination,
        'history': history,
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
  final String? patientName;
  final String? doctorName;
  final String? issuedDate;
  final String? rejectionNote;

  PrescriptionData({
    required this.id,
    this.imageUrl,
    required this.status,
    this.patientName,
    this.doctorName,
    this.issuedDate,
    this.rejectionNote,
  });

  factory PrescriptionData.fromJson(Map<String, dynamic> json) {
    return PrescriptionData(
      id: json['id']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      status: json['status']?.toString() ?? 'UPLOADING',
      patientName: json['patient_name']?.toString(),
      doctorName: json['doctor_name']?.toString(),
      issuedDate: json['issued_date']?.toString(),
      rejectionNote: json['rejection_note']?.toString(),
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
  final String? cancellationReason;
  final bool requiresPrescription;
  final String createdAt;
  final Map<String, dynamic> buyer;
  final Map<String, dynamic> pharmacy;
  final List<OrderItem> items;
  final List<OrderStatusLog> statusLogs;
  final DeliveryTracking? tracking;
  final Map<String, dynamic>? address;
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
    this.cancellationReason,
    required this.requiresPrescription,
    required this.createdAt,
    required this.buyer,
    required this.pharmacy,
    required this.items,
    this.statusLogs = const [],
    this.tracking,
    this.address,
    this.verificationCode,
    this.prescription,
  });

  Map<String, dynamic> get customer => buyer;
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
      cancellationReason: json['cancellation_reason']?.toString(),
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
          .map((e) => OrderStatusLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      tracking: trackingData != null && trackingData is Map
          ? DeliveryTracking.fromJson(
              trackingData as Map<String, dynamic>)
          : null,
      address: json['address'] is Map
          ? json['address'] as Map<String, dynamic>
          : null,
      verificationCode: json['verification_code']?.toString(),
      prescription: json['prescription'] is Map
          ? PrescriptionData.fromJson(
              json['prescription'] as Map<String, dynamic>)
          : null,
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
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      subtotal: num.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      requiresPrescription: json['requires_prescription'] == true ||
          json['requires_prescription'] == 1,
      medicine: json['medicine'] is Map<String, dynamic>
          ? json['medicine'] as Map<String, dynamic>
          : {},
    );
  }
}