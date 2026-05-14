import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/staff_provider.dart';
import '../widgets/urgent_task_card.dart';
import '../../data/models/medicine.dart';
import '../../data/models/order.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _formatStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu';
      case 'PROCESSING':
        return 'Diproses';
      case 'READY_FOR_PICKUP':
        return 'Siap Diambil';
      case 'SHIPPED':
        return 'Dikirim';
      case 'DELIVERED':
        return 'Terkirim';
      case 'COMPLETED':
        return 'Selesai';
      case 'CANCELLED':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '$hour:$minute · ${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return raw;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return AppColors.warning;
      case 'PROCESSING':
        return AppColors.primary;
      case 'READY_FOR_PICKUP':
      case 'DELIVERED':
      case 'COMPLETED':
        return AppColors.success;
      case 'SHIPPED':
        return AppColors.accentIndigo;
      case 'CANCELLED':
        return AppColors.danger;
      default:
        return AppColors.textLight;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.schedule_rounded;
      case 'PROCESSING':
        return Icons.autorenew_rounded;
      case 'READY_FOR_PICKUP':
        return Icons.check_circle_outline_rounded;
      case 'SHIPPED':
        return Icons.local_shipping_outlined;
      case 'DELIVERED':
        return Icons.inventory_2_outlined;
      case 'COMPLETED':
        return Icons.done_all_rounded;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          backgroundColor: Colors.white,
          strokeWidth: 2.5,
          displacement: 100,
          onRefresh: () async {
            ref.invalidate(staffOrdersProvider);
            ref.invalidate(staffMedicinesProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildSliverHeader(context, user, orders, medicines),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildPrimaryActions(context),
                    const SizedBox(height: 24),
                    _buildMetricsRow(orders, medicines),
                    const SizedBox(height: 28),
                    _buildUrgentSection(orders, medicines, context),
                    const SizedBox(height: 28),
                    _buildRecentOrdersSection(ordersAsync, context),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  SLIVER HEADER – gradient hero with greeting + quick stats
  // ───────────────────────────────────────────────────────────
  Widget _buildSliverHeader(
    BuildContext context,
    dynamic user,
    List<Order> orders,
    List<Medicine> medicines,
  ) {
    final String firstName = user?.username.split(' ')[0] ?? 'Staff';
    final String pharmacyName =
        user?.pharmacyName.toUpperCase() ?? 'APOTRAK SYSTEM';

    return SliverAppBar(
      expandedHeight: 160,
      collapsedHeight: 64,
      pinned: true,
      stretch: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.primary,
      centerTitle: false,
      titleSpacing: 24,
      actions: [
        _NotificationBell(onTap: () => context.push('/staff/notifications')),
        const SizedBox(width: 16),
      ],
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1D70F5), Color(0xFF1148C4)],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: 80,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // Top row: pharmacy name badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF34D399),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    pharmacyName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Greeting
                    Text(
                      'Selamat datang,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  PRIMARY ACTIONS – SCAN QR & KASIR POS (hero buttons)
  // ───────────────────────────────────────────────────────────
  Widget _buildPrimaryActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _HeroCTA(
              label: 'Scan QR',
              subLabel: 'Customer Check-in',
              icon: Icons.qr_code_scanner_rounded,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1D70F5), Color(0xFF1148C4)],
              ),
              onTap: () => context.push('/staff/scanner'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _HeroCTA(
              label: 'Kasir POS',
              subLabel: 'Transaksi Baru',
              icon: Icons.point_of_sale_rounded,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF97316), Color(0xFFEA580C)],
              ),
              onTap: () => context.push('/staff/pos'),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  METRICS ROW – operational stats cards
  // ───────────────────────────────────────────────────────────
  Widget _buildMetricsRow(List<Order> orders, List<Medicine> medicines) {
    final pending = orders.where((o) => o.orderStatus == 'PENDING').length;
    final lowStock = medicines.where((m) => m.totalActiveStock <= 10).length;
    final critical = medicines.where((m) => m.totalActiveStock <= 5).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _MetricCard(
              value: orders.length.toString(),
              label: 'Order Aktif',
              icon: Icons.receipt_long_rounded,
              iconColor: AppColors.primary,
              iconBg: AppColors.primaryLight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MetricCard(
              value: pending.toString(),
              label: 'Menunggu',
              icon: Icons.hourglass_top_rounded,
              iconColor: AppColors.warning,
              iconBg: AppColors.warningLight,
              highlight: pending > 0,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MetricCard(
              value: lowStock.toString(),
              label: 'Stok Tipis',
              icon: Icons.inventory_2_outlined,
              iconColor: critical > 0 ? AppColors.danger : AppColors.warning,
              iconBg: critical > 0
                  ? AppColors.dangerLight
                  : AppColors.warningLight,
              highlight: lowStock > 0,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  URGENT TASKS SECTION
  // ───────────────────────────────────────────────────────────
  Widget _buildUrgentSection(
    List<Order> orders,
    List<Medicine> medicines,
    BuildContext context,
  ) {
    final pending = orders.where((o) => o.orderStatus == 'PENDING').length;
    final critical = medicines.where((m) => m.totalActiveStock <= 5).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SectionLabel(title: 'TINDAKAN MENDESAK', onAction: null),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              if (pending > 0) ...[
                UrgentTaskCard(
                  title: '$pending Pesanan Baru',
                  subtitle: 'Butuh Validasi Segera',
                  icon: Icons.assignment_late_rounded,
                  color: AppColors.primary,
                  onTap: () => context.go('/staff?tab=1'),
                ),
                const SizedBox(width: 12),
              ],
              if (critical > 0) ...[
                UrgentTaskCard(
                  title: '$critical Obat Kritis',
                  subtitle: 'Restock Diperlukan',
                  icon: Icons.warning_rounded,
                  color: AppColors.danger,
                  onTap: () {},
                ),
                const SizedBox(width: 12),
              ],
              if (pending == 0 && critical == 0)
                UrgentTaskCard(
                  title: 'Operasional Aman',
                  subtitle: 'Tidak ada kendala kritis',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  onTap: () {},
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────
  //  RECENT ORDERS SECTION
  // ───────────────────────────────────────────────────────────
  Widget _buildRecentOrdersSection(
    AsyncValue<List<Order>> ordersAsync,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SectionLabel(
            title: 'AKTIVITAS PESANAN',
            actionLabel: 'Lihat Semua',
            onAction: () => context.go('/staff?tab=1'),
          ),
        ),
        const SizedBox(height: 12),
        ordersAsync.when(
          data: (orders) {
            if (orders.isEmpty) {
              return const _EmptyOrdersPlaceholder();
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: orders.take(5).length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final order = orders[i];
                return _OrderListTile(
                  order: order,
                  statusLabel: _formatStatus(order.orderStatus),
                  statusColor: _getStatusColor(order.orderStatus),
                  statusIcon: _getStatusIcon(order.orderStatus),
                  timeLabel: _formatDateTime(order.createdAt),
                  onTap: () =>
                      context.push(AppRouter.staffOrderDetail, extra: order),
                );
              },
            );
          },
          loading: () => const _OrdersLoadingSkeleton(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PRIVATE REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Animated notification bell button in the header
class _NotificationBell extends StatelessWidget {
  final VoidCallback onTap;
  const _NotificationBell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: const Icon(
          Icons.notifications_active_outlined,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

/// Hero CTA button – the two dominant actions (Scan QR, Kasir POS)
class _HeroCTA extends StatefulWidget {
  final String label;
  final String subLabel;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _HeroCTA({
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_HeroCTA> createState() => _HeroCTAState();
}

class _HeroCTAState extends State<_HeroCTA>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: (widget.gradient as LinearGradient).colors.first
                    .withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circle
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 22),
                    ),
                    const Spacer(),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subLabel,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual metric card for the stats row
class _MetricCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool highlight;

  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight
              ? iconColor.withOpacity(0.3)
              : AppColors.divider.withOpacity(0.6),
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header with optional "see all" action
class _SectionLabel extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionLabel({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textLight,
            letterSpacing: 1.4,
          ),
        ),
        if (onAction != null && actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Order list tile – premium enterprise card
class _OrderListTile extends StatelessWidget {
  final Order order;
  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final String timeLabel;
  final VoidCallback onTap;

  const _OrderListTile({
    required this.order,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primaryLight,
        highlightColor: AppColors.primaryLight.withOpacity(0.5),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              // Status icon bubble
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 14),
              // Customer info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customer['username'] ?? 'PELANGGAN UMUM',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: AppColors.textDark,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${order.orderNumber}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMid,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Status badge + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: AppColors.textSubtle,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state when no orders exist
class _EmptyOrdersPlaceholder extends StatelessWidget {
  const _EmptyOrdersPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 28,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada pesanan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textMid,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pesanan baru akan muncul di sini',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading state for orders
class _OrdersLoadingSkeleton extends StatelessWidget {
  const _OrdersLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(
          3,
          (i) => Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                _ShimmerBox(width: 44, height: 44, radius: 13),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(
                        width: double.infinity,
                        height: 13,
                        radius: 6,
                      ),
                      const SizedBox(height: 8),
                      _ShimmerBox(width: 100, height: 10, radius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _ShimmerBox(width: 60, height: 26, radius: 8),
                const SizedBox(width: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
