import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';

class AuditLogDetailScreen extends StatelessWidget {
  final Map<String, dynamic> activity;

  const AuditLogDetailScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final category = _getCategory(activity['action']);
    final color = _getCategoryColor(category);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // --- PREMIUM SLIVER HEADER ---
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withBlue(220),
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Icon(
                        _getCategoryIcon(category),
                        size: 250,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                            ),
                            child: Icon(
                              _getCategoryIcon(category),
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
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

          // --- CONTENT ---
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- ACTION TITLE ---
                    Text(
                      activity['action'] ?? 'Aktivitas Sistem',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time_filled_rounded, color: AppColors.textLight, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          activity['relative_time'] ?? 'Baru saja',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // --- DETAILS CARD ---
                    const Text(
                      'LOG DATA PEMERIKSAAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textLight,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.info_outline_rounded, 'Deskripsi', activity['description'] ?? '-'),
                          _buildDivider(),
                          _buildDetailRow(Icons.event_note_rounded, 'Waktu Riil', activity['created_at'] ?? activity['relative_time'] ?? '-'),
                          _buildDivider(),
                          _buildDetailRow(Icons.fingerprint_rounded, 'ID Log', '#LOG-${activity['id'] ?? '0000'}'),
                          _buildDivider(),
                          _buildDetailRow(Icons.person_pin_rounded, 'Otoritas', 'Staff Apotek'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- STATUS BADGE SECTION ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.success.withOpacity(0.1), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 24),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Aktivitas Terverifikasi',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textDark),
                                ),
                                Text(
                                  'Log ini telah dicatat secara otomatis oleh sistem keamanan ApoTrack.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMid, height: 1.4),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textLight.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(height: 1, color: AppColors.divider.withOpacity(0.5)),
    );
  }

  String _getCategory(String? action) {
    if (action == null) return 'Umum';
    if (action.contains('Stok')) return 'Inventori';
    if (action.contains('Pesanan')) return 'Transaksi';
    if (action.contains('Profil')) return 'Akun';
    return 'Sistem';
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Inventori': return Icons.inventory_2_rounded;
      case 'Transaksi': return Icons.receipt_long_rounded;
      case 'Akun': return Icons.manage_accounts_rounded;
      case 'Sistem': return Icons.settings_suggest_rounded;
      default: return Icons.history_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Inventori': return AppColors.primary;
      case 'Transaksi': return AppColors.success;
      case 'Akun': return AppColors.warning;
      case 'Sistem': return AppColors.danger;
      default: return AppColors.textMid;
    }
  }
}
