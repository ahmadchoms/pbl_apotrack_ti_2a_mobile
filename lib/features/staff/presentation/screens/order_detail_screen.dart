import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
//  SHARED THEME
// ─────────────────────────────────────────────
class _C {
  static const primary = Color(0xFF1D70F5);
  static const primaryLight = Color(0xFFEEF4FF);
  static const bg = Color(0xFFF4F7FE);
  static const surface = Colors.white;
  static const textDark = Color(0xFF0F1828);
  static const textMid = Color(0xFF4B5563);
  static const textLight = Color(0xFF9CA3AF);
  static const divider = Color(0xFFE5EAF2);
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFFFBEB);
  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFEF2F2);
  static const orange = Color(0xFFF97316);
  static const orangeLight = Color(0xFFFFF7ED);
}

String _formatRupiah(num value) {
  final str = value.toStringAsFixed(0);
  final buf = StringBuffer();
  final len = str.length;
  for (int i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buf.write('.');
    buf.write(str[i]);
  }
  return 'Rp ${buf.toString()}';
}

// ─────────────────────────────────────────────
//  STATUS CONFIG
// ─────────────────────────────────────────────
class _StatusCfg {
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;
  const _StatusCfg(this.label, this.color, this.bg, this.icon);
}

const Map<String, _StatusCfg> _statusMap = {
  'PENDING': _StatusCfg('Menunggu', Color(0xFFF59E0B), Color(0xFFFFFBEB), Icons.hourglass_top_rounded),
  'PROCESSING': _StatusCfg('Sedang Diproses', Color(0xFF1D70F5), Color(0xFFEEF4FF), Icons.autorenew_rounded),
  'READY': _StatusCfg('Siap Diambil', Color(0xFF10B981), Color(0xFFECFDF5), Icons.check_circle_rounded),
  'COMPLETED': _StatusCfg('Selesai', Color(0xFF6B7280), Color(0xFFF3F4F6), Icons.done_all_rounded),
  'CANCELLED': _StatusCfg('Dibatalkan', Color(0xFFEF4444), Color(0xFFFEF2F2), Icons.cancel_rounded),
};

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy order data
    final order = {
      'id': '#ORD-0921',
      'date': '05 Mei 2026, 10:30',
      'customer': 'Andi Setiawan',
      'status': 'PROCESSING',
      'type': 'DELIVERY',
      'payment_status': 'PAID',
      'payment_method': 'Bank Transfer (BCA)',
      'shipping': {
        'address': 'Jl. Merdeka No. 123, Kel. Sukamaju, Kec. Cilodong, Kota Depok, 16415',
        'courier': 'Biteship (Sicepat Reg)',
        'tracking_no': 'AFT-9821039812',
        'distance': '4.2 km',
      },
      'items': [
        {'name': 'Amoxicillin 500mg', 'unit': 'Strip isi 10', 'qty': 2, 'price': 15000, 'icon': Icons.local_pharmacy_rounded, 'color': Color(0xFF6366F1)},
        {'name': 'Paracetamol 500mg', 'unit': 'Tablet', 'qty': 5, 'price': 2500, 'icon': Icons.medication_rounded, 'color': Color(0xFF10B981)},
      ],
      'summary': {'subtotal': 42500, 'shipping_cost': 10000, 'total': 52500},
      'notes': 'Mohon obat jangan dibanting, teras depan rumah ada pagar hitam.',
      'has_prescription': true,
    };

    final status = order['status'] as String;
    final cfg = _statusMap[status]!;
    final isFinished = status == 'COMPLETED' || status == 'CANCELLED';
    final isDelivery = order['type'] == 'DELIVERY';

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverHeader(context, order, cfg, isDelivery),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStatusTimeline(status),
                    const SizedBox(height: 16),
                    if (isDelivery) ...[
                      _buildShippingCard(order['shipping'] as Map<String, dynamic>),
                      const SizedBox(height: 16),
                    ],
                    _buildItemsCard(order),
                    const SizedBox(height: 16),
                    _buildPaymentCard(order),
                    const SizedBox(height: 16),
                    if ((order['has_prescription'] as bool) || (order['notes'] as String).isNotEmpty)
                      _buildNotesCard(context, order),
                  ]),
                ),
              ),
            ],
          ),
          if (!isFinished)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildActionPanel(context, status),
            ),
        ],
      ),
    );
  }

  // ── SLIVER HEADER ────────────────────────────
  Widget _buildSliverHeader(
    BuildContext context,
    Map<String, dynamic> order,
    _StatusCfg cfg,
    bool isDelivery,
  ) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: _C.primary,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 16),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white, size: 20),
            onPressed: () => _showMoreOptions(context),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            color: _C.primary,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        order['id'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cfg.icon, size: 10, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              cfg.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order['customer'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isDelivery
                            ? Icons.delivery_dining_rounded
                            : Icons.store_rounded,
                        color: Colors.white.withOpacity(0.7),
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isDelivery ? 'Delivery' : 'Pickup',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time_rounded,
                          color: Colors.white.withOpacity(0.7), size: 13),
                      const SizedBox(width: 5),
                      Text(
                        order['date'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      title: const Text(
        'Detail Pesanan',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 17,
        ),
      ),
    );
  }

  // ── STATUS TIMELINE ──────────────────────────
  Widget _buildStatusTimeline(String currentStatus) {
    final steps = [
      {'status': 'PENDING', 'label': 'Diterima', 'icon': Icons.inbox_rounded},
      {'status': 'PROCESSING', 'label': 'Diproses', 'icon': Icons.autorenew_rounded},
      {'status': 'READY', 'label': 'Siap', 'icon': Icons.check_circle_outline_rounded},
      {'status': 'COMPLETED', 'label': 'Selesai', 'icon': Icons.done_all_rounded},
    ];

    final statusOrder = ['PENDING', 'PROCESSING', 'READY', 'COMPLETED'];
    final currentIdx = statusOrder.indexOf(currentStatus);

    return _SectionCard(
      title: 'PROGRES PESANAN',
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final lineIdx = i ~/ 2;
            final isDone = lineIdx < currentIdx;
            return Expanded(
              child: Container(
                height: 2.5,
                decoration: BoxDecoration(
                  color: isDone ? _C.primary : _C.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final step = steps[stepIdx];
          final isDone = stepIdx < currentIdx;
          final isCurrent = stepIdx == currentIdx;

          return Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDone || isCurrent
                      ? _C.primary
                      : _C.bg,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(color: _C.primary, width: 2.5)
                      : null,
                  boxShadow: isCurrent
                      ? [BoxShadow(color: _C.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))]
                      : [],
                ),
                child: Icon(
                  step['icon'] as IconData,
                  size: 17,
                  color: isDone || isCurrent ? Colors.white : _C.textLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                step['label'] as String,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      isCurrent ? FontWeight.w900 : FontWeight.w600,
                  color: isCurrent ? _C.primary : _C.textLight,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── SHIPPING CARD ─────────────────────────────
  Widget _buildShippingCard(Map<String, dynamic> shipping) {
    return _SectionCard(
      title: 'INFO PENGIRIMAN',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address block
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _C.primaryLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: _C.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alamat Tujuan',
                        style: TextStyle(
                          fontSize: 11,
                          color: _C.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        shipping['address'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _C.textDark,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Courier info
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.local_shipping_rounded,
                  label: 'Kurir',
                  value: shipping['courier'] as String,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  icon: Icons.near_me_rounded,
                  label: 'Jarak',
                  value: shipping['distance'] as String,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoTile(
            icon: Icons.qr_code_rounded,
            label: 'No. Resi',
            value: shipping['tracking_no'] as String,
            highlight: true,
          ),
        ],
      ),
    );
  }

  // ── ITEMS CARD ───────────────────────────────
  Widget _buildItemsCard(Map<String, dynamic> order) {
    final items = order['items'] as List;
    final summary = order['summary'] as Map<String, dynamic>;

    return _SectionCard(
      title: 'ITEM PESANAN',
      child: Column(
        children: [
          ...items.map((item) => _buildItemRow(item as Map<String, dynamic>)),
          const SizedBox(height: 4),
          Container(height: 1, color: _C.divider),
          const SizedBox(height: 14),
          _PriceRow(label: 'Subtotal Produk', value: _formatRupiah(summary['subtotal'])),
          const SizedBox(height: 6),
          _PriceRow(label: 'Biaya Ongkir', value: _formatRupiah(summary['shipping_cost'])),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.primary.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grand Total',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: _C.textDark,
                  ),
                ),
                Text(
                  _formatRupiah(summary['total']),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: _C.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (item['color'] as Color).withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item['icon'] as IconData,
                color: item['color'] as Color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: _C.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item['unit']}  ·  ${item['qty']}x ${_formatRupiah(item['price'] as num)}',
                  style: const TextStyle(
                    color: _C.textLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatRupiah((item['qty'] as int) * (item['price'] as num)),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: _C.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── PAYMENT CARD ─────────────────────────────
  Widget _buildPaymentCard(Map<String, dynamic> order) {
    final isPaid = order['payment_status'] == 'PAID';
    return _SectionCard(
      title: 'PEMBAYARAN',
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPaid ? _C.successLight : _C.dangerLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isPaid
                  ? Icons.verified_rounded
                  : Icons.warning_amber_rounded,
              color: isPaid ? _C.success : _C.danger,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaid ? 'Sudah Dibayar' : 'Belum Dibayar',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: isPaid ? _C.success : _C.danger,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order['payment_method'] as String,
                  style: const TextStyle(
                    color: _C.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isPaid ? _C.successLight : _C.dangerLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isPaid
                    ? _C.success.withOpacity(0.3)
                    : _C.danger.withOpacity(0.3),
              ),
            ),
            child: Text(
              order['payment_status'] as String,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: isPaid ? _C.success : _C.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── NOTES CARD ───────────────────────────────
  Widget _buildNotesCard(BuildContext context, Map<String, dynamic> order) {
    final hasPrescription = order['has_prescription'] as bool;
    final notes = order['notes'] as String;

    return _SectionCard(
      title: 'CATATAN & RESEP',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPrescription)
            GestureDetector(
              onTap: () => _showPrescriptionDialog(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _C.orangeLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _C.orange.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _C.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.description_rounded,
                          color: _C.orange, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Pesanan ini melampirkan Resep Dokter',
                        style: TextStyle(
                          color: _C.orange,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: _C.orange, size: 18),
                  ],
                ),
              ),
            ),
          if (notes.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _C.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2_outlined,
                      color: _C.textLight, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notes,
                      style: const TextStyle(
                        color: _C.textMid,
                        fontSize: 13,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── ACTION PANEL ─────────────────────────────
  Widget _buildActionPanel(BuildContext context, String status) {
    final Map<String, Map<String, dynamic>> _actions = {
      'PENDING': {
        'label': 'Mulai Proses Pesanan',
        'icon': Icons.play_arrow_rounded,
        'sub': 'Ubah status ke "Sedang Diproses"',
      },
      'PROCESSING': {
        'label': 'Tandai Siap Diambil',
        'icon': Icons.check_circle_outline_rounded,
        'sub': 'Ubah status ke "Siap"',
      },
      'READY': {
        'label': 'Selesaikan Pesanan',
        'icon': Icons.done_all_rounded,
        'sub': 'Ubah status ke "Selesai"',
      },
    };

    final action = _actions[status];
    if (action == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            children: [
              // Cancel / More options
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _C.bg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: _C.textMid, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              // Main CTA
              Expanded(
                child: GestureDetector(
                  onTap: () => HapticFeedback.mediumImpact(),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: _C.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _C.primary.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(action['icon'] as IconData,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              action['label'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              action['sub'] as String,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: _C.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            _buildSheetItem(Icons.phone_outlined, 'Hubungi Customer', () => Navigator.pop(context)),
            _buildSheetItem(Icons.print_outlined, 'Cetak Struk', () => Navigator.pop(context)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: _C.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: _C.textDark)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showPrescriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Resep Dokter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _C.textDark)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.camera_alt_outlined, color: _C.textLight, size: 48),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: _C.textLight,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight ? _C.primaryLight : _C.bg,
        borderRadius: BorderRadius.circular(11),
        border: highlight
            ? Border.all(color: _C.primary.withOpacity(0.2))
            : null,
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 15,
              color: highlight ? _C.primary : _C.textLight),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: highlight ? _C.primary : _C.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: highlight ? _C.primary : _C.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: _C.textMid, fontWeight: FontWeight.w500)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                color: _C.textDark,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}