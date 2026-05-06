import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/order_list_card.dart';

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
      _allOrders.where((o) => o['order_status'] == status).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
        color: AppColors.primary,
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
      {'label': 'Total', 'value': _allOrders.length, 'color': AppColors.primary},
      {'label': 'Pending', 'value': _countByStatus('PENDING'), 'color': AppColors.warning},
      {'label': 'Diproses', 'value': _countByStatus('PROCESSING'), 'color': AppColors.primary},
      {'label': 'Selesai', 'value': _countByStatus('COMPLETED'), 'color': AppColors.success},
    ];

    return Container(
      color: Colors.white,
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
                    color: AppColors.textLight,
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
      color: Colors.white,
      child: Column(
        children: [
          const Divider(height: 1, color: AppColors.divider),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.primary,
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
                              ? AppColors.warningLight
                              : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: t['status'] == 'PENDING'
                                ? AppColors.warning
                                : AppColors.primary,
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

class _OrderListView extends StatelessWidget {
  const _OrderListView({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final orders =
        _allOrders.where((o) => o['order_status'] == status).toList();

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.inbox_rounded,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tidak ada pesanan',
              style: TextStyle(
                color: AppColors.textLight,
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
      itemBuilder: (_, i) {
        final order = orders[i];
        final statusCfg = _statusMap[order['order_status']]!;
        return OrderListCard(
          order: order,
          statusConfig: {
            'label': statusCfg.label,
            'color': statusCfg.color,
            'bgColor': statusCfg.bgColor,
            'icon': statusCfg.icon,
          },
          formatRupiah: _formatRupiah,
        );
      },
    );
  }
}

// Dummy data & Helpers (Ideally moved to Data Layer in Phase 4)
final List<Map<String, dynamic>> _allOrders = [
  {
    'id': 1,
    'order_number': 'ORD-0921',
    'created_at': '05 Mei 2026 10:30',
    'buyer': {'username': 'Andi Setiawan'},
    'service_type': 'DELIVERY',
    'grand_total': 85000.0,
    'order_status': 'PENDING',
    'item_count': 3
  },
  {
    'id': 2,
    'order_number': 'ORD-0919',
    'created_at': '05 Mei 2026 09:45',
    'buyer': {'username': 'Rina Kusuma'},
    'service_type': 'PICKUP',
    'grand_total': 32000.0,
    'order_status': 'PENDING',
    'item_count': 1
  },
  {
    'id': 3,
    'order_number': 'ORD-0922',
    'created_at': '05 Mei 2026 11:15',
    'buyer': {'username': 'Siti Aminah'},
    'service_type': 'PICKUP',
    'grand_total': 120000.0,
    'order_status': 'PROCESSING',
    'item_count': 5
  },
  {
    'id': 4,
    'order_number': 'ORD-0920',
    'created_at': '05 Mei 2026 10:05',
    'buyer': {'username': 'Budi Prasetyo'},
    'service_type': 'DELIVERY',
    'grand_total': 67500.0,
    'order_status': 'PROCESSING',
    'item_count': 2
  },
  {
    'id': 5,
    'order_number': 'ORD-0918',
    'created_at': '05 Mei 2026 09:00',
    'buyer': {'username': 'Dewi Lestari'},
    'service_type': 'DELIVERY',
    'grand_total': 45000.0,
    'order_status': 'READY',
    'item_count': 2
  },
  {
    'id': 6,
    'order_number': 'ORD-0917',
    'created_at': '05 Mei 2026 08:30',
    'buyer': {'username': 'Ahmad Fauzi'},
    'service_type': 'PICKUP',
    'grand_total': 15000.0,
    'order_status': 'COMPLETED',
    'item_count': 1
  },
];

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
    color: AppColors.warning,
    bgColor: AppColors.warningLight,
    icon: Icons.hourglass_top_rounded,
  ),
  'PROCESSING': _StatusConfig(
    label: 'Diproses',
    color: AppColors.primary,
    bgColor: AppColors.primaryLight,
    icon: Icons.autorenew_rounded,
  ),
  'READY': _StatusConfig(
    label: 'Siap',
    color: AppColors.success,
    bgColor: AppColors.successLight,
    icon: Icons.check_circle_rounded,
  ),
  'COMPLETED': _StatusConfig(
    label: 'Selesai',
    color: AppColors.textMid,
    bgColor: AppColors.background,
    icon: Icons.done_all_rounded,
  ),
  'CANCELLED': _StatusConfig(
    label: 'Dibatalkan',
    color: AppColors.danger,
    bgColor: AppColors.dangerLight,
    icon: Icons.cancel_rounded,
  ),
};

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