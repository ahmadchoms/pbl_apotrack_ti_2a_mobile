
import 'package:mobile/core/network/api_client.dart';

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
      imageUrl: resolveImageUrl(json['image_url']?.toString()),
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

class OrderItem {
  final String id;
  final String? orderId;
  final String? medicineId;
  final String medicineName;
  final String unitName;
  final bool requiresPrescription;
  final int quantity;
  final num price;
  final num subtotal;
  final Map<String, dynamic> medicine;

  OrderItem({
    required this.id,
    this.orderId,
    this.medicineId,
    required this.medicineName,
    required this.unitName,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.requiresPrescription,
    this.medicine = const {},
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString(),
      medicineId: json['medicine_id']?.toString() ?? json['medicine']?['id']?.toString(),
      medicineName: json['medicine_name']?.toString() ?? json['medicine']?['name']?.toString() ?? '',
      unitName: json['unit_name']?.toString() ?? json['medicine']?['unit']?.toString() ?? 'Pcs',
      price: num.tryParse(json['price']?.toString() ?? '0') ?? 0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      subtotal: num.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      requiresPrescription: json['requires_prescription'] == true ||
          json['requires_prescription'] == 1 ||
          json['medicine']?['requires_prescription'] == true ||
          json['medicine']?['requires_prescription'] == 1,
      medicine: json['medicine'] is Map<String, dynamic>
          ? json['medicine'] as Map<String, dynamic>
          : {},
    );
  }
}

class Order {
  final String id;
  final String userId;
  final String pharmacyId;
  final String orderNumber;
  final String orderStatus;
  final String paymentStatus;
  final String paymentMethod;
  final String serviceType;
  final num grandTotal;
  final num subtotalAmount;
  final String? notes;
  final String? cancellationReason;
  final double? distanceKm;
  final String? paidAt;
  final String? expiredAt;
  final String createdAt;
  final String? updatedAt;
  final String? verificationCode;
  final bool requiresPrescription;
  final Map<String, dynamic> buyer;
  final Map<String, dynamic> pharmacy;
  final List<OrderItem> items;
  final List<OrderStatusLog> statusLogs;
  final PrescriptionData? prescription;
  final bool isReviewed;

  Order({
    required this.id,
    this.userId = '',
    this.pharmacyId = '',
    required this.orderNumber,
    required this.orderStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.serviceType,
    required this.grandTotal,
    required this.subtotalAmount,
    this.notes,
    this.cancellationReason,
    this.distanceKm,
    this.paidAt,
    this.expiredAt,
    required this.createdAt,
    this.updatedAt,
    required this.requiresPrescription,
    this.buyer = const {},
    this.pharmacy = const {},
    required this.items,
    this.statusLogs = const [],
    this.verificationCode,
    this.prescription,
    this.isReviewed = false,
  });

  String get status => orderStatus;
  double get totalAmount => grandTotal.toDouble();
  Map<String, dynamic> get customer => buyer;
  bool get hasPrescription => requiresPrescription;

  factory Order.fromJson(Map<String, dynamic> json) {
    final buyerData = json['buyer'] ?? json['user'] ?? {};
    final pharmacyData = json['pharmacy'] ?? {};
    final itemsRaw = json['items'] ?? json['order_items'] ?? [];

    final List<OrderItem> parsedItems = (itemsRaw as List<dynamic>)
        .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return Order(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      pharmacyId: json['pharmacy_id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? 'N/A',
      orderStatus: json['order_status']?.toString() ?? 'PENDING',
      paymentStatus: json['payment_status']?.toString() ?? 'UNPAID',
      paymentMethod: json['payment_method']?.toString() ?? '',
      serviceType: json['service_type']?.toString() ?? 'PICKUP',
      grandTotal: num.tryParse(json['grand_total']?.toString() ?? '0') ?? 0,
      subtotalAmount: num.tryParse(json['subtotal_amount']?.toString() ?? '0') ?? 0,
      notes: json['notes']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      paidAt: json['paid_at']?.toString(),
      expiredAt: json['expired_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '-',
      updatedAt: json['updated_at']?.toString(),
      verificationCode: json['verification_code']?.toString(),
      requiresPrescription: json['requires_prescription'] == true || json['requires_prescription'] == 1,
      buyer: buyerData is Map<String, dynamic> ? buyerData : {'username': 'Pembeli Umum'},
      pharmacy: pharmacyData is Map<String, dynamic> ? pharmacyData : {},
      items: parsedItems,
      statusLogs: (json['status_logs'] as List<dynamic>? ?? [])
          .map((e) => OrderStatusLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      prescription: json['prescription'] is Map
          ? PrescriptionData.fromJson(json['prescription'] as Map<String, dynamic>)
          : null,
      isReviewed: json['is_reviewed'] == true || json['is_reviewed'] == 1 || json['is_reviewed'] == 'true',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_number': orderNumber,
      };
}

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

// Typedef aliases for backward compatibility
typedef OrderModel = Order;
typedef OrderItemModel = OrderItem;
