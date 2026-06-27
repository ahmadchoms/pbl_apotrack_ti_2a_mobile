import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/models/audit_log.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/staff_provider.dart';

class ActivityHistoryScreen extends ConsumerWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditsState = ref.watch(staffAuditsProvider);

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
        onRefresh: () async => ref.read(staffAuditsProvider.notifier).refresh(),
        child: auditsState.isLoading && auditsState.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : auditsState.error != null && auditsState.items.isEmpty
            ? _buildErrorState(auditsState.error!, ref)
            : auditsState.items.isEmpty
            ? _buildEmptyState()
            : NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (!auditsState.isLoadingNextPage &&
                      auditsState.hasMore &&
                      scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 200) {
                    ref.read(staffAuditsProvider.notifier).fetchNextPage();
                  }
                  return false;
                },
                child: _buildActivityList(
                  auditsState.items,
                  auditsState.isLoadingNextPage,
                ),
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
            color: AppColors.textLight.withValues(alpha: 0.2),
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
              onPressed: () => ref.read(staffAuditsProvider.notifier).refresh(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList(List<AuditLog> audits, bool isLoadingNextPage) {
    final Map<String, List<AuditLog>> grouped = {};
    for (final audit in audits) {
      final dateKey = DateFormat('yyyy-MM-dd').format(audit.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(audit);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: sortedKeys.length + (isLoadingNextPage ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == sortedKeys.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

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
            ...dayAudits.map((audit) => LogItemCard(audit: audit)),
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
}

class LogItemCard extends StatelessWidget {
  final AuditLog audit;

  const LogItemCard({super.key, required this.audit});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    final action = audit.action.toUpperCase();
    if (action.contains('LOGIN')) {
      icon = Icons.login_rounded;
      color = AppColors.accentIndigo;
    } else if (action.contains('LOGOUT')) {
      icon = Icons.logout_rounded;
      color = AppColors.textLight;
    } else if (action.contains('ADD_MEDICINE') ||
        action.contains('UPDATE_MEDICINE')) {
      icon = Icons.check_circle_outline_rounded;
      color = AppColors.success;
    } else if (action.contains('DELETE_MEDICINE')) {
      icon = Icons.delete_outline_rounded;
      color = AppColors.danger;
    } else if (action.contains('ADJUST_STOCK') || action.contains('STOCK')) {
      icon = Icons.warning_amber_rounded;
      color = AppColors.warning;
    } else if (action.contains('ORDER') ||
        action.contains('POS') ||
        action.contains('SHIP') ||
        action.contains('VERIFY')) {
      icon = Icons.shopping_bag_outlined;
      color = AppColors.primary;
    } else if (action.contains('PROFILE') || action.contains('PASSWORD')) {
      icon = Icons.person_outline_rounded;
      color = AppColors.accentPurple;
    } else {
      icon = Icons.bolt_rounded;
      color = AppColors.info;
    }

    final displayTime = audit.relativeTime.isNotEmpty
        ? audit.relativeTime
        : DateFormat('HH:mm').format(audit.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/staff/audit-log-detail', extra: audit),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            audit.action.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: color,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Text(
                          displayTime,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      audit.description,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ID: ${audit.id.substring(0, 8).toUpperCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
