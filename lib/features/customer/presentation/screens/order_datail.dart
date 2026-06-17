import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/order.dart';
import '../../data/models/order_model.dart';
import '../../data/services/order_service.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late final OrderService _orderService;
  OrderModel? _order;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _orderService = ref.read(orderServiceProvider);
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      _order = await _orderService.getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _items = _order!.items
              .map((item) => {
                    'medicine_name': item.medicineName,
                    'quantity': item.quantity,
                    'price': item.price,
                    'subtotal': item.subtotal,
                  })
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatPrice(dynamic price) {
    final p = (price is int ? price : (price as num).toInt());
    return p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  OrderStatus _parseStatus(String status) {
    switch (status) {
      case 'PENDING': return OrderStatus.waitingPayment;
      case 'CONFIRMED': return OrderStatus.confirmed;
      case 'PROCESSING': return OrderStatus.processing;
      case 'SHIPPED': return OrderStatus.shipping;
      case 'READY_FOR_PICKUP': return OrderStatus.shipping;
      case 'DELIVERED': return OrderStatus.delivered;
      case 'COMPLETED': return OrderStatus.completed;
      case 'CANCELLED': return OrderStatus.cancelled;
      default: return OrderStatus.waitingPayment;
    }
  }

  bool get _isDelivery => _order?.serviceType == 'DELIVERY';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F2F8),
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F2F8),
        appBar: _buildAppBar(),
        body: const Center(child: Text('Pesanan tidak ditemukan')),
      );
    }

    final order = _order!;
    final status = _parseStatus(order.orderStatus);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(status, order),
            const SizedBox(height: 16),
            _buildInfoCard(order),
            const SizedBox(height: 16),
            _buildItemsCard(order),
            const SizedBox(height: 16),
            _buildPaymentCard(order),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF0F2F8), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textDark),
        ),
      ),
      title: Text(
        _order != null ? 'Pesanan ${_order!.orderNumber}' : 'Detail Pesanan',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark),
      ),
      centerTitle: true,
    );
  }

  Widget _buildStatusCard(OrderStatus status, OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: _getStatusColor(status).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            'Pesanan ${status.label}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _getStatusColor(status)),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(order.createdAt.toString()),
            style: const TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_pharmacy_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Informasi Apotek', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.store_rounded, 'Apotek', 'Apotek'),
          const SizedBox(height: 8),
          _infoRow(Icons.receipt_long_rounded, 'No. Pesanan', order.orderNumber),
          const SizedBox(height: 8),
          _infoRow(Icons.local_shipping_rounded, 'Layanan', _isDelivery ? 'Dikirim' : 'Ambil di Apotek'),
          const SizedBox(height: 8),
          _infoRow(Icons.calendar_month_rounded, 'Tanggal', _formatDate(order.createdAt.toString())),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textLight),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsCard(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.medication_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Daftar Obat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 12),
          ..._items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['medicine_name'] ?? '-',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item['quantity']} x ${item['unit'] ?? ''}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rp ${_formatPrice(item['subtotal'] ?? 0)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(OrderModel order) {
    final subtotal = order.subtotalAmount.toInt();
    final shipping = order.shippingCost.toInt();
    final total = order.grandTotal.toInt();
    final paymentMethod = order.paymentMethod;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Metode Pembayaran', style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500)),
              Text(_paymentLabel(paymentMethod), style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w700)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500)),
              Text('Rp ${_formatPrice(subtotal)}', style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w700)),
            ],
          ),
          if (shipping > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Biaya Kirim', style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                Text('Rp ${_formatPrice(shipping)}', style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              Text('Rp ${_formatPrice(total)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'QRIS': return 'QRIS';
      case 'BANK_TRANSFER': return 'Transfer Bank';
      case 'VIRTUAL_ACCOUNT': return 'Rekening Virtual';
      case 'COD': return 'COD';
      default: return method;
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.waitingPayment: return const Color(0xFFF59E0B);
      case OrderStatus.confirmed: return AppColors.primary;
      case OrderStatus.processing: return const Color(0xFF6366F1);
      case OrderStatus.shipping: return const Color(0xFF3B82F6);
      case OrderStatus.delivered: return const Color(0xFF10B981);
      case OrderStatus.completed: return const Color(0xFF10B981);
      case OrderStatus.cancelled: return const Color(0xFFEF4444);
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.waitingPayment: return Icons.access_time_rounded;
      case OrderStatus.confirmed: return Icons.check_circle_outline;
      case OrderStatus.processing: return Icons.inventory_2_outlined;
      case OrderStatus.shipping: return Icons.local_shipping_outlined;
      case OrderStatus.delivered: return Icons.check_circle_rounded;
      case OrderStatus.completed: return Icons.task_alt_rounded;
      case OrderStatus.cancelled: return Icons.cancel_outlined;
    }
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return '-';
    final date = DateTime.tryParse(timestamp);
    if (date == null) return timestamp;
    return '${date.day} ${_months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
}
