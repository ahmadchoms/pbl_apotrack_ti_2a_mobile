import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/models/order.dart';

class DeliveryInfoCard extends StatelessWidget {
  final Order order;

  const DeliveryInfoCard({super.key, required this.order});

  static const Map<String, String> _courierMap = {
    'jne':      'JNE Express',
    'jnt':      'J&T Express',
    'sicepat':  'SiCepat',
    'gojek':    'GoSend',
    'grab':     'GrabExpress',
    'anteraja': 'AnterAja',
    'tiki':     'TIKI',
    'pos':      'POS Indonesia',
  };

  static const Map<String, Map<String, dynamic>> _statusMap = {
    'confirmed':         {'label': 'Mencari Kurir',          'color': AppColors.warning},
    'allocated':         {'label': 'Kurir Ditemukan',         'color': AppColors.warning},
    'picking_up':        {'label': 'Menuju Apotek',           'color': AppColors.primary},
    'picked':            {'label': 'Paket Diambil',           'color': AppColors.primary},
    'dropping_off':      {'label': 'Sedang Diantar',          'color': AppColors.accentIndigo},
    'delivered':         {'label': 'Sampai Tujuan',           'color': AppColors.success},
    'cancelled':         {'label': 'Dibatalkan',              'color': AppColors.danger},
    'rejected':          {'label': 'Ditolak Kurir',           'color': AppColors.danger},
    'on_hold':           {'label': 'Ditahan Sementara',       'color': AppColors.warning},
    'courier_not_found': {'label': 'Kurir Tidak Ditemukan',   'color': AppColors.danger},
    'return_in_transit': {'label': 'Proses Pengembalian',     'color': AppColors.warning},
    'returned':          {'label': 'Paket Dikembalikan',      'color': AppColors.danger},
  };

  Future<void> _openTrackingUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracking = order.tracking;
    final address = order.address;

    final statusKey = tracking?.status ?? 'confirmed';
    final statusInfo = _statusMap[statusKey] ??
        {'label': statusKey.toUpperCase().replaceAll('_', ' '), 'color': AppColors.textMid};

    final companyRaw = tracking?.courierCompany?.toLowerCase() ?? '';
    final courierDisplayName = _courierMap[companyRaw] ?? companyRaw.toUpperCase();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INFO PENGIRIMAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.textLight,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),

          // Alamat tujuan
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alamat Tujuan',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        address?['address_detail']?.toString() ??
                            address?['complete_address']?.toString() ??
                            tracking?.destination?['address']?.toString() ??
                            '-',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Kurir & Status
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.local_shipping_rounded,
                  label: 'Kurir',
                  value: tracking != null && courierDisplayName.isNotEmpty
                      ? courierDisplayName
                      : '-',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  icon: Icons.info_outline_rounded,
                  label: 'Status Kurir',
                  value: statusInfo['label'] as String,
                  highlightColor: statusInfo['color'] as Color,
                  highlight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Nama & plat kurir
          if (tracking?.driverName != null) ...[
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.person_rounded,
                    label: 'Nama Kurir',
                    value: tracking!.driverName!,
                  ),
                ),
                if (tracking.driverPlateNumber != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.directions_car_rounded,
                      label: 'Plat Nomor',
                      value: tracking.driverPlateNumber!,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],

          // No. Resi
          _InfoTile(
            icon: Icons.qr_code_rounded,
            label: 'No. Resi / AWB',
            value: tracking?.trackingNumber ?? '-',
            highlight: tracking?.trackingNumber != null,
            trailing: tracking?.trackingNumber != null
                ? GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: tracking!.trackingNumber!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Resi disalin!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),

          // Tombol lacak
          if (tracking?.trackingLink != null) ...[
            const SizedBox(height: 16),
            AppButton(
              label: 'Lacak Paket (Biteship)',
              icon: Icons.open_in_new_rounded,
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.primary,
              onPressed: () => _openTrackingUrl(tracking!.trackingLink!),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  final Color highlightColor;
  final Widget? trailing;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
    this.highlightColor = AppColors.primary,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(color: highlightColor.withOpacity(0.2))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: highlight ? highlightColor : AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}