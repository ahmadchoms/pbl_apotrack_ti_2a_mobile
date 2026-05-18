import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/staff/data/models/audit_log.dart';
import '../../../../core/theme/app_colors.dart';

class AuditLogDetailScreen extends StatelessWidget {
  final AuditLog activity;

  const AuditLogDetailScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final category = _getCategory(activity.action);
    final color = _getCategoryColor(category);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // --- PREMIUM SLIVER HEADER ---
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: color,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withOpacity(0.8),
                      color.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background large glow icon
                    Positioned(
                      right: -60,
                      top: -40,
                      child: Icon(
                        _getCategoryIcon(category),
                        size: 300,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    // Glassmorphism overlay
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                _getCategoryIcon(category),
                                color: Colors.white,
                                size: 44,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Action Name
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                activity.action.replaceAll('_', ' ').toUpperCase(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Glow Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: activity.status.toUpperCase() == 'SUCCESS'
                                    ? AppColors.success.withOpacity(0.9)
                                    : AppColors.danger.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: activity.status.toUpperCase() == 'SUCCESS'
                                        ? AppColors.success.withOpacity(0.6)
                                        : AppColors.danger.withOpacity(0.6),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    activity.status.toUpperCase() == 'SUCCESS'
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.error_outline_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    activity.status.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- CONTENT ---
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -32),
              child: Container(
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 48),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TIME AND RELATIVE INFO ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.access_time_filled_rounded,
                                color: color,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat(
                                'EEEE, d MMM yyyy - HH:mm',
                                'id_ID',
                              ).format(activity.createdAt),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textMid,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        if (activity.relativeTime.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.textLight.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              activity.relativeTime,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMid,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // --- DETAILS CARD ---
                    const Text(
                      'LOG DATA PEMERIKSAAN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textLight,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildGlassCard(
                      color: color,
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: Icons.info_outline_rounded,
                            label: 'Deskripsi Aktivitas',
                            value: activity.description,
                            color: color,
                          ),
                          _buildDivider(),
                          _buildDetailRow(
                            icon: Icons.fingerprint_rounded,
                            label: 'ID Log Sistem',
                            value: activity.id.toUpperCase(),
                            color: color,
                          ),
                          _buildDivider(),
                          _buildDetailRow(
                            icon: Icons.person_pin_rounded,
                            label: 'Otoritas Pengguna',
                            value: activity.username ?? 'Staff Apotek / Apoteker',
                            color: color,
                          ),
                        ],
                      ),
                    ),

                    // --- DYNAMIC METADATA CARD ---
                    if (activity.metadata != null && activity.metadata!.isNotEmpty) ...[
                      const SizedBox(height: 36),
                      const Text(
                        'METADATA TAMBAHAN (TERSTRUKTUR)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textLight,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGlassCard(
                        color: color,
                        child: Column(
                          children: activity.metadata!.entries.map((e) {
                            final isLast = e.key == activity.metadata!.keys.last;
                            return Column(
                              children: [
                                _buildMetadataRow(
                                  key: e.key,
                                  value: e.value.toString(),
                                  color: color,
                                ),
                                if (!isLast) _buildDivider(),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // --- STATUS BADGE SECTION ---
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: AppColors.success,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 20),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Aktivitas Terverifikasi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Log ini telah dicatat secara otomatis oleh sistem keamanan ApoTrack.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMid,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow({
    required String key,
    required String value,
    required Color color,
  }) {
    final label = _mapMetadataKey(key);
    final icon = _getMetadataIcon(key);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Divider(height: 1, color: AppColors.divider.withOpacity(0.6)),
    );
  }

  String _mapMetadataKey(String key) {
    switch (key.toLowerCase()) {
      case 'order_id':
      case 'order_number':
      case 'invoice':
      case 'invoice_number':
        return 'Nomor Transaksi / Invoice';
      case 'total':
      case 'grand_total':
        return 'Total Pembayaran';
      case 'status':
      case 'order_status':
        return 'Status Pesanan';
      case 'courier':
      case 'courier_code':
      case 'courier_service':
        return 'Kurir Pengiriman';
      case 'medicine_id':
      case 'medicine_name':
        return 'Identitas Obat';
      case 'old_stock':
        return 'Stok Lama';
      case 'new_stock':
        return 'Stok Baru';
      case 'user_id':
      case 'staff_id':
        return 'ID Pengguna / Staf';
      case 'device':
      case 'user_agent':
        return 'Perangkat / Akses';
      case 'reason':
      case 'rejection_reason':
        return 'Keterangan / Alasan';
      default:
        return key
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
    }
  }

  IconData _getMetadataIcon(String key) {
    switch (key.toLowerCase()) {
      case 'order_id':
      case 'order_number':
      case 'invoice':
      case 'invoice_number':
        return Icons.tag_rounded;
      case 'total':
      case 'grand_total':
        return Icons.payments_rounded;
      case 'status':
      case 'order_status':
        return Icons.info_outline_rounded;
      case 'courier':
      case 'courier_code':
      case 'courier_service':
        return Icons.local_shipping_rounded;
      case 'medicine_id':
      case 'medicine_name':
        return Icons.medication_rounded;
      case 'old_stock':
        return Icons.history_toggle_off_rounded;
      case 'new_stock':
        return Icons.update_rounded;
      case 'user_id':
      case 'staff_id':
        return Icons.badge_rounded;
      case 'device':
      case 'user_agent':
        return Icons.devices_rounded;
      case 'reason':
      case 'rejection_reason':
        return Icons.notes_rounded;
      default:
        return Icons.data_object_rounded;
    }
  }

  String _getCategory(String action) {
    final act = action.toUpperCase();
    if (act.contains('MEDICINE') || act.contains('STOCK')) return 'Inventori';
    if (act.contains('ORDER') || act.contains('POS') || act.contains('SHIP') || act.contains('VERIFY')) return 'Transaksi';
    if (act.contains('PROFILE') || act.contains('PASSWORD')) return 'Akun';
    if (act.contains('LOGIN') || act.contains('LOGOUT')) return 'Sistem';
    return 'Umum';
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Inventori':
        return Icons.inventory_2_rounded;
      case 'Transaksi':
        return Icons.receipt_long_rounded;
      case 'Akun':
        return Icons.manage_accounts_rounded;
      case 'Sistem':
        return Icons.settings_suggest_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Inventori':
        return AppColors.primary;
      case 'Transaksi':
        return AppColors.success;
      case 'Akun':
        return AppColors.accentPurple;
      case 'Sistem':
        return AppColors.accentIndigo;
      default:
        return AppColors.textMid;
    }
  }
}
