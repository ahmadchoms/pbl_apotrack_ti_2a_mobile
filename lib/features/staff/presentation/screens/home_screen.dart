import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/staff_provider.dart';
import '../providers/staff_notification_provider.dart';
import '../../data/services/staff_service.dart';
import '../../data/models/medicine.dart';
import '../../data/models/order.dart';
import 'package:mobile/features/staff/presentation/screens/scanner_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final shouldCollapse = _scrollController.offset > 100;

    if (shouldCollapse != _isCollapsed) {
      setState(() {
        _isCollapsed = shouldCollapse;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);

    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final ordersAsync = ref.watch(staffOrdersProvider);
    final medicinesState = ref.watch(staffMedicinesProvider);
    final orders = ordersAsync.whenOrNull(data: (d) => d) ?? [];
    final medicines = medicinesState.items;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(staffOrdersProvider);
            ref.invalidate(staffMedicinesProvider);
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernHeader(user),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPrimaryActionGrid(context),
                      const SizedBox(height: 32),
                      _buildOperationalKPI(orders, medicines),
                      const SizedBox(height: 32),
                      _buildRecentActivitySection(context, ordersAsync),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(dynamic user) {
    final firstName = user?.username.split(' ')[0] ?? 'Staff';
    final pharmacy = user?.pharmacyName ?? 'Apotek ApoTrack';

    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      centerTitle: false,
      titleSpacing: 20,
      title: AnimatedSlide(
        duration: const Duration(milliseconds: 250),
        offset: _isCollapsed ? Offset.zero : const Offset(0, -1),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _isCollapsed ? 1 : 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                firstName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
            ),
            Positioned(
              top: -20,
              right: -20,
              child: CircleAvatar(
                radius: 100,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isCollapsed ? 0 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPharmacyBadge(pharmacy),
                      const Spacer(),
                      const Text(
                        'Selamat bekerja,',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        firstName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _NotifBadgeIcon(
            unreadCountAsync: ref.watch(staffUnreadNotifProvider),
            onPressed: () => context.push('/staff/notifications'),
          ),
        ),
      ],
    );
  }

  Widget _buildPharmacyBadge(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: Color(0xFF34D399),
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _ActionCard(
            title: 'Scan QR',
            subtitle: 'Verifikasi Pengambilan',
            icon: Icons.qr_code_scanner_rounded,
            color: AppColors.primary,
            onTap: () async {
              final code = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (_) => const ScannerScreen()),
              );
              if (code == null || code.isEmpty) return;

              if (!context.mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                final order = await ref
                    .read(staffServiceProvider)
                    .verifyOrderByCode(code);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verifikasi berhasil!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                );
                context.push('/staff/order-detail', extra: order);
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Verifikasi gagal: $e'),
                    backgroundColor: AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 16),
          _ActionCard(
            title: 'Kasir POS',
            subtitle: 'Transaksi Baru',
            icon: Icons.point_of_sale_rounded,
            color: const Color(0xFFF97316),
            onTap: () => context.push('/staff/pos'),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalKPI(List<Order> orders, List<Medicine> medicines) {
    final pending = orders.where((o) => o.orderStatus == 'PENDING').length;
    final lowStock = medicines.where((m) => m.totalActiveStock <= 10).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _KPICard(
            label: 'Order Aktif',
            value: '${orders.length}',
            icon: Icons.receipt_long,
            color: AppColors.primary,
          ),
          _KPICard(
            label: 'Perlu Proses',
            value: '$pending',
            icon: Icons.pending_actions,
            color: AppColors.warning,
          ),
          _KPICard(
            label: 'Stok Kritis',
            value: '$lowStock',
            icon: Icons.inventory_2_outlined,
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(
    BuildContext context,
    AsyncValue<List<Order>> ordersAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'AKTIVITAS TERBARU',
          context,
          action: 'Lihat Semua',
          onTap: () => context.go('/staff/orders'),
        ),
        const SizedBox(height: 16),
        ordersAsync.when(
          data: (orders) => orders.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada aktivitas',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: orders.take(5).length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) =>
                      _RecentOrderTile(order: orders[i]),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    BuildContext context, {
    String? action,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.textLight,
              letterSpacing: 1.5,
            ),
          ),
          if (action != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    action,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final Order order;
  const _RecentOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final rupiahFormat = NumberFormat('#,###', 'id_ID');
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/staff/order-detail', extra: order);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.background,
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customer['username'] ?? 'Pelanggan',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rp ${rupiahFormat.format(order.grandTotal)}',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(order.orderStatus),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final Map<String, ({String label, Color color, IconData icon})>
    statusConfig = {
      'PENDING': (
        label: 'Pesanan Baru',
        color: AppColors.warning,
        icon: Icons.auto_awesome_rounded,
      ),
      'PROCESSING': (
        label: 'Sedang Disiapkan',
        color: AppColors.primary,
        icon: Icons.sync_rounded,
      ),
      'READY_FOR_PICKUP': (
        label: 'Siap Diambil',
        color: AppColors.success,
        icon: Icons.inventory_2_rounded,
      ),
      'COMPLETED': (
        label: 'Transaksi Selesai',
        color: AppColors.textMid,
        icon: Icons.check_circle_outline_rounded,
      ),
      'CANCELLED': (
        label: 'Dibatalkan',
        color: AppColors.danger,
        icon: Icons.cancel_outlined,
      ),
    };

    final config =
        statusConfig[status.toUpperCase()] ?? statusConfig['PENDING']!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: config.color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 12, color: config.color),
          const SizedBox(width: 6),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifBadgeIcon extends ConsumerWidget {
  final AsyncValue<int> unreadCountAsync;
  final VoidCallback onPressed;

  const _NotifBadgeIcon({
    required this.unreadCountAsync,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = unreadCountAsync.whenOrNull(data: (c) => c) ?? 0;

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: onPressed,
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
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
}
