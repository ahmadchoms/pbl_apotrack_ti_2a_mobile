import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────
//  SHARED THEME (konsisten dengan pos_screen)
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
class _StatusConfig {
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _StatusConfig({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.icon,
  });
}

const Map<String, _StatusConfig> _statusMap = {
  'PENDING': _StatusConfig(
    label: 'Pending',
    color: Color(0xFFF59E0B),
    bgColor: Color(0xFFFFFBEB),
    icon: Icons.hourglass_top_rounded,
  ),
  'PROCESSING': _StatusConfig(
    label: 'Diproses',
    color: Color(0xFF1D70F5),
    bgColor: Color(0xFFEEF4FF),
    icon: Icons.autorenew_rounded,
  ),
  'READY': _StatusConfig(
    label: 'Siap',
    color: Color(0xFF10B981),
    bgColor: Color(0xFFECFDF5),
    icon: Icons.check_circle_rounded,
  ),
  'COMPLETED': _StatusConfig(
    label: 'Selesai',
    color: Color(0xFF6B7280),
    bgColor: Color(0xFFF3F4F6),
    icon: Icons.done_all_rounded,
  ),
  'CANCELLED': _StatusConfig(
    label: 'Dibatalkan',
    color: Color(0xFFEF4444),
    bgColor: Color(0xFFFEF2F2),
    icon: Icons.cancel_rounded,
  ),
};

// ─────────────────────────────────────────────
//  DUMMY DATA
// ─────────────────────────────────────────────
final List<Map<String, dynamic>> _allOrders = [
  {'id': '#ORD-0921', 'time': '10:30', 'customer': 'Andi Setiawan', 'type': 'DELIVERY', 'total': 85000, 'status': 'PENDING', 'items': 3},
  {'id': '#ORD-0919', 'time': '09:45', 'customer': 'Rina Kusuma', 'type': 'PICKUP', 'total': 32000, 'status': 'PENDING', 'items': 1},
  {'id': '#ORD-0922', 'time': '11:15', 'customer': 'Siti Aminah', 'type': 'PICKUP', 'total': 120000, 'status': 'PROCESSING', 'items': 5},
  {'id': '#ORD-0920', 'time': '10:05', 'customer': 'Budi Prasetyo', 'type': 'DELIVERY', 'total': 67500, 'status': 'PROCESSING', 'items': 2},
  {'id': '#ORD-0918', 'time': '09:00', 'customer': 'Dewi Lestari', 'type': 'DELIVERY', 'total': 45000, 'status': 'READY', 'items': 2},
  {'id': '#ORD-0917', 'time': '08:30', 'customer': 'Ahmad Fauzi', 'type': 'PICKUP', 'total': 15000, 'status': 'COMPLETED', 'items': 1},
  {'id': '#ORD-0916', 'time': '08:00', 'customer': 'Mira Santoso', 'type': 'DELIVERY', 'total': 230000, 'status': 'COMPLETED', 'items': 7},
];

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────
class StaffOrdersScreen extends StatefulWidget {
  const StaffOrdersScreen({super.key});

  @override
  State<StaffOrdersScreen> createState() => _StaffOrdersScreenState();
}

class _StaffOrdersScreenState extends State<StaffOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    {'status': 'PENDING', 'label': 'Pending'},
    {'status': 'PROCESSING', 'label': 'Diproses'},
    {'status': 'READY', 'label': 'Siap'},
    {'status': 'COMPLETED', 'label': 'Selesai'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _countByStatus(String status) =>
      _allOrders.where((o) => o['status'] == status).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          _buildHeader(),
          _buildSummaryStrip(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs
                  .map((t) => _OrderListView(status: t['status']!))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: _C.primary,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manajemen Pesanan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    'Hari ini, 05 Mei 2026',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/staff/notifications'),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_none_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStrip() {
    final stats = [
      {'label': 'Total', 'value': _allOrders.length, 'color': _C.primary},
      {'label': 'Pending', 'value': _countByStatus('PENDING'), 'color': _C.warning},
      {'label': 'Diproses', 'value': _countByStatus('PROCESSING'), 'color': _C.primary},
      {'label': 'Selesai', 'value': _countByStatus('COMPLETED'), 'color': _C.success},
    ];

    return Container(
      color: _C.surface,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Column(
              children: [
                Text(
                  s['value'].toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: s['color'] as Color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s['label'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _C.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: _C.surface,
      child: Column(
        children: [
          const Divider(height: 1, color: _C.divider),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            labelColor: _C.primary,
            unselectedLabelColor: _C.textLight,
            indicatorColor: _C.primary,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            tabs: _tabs.map((t) {
              final count = _countByStatus(t['status']!);
              return Tab(
                child: Row(
                  children: [
                    Text(t['label']!),
                    if (count > 0 && t['status'] != 'COMPLETED') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: t['status'] == 'PENDING'
                              ? _C.warningLight
                              : _C.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: t['status'] == 'PENDING'
                                ? _C.warning
                                : _C.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ORDER LIST VIEW
// ─────────────────────────────────────────────
class _OrderListView extends StatelessWidget {
  const _OrderListView({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final orders =
        _allOrders.where((o) => o['status'] == status).toList();

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _C.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.inbox_rounded,
                  color: _C.primary, size: 36),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tidak ada pesanan',
              style: TextStyle(
                color: _C.textLight,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: orders.length,
      itemBuilder: (_, i) => _OrderCard(order: orders[i]),
    );
  }
}

// ─────────────────────────────────────────────
//  ORDER CARD
// ─────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String;
    final cfg = _statusMap[status]!;
    final isCompleted =
        status == 'COMPLETED' || status == 'CANCELLED';
    final isDelivery = order['type'] == 'DELIVERY';

    // Next action label
    final Map<String, String> _nextAction = {
      'PENDING': 'Mulai Proses',
      'PROCESSING': 'Tandai Siap',
      'READY': 'Selesaikan',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/staff/order-detail', extra: order);
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── ROW 1: ID + Time + Status ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _C.bg,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        order['id'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: _C.textMid,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.access_time_rounded,
                        size: 12, color: _C.textLight),
                    const SizedBox(width: 3),
                    Text(
                      order['time'],
                      style: const TextStyle(
                          fontSize: 11,
                          color: _C.textLight,
                          fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: cfg.bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cfg.icon, size: 11, color: cfg.color),
                          const SizedBox(width: 4),
                          Text(
                            cfg.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: cfg.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── ROW 2: Customer + Items ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['customer'],
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: _C.textDark,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${order['items']} item pesanan',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _C.textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatRupiah(order['total']),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: _C.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── ROW 3: Type + Action ──
                Row(
                  children: [
                    // Type pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDelivery ? _C.primaryLight : _C.successLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDelivery
                                ? Icons.delivery_dining_rounded
                                : Icons.store_rounded,
                            size: 13,
                            color: isDelivery ? _C.primary : _C.success,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isDelivery ? 'Delivery' : 'Pickup',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDelivery ? _C.primary : _C.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _C.bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Pesanan Selesai',
                          style: TextStyle(
                            color: _C.textLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.push('/staff/order-detail', extra: order);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _C.primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: _C.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            _nextAction[status] ?? 'Lihat Detail',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}