import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../staff/data/models/order.dart';

class TrackOrderEtaCard extends StatelessWidget {
  final DeliveryTracking tracking;

  const TrackOrderEtaCard({super.key, required this.tracking});

  String _statusTitle(String status) {
    switch (status) {
      case 'PICKED_UP':
        return 'Pesanan Sedang Dijemput';
      case 'DROPPING_OFF':
        return 'Kurir Dalam Perjalanan';
      case 'DELIVERED':
        return 'Pesanan Telah Sampai';
      default:
        return 'Status Pengiriman';
    }
  }

  String _statusSubtitle(String status) {
    switch (status) {
      case 'PICKED_UP':
        return 'Kurir sedang mengambil pesanan dari apotek';
      case 'DROPPING_OFF':
        return 'Kurir sedang menuju lokasi Anda';
      case 'DELIVERED':
        return 'Pesanan berhasil diterima';
      default:
        return 'Mohon tunggu proses pengiriman';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.03),
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
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tracking.status.replaceAll('_', ' '),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
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
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.delivery_dining_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}