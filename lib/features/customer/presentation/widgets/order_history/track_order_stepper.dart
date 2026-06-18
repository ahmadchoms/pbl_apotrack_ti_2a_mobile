import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class TrackOrderStepper extends StatelessWidget {
  final String trackingStatus;

  const TrackOrderStepper({super.key, required this.trackingStatus});

  static const _statusOrder = [
    'confirmed',
    'allocated',
    'picking_up',
    'picked',
    'dropping_off',
    'delivered',
  ];

  static const _stepConfig = {
    'confirmed': {
      'label': 'Pesanan Dikonfirmasi',
      'sub': 'Sistem mencari kurir terdekat',
      'icon': Icons.search_rounded,
    },
    'allocated': {
      'label': 'Kurir Ditemukan',
      'sub': 'Kurir akan segera menjemput pesanan',
      'icon': Icons.person_pin_circle_rounded,
    },
    'picking_up': {
      'label': 'Kurir Menuju Apotek',
      'sub': 'Kurir dalam perjalanan ke apotek',
      'icon': Icons.store_rounded,
    },
    'picked': {
      'label': 'Paket Diambil',
      'sub': 'Pesanan sudah diambil oleh kurir',
      'icon': Icons.inventory_2_rounded,
    },
    'dropping_off': {
      'label': 'Sedang Dikirim',
      'sub': 'Kurir sedang menuju lokasi Anda',
      'icon': Icons.delivery_dining_rounded,
    },
    'delivered': {
      'label': 'Sampai di Tujuan',
      'sub': 'Paket telah diserahkan kepada Anda',
      'icon': Icons.check_circle_outline_rounded,
    },
  };

  @override
  Widget build(BuildContext context) {
    final currentIndex = _statusOrder.indexOf(trackingStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATUS PENGIRIMAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ..._statusOrder.asMap().entries.map((entry) {
            final i = entry.key;
            final statusKey = entry.value;
            final config = _stepConfig[statusKey]!;
            final isDone = currentIndex > i;
            final isActive = i == currentIndex;
            final isLast = i == _statusOrder.length - 1;

            return _buildStep(
              label: config['label'] as String,
              sub: config['sub'] as String,
              icon: config['icon'] as IconData,
              isDone: isDone,
              isActive: isActive,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String label,
    required String sub,
    required IconData icon,
    required bool isDone,
    required bool isActive,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.primary
                    : isActive
                    ? AppColors.primaryLight
                    : AppColors.stepInactiveBg,
                shape: BoxShape.circle,
                border: isActive
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
              child: Icon(
                isDone ? Icons.check_rounded : icon,
                color: isDone
                    ? AppColors.white
                    : isActive
                    ? AppColors.primary
                    : AppColors.stepInactive,
                size: isDone ? 18 : 16,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isDone ? AppColors.primary : AppColors.stepLine,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive || isDone
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: isActive
                        ? AppColors.primary
                        : isDone
                        ? AppColors.stepDone
                        : AppColors.stepInactive,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive || isDone
                        ? AppColors.textSlate
                        : AppColors.stepLine,
                  ),
                ),
                if (!isLast) const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
