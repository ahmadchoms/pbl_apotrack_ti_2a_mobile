import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class NotificationPopup {
  static void show({
    required BuildContext context,
    required String title,
    required String body,
    String type = 'ORDER',
    String? referenceId,
    VoidCallback? onTap,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        Timer(const Duration(seconds: 5), () {
          if (ctx.mounted) Navigator.of(ctx).pop();
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getIconBgColor(type),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIcon(type),
                          color: _getIconColor(type),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        body,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                if (referenceId != null && referenceId.isNotEmpty)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: Text(
                              'Tutup',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: Colors.grey.shade200,
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              onTap?.call();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: const Text(
                              'Lihat',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static IconData _getIcon(String type) {
    switch (type.toUpperCase()) {
      case 'ORDER':
      case 'ORDER_STATUS':
        return Icons.shopping_bag_rounded;
      case 'STOCK':
      case 'INVENTORY':
        return Icons.inventory_2_rounded;
      case 'SYSTEM':
        return Icons.info_rounded;
      case 'PROMO':
        return Icons.discount_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  static Color _getIconBgColor(String type) {
    switch (type.toUpperCase()) {
      case 'ORDER':
      case 'ORDER_STATUS':
        return AppColors.primary.withValues(alpha: 0.1);
      case 'STOCK':
      case 'INVENTORY':
        return AppColors.success.withValues(alpha: 0.1);
      case 'SYSTEM':
        return AppColors.warning.withValues(alpha: 0.1);
      case 'PROMO':
        return AppColors.accentPurple.withValues(alpha: 0.1);
      default:
        return AppColors.info.withValues(alpha: 0.1);
    }
  }

  static Color _getIconColor(String type) {
    switch (type.toUpperCase()) {
      case 'ORDER':
      case 'ORDER_STATUS':
        return AppColors.primary;
      case 'STOCK':
      case 'INVENTORY':
        return AppColors.success;
      case 'SYSTEM':
        return AppColors.warning;
      case 'PROMO':
        return AppColors.accentPurple;
      default:
        return AppColors.info;
    }
  }
}
