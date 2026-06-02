enum OrderStatus {
  waitingPayment,
  confirmed,
  processing,
  shipping,
  delivered,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case OrderStatus.waitingPayment:
        return 'Menunggu Pembayaran';
      case OrderStatus.confirmed:
        return 'Dikonfirmasi';
      case OrderStatus.processing:
        return 'Diproses';
      case OrderStatus.shipping:
        return 'Dikirim';
      case OrderStatus.delivered:
        return 'Telah Sampai';
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  String get iconLabel {
    switch (this) {
      case OrderStatus.waitingPayment:
        return 'waiting';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.shipping:
        return 'shipping';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }
}

class Order {
  final int id;
  final String orderNumber;
  final String createdAt;
  final OrderStatus status;
  final int total;
  final String paymentMethod;
  final String pharmacyName;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
    required this.status,
    required this.total,
    required this.paymentMethod,
    required this.pharmacyName,
    required this.items,
  });
}

class OrderItem {
  final String name;
  final int quantity;
  final String unit;
  final int price;

  const OrderItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
  });

  int get subtotal => quantity * price;
}
