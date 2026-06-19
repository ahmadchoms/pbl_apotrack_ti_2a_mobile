import 'package:flutter/material.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/status_badge.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../staff/data/models/order.dart';

class OrderHistoryCard extends StatelessWidget {
  final Order order;
  final VoidCallback onDetailTap;
  final VoidCallback? onPrimaryActionTap;
  final VoidCallback? onSecondaryActionTap;

  const OrderHistoryCard({
    super.key,
    required this.order,
    required this.onDetailTap,
    this.onPrimaryActionTap,
    this.onSecondaryActionTap,
  });

  _StatusConfig get _config {
    switch (order.orderStatus) {
      case 'PENDING':
        return _StatusConfig(
          badgeLabel: 'Menunggu',
          badgeColor: AppColors.warning,
          badgeBg: AppColors.warningLight,
          iconColor: AppColors.warning,
          iconBg: AppColors.warningLight,
          icon: Icons.hourglass_top_rounded,
          primaryLabel: 'Batalkan Pesanan',
          primarySolid: true,
        );
      case 'PROCESSING':
        return _StatusConfig(
          badgeLabel: 'Diproses',
          badgeColor: AppColors.info,
          badgeBg: AppColors.infoLight,
          iconColor: AppColors.info,
          iconBg: AppColors.infoLight,
          icon: Icons.science_rounded,
        );
      case 'READY_FOR_PICKUP':
        return _StatusConfig(
          badgeLabel: 'Siap Diambil',
          badgeColor: AppColors.accentIndigo,
          badgeBg: AppColors.primaryLight,
          iconColor: AppColors.accentIndigo,
          iconBg: AppColors.primaryLight,
          icon: Icons.storefront_rounded,
        );
      case 'SHIPPED':
        return _StatusConfig(
          badgeLabel: 'Dikirim',
          badgeColor: AppColors.accentOrange,
          badgeBg: AppColors.warningLight,
          iconColor: AppColors.accentOrange,
          iconBg: AppColors.warningLight,
          icon: Icons.local_shipping_rounded,
          primaryLabel: 'Lacak Kurir',
          primarySolid: true,
        );
      case 'DELIVERED':
        return _StatusConfig(
          badgeLabel: 'Diterima',
          badgeColor: AppColors.mapGrid,
          badgeBg: AppColors.warningLight,
          iconColor: AppColors.mapGrid,
          iconBg: AppColors.warningLight,
          icon: Icons.check_circle_rounded,
          primaryLabel: 'Beli Lagi',
          primarySolid: true,
        );
      case 'COMPLETED':
        return _StatusConfig(
          badgeLabel: 'Selesai',
          badgeColor: AppColors.success,
          badgeBg: AppColors.successLight,
          iconColor: AppColors.success,
          iconBg: AppColors.successLight,
          icon: Icons.check_circle_rounded,
          primaryLabel: 'Pesan Lagi',
          primarySolid: true,
          secondaryLabel: 'Ulasan',
        );
      case 'REVIEWED':
        return _StatusConfig(
          badgeLabel: 'Selesai',
          badgeColor: AppColors.success,
          badgeBg: AppColors.successLight,
          iconColor: AppColors.success,
          iconBg: AppColors.successLight,
          icon: Icons.check_circle_rounded,
          primaryLabel: 'Pesan Lagi',
          primarySolid: true,
          secondaryLabel: 'Sudah Diulas',
          secondaryDisabled: true,
        );
      case 'CANCELLED':
        return _StatusConfig(
          badgeLabel: 'Dibatalkan',
          badgeColor: AppColors.danger,
          badgeBg: AppColors.dangerLight,
          iconColor: AppColors.danger,
          iconBg: AppColors.dangerLight,
          icon: Icons.close_rounded,
          primaryLabel: 'Pesan Lagi',
          primarySolid: true,
          secondaryLabel: 'Rincian Pembatalan',
          priceStrikethrough: true,
        );
        case 'CANCEL_REQUESTED':
          return _StatusConfig(
            badgeLabel: 'Menunggu Konfirmasi',
            badgeColor: AppColors.textMid,
            badgeBg: AppColors.background,
            iconColor: AppColors.textMid,
            iconBg: AppColors.background,
            icon: Icons.pending_rounded,
            primaryLabel: 'Rincian Pembatalan',
            primarySolid: false,
          );
      default:
        return _StatusConfig(
          badgeLabel: order.orderStatus,
          badgeColor: AppColors.textLight,
          badgeBg: AppColors.background,
          iconColor: AppColors.textLight,
          iconBg: AppColors.background,
          icon: Icons.receipt_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config;
    final bool hasActions = cfg.primaryLabel != null;
    final bool hasTwoActions =
        cfg.secondaryLabel != null &&
        (onSecondaryActionTap != null || cfg.secondaryDisabled);

    final pharmacyName = order.pharmacy['name']?.toString() ?? '—';
    final pharmacyLogoUrl = order.pharmacy['logo_url']?.toString() ?? '';

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              pharmacyLogoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        pharmacyLogoUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cfg.iconBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.local_pharmacy_rounded,
                            color: cfg.iconColor,
                            size: 22,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cfg.iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.local_pharmacy_rounded,
                        color: cfg.iconColor,
                        size: 22,
                      ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pharmacyName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.createdAt,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: cfg.badgeLabel,
                color: cfg.badgeColor,
                backgroundColor: cfg.badgeBg,
                icon: Icons.circle,
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: AppColors.surfaceLight, height: 1),
          const SizedBox(height: 12),

          // ── Harga + detail ────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${order.items.length} Produk',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rp ${_formatPrice(order.grandTotal)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: cfg.priceStrikethrough
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      decoration: cfg.priceStrikethrough
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: AppColors.textMuted,
                      decorationThickness: 2,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: onDetailTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Detail Pesanan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Tombol aksi ───────────────────────────
          if (hasActions) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.surfaceLight, height: 1),
            const SizedBox(height: 12),
            if (hasTwoActions)
              Row(
                children: [
                  Expanded(
                    child: _actionBtn(
                      label: cfg.secondaryLabel!,
                      solid: false,
                      disabled: cfg.secondaryDisabled,
                      onTap: cfg.secondaryDisabled
                          ? null
                          : onSecondaryActionTap,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionBtn(
                      label: cfg.primaryLabel!,
                      solid: cfg.primarySolid,
                      onTap: onPrimaryActionTap,
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width / 2 - 26,
                  child: _actionBtn(
                    label: cfg.primaryLabel!,
                    solid: cfg.primarySolid,
                    onTap: onPrimaryActionTap,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required bool solid,
    bool disabled = false,
    VoidCallback? onTap,
  }) {
    final bgColor = disabled
        ? AppColors.surfaceLight
        : solid
        ? AppColors.primary
        : AppColors.white;
    final borderColor = disabled
        ? AppColors.divider
        : solid
        ? AppColors.primary
        : AppColors.divider;
    final textColor = disabled
        ? AppColors.textMuted
        : solid
        ? AppColors.white
        : AppColors.textMid;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(num price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }
}

class _StatusConfig {
  final String badgeLabel;
  final Color badgeColor;
  final Color badgeBg;
  final Color iconColor;
  final Color iconBg;
  final IconData icon;
  final String? primaryLabel;
  final bool primarySolid;
  final String? secondaryLabel;
  final bool secondaryDisabled;
  final bool priceStrikethrough;

  const _StatusConfig({
    required this.badgeLabel,
    required this.badgeColor,
    required this.badgeBg,
    required this.iconColor,
    required this.iconBg,
    required this.icon,
    this.primaryLabel,
    this.primarySolid = false,
    this.secondaryLabel,
    this.secondaryDisabled = false,
    this.priceStrikethrough = false,
  });
}
