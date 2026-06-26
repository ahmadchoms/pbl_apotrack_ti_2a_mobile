import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class VerificationScreen extends StatelessWidget {
  final String orderId;
  final String orderNumber;
  final String verificationCode;
  final String pharmacyName;
  final String serviceType;
  final List<Map<String, dynamic>> items;
  final int total;

  const VerificationScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.verificationCode,
    required this.pharmacyName,
    required this.serviceType,
    required this.items,
    required this.total,
  });

  String _rupiah(int amount) =>
      'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Verifikasi Pengambilan',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
            size: 18,
          ),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSuccessBanner(),
            const SizedBox(height: 24),
            _buildOrderInfo(),
            const SizedBox(height: 24),
            _buildQrCodeSection(),
            const SizedBox(height: 24),
            _buildInstructionCard(),
            const SizedBox(height: 32),
            _buildDoneButton(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pembayaran Berhasil!',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tunjukkan QR Code ini ke petugas apotek\nsaat mengambil obat',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              const Text(
                'INFORMASI PESANAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textLight,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow('No. Pesanan', orderNumber),
          const SizedBox(height: 10),
          _infoRow('Apotek', pharmacyName),
          const SizedBox(height: 10),
          _infoRow('Status', isPickUp ? 'Siap Diambil' : 'Diproses'),
          const SizedBox(height: 10),
          _infoRow('Total Bayar', _rupiah(total)),
          if (verificationCode.isNotEmpty && isPickUp) ...[
            const SizedBox(height: 10),
            _infoRow('Kode Verifikasi', verificationCode),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textLight),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  bool get isPickUp => serviceType == 'PICK_UP' || serviceType == 'PICKUP';

  Widget _buildQrCodeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'QR CODE PENGAMBILAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textLight,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: QrImageView(
              data: verificationCode.isNotEmpty ? verificationCode : orderId,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.textDark,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Pindai Kode QR ini di apotek${pharmacyName.isNotEmpty ? ' $pharmacyName' : ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tunjukkan QR Code atau kode verifikasi ke petugas apotek untuk mengambil obat.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E3A5F),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Selesai',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
    );
  }
}
