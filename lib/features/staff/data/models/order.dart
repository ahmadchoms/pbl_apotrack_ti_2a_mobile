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
  final Map<String, dynamic>? tracking;
  final Map<String, dynamic>? address;
  final String? verificationCode;

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
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Backend returns 'user' as customer, but we can also handle 'buyer'
    final userData = json['user'] ?? json['buyer'] ?? {};
    
    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? 'N/A',
      orderStatus: json['order_status']?.toString() ?? 'PENDING',
      paymentStatus: json['payment_status']?.toString() ?? 'UNPAID',
      serviceType: json['service_type']?.toString() ?? 'PICKUP',
      grandTotal: num.tryParse(json['grand_total']?.toString() ?? '0') ?? 0,
      shippingCost: num.tryParse(json['shipping_cost']?.toString() ?? '0') ?? 0,
      notes: json['notes'],
      hasPrescription: json['has_prescription'] == true || json['has_prescription'] == 1 || json['has_prescription']?.toString() == 'true',
      createdAt: json['created_at']?.toString() ?? '-',
      customer: userData is Map<String, dynamic> ? userData : {'username': 'Pembeli Umum'},
      items: (json['items'] as List? ?? [])
          .map((i) => OrderItem.fromJson(i))
          .toList(),
      tracking: json['delivery_tracking'] ?? json['tracking'],
      address: json['address'],
      verificationCode: json['verification_code']?.toString(),
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
