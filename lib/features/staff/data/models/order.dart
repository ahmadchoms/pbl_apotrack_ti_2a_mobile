class Order {
  final int id;
  final String orderNumber;
  final String orderStatus;
  final String paymentStatus;
  final String serviceType;
  final num grandTotal;
  final num shippingCost;
  final String? notes;
  final bool hasPrescription;
  final String createdAt;
  final Map<String, dynamic> buyer;
  final List<OrderItem> items;
  final Map<String, dynamic>? tracking;
  final Map<String, dynamic>? address;

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
    required this.buyer,
    required this.items,
    this.tracking,
    this.address,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['order_number'],
      orderStatus: json['order_status'],
      paymentStatus: json['payment_status'],
      serviceType: json['service_type'],
      grandTotal: json['grand_total'] ?? 0,
      shippingCost: json['shipping_cost'] ?? 0,
      notes: json['notes'],
      hasPrescription: json['has_prescription'] ?? false,
      createdAt: json['created_at'],
      buyer: json['buyer'],
      items: (json['items'] as List)
          .map((i) => OrderItem.fromJson(i))
          .toList(),
      tracking: json['tracking'],
      address: json['address'],
    );
  }
}

class OrderItem {
  final int id;
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
      id: json['id'],
      price: json['price'] ?? 0,
      quantity: json['quantity'] ?? 0,
      subtotal: json['subtotal'] ?? 0,
      medicine: json['medicine'],
    );
  }
}
