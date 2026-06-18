import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../staff/data/models/order.dart';

class TrackOrderEtaCard extends StatelessWidget {
  final DeliveryTracking tracking;

  const TrackOrderEtaCard({super.key, required this.tracking});

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'MENCARI KURIR';
      case 'allocated':
        return 'KURIR DITEMUKAN';
      case 'picking_up':
        return 'MENUJU APOTEK';
      case 'picked':
        return 'PAKET DIAMBIL';
      case 'dropping_off':
        return 'DALAM PERJALANAN';
      case 'delivered':
        return 'TERKIRIM';
      case 'cancelled':
        return 'DIBATALKAN';
      case 'rejected':
        return 'DITOLAK KURIR';
      case 'returned':
        return 'PAKET DIKEMBALIKAN';
      default:
        return status.toUpperCase().replaceAll('_', ' ');
    }
  }

  String _statusTitle(String status) {
    switch (status) {
      case 'confirmed':
        return 'Mencari Kurir Terdekat';
      case 'allocated':
        return 'Kurir Telah Ditemukan';
      case 'picking_up':
        return 'Kurir Menuju Apotek';
      case 'picked':
        return 'Paket Sedang Dibawa Kurir';
      case 'dropping_off':
        return 'Kurir Dalam Perjalanan';
      case 'delivered':
        return 'Pesanan Telah Sampai';
      case 'cancelled':
        return 'Pengiriman Dibatalkan';
      case 'rejected':
        return 'Kurir Menolak Pesanan';
      case 'returned':
        return 'Paket Dikembalikan';
      default:
        return 'Status Pengiriman';
    }
  }

  String _statusSubtitle(String status) {
    switch (status) {
      case 'confirmed':
        return 'Sistem sedang mencari kurir terdekat';
      case 'allocated':
        return 'Kurir akan segera menjemput pesanan';
      case 'picking_up':
        return 'Kurir sedang dalam perjalanan ke apotek';
      case 'picked':
        return 'Pesanan sudah diambil dan siap dikirim';
      case 'dropping_off':
        return 'Kurir sedang menuju lokasi Anda';
      case 'delivered':
        return 'Pesanan berhasil diterima';
      case 'cancelled':
        return 'Pengiriman telah dibatalkan';
      case 'rejected':
        return 'Kurir tidak dapat memproses pesanan ini';
      case 'returned':
        return 'Paket sedang dalam proses pengembalian';
      default:
        return 'Mohon tunggu proses pengiriman';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
      case 'rejected':
        return AppColors.danger;
      case 'returned':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'delivered':
        return AppColors.successLight;
      case 'cancelled':
      case 'rejected':
        return AppColors.dangerLight;
      case 'returned':
        return AppColors.warningLight;
      default:
        return AppColors.primaryLight;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.search_rounded;
      case 'allocated':
        return Icons.person_pin_circle_rounded;
      case 'picking_up':
        return Icons.store_rounded;
      case 'picked':
        return Icons.inventory_2_rounded;
      case 'dropping_off':
        return Icons.delivery_dining_rounded;
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel_rounded;
      case 'returned':
        return Icons.assignment_return_rounded;
      default:
        return Icons.local_shipping_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(tracking.status);
    final bgColor = _statusBgColor(tracking.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _statusLabel(tracking.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _statusTitle(tracking.status),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _statusSubtitle(tracking.status),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSlate,
                  ),
                ),
                if (tracking.trackingNumber != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.tag_rounded,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tracking.trackingNumber!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(_statusIcon(tracking.status), color: color, size: 30),
          ),
        ],
      ),
    );
  }
}
