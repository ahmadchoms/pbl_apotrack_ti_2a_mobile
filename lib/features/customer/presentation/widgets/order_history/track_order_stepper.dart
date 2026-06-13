import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class TrackOrderStepper extends StatelessWidget {
  final String trackingStatus;

  const TrackOrderStepper({super.key, required this.trackingStatus});

  static const _statusOrder = ['PICKED_UP', 'DROPPING_OFF', 'DELIVERED'];

  static const _stepConfig = {
    'PICKED_UP': {
      'label': 'Pesanan Dijemput',
      'sub': 'Kurir sedang mengambil pesanan dari apotek',
      'icon': Icons.store_outlined,
    },
    'DROPPING_OFF': {
      'label': 'Sedang Dikirim',
      'sub': 'Kurir sedang menuju lokasi Anda',
      'icon': Icons.delivery_dining_rounded,
    },
    'DELIVERED': {
      'label': 'Sampai di Tujuan',
      'sub': 'Paket telah diserahkan kepada Anda',
      'icon': Icons.check_circle_outline_rounded,
    },
  };

  @override
  Widget build(BuildContext context) {
    final currentIndex = _statusOrder.indexOf(trackingStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STATUS PENGIRIMAN',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        ..._statusOrder.asMap().entries.map((entry) {
          final i = entry.key;
          final statusKey = entry.value;
          final config = _stepConfig[statusKey]!;
          final isDone = i < currentIndex;
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
        // ── Indikator kiri ──────────────────────
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
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: isActive
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
              child: Icon(
                isDone ? Icons.check_rounded : icon,
                color: isDone
                    ? Colors.white
                    : isActive
                    ? AppColors.primary
                    : const Color(0xFFCBD5E1),
                size: isDone ? 18 : 16,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isDone ? AppColors.primary : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 14),

        // ── Label kanan ─────────────────────────
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
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive || isDone
                        ? const Color(0xFF64748B)
                        : const Color(0xFFCBD5E1),
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
