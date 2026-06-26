import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../staff/data/models/order.dart';

/// This screen is no longer used since the delivery/tracking feature has been removed.
/// All orders are now pickup-only.
class TrackOrderScreen extends StatelessWidget {
  final Order order;

  const TrackOrderScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lacak Pesanan',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storefront_rounded,
                size: 64,
                color: AppColors.primary,
              ),
              SizedBox(height: 16),
              Text(
                'Ambil di Apotek',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Pesanan ini menggunakan metode ambil di tempat. Tunjukkan QR Code kepada staff apotek saat mengambil pesanan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
