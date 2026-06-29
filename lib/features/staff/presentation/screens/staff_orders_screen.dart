import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/staff_provider.dart';
import '../providers/staff_notification_provider.dart';
import '../widgets/order_list_card.dart';
import 'package:mobile/core/models/order.dart';

class StaffOrdersScreen extends ConsumerStatefulWidget {
  const StaffOrdersScreen({super.key});

  @override
  ConsumerState<StaffOrdersScreen> createState() => _StaffOrdersScreenState();
}

class _StaffOrdersScreenState extends ConsumerState<StaffOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    {'status': 'PENDING', 'label': 'Baru'},
    {'status': 'PROCESSING', 'label': 'Proses'},
    {'status': 'READY_FOR_PICKUP', 'label': 'Siap'},
    {'status': 'CANCEL_REQUESTED', 'label': 'Minta Batal'},
    {'status': 'COMPLETED', 'label': 'Selesai'},
    {'status': 'CANCELLED', 'label': 'Batal'},
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

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(staffOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ordersAsync.when(
        data: (allOrders) => Column(
          children: [
            _buildFixedHeader(),
            _buildStickyTabBar(allOrders),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: _tabs.map((t) {
                  return _OrderListView(
                    status: t['status'] as String,
                    orders: allOrders
                        .where((o) => o.orderStatus == t['status'])
                        .toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildErrorState(err.toString()),
      ),
    );
  }

  Widget _buildFixedHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OPERASIONAL TOKO',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pesanan Pelanggan',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          _buildNotifBadgeIcon(),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildNotifBadgeIcon() {
    final unreadCountAsync = ref.watch(staffUnreadNotifProvider);
    final unreadCount = unreadCountAsync.whenOrNull(data: (c) => c) ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: () => context.push('/staff/notifications'),
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStickyTabBar(List<Order> orders) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: Align(
          alignment: Alignment.centerLeft,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textLight,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            dividerColor: Colors.transparent,
            tabs: _tabs.map((t) {
              final count = orders
                  .where((o) => o.orderStatus == t['status'])
                  .length;
              final isCancelRequest = t['status'] == 'CANCEL_REQUESTED';

              return Tab(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(t['label'] as String),
                    if (count > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (t['status'] == 'PENDING' || isCancelRequest)
                              ? AppColors.danger
                              : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: (t['status'] == 'PENDING' || isCancelRequest)
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 64,
            color: AppColors.danger,
          ),
          const SizedBox(height: 16),
          const Text(
            'Koneksi Terputus',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          Text(error, style: const TextStyle(color: AppColors.textLight)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.refresh(staffOrdersProvider),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(color: Colors.white),
            ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: AppColors.divider),
            const SizedBox(height: 16),
            Text(
              'Tidak ada pesanan',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final order = orders[i];
        return OrderListCard(
          order: order,
          statusConfig: _statusMap[order.orderStatus] ?? _statusMap['PENDING']!,
          formatRupiah: (val) {
            final str = val.toStringAsFixed(0);
            final buf = StringBuffer();
            for (int j = 0; j < str.length; j++) {
              if (j > 0 && (str.length - j) % 3 == 0) buf.write('.');
              buf.write(str[j]);
            }
            return 'Rp ${buf.toString()}';
          },
        );
      },
    );
  }
}

final Map<String, dynamic> _statusMap = {
  'PENDING': {
    'label': 'Baru',
    'color': AppColors.warning,
    'bgColor': AppColors.warningLight,
    'icon': Icons.hourglass_top_rounded,
  },
  'PROCESSING': {
    'label': 'Proses',
    'color': AppColors.primary,
    'bgColor': AppColors.primaryLight,
    'icon': Icons.autorenew_rounded,
  },
  'READY_FOR_PICKUP': {
    'label': 'Siap',
    'color': AppColors.success,
    'bgColor': AppColors.successLight,
    'icon': Icons.check_circle_rounded,
  },
  'COMPLETED': {
    'label': 'Selesai',
    'color': AppColors.success,
    'bgColor': AppColors.successLight,
    'icon': Icons.done_all_rounded,
  },
  'CANCEL_REQUESTED': {
    'label': 'Minta Batal',
    'color': AppColors.danger,
    'bgColor': AppColors.dangerLight,
    'icon': Icons.cancel_outlined,
  },
  'CANCELLED': {
    'label': 'Batal',
    'color': AppColors.danger,
    'bgColor': AppColors.dangerLight,
    'icon': Icons.cancel_rounded,
  },
};
