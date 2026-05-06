import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OrderStatusTimeline extends StatelessWidget {
  final String currentStatus;

  const OrderStatusTimeline({
    super.key,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'status': 'PENDING', 'label': 'Diterima', 'icon': Icons.inbox_rounded},
      {'status': 'PROCESSING', 'label': 'Diproses', 'icon': Icons.autorenew_rounded},
      {'status': 'READY', 'label': 'Siap', 'icon': Icons.check_circle_outline_rounded},
      {'status': 'COMPLETED', 'label': 'Selesai', 'icon': Icons.done_all_rounded},
    ];

    final statusOrder = ['PENDING', 'PROCESSING', 'READY', 'COMPLETED'];
    final currentIdx = statusOrder.indexOf(currentStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROGRES PESANAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.textLight,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                final lineIdx = i ~/ 2;
                final isDone = lineIdx < currentIdx;
                return Expanded(
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.primary : AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }
              final stepIdx = i ~/ 2;
              final step = steps[stepIdx];
              final isDone = stepIdx < currentIdx;
              final isCurrent = stepIdx == currentIdx;

              return Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDone || isCurrent ? AppColors.primary : AppColors.background,
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: AppColors.primary, width: 2.5)
                          : null,
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      step['icon'] as IconData,
                      size: 17,
                      color: isDone || isCurrent ? Colors.white : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step['label'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                      color: isCurrent ? AppColors.primary : AppColors.textLight,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
