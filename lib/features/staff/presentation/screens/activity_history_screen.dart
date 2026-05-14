import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/staff/data/models/audit_log.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/staff_provider.dart';

class ActivityHistoryScreen extends ConsumerWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditsAsync = ref.watch(staffAuditsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Riwayat Aktivitas',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(staffAuditsProvider.future),
        child: auditsAsync.when(
          data: (audits) {
            if (audits.isEmpty) {
              return _buildEmptyState();
            }
            return _buildActivityList(audits);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildErrorState(e.toString(), ref),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 80,
            color: AppColors.textLight.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada riwayat aktivitas',
            style: TextStyle(
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMid),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.refresh(staffAuditsProvider),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList(List<AuditLog> audits) {
    // Group by date
    final Map<String, List<AuditLog>> grouped = {};
    for (final audit in audits) {
      final dateKey = DateFormat('yyyy-MM-dd').format(audit.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(audit);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final dayAudits = grouped[dateKey]!;
        final dateLabel = _getFriendlyDate(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 16, top: 8),
              child: Text(
                dateLabel.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textLight,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...dayAudits.map((audit) => _buildTimelineItem(context, audit)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  String _getFriendlyDate(String dateKey) {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(now.subtract(const Duration(days: 1)));

    if (dateKey == today) return 'Hari Ini';
    if (dateKey == yesterday) return 'Kemarin';

    final date = DateTime.parse(dateKey);
    return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(date);
  }

  Widget _buildTimelineItem(BuildContext context, AuditLog audit) {
    final IconData icon;
    final Color color;

    final action = audit.action.toUpperCase();
    if (action.contains('LOGIN')) {
      icon = Icons.login_rounded;
      color = const Color(0xFF6366F1); // Indigo
    } else if (action.contains('LOGOUT')) {
      icon = Icons.logout_rounded;
      color = const Color(0xFF94A3B8); // Slate
    } else if (action.contains('MEDICINE') || action.contains('STOCK')) {
      icon = Icons.medication_rounded;
      color = const Color(0xFF10B981); // Emerald
    } else if (action.contains('ORDER') || action.contains('POS')) {
      icon = Icons.shopping_cart_rounded;
      color = const Color(0xFFF59E0B); // Amber
    } else if (action.contains('PROFILE') || action.contains('PASSWORD')) {
      icon = Icons.person_rounded;
      color = const Color(0xFF8B5CF6); // Violet
    } else {
      icon = Icons.bolt_rounded;
      color = const Color(0xFF3B82F6); // Blue
    }

    return InkWell(
      onTap: () => context.push('/staff/audit-log-detail', extra: audit),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- TIMELINE INDICATOR ---
              SizedBox(
                width: 44,
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withOpacity(0.2), width: 2),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              color.withOpacity(0.5),
                              color.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // --- CONTENT CARD ---
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: color.withOpacity(0.05), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              audit.action.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: color,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(audit.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        audit.description,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${audit.id.substring(0, 8).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textLight.withOpacity(0.7),
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
    );
  }
}
