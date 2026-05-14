import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/staff_provider.dart';
import '../widgets/order_list_card.dart';
import '../../data/models/order.dart';

class StaffOrdersScreen extends ConsumerStatefulWidget {
  const StaffOrdersScreen({super.key});

  @override
  ConsumerState<StaffOrdersScreen> createState() => _StaffOrdersScreenState();
}

class _StaffOrdersScreenState extends ConsumerState<StaffOrdersScreen>
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

  int _countByStatus(List<Order> orders, String status) =>
      orders.where((o) => o.orderStatus == status).length;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(staffOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ordersAsync.when(
        data: (allOrders) => Column(
          children: [
            _buildHeader(),
            _buildSummaryStrip(allOrders),
            _buildTabBar(allOrders),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(staffOrdersProvider.future),
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs
                      .map((t) => _OrderListView(
                            status: t['status']!,
                            orders: allOrders.where((o) => o.orderStatus == t['status']).toList(),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildErrorState(err.toString()),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Gagal Mengambil Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textLight),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.refresh(staffOrdersProvider),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(color: AppColors.primary),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manajemen Pesanan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    'Data riil dari Apotek Anda',
                    style: TextStyle(
                      color: Colors.white70,
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
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStrip(List<Order> orders) {
    final stats = [
      {'label': 'Total', 'value': orders.length, 'color': AppColors.primary},
      {'label': 'Pending', 'value': _countByStatus(orders, 'PENDING'), 'color': AppColors.warning},
      {'label': 'Diproses', 'value': _countByStatus(orders, 'PROCESSING'), 'color': AppColors.primary},
      {'label': 'Selesai', 'value': _countByStatus(orders, 'COMPLETED'), 'color': AppColors.success},
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
                  style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabBar(List<Order> orders) {
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
            tabs: _tabs.map((t) {
              final count = _countByStatus(orders, t['status']!);
              return Tab(
                child: Row(
                  children: [
                    Text(t['label']!),
                    if (count > 0 && t['status'] != 'COMPLETED') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: t['status'] == 'PENDING' ? AppColors.warningLight : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: t['status'] == 'PENDING' ? AppColors.warning : AppColors.primary,
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
  const _OrderListView({required this.status, required this.orders});
  final String status;
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text('Tidak ada pesanan'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final order = orders[i];
        final statusCfg = _statusMap[order.orderStatus] ?? _statusMap['PENDING']!;
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

const Map<String, _StatusConfig> _statusMap = {
  'PENDING': _StatusConfig(label: 'Pending', color: AppColors.warning, bgColor: AppColors.warningLight, icon: Icons.hourglass_top_rounded),
  'PROCESSING': _StatusConfig(label: 'Diproses', color: AppColors.primary, bgColor: AppColors.primaryLight, icon: Icons.autorenew_rounded),
  'READY': _StatusConfig(label: 'Siap', color: AppColors.success, bgColor: AppColors.successLight, icon: Icons.check_circle_rounded),
  'COMPLETED': _StatusConfig(label: 'Selesai', color: AppColors.textMid, bgColor: AppColors.background, icon: Icons.done_all_rounded),
};

class _StatusConfig {
  final String label; final Color color; final Color bgColor; final IconData icon;
  const _StatusConfig({required this.label, required this.color, required this.bgColor, required this.icon});
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