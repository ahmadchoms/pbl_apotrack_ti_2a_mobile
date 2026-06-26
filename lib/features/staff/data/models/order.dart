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
  final String? notes;
  final String? cancellationReason;
  final bool requiresPrescription;
  final String createdAt;
  final Map<String, dynamic> buyer;
  final Map<String, dynamic> pharmacy;
  final List<OrderItem> items;
  final List<OrderStatusLog> statusLogs;
  final String? verificationCode;
  final PrescriptionData? prescription;
  final bool isReviewed;

  Order({
    required this.id,
    required this.orderNumber,
    required this.orderStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.serviceType,
    required this.grandTotal,
    required this.subtotalAmount,
    this.notes,
    this.cancellationReason,
    required this.requiresPrescription,
    required this.createdAt,
    required this.buyer,
    required this.pharmacy,
    required this.items,
    this.statusLogs = const [],
    this.verificationCode,
    this.prescription,
    this.isReviewed = false,
  });

  Map<String, dynamic> get customer => buyer;
  bool get hasPrescription => requiresPrescription;

  factory Order.fromJson(Map<String, dynamic> json) {
    final buyerData = json['buyer'] ?? json['user'] ?? {};
    final pharmacyData = json['pharmacy'] ?? {};

    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? 'N/A',
      orderStatus: json['order_status']?.toString() ?? 'PENDING',
      paymentStatus: json['payment_status']?.toString() ?? 'UNPAID',
      paymentMethod: json['payment_method']?.toString() ?? '',
      serviceType: json['service_type']?.toString() ?? 'PICKUP',
      grandTotal:
          num.tryParse(json['grand_total']?.toString() ?? '0') ?? 0,
      subtotalAmount:
          num.tryParse(json['subtotal_amount']?.toString() ?? '0') ?? 0,
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
      verificationCode: json['verification_code']?.toString(),
      prescription: json['prescription'] is Map
          ? PrescriptionData.fromJson(
              json['prescription'] as Map<String, dynamic>)
          : null,
      isReviewed: json['is_reviewed'] == true ||
          json['is_reviewed'] == 1 ||
          json['is_reviewed'] == 'true',
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